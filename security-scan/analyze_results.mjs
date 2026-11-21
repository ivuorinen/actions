// Counts the findings in the SARIF reports security-scan's verification accepted, writes the
// total_issues and critical_issues outputs and a job summary, and exits 1 when a finding is
// critical. The outputs are left unset when a scanner that was to run has no counted report,
// so a caller never reads a scan that did not happen as zero findings.
//
// The Analyze Results step runs it with node from the workspace, where the reports are.
// verify-sarif and check-configs supply HAS_TRIVY, HAS_GITLEAKS, RUN_TRIVY and RUN_GITLEAKS
// through env, so a value with an apostrophe or a backtick cannot break the script.

import { appendFileSync, existsSync, readFileSync } from 'node:fs';

try {
  let totalIssues = 0;
  let criticalIssues = 0;

  const isCriticalLevel = r =>
    r.level === 'error' ||
    r.level === 'critical' ||
    (r.ruleId || '').toLowerCase().includes('critical');

  const analyzeSarif = (file, tool, isCritical) => {
    if (!existsSync(file)) {
      console.log(`No results file found for ${tool}`);
      return null;
    }

    try {
      const sarif = JSON.parse(readFileSync(file, 'utf8'));
      return sarif.runs.reduce((acc, run) => {
        if (!run.results) return acc;

        const critical = run.results.filter(isCritical).length;

        return {
          total: acc.total + run.results.length,
          critical: acc.critical + critical
        };
      }, { total: 0, critical: 0 });
    } catch (error) {
      console.log(`Error analyzing ${tool} results: ${error.message}`);
      return null;
    }
  };

  // Only analyze reports that verification accepted.
  const results = {
    trivy: process.env.HAS_TRIVY === 'true' ?
      analyzeSarif('trivy-results.sarif', 'trivy', isCriticalLevel) : null,
    // Gitleaks results carry no level, and each one is a detected secret.
    gitleaks: process.env.HAS_GITLEAKS === 'true' ?
      analyzeSarif('results.sarif', 'gitleaks', () => true) : null
  };

  // Aggregate results
  Object.entries(results).forEach(([tool, result]) => {
    if (result) {
      totalIssues += result.total;
      criticalIssues += result.critical;
      console.log(`${tool}: ${result.total} total, ${result.critical} critical issues`);
    }
  });

  // Every scanner is to run unless check-configs said otherwise; its RUN_* flag is empty when
  // the job stopped before check-configs finished. Totals without one of them are not totals.
  const uncounted = Object.keys(results).filter(
    tool => results[tool] === null && process.env[`RUN_${tool.toUpperCase()}`] !== 'false'
  );
  if (uncounted.length > 0) {
    console.log(`::warning::No issue totals: ${uncounted.join(' and ')} left no report to count`);
  }
  const shown = count => (uncounted.length > 0 ? 'not counted' : count);

  // Create summary
  const summary = `## Security Scan Summary

  - Total Issues Found: ${shown(totalIssues)}
  - Critical Issues: ${shown(criticalIssues)}

  ### Tool Breakdown
  ${Object.entries(results)
    .filter(([_, r]) => r)
    .map(([tool, r]) =>
      `- ${tool}: ${r.total} total, ${r.critical} critical`
    )
    .concat(uncounted.map(tool => `- ${tool}: no report to count`))
    .join('\n')}
  `;

  // Set outputs using GITHUB_OUTPUT
  const outputFile = process.env.GITHUB_OUTPUT;
  if (outputFile && uncounted.length === 0) {
    appendFileSync(outputFile, `total_issues=${totalIssues}\n`);
    appendFileSync(outputFile, `critical_issues=${criticalIssues}\n`);
  }

  // Add job summary using GITHUB_STEP_SUMMARY
  const summaryFile = process.env.GITHUB_STEP_SUMMARY;
  if (summaryFile) {
    appendFileSync(summaryFile, summary + '\n');
  }

  // Fail if critical issues found
  if (criticalIssues > 0) {
    console.error(`Found ${criticalIssues} critical security issues`);
    process.exit(1);
  }
} catch (error) {
  console.error(`Analysis failed: ${error.message}`);
  process.exit(1);
}

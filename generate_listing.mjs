#!/usr/bin/env node
// Prints the action catalog, or with --update writes it into README.md between its LISTING
// markers. Every top-level directory with an action.yml is an action in it.

import fs from 'node:fs';
import path from 'node:path';
import { load } from 'js-yaml';
import { markdownTable } from 'markdown-table';

// Each category's icon and actions, in the order the catalog lists the categories. An action in
// none of them is listed under Other, last.
const CATEGORIES = new Map([
  ['Setup', { icon: '🔧', actions: ['language-version-detect'] }],
  [
    'Linting',
    {
      icon: '📝',
      actions: ['ansible-lint-fix', 'biome-lint', 'csharp-lint-check', 'eslint-lint', 'go-lint', 'pr-lint', 'pre-commit', 'prettier-lint', 'python-lint-fix', 'terraform-lint-fix'],
    },
  ],
  ['Testing', { icon: '🧪', actions: ['php-tests'] }],
  ['Build', { icon: '🏗️', actions: ['csharp-build', 'go-build', 'docker-build'] }],
  ['Publishing', { icon: '🚀', actions: ['npm-publish', 'npm-semantic-release', 'docker-publish', 'csharp-publish'] }],
  ['Repository', { icon: '📦', actions: ['release-monthly', 'sync-labels', 'stale', 'compress-images', 'codeql-analysis'] }],
  ['Security', { icon: '🛡️', actions: ['security-scan'] }],
  ['Other', { icon: '📦', actions: [] }],
]);

const CATEGORY_OF = new Map([...CATEGORIES].flatMap(([category, { actions }]) => actions.map(name => [name, category])));

// The languages each action works with.
const LANGUAGE_SUPPORT = new Map([
  ['language-version-detect', ['PHP', 'Python', 'Go', '.NET', 'Node.js']],
  ['php-tests', ['PHP', 'Laravel']],
  ['python-lint-fix', ['Python']],
  ['go-lint', ['Go']],
  ['go-build', ['Go']],
  ['csharp-lint-check', ['C#', '.NET']],
  ['csharp-build', ['C#', '.NET']],
  ['csharp-publish', ['C#', '.NET']],
  ['docker-build', ['Docker']],
  ['docker-publish', ['Docker']],
  ['terraform-lint-fix', ['Terraform', 'HCL']],
  ['ansible-lint-fix', ['Ansible', 'YAML']],
  ['eslint-lint', ['JavaScript', 'TypeScript']],
  ['prettier-lint', ['JavaScript', 'TypeScript', 'Markdown', 'YAML', 'JSON']],
  ['biome-lint', ['JavaScript', 'TypeScript', 'JSON']],
  ['npm-publish', ['Node.js', 'npm']],
  ['npm-semantic-release', ['Node.js', 'npm']],
  ['codeql-analysis', ['JavaScript', 'TypeScript', 'Python', 'Java', 'C#', 'C++', 'Go', 'Ruby']],
  ['pre-commit', ['Python', 'Multiple Languages']],
  ['pr-lint', ['Conventional Commits']],
  ['sync-labels', ['YAML', 'GitHub']],
  ['release-monthly', ['GitHub Actions']],
  ['stale', ['GitHub Actions']],
  ['compress-images', ['Images', 'PNG', 'JPEG']],
]);

// The catalog's icon for each branding icon an action.yml can name.
const ICON_MAP = new Map([
  ['terminal', '💻'],
  ['code', '📝'],
  ['check-circle', '✅'],
  ['check', '✓'],
  ['package', '📦'],
  ['upload-cloud', '☁️'],
  ['git-commit', '🔀'],
  ['git-pull-request', '🔄'],
  ['tag', '🏷️'],
  ['alert-circle', '⚠️'],
  ['settings', '⚙️'],
  ['shield', '🛡️'],
  ['lock', '🔒'],
  ['unlock', '🔓'],
  ['eye', '👁️'],
  ['database', '💾'],
  ['server', '🖥️'],
  ['globe', '🌐'],
  ['zap', '⚡'],
  ['refresh-cw', '🔄'],
  ['box', '📦'],
  ['layers', '📚'],
  ['file-text', '📄'],
  ['folder', '📁'],
  ['archive', '🗂️'],
  ['image', '🖼️'],
  ['activity', '📊'],
]);

// The parsed action.yml in dir, or null when dir has none. js-yaml 4 and later builds only plain
// data: a tag that would construct a function or a regular expression fails the load, and the
// error names the file.
function readAction(dir) {
  const file = path.join(dir, 'action.yml');
  let content;
  try {
    // The rule flags every path that is not a literal; this one is a top-level directory of the
    // repository, from getAllActions' own listing, joined with action.yml.
    // eslint-disable-next-line security/detect-non-literal-fs-filename -- a listed directory's action.yml
    content = fs.readFileSync(file, 'utf8');
  } catch (error) {
    if (error.code === 'ENOENT') return null;
    throw error;
  }
  return load(content, { filename: file });
}

// Caching, read from the steps: an actions/cache step, a step's cache or cache-from setting that
// is not false, or a cache or cache-from input. The raw text also held comments and settings that
// turn a cache off, such as no-cache: true.
function caches(action) {
  const cacheSetting = ([key, value]) => ['cache', 'cache-from'].includes(key) && String(value) !== 'false';
  const cachingStep = step => String(step.uses || '').startsWith('actions/cache') || Object.entries(step.with || {}).some(cacheSetting);
  const steps = action.runs?.steps || [];
  return steps.some(cachingStep) || ['cache', 'cache-from'].some(name => name in (action.inputs || {}));
}

// Auto-detection is what the action documents: its directory, its name, its description or an
// input's description says it detects something. A comment or a step's text says nothing to a
// caller.
function detects(action, name) {
  const inputs = Object.values(action.inputs || {});
  const documented = [name, action.name, action.description, ...inputs.map(input => input?.description)];
  return documented.some(text => /\bdetect/i.test(String(text ?? '')));
}

// The features the catalog lists for the action named name, in the feature matrix's order.
function featuresOf(action, name) {
  const features = [];
  if (caches(action)) features.push('Caching');
  if (detects(action, name)) features.push('Auto-detection');
  if (action.inputs?.token) features.push('Token auth');
  if (Object.keys(action.outputs || {}).length > 0) features.push('Outputs');
  return features;
}

// The catalog entry for the action in dir, or null when dir has no action.yml.
function getActionDetails(dir) {
  const action = readAction(dir);
  if (!action) return null;

  const name = path.basename(dir);
  return {
    name,
    description: action.description || 'No description',
    category: CATEGORY_OF.get(name) ?? 'Other',
    icon: ICON_MAP.get(action.branding?.icon) ?? '📦',
    features: featuresOf(action, name),
    languages: LANGUAGE_SUPPORT.get(name) ?? [],
  };
}

// Every top-level directory's action, sorted by name.
function getAllActions() {
  return fs
    .readdirSync('.', { withFileTypes: true })
    .filter(entry => entry.isDirectory() && !entry.name.startsWith('.') && entry.name !== 'node_modules')
    .map(entry => getActionDetails(entry.name))
    .filter(Boolean)
    .sort((a, b) => a.name.localeCompare(b.name));
}

// The action's name, linked to its README through the reference links.
function link(name) {
  return `[\`${name}\`][${name}]`;
}

// text cut to length characters, with an ellipsis when it was longer.
function shorten(text, length) {
  return text.length > length ? `${text.substring(0, length)}...` : text;
}

function generateQuickReference(actions) {
  const rows = [
    ['Icon', 'Action', 'Category', 'Description', 'Key Features'],
    ...actions.map(action => [action.icon, link(action.name), action.category, shorten(action.description, 60), action.features.join(', ') || '-']),
  ];
  return markdownTable(rows, { align: ['c', 'l', 'l', 'l', 'l'] });
}

/**
 * Generate per-category Markdown sections containing tables of actions and their brief details.
 *
 * Sections appear in the order of CATEGORIES, and a category with no actions has none.
 *
 * @param {Array<Object>} actions - Catalog entries, as getActionDetails returns them.
 * @returns {string} A Markdown string with one section per category, each containing a table of actions with columns: Action, Description, Languages, and Features.
 */
function generateCategoryTables(actions) {
  let output = '';

  for (const [category, { icon }] of CATEGORIES) {
    const listed = actions.filter(action => action.category === category);
    if (listed.length === 0) continue;

    const actionWord = listed.length === 1 ? 'action' : 'actions';
    output += `\n#### ${icon} ${category} (${listed.length} ${actionWord})\n\n`;

    const rows = [
      ['Action', 'Description', 'Languages', 'Features'],
      ...listed.map(action => [`${action.icon} ${link(action.name)}`, shorten(action.description, 50), action.languages.join(', ') || '-', action.features.join(', ') || '-']),
    ];
    output += `${markdownTable(rows, { align: ['l', 'l', 'l', 'l'] })}\n`;
  }

  return output;
}

function generateFeatureMatrix(actions) {
  const features = ['Caching', 'Auto-detection', 'Token auth', 'Outputs'];
  const rows = [['Action', ...features], ...actions.map(action => [link(action.name), ...features.map(feature => (action.features.includes(feature) ? '✅' : '-'))])];
  return markdownTable(rows, { align: ['l', 'c', 'c', 'c', 'c'] });
}

function generateLanguageMatrix(actions) {
  const languages = [...new Set(actions.flatMap(action => action.languages))].sort();
  if (languages.length === 0) return '';

  const rows = [
    ['Language', 'Actions'],
    ...languages.map(language => [
      language,
      actions
        .filter(action => action.languages.includes(language))
        .map(action => link(action.name))
        .join(', '),
    ]),
  ];
  return markdownTable(rows, { align: ['l', 'l'] });
}

function generateReferenceLinks(actions) {
  const links = actions.map(action => `[${action.name}]: ${action.name}/README.md`).join('\n');
  return `\n<!-- Reference Links -->\n${links}\n`;
}

/**
 * Builds the complete Markdown catalog for the actions.
 *
 * The generated content includes a quick reference, per-category tables, a feature matrix,
 * language support matrix, usage examples with recommended pinned refs, action reference links,
 * and a closing separator.
 *
 * @param {Array<Object>} actions - Catalog entries, sorted by name.
 * @returns {string} The assembled catalog as a Markdown-formatted string.
 */
function generateCatalogContent(actions) {
  const totalCount = actions.length;

  let content = `## 📚 Action Catalog\n\n`;
  content += `This repository contains **${totalCount} reusable GitHub Actions** for CI/CD automation.\n\n`;

  content += `### Quick Reference (${totalCount} Actions)\n\n`;
  content += generateQuickReference(actions);

  content += `\n\n### Actions by Category\n`;
  content += generateCategoryTables(actions);

  content += `\n### Feature Matrix\n\n`;
  content += generateFeatureMatrix(actions);

  content += `\n\n### Language Support\n\n`;
  content += generateLanguageMatrix(actions);

  content += `\n\n### Action Usage\n\n`;
  content += 'All actions can be used independently in your workflows:\n\n';
  content += '```yaml\n';
  content += '# Recommended: Use pinned refs for supply-chain security\n';
  content += '- uses: ivuorinen/actions/action-name@vYYYY-MM-DD # Date-based tag (example)\n';
  content += '  with:\n';
  content += '    # action-specific inputs\n';
  content += '\n';
  content += '# Alternative: Use commit SHA for immutability\n';
  content += '- uses: ivuorinen/actions/action-name@abc123def456 # Full commit SHA\n';
  content += '  with:\n';
  content += '    # action-specific inputs\n';
  content += '```\n\n';
  content += '> **Security Note**: Always pin to specific tags or commit SHAs instead of `@main` to ensure reproducible workflows and supply-chain integrity.\n';

  content += generateReferenceLinks(actions);

  content += `\n---`;

  return content;
}

function updateReadme(catalogContent, count) {
  const readmeContent = fs.readFileSync('README.md', 'utf8');
  const startMarker = '<!--LISTING-->';
  const endMarker = '<!--/LISTING-->';

  const startIndex = readmeContent.indexOf(startMarker);
  const endIndex = readmeContent.indexOf(endMarker);

  if (startIndex === -1 || endIndex === -1) {
    console.error('❌ Error: Could not find LISTING markers in README.md');
    console.error('   Make sure README.md contains <!--LISTING--> and <!--/LISTING--> markers');
    process.exit(1);
  }

  if (startIndex >= endIndex) {
    console.error('❌ Error: Invalid marker order in README.md');
    console.error('   <!--LISTING--> must come before <!--/LISTING-->');
    process.exit(1);
  }

  const before = readmeContent.substring(0, startIndex + startMarker.length);
  const after = readmeContent.substring(endIndex);
  const newContent = `${before}\n<!-- This section is auto-generated. Run 'npm run update-catalog' to update. -->\n\n${catalogContent}\n\n${after}`;

  fs.writeFileSync('README.md', newContent, 'utf8');
  console.log('✅ Successfully updated README.md with new catalog');
  console.log(`📊 Updated catalog with ${count} ${count === 1 ? 'action' : 'actions'}`);
}

const actions = getAllActions();
const catalogContent = generateCatalogContent(actions);

if (process.argv.slice(2).includes('--update')) {
  updateReadme(catalogContent, actions.length);
} else {
  console.log(catalogContent);
}

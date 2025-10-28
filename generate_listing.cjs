#!/usr/bin/env node

const fs = require('node:fs');
const path = require('node:path');
const yaml = require('js-yaml');
const { markdownTable } = require('markdown-table');

// Category mappings
const CATEGORIES = {
  // Setup & Environment
  'node-setup': 'Setup',
  'set-git-config': 'Setup',
  'php-version-detect': 'Setup',
  'python-version-detect': 'Setup',
  'python-version-detect-v2': 'Setup',
  'go-version-detect': 'Setup',
  'dotnet-version-detect': 'Setup',

  // Utilities
  'action-versioning': 'Utilities',
  'version-file-parser': 'Utilities',
  'version-validator': 'Utilities',

  // Linting & Formatting
  'ansible-lint-fix': 'Linting',
  'biome-check': 'Linting',
  'biome-fix': 'Linting',
  'csharp-lint-check': 'Linting',
  'eslint-check': 'Linting',
  'eslint-fix': 'Linting',
  'go-lint': 'Linting',
  'pr-lint': 'Linting',
  'pre-commit': 'Linting',
  'prettier-check': 'Linting',
  'prettier-fix': 'Linting',
  'python-lint-fix': 'Linting',
  'terraform-lint-fix': 'Linting',

  // Testing & Quality
  'php-tests': 'Testing',
  'php-laravel-phpunit': 'Testing',
  'php-composer': 'Testing',

  // Build & Package
  'csharp-build': 'Build',
  'go-build': 'Build',
  'docker-build': 'Build',

  // Publishing
  'npm-publish': 'Publishing',
  'docker-publish': 'Publishing',
  'docker-publish-gh': 'Publishing',
  'docker-publish-hub': 'Publishing',
  'csharp-publish': 'Publishing',

  // Repository Management
  'github-release': 'Repository',
  'release-monthly': 'Repository',
  'sync-labels': 'Repository',
  stale: 'Repository',
  'compress-images': 'Repository',
  'common-cache': 'Repository',
  'common-file-check': 'Repository',
  'common-retry': 'Repository',
  'codeql-analysis': 'Repository',

  // Validation
  'validate-inputs': 'Validation',
};

// Language support mappings
const LANGUAGE_SUPPORT = {
  'node-setup': ['Node.js', 'JavaScript', 'TypeScript'],
  'php-tests': ['PHP'],
  'php-laravel-phpunit': ['PHP', 'Laravel'],
  'php-composer': ['PHP'],
  'php-version-detect': ['PHP'],
  'python-lint-fix': ['Python'],
  'python-version-detect': ['Python'],
  'python-version-detect-v2': ['Python'],
  'go-lint': ['Go'],
  'go-build': ['Go'],
  'go-version-detect': ['Go'],
  'csharp-lint-check': ['C#', '.NET'],
  'csharp-build': ['C#', '.NET'],
  'csharp-publish': ['C#', '.NET'],
  'dotnet-version-detect': ['C#', '.NET'],
  'docker-build': ['Docker'],
  'docker-publish': ['Docker'],
  'docker-publish-gh': ['Docker'],
  'docker-publish-hub': ['Docker'],
  'terraform-lint-fix': ['Terraform', 'HCL'],
  'ansible-lint-fix': ['Ansible', 'YAML'],
  'eslint-check': ['JavaScript', 'TypeScript'],
  'eslint-fix': ['JavaScript', 'TypeScript'],
  'prettier-check': ['JavaScript', 'TypeScript', 'Markdown', 'YAML', 'JSON'],
  'prettier-fix': ['JavaScript', 'TypeScript', 'Markdown', 'YAML', 'JSON'],
  'biome-check': ['JavaScript', 'TypeScript', 'JSON'],
  'biome-fix': ['JavaScript', 'TypeScript', 'JSON'],
  'npm-publish': ['Node.js', 'npm'],
  'codeql-analysis': ['JavaScript', 'TypeScript', 'Python', 'Java', 'C#', 'C++', 'Go', 'Ruby'],
  'validate-inputs': ['YAML', 'GitHub Actions'],
  'pre-commit': ['Python', 'Multiple Languages'],
  'pr-lint': ['Conventional Commits'],
  'sync-labels': ['YAML', 'GitHub'],
  'version-file-parser': ['Multiple Languages'],
  'version-validator': ['Semantic Versioning', 'CalVer'],
};

// Icon mapping for GitHub branding
const ICON_MAP = {
  terminal: '💻',
  code: '📝',
  'check-circle': '✅',
  check: '✓',
  package: '📦',
  'upload-cloud': '☁️',
  'git-commit': '🔀',
  'git-pull-request': '🔄',
  tag: '🏷️',
  'alert-circle': '⚠️',
  settings: '⚙️',
  shield: '🛡️',
  lock: '🔒',
  unlock: '🔓',
  eye: '👁️',
  database: '💾',
  server: '🖥️',
  globe: '🌐',
  zap: '⚡',
  'refresh-cw': '🔄',
  box: '📦',
  layers: '📚',
  'file-text': '📄',
  folder: '📁',
  archive: '🗂️',
  image: '🖼️',
  activity: '📊',
};

// Category icons
const CATEGORY_ICONS = {
  Setup: '🔧',
  Utilities: '🛠️',
  Linting: '📝',
  Testing: '🧪',
  Build: '🏗️',
  Publishing: '🚀',
  Repository: '📦',
  Validation: '✅',
};

function getActionDetails(actionPath) {
  const actionYmlPath = path.join(actionPath, 'action.yml');
  if (!fs.existsSync(actionYmlPath)) {
    return null;
  }

  try {
    const content = fs.readFileSync(actionYmlPath, 'utf8');
    const action = yaml.load(content);
    const actionName = path.basename(actionPath);

    // Extract features
    const features = [];

    // Check for caching
    if (content.includes('actions/cache') || content.includes('cache:')) {
      features.push('Caching');
    }

    // Check for auto-detection
    if (actionName.includes('detect') || content.includes('detect')) {
      features.push('Auto-detection');
    }

    // Check for token usage
    if (action.inputs?.token) {
      features.push('Token auth');
    }

    // Check for outputs
    if (action.outputs && Object.keys(action.outputs).length > 0) {
      features.push('Outputs');
    }

    // Get icon
    const icon = action.branding?.icon ? ICON_MAP[action.branding.icon] || '📦' : '📦';

    return {
      name: actionName,
      displayName: action.name || actionName,
      description: action.description || 'No description',
      category: CATEGORIES[actionName] || 'Other',
      icon: icon,
      features: features,
      languages: LANGUAGE_SUPPORT[actionName] || [],
      hasInputs: action.inputs && Object.keys(action.inputs).length > 0,
      hasOutputs: action.outputs && Object.keys(action.outputs).length > 0,
      path: actionPath,
    };
  } catch (error) {
    console.error(`Error parsing ${actionYmlPath}:`, error.message);
    return null;
  }
}

function getAllActions() {
  const actions = [];
  const dirs = fs.readdirSync('.', { withFileTypes: true });

  for (const dir of dirs) {
    if (dir.isDirectory() && !dir.name.startsWith('.') && dir.name !== 'node_modules') {
      const actionDetails = getActionDetails(dir.name);
      if (actionDetails) {
        actions.push(actionDetails);
      }
    }
  }

  return actions.sort((a, b) => a.name.localeCompare(b.name));
}

function generateQuickReference(actions) {
  const rows = [['Icon', 'Action', 'Category', 'Description', 'Key Features']];

  for (const action of actions) {
    rows.push([
      action.icon,
      `[\`${action.name}\`][${action.name}]`,
      action.category,
      action.description.substring(0, 60) + (action.description.length > 60 ? '...' : ''),
      action.features.join(', ') || '-',
    ]);
  }

  return markdownTable(rows, { align: ['c', 'l', 'l', 'l', 'l'] });
}

/**
 * Generate per-category Markdown sections containing tables of actions and their brief details.
 *
 * Sections appear in a fixed priority order: Setup, Utilities, Linting, Testing, Build, Publishing, Repository, Validation.
 *
 * @param {Array<Object>} actions - Array of action metadata objects. Each object should include at least: `name`, `description`, `category`, `icon`, `languages` (array), and `features` (array).
 * @returns {string} A Markdown string with one section per category (when present), each containing a table of actions with columns: Action, Description, Languages, and Features.
 */
function generateCategoryTables(actions) {
  const categories = {};

  // Group by category
  for (const action of actions) {
    if (!categories[action.category]) {
      categories[action.category] = [];
    }
    categories[action.category].push(action);
  }

  let output = '';

  // Sort categories by priority
  const categoryOrder = ['Setup', 'Utilities', 'Linting', 'Testing', 'Build', 'Publishing', 'Repository', 'Validation'];

  for (const category of categoryOrder) {
    if (!categories[category]) continue;

    const categoryActions = categories[category];
    const icon = CATEGORY_ICONS[category] || '📦';
    const actionWord = categoryActions.length === 1 ? 'action' : 'actions';

    output += `\n#### ${icon} ${category} (${categoryActions.length} ${actionWord})\n\n`;

    const rows = [['Action', 'Description', 'Languages', 'Features']];

    for (const action of categoryActions) {
      rows.push([
        `${action.icon} [\`${action.name}\`][${action.name}]`,
        action.description.substring(0, 50) + (action.description.length > 50 ? '...' : ''),
        action.languages.join(', ') || '-',
        action.features.join(', ') || '-',
      ]);
    }

    output += markdownTable(rows, { align: ['l', 'l', 'l', 'l'] });
    output += '\n';
  }

  return output;
}

function generateFeatureMatrix(actions) {
  const features = ['Caching', 'Auto-detection', 'Token auth', 'Outputs'];
  const rows = [['Action', ...features]];

  for (const action of actions) {
    const row = [`[\`${action.name}\`][${action.name}]`];
    for (const feature of features) {
      row.push(action.features.includes(feature) ? '✅' : '-');
    }
    rows.push(row);
  }

  return markdownTable(rows, { align: ['l', 'c', 'c', 'c', 'c'] });
}

function generateLanguageMatrix(actions) {
  const languages = [...new Set(actions.flatMap(a => a.languages))].sort();
  if (languages.length === 0) return '';

  const rows = [['Language', 'Actions']];

  for (const language of languages) {
    const languageActions = actions
      .filter(a => a.languages.includes(language))
      .map(a => `[\`${a.name}\`][${a.name}]`)
      .join(', ');

    rows.push([language, languageActions]);
  }

  return markdownTable(rows, { align: ['l', 'l'] });
}

function generateReferenceLinks(actions) {
  const links = actions
    .sort((a, b) => a.name.localeCompare(b.name))
    .map(action => `[${action.name}]: ${action.name}/README.md`)
    .join('\n');
  return `\n<!-- Reference Links -->\n${links}\n`;
}

/**
 * Builds the complete Markdown catalog for all discovered actions in the repository.
 *
 * The generated content includes a quick reference, per-category tables, a feature matrix,
 * language support matrix, usage examples with recommended pinned refs, action reference links,
 * and a closing separator.
 *
 * @returns {string} The assembled catalog as a Markdown-formatted string.
 */
function generateCatalogContent() {
  const actions = getAllActions();
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

  // Add reference links before the timestamp
  content += generateReferenceLinks(actions);

  content += `\n---`;

  return content;
}

function updateReadme(catalogContent) {
  try {
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
    console.log(`📊 Updated catalog with ${getAllActions().length} actions`);
  } catch (error) {
    console.error('❌ Error updating README.md:', error.message);
    process.exit(1);
  }
}

// Main execution
function main() {
  // Parse command line arguments
  const args = process.argv.slice(2);
  const shouldUpdate = args.includes('--update');

  const catalogContent = generateCatalogContent();

  if (shouldUpdate) {
    updateReadme(catalogContent);
  } else {
    console.log(catalogContent);
  }
}

// Run the script
main();
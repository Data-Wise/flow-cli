/**
 * Test: Project Detector Bridge
 *
 * Tests the bridge to vendored zsh-claude-workflow functions
 */

import { detectProjectType, detectMultipleProjects, getSupportedTypes, isTypeSupported } from '../lib/project-detector-bridge.js';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ANSI colors for output
const colors = {
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m',
  reset: '\x1b[0m'
};

function pass(message) {
  console.log(`${colors.green}✓${colors.reset} ${message}`);
}

function fail(message) {
  console.log(`${colors.red}✗${colors.reset} ${message}`);
}

function info(message) {
  console.log(`${colors.cyan}ℹ${colors.reset} ${message}`);
}

async function runTests() {
  console.log('\n=== Testing Project Detector Bridge ===\n');

  let testsPassed = 0;
  let testsFailed = 0;

  // Test 1: Get supported types
  info('Test 1: getSupportedTypes()');
  const types = getSupportedTypes();
  if (Array.isArray(types) && types.length > 0) {
    pass(`Returns ${types.length} supported types: ${types.join(', ')}`);
    testsPassed++;
  } else {
    fail('Failed to get supported types');
    testsFailed++;
  }

  // Test 2: Check if type is supported
  info('\nTest 2: isTypeSupported()');
  if (isTypeSupported('r-package') && !isTypeSupported('invalid-type')) {
    pass('Correctly identifies supported and unsupported types');
    testsPassed++;
  } else {
    fail('Type support check failed');
    testsFailed++;
  }

  // Test 3: Detect R package
  info('\nTest 3: Detect R package project');
  const rPackagePath = path.join(process.env.HOME, 'projects/r-packages/stable/rmediation');
  try {
    const rType = await detectProjectType(rPackagePath);
    if (rType === 'r-package') {
      pass(`Correctly detected R package: ${rPackagePath}`);
      testsPassed++;
    } else {
      fail(`Expected 'r-package', got '${rType}'`);
      testsFailed++;
    }
  } catch (error) {
    fail(`Error detecting R package: ${error.message}`);
    testsFailed++;
  }

  // Test 4: Detect Quarto project
  info('\nTest 4: Detect Quarto project');
  const quartoPath = path.join(process.env.HOME, 'projects/teaching/stat-440');
  try {
    const quartoType = await detectProjectType(quartoPath);
    if (quartoType === 'quarto') {
      pass(`Correctly detected Quarto project: ${quartoPath}`);
      testsPassed++;
    } else {
      fail(`Expected 'quarto', got '${quartoType}'`);
      testsFailed++;
    }
  } catch (error) {
    fail(`Error detecting Quarto project: ${error.message}`);
    testsFailed++;
  }

  // Test 5: Detect generic git project (this project)
  info('\nTest 5: Detect generic git project');
  const nodePath = path.join(process.env.HOME, 'projects/dev-tools/zsh-configuration');
  try {
    const nodeType = await detectProjectType(nodePath);
    // This project has package.json and .git, so it should detect as 'generic' (git project)
    if (nodeType === 'generic') {
      pass(`Correctly detected generic git project: ${nodePath}`);
      testsPassed++;
    } else {
      fail(`Expected 'generic', got '${nodeType}'`);
      testsFailed++;
    }
  } catch (error) {
    fail(`Error detecting git project: ${error.message}`);
    testsFailed++;
  }

  // Test 6: Detect multiple projects in parallel
  info('\nTest 6: Detect multiple projects in parallel');
  try {
    const results = await detectMultipleProjects([
      rPackagePath,
      quartoPath,
      nodePath
    ]);

    const expectedCount = 3;
    const actualCount = Object.keys(results).length;

    if (actualCount === expectedCount) {
      pass(`Detected ${actualCount} projects in parallel`);
      for (const [path, type] of Object.entries(results)) {
        console.log(`  ${colors.yellow}→${colors.reset} ${path.split('/').pop()}: ${type}`);
      }
      testsPassed++;
    } else {
      fail(`Expected ${expectedCount} results, got ${actualCount}`);
      testsFailed++;
    }
  } catch (error) {
    fail(`Error detecting multiple projects: ${error.message}`);
    testsFailed++;
  }

  // Test 7: Handle invalid path gracefully
  info('\nTest 7: Handle invalid path gracefully');
  const invalidPath = '/nonexistent/path/to/project';
  try {
    const result = await detectProjectType(invalidPath);
    if (result === 'unknown') {
      pass('Returns "unknown" for invalid paths without throwing');
      testsPassed++;
    } else {
      fail(`Expected 'unknown', got '${result}'`);
      testsFailed++;
    }
  } catch (error) {
    fail(`Should not throw on invalid path: ${error.message}`);
    testsFailed++;
  }

  // Summary
  console.log('\n' + '='.repeat(50));
  console.log(`\nTests Passed: ${colors.green}${testsPassed}${colors.reset}`);
  console.log(`Tests Failed: ${colors.red}${testsFailed}${colors.reset}`);
  console.log(`Total: ${testsPassed + testsFailed}\n`);

  if (testsFailed > 0) {
    process.exit(1);
  }
}

// Run tests
runTests().catch(error => {
  console.error(`${colors.red}Fatal error:${colors.reset}`, error);
  process.exit(1);
});

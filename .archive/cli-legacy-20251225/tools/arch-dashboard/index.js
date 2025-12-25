#!/usr/bin/env node

/**
 * Architecture Health Dashboard
 *
 * Real-time metrics for architectural health:
 * - Dependency violations
 * - Layer boundary checks
 * - Test coverage by layer
 * - Coupling metrics
 *
 * Usage: npm run arch-dashboard
 */

import { glob } from 'glob'
import { readFileSync } from 'fs'
import { join, dirname } from 'path'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)
const ROOT = join(__dirname, '../../..')

// ────────────────────────────────────────────────────────────
// Metrics Collection
// ────────────────────────────────────────────────────────────

async function analyzeArchitecture() {
  console.log('🔍 Analyzing architecture...\n')

  const metrics = {
    layers: await analyzeLayers(),
    dependencies: await analyzeDependencies(),
    tests: await analyzeTests(),
    complexity: await analyzeComplexity()
  }

  return metrics
}

async function analyzeLayers() {
  const layers = {
    domain: await countFiles('cli/domain/**/*.js'),
    useCases: await countFiles('cli/use-cases/**/*.js'),
    adapters: await countFiles('cli/adapters/**/*.js'),
    frameworks:
      (await countFiles('cli/frameworks/**/*.js')) + (await countFiles('cli/vendor/**/*.{sh,js}'))
  }

  return layers
}

async function analyzeDependencies() {
  // Check for outward dependencies (violations)
  const violations = []

  // Domain should have ZERO outward dependencies
  const domainFiles = await glob('cli/domain/**/*.js', { cwd: ROOT })

  for (const file of domainFiles) {
    const content = readFileSync(join(ROOT, file), 'utf-8')

    // Check for imports from outer layers
    if (content.match(/from\s+['"]\.\.\/use-cases/)) {
      violations.push({ file, issue: 'Domain imports from Use Cases (VIOLATION)' })
    }
    if (content.match(/from\s+['"]\.\.\/adapters/)) {
      violations.push({ file, issue: 'Domain imports from Adapters (VIOLATION)' })
    }
    if (content.match(/from\s+['"]\.\.\/frameworks/)) {
      violations.push({ file, issue: 'Domain imports from Frameworks (VIOLATION)' })
    }
  }

  // Use Cases should not import from Adapters or Frameworks
  const useCaseFiles = await glob('cli/use-cases/**/*.js', { cwd: ROOT })

  for (const file of useCaseFiles) {
    const content = readFileSync(join(ROOT, file), 'utf-8')

    if (content.match(/from\s+['"]\.\.\/adapters/)) {
      violations.push({ file, issue: 'Use Case imports from Adapters (VIOLATION)' })
    }
    if (content.match(/from\s+['"]\.\.\/frameworks/)) {
      violations.push({ file, issue: 'Use Case imports from Frameworks (VIOLATION)' })
    }
  }

  return {
    total: domainFiles.length + useCaseFiles.length,
    violations: violations.length,
    details: violations
  }
}

async function analyzeTests() {
  const testFiles = await glob('**/*.test.js', { cwd: ROOT })

  const byLayer = {
    domain: testFiles.filter(f => f.includes('domain')).length,
    useCases: testFiles.filter(f => f.includes('use-cases')).length,
    adapters: testFiles.filter(f => f.includes('adapters')).length,
    integration: testFiles.filter(f => f.includes('integration')).length
  }

  return {
    total: testFiles.length,
    byLayer
  }
}

async function analyzeComplexity() {
  // Simple metrics: lines of code by layer
  const layers = ['domain', 'use-cases', 'adapters', 'frameworks']
  const loc = {}

  for (const layer of layers) {
    const files = await glob(`cli/${layer}/**/*.js`, { cwd: ROOT })
    let totalLines = 0

    for (const file of files) {
      const content = readFileSync(join(ROOT, file), 'utf-8')
      totalLines += content.split('\n').length
    }

    loc[layer] = totalLines
  }

  return { linesOfCode: loc }
}

async function countFiles(pattern) {
  const files = await glob(pattern, { cwd: ROOT })
  return files.length
}

// ────────────────────────────────────────────────────────────
// Dashboard Display
// ────────────────────────────────────────────────────────────

function displayDashboard(metrics) {
  console.clear()
  console.log('═══════════════════════════════════════════════════')
  console.log('   ARCHITECTURE HEALTH DASHBOARD')
  console.log('═══════════════════════════════════════════════════\n')

  // Layer Metrics
  console.log('📊 LAYER DISTRIBUTION')
  console.log('─'.repeat(50))
  const layers = metrics.layers
  const total = Object.values(layers).reduce((a, b) => a + b, 0)

  for (const [layer, count] of Object.entries(layers)) {
    const pct = total > 0 ? Math.round((count / total) * 100) : 0
    const bar = '█'.repeat(Math.floor(pct / 2))
    console.log(`  ${layer.padEnd(12)} ${count.toString().padStart(3)} files  ${bar} ${pct}%`)
  }
  console.log(`  ${'TOTAL'.padEnd(12)} ${total.toString().padStart(3)} files\n`)

  // Dependency Health
  console.log('🔗 DEPENDENCY HEALTH')
  console.log('─'.repeat(50))
  const deps = metrics.dependencies

  if (deps.violations === 0) {
    console.log('  ✅ PERFECT: No dependency violations detected')
    console.log(`     Checked ${deps.total} files\n`)
  } else {
    console.log(`  ⚠️  ${deps.violations} VIOLATIONS found!\n`)

    for (const violation of deps.details.slice(0, 5)) {
      console.log(`     ❌ ${violation.file}`)
      console.log(`        ${violation.issue}\n`)
    }

    if (deps.details.length > 5) {
      console.log(`     ... and ${deps.details.length - 5} more\n`)
    }
  }

  // Test Coverage
  console.log('🧪 TEST COVERAGE')
  console.log('─'.repeat(50))
  const tests = metrics.tests

  console.log(`  Total Test Files: ${tests.total}`)
  console.log(`  By Layer:`)
  for (const [layer, count] of Object.entries(tests.byLayer)) {
    console.log(`    ${layer.padEnd(15)} ${count} tests`)
  }
  console.log()

  // Code Complexity
  console.log('📏 CODE COMPLEXITY (Lines of Code)')
  console.log('─'.repeat(50))
  const loc = metrics.complexity.linesOfCode
  const totalLoc = Object.values(loc).reduce((a, b) => a + b, 0)

  for (const [layer, lines] of Object.entries(loc)) {
    const pct = totalLoc > 0 ? Math.round((lines / totalLoc) * 100) : 0
    console.log(`  ${layer.padEnd(12)} ${lines.toString().padStart(5)} lines (${pct}%)`)
  }
  console.log(`  ${'TOTAL'.padEnd(12)} ${totalLoc.toString().padStart(5)} lines\n`)

  // Health Score
  console.log('🏆 OVERALL HEALTH SCORE')
  console.log('─'.repeat(50))

  const score = calculateHealthScore(metrics)

  if (score >= 90) {
    console.log(`  ${score}/100  ✅ EXCELLENT`)
  } else if (score >= 75) {
    console.log(`  ${score}/100  🟢 GOOD`)
  } else if (score >= 60) {
    console.log(`  ${score}/100  🟡 FAIR`)
  } else {
    console.log(`  ${score}/100  🔴 NEEDS IMPROVEMENT`)
  }

  console.log('\n═══════════════════════════════════════════════════\n')

  // Recommendations
  if (deps.violations > 0) {
    console.log('💡 RECOMMENDATIONS:')
    console.log('  - Fix dependency violations (see above)')
    console.log('  - Review layer boundaries')
    console.log('  - Run: npm run arch-lint\n')
  }

  if (tests.total < total * 0.5) {
    console.log('💡 RECOMMENDATIONS:')
    console.log('  - Increase test coverage (aim for 1 test per file)')
    console.log('  - Focus on domain and use case layers first\n')
  }
}

function calculateHealthScore(metrics) {
  let score = 100

  // Deduct for violations (20 points per violation, max -40)
  score -= Math.min(metrics.dependencies.violations * 20, 40)

  // Deduct if test coverage is low (max -30)
  const testRatio = metrics.tests.total / Object.values(metrics.layers).reduce((a, b) => a + b, 0)
  if (testRatio < 0.5) {
    score -= 30
  } else if (testRatio < 0.75) {
    score -= 15
  }

  // Deduct if domain layer is too small (should be significant)
  const domainPct = metrics.layers.domain / Object.values(metrics.layers).reduce((a, b) => a + b, 0)
  if (domainPct < 0.15) {
    score -= 10
  }

  return Math.max(score, 0)
}

// ────────────────────────────────────────────────────────────
// Main
// ────────────────────────────────────────────────────────────

async function main() {
  try {
    const metrics = await analyzeArchitecture()
    displayDashboard(metrics)

    // Exit with error if there are violations
    if (metrics.dependencies.violations > 0) {
      process.exit(1)
    }
  } catch (error) {
    console.error('❌ Error:', error.message)
    process.exit(1)
  }
}

main()

/**
 * E2E Tests for Flow CLI
 *
 * Tests the CLI commands end-to-end using the actual binary
 */

import { describe, test, expect } from '@jest/globals'
import { execSync } from 'child_process'
import { join } from 'path'
import { fileURLToPath } from 'url'
import { dirname } from 'path'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)
const CLI_PATH = join(__dirname, '../../cli/bin/flow.js')

/**
 * Execute CLI command and return output
 */
function runCLI(args = '', options = {}) {
  try {
    const output = execSync(`node ${CLI_PATH} ${args}`, {
      encoding: 'utf8',
      env: { ...process.env, NODE_ENV: 'test' },
      ...options
    })
    return { stdout: output, stderr: '', exitCode: 0 }
  } catch (error) {
    return {
      stdout: error.stdout || '',
      stderr: error.stderr || '',
      exitCode: error.status
    }
  }
}

describe('Flow CLI - E2E Tests', () => {
  describe('Help and Version', () => {
    test('shows help with --help', () => {
      const { stdout, exitCode } = runCLI('--help')

      expect(exitCode).toBe(0)
      expect(stdout).toContain('Usage: flow <command>')
      expect(stdout).toContain('Commands:')
      expect(stdout).toContain('status')
    })

    test('shows help with help command', () => {
      const { stdout, exitCode } = runCLI('help')

      expect(exitCode).toBe(0)
      expect(stdout).toContain('Usage: flow <command>')
    })

    test('shows help with no command', () => {
      const { stdout, exitCode } = runCLI('')

      expect(exitCode).toBe(0)
      expect(stdout).toContain('Usage: flow <command>')
    })

    test('shows version with --version', () => {
      const { stdout, exitCode } = runCLI('--version')

      expect(exitCode).toBe(0)
      expect(stdout).toMatch(/flow-cli v\d+\.\d+\.\d+/)
    })

    test('shows version with -v', () => {
      const { stdout, exitCode } = runCLI('-v')

      expect(exitCode).toBe(0)
      expect(stdout).toMatch(/flow-cli v\d+\.\d+\.\d+/)
    })
  })

  describe('Error Handling', () => {
    test('shows error for unknown command', () => {
      const { stderr, exitCode } = runCLI('nonexistent')

      expect(exitCode).toBe(1)
      expect(stderr).toContain("unknown command 'nonexistent'")
    })

    test('shows help hint for unknown command', () => {
      const { stderr } = runCLI('invalid')

      expect(stderr).toContain("Run 'flow help' for usage")
    })
  })

  describe('Status Command', () => {
    test('runs status command successfully', () => {
      const { exitCode } = runCLI('status')

      // Should not crash
      expect(exitCode).toBe(0)
    })

    test('status command produces output', () => {
      const { stdout } = runCLI('status')

      // Should show at least today's summary
      expect(stdout).toContain('Today')
    })

    test('status --help shows status help', () => {
      const { stdout, exitCode } = runCLI('status --help')

      expect(exitCode).toBe(0)
      expect(stdout).toContain('status')
    })
  })

  describe('CLI Performance', () => {
    test('help command executes quickly', () => {
      const start = Date.now()
      runCLI('--help')
      const duration = Date.now() - start

      // Should complete in under 2 seconds
      expect(duration).toBeLessThan(2000)
    })

    test('version command executes quickly', () => {
      const start = Date.now()
      runCLI('--version')
      const duration = Date.now() - start

      // Should complete in under 2 seconds
      expect(duration).toBeLessThan(2000)
    })
  })

  describe('Exit Codes', () => {
    test('returns 0 on success', () => {
      const { exitCode } = runCLI('--help')
      expect(exitCode).toBe(0)
    })

    test('returns 1 on error', () => {
      const { exitCode } = runCLI('invalid-command')
      expect(exitCode).toBe(1)
    })
  })
})

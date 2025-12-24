/**
 * Unit tests for GitGateway
 */

import { describe, test, expect, beforeAll } from '@jest/globals'
import { GitGateway } from '../../../cli/adapters/gateways/GitGateway.js'
import { fileURLToPath } from 'url'
import { dirname, join } from 'path'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

describe('GitGateway', () => {
  let gateway
  let projectRoot

  beforeAll(() => {
    gateway = new GitGateway()
    // Use the flow-cli project root as test directory (it's a git repo)
    projectRoot = join(__dirname, '..', '..', '..')
  })

  describe('getStatus', () => {
    test('returns git status for valid repository', async () => {
      const status = await gateway.getStatus(projectRoot)

      expect(status).toBeTruthy()
      expect(status.branch).toBeTruthy()
      expect(typeof status.branch).toBe('string')
      expect(typeof status.dirty).toBe('boolean')
      expect(Array.isArray(status.uncommittedFiles)).toBe(true)
      expect(typeof status.ahead).toBe('number')
      expect(typeof status.behind).toBe('number')
    })

    test('returns null for non-git directory', async () => {
      const status = await gateway.getStatus('/tmp')

      expect(status).toBeNull()
    })

    test('returns null for non-existent directory', async () => {
      const status = await gateway.getStatus('/nonexistent/path/12345')

      expect(status).toBeNull()
    })
  })

  describe('isGitRepository', () => {
    test('returns true for git repository', async () => {
      const isGit = await gateway.isGitRepository(projectRoot)

      expect(isGit).toBe(true)
    })

    test('returns false for non-git directory', async () => {
      const isGit = await gateway.isGitRepository('/tmp')

      expect(isGit).toBe(false)
    })
  })

  describe('getLastCommitMessage', () => {
    test('returns last commit message for git repository', async () => {
      const message = await gateway.getLastCommitMessage(projectRoot)

      expect(message).toBeTruthy()
      expect(typeof message).toBe('string')
      expect(message.length).toBeGreaterThan(0)
    })

    test('returns null for non-git directory', async () => {
      const message = await gateway.getLastCommitMessage('/tmp')

      expect(message).toBeNull()
    })
  })
})

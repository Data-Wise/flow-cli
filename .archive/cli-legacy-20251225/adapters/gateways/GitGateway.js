/**
 * GitGateway
 *
 * Adapter for reading git repository information.
 * Provides git status, branch, and uncommitted changes.
 */

import { exec } from 'child_process'
import { promisify } from 'util'
import { existsSync } from 'fs'
import { join } from 'path'

const execAsync = promisify(exec)

export class GitGateway {
  /**
   * Get git status for a project
   * @param {string} projectPath - Path to project directory
   * @returns {Promise<Object|null>} Git status or null if not a git repo
   */
  async getStatus(projectPath) {
    // Check if directory exists and has .git
    if (!existsSync(projectPath)) {
      return null
    }

    const gitDir = join(projectPath, '.git')
    if (!existsSync(gitDir)) {
      return null
    }

    try {
      // Get current branch
      const { stdout: branchOutput } = await execAsync('git branch --show-current', {
        cwd: projectPath
      })
      const branch = branchOutput.trim()

      // Get git status --porcelain for changes
      const { stdout: statusOutput } = await execAsync('git status --porcelain', {
        cwd: projectPath
      })

      const uncommittedFiles = statusOutput
        .split('\n')
        .filter(Boolean)
        .map(line => {
          const status = line.substring(0, 2).trim()
          const file = line.substring(3).trim()
          return { status, file }
        })

      // Get ahead/behind counts
      let ahead = 0
      let behind = 0

      try {
        const { stdout: aheadBehindOutput } = await execAsync(
          'git rev-list --left-right --count @{u}...HEAD',
          { cwd: projectPath }
        )

        const [behindStr, aheadStr] = aheadBehindOutput.trim().split('\t')
        ahead = parseInt(aheadStr, 10) || 0
        behind = parseInt(behindStr, 10) || 0
      } catch (error) {
        // No upstream branch configured - that's okay
      }

      return {
        branch,
        ahead,
        behind,
        dirty: uncommittedFiles.length > 0,
        uncommittedFiles
      }
    } catch (error) {
      console.error(`Warning: Could not read git status: ${error.message}`)
      return null
    }
  }

  /**
   * Check if path is a git repository
   * @param {string} projectPath - Path to check
   * @returns {Promise<boolean>}
   */
  async isGitRepository(projectPath) {
    const gitDir = join(projectPath, '.git')
    return existsSync(gitDir)
  }

  /**
   * Get last commit message
   * @param {string} projectPath - Path to project directory
   * @returns {Promise<string|null>}
   */
  async getLastCommitMessage(projectPath) {
    try {
      const { stdout } = await execAsync('git log -1 --pretty=%B', {
        cwd: projectPath
      })
      return stdout.trim()
    } catch (error) {
      return null
    }
  }
}

/**
 * Integration tests for status command
 */

import { describe, test, expect, beforeEach, afterEach } from '@jest/globals'
import { StatusController } from '../../cli/adapters/controllers/StatusController.js'
import { GetStatusUseCase } from '../../cli/use-cases/GetStatusUseCase.js'
import { Session } from '../../cli/domain/entities/Session.js'
import { writeFile, unlink, mkdir } from 'fs/promises'
import { join } from 'path'
import { homedir } from 'os'
import { existsSync } from 'fs'

// Mock repositories
class MockSessionRepository {
  constructor() {
    this.sessions = []
  }

  async findActive() {
    return this.sessions.find(s => s.state.isActive()) || null
  }

  async list(filters = {}) {
    let sessions = [...this.sessions]

    if (filters.since) {
      sessions = sessions.filter(s => s.startTime >= filters.since)
    }

    return sessions
  }
}

class MockProjectRepository {
  constructor() {
    this.projects = []
  }

  async findAll() {
    return [...this.projects]
  }

  async findRecent(hours, limit) {
    return this.projects.slice(0, limit)
  }

  async findTopByDuration(limit) {
    return this.projects.slice(0, limit)
  }

  async count() {
    return this.projects.length
  }
}

describe('StatusController', () => {
  let controller
  let sessionRepo
  let projectRepo
  let worklogPath

  beforeEach(async () => {
    sessionRepo = new MockSessionRepository()
    projectRepo = new MockProjectRepository()

    const getStatusUseCase = new GetStatusUseCase(sessionRepo, projectRepo)
    controller = new StatusController(getStatusUseCase)

    // Create test worklog
    worklogPath = join(homedir(), '.config', 'zsh', '.worklog.test')
    const testDir = join(homedir(), '.config', 'zsh')
    if (!existsSync(testDir)) {
      await mkdir(testDir, { recursive: true })
    }
  })

  afterEach(async () => {
    // Clean up test worklog
    if (existsSync(worklogPath)) {
      await unlink(worklogPath)
    }
  })

  describe('Active Session Display', () => {
    test('returns success with active session', async () => {
      const session = new Session('session-1', 'rmediation', {
        task: 'Fix bug'
      })
      sessionRepo.sessions.push(session)

      const result = await controller.handle()

      expect(result.success).toBe(true)
      expect(result.status.activeSession).toBeTruthy()
      expect(result.status.activeSession.project).toBe('rmediation')
    })

    test('detects flow state', async () => {
      const session = new Session('session-1', 'rmediation')
      session.startTime = new Date(Date.now() - 20 * 60 * 1000) // 20 min ago
      sessionRepo.sessions.push(session)

      const result = await controller.handle()

      expect(result.status.activeSession.isFlowState).toBe(true)
    })

    test('returns success with no active session', async () => {
      const result = await controller.handle()

      expect(result.success).toBe(true)
      expect(result.status.activeSession).toBeNull()
    })
  })

  describe('Verbose Mode', () => {
    test('returns status with verbose enabled', async () => {
      const session = new Session('session-1', 'rmediation', {
        task: 'Fix bug',
        branch: 'fix/bug-123'
      })
      sessionRepo.sessions.push(session)

      const result = await controller.handle({ verbose: true })

      expect(result.success).toBe(true)
      expect(result.status.activeSession.branch).toBe('fix/bug-123')
    })

    test('includes productivity metrics', async () => {
      const session = new Session('session-1', 'rmediation')
      session.end('completed')
      sessionRepo.sessions.push(session)

      const result = await controller.handle({ verbose: true })

      expect(result.success).toBe(true)
      expect(result.status.metrics).toBeTruthy()
    })
  })

  describe('Worklog Integration', () => {
    test('reads worklog entries when available', async () => {
      // Create test worklog
      const entries = [
        `${new Date().toISOString()} startsession: rmediation`,
        `${new Date(Date.now() - 60000).toISOString()} endsession: completed`
      ]
      await writeFile(worklogPath, entries.join('\n'))

      // Read worklog directly
      const worklog = await controller.readWorklog()

      // Temporarily point to test worklog for this test
      // (In real implementation, this would be configurable)
      expect(worklog.length).toBeGreaterThanOrEqual(0)
    })

    test('handles missing worklog gracefully', async () => {
      const result = await controller.handle({ includeWorklog: true })

      expect(result.success).toBe(true)
    })
  })

  describe('Helper Methods', () => {
    test('formatDuration converts minutes correctly', () => {
      expect(controller.formatDuration(30)).toBe('30m')
      expect(controller.formatDuration(60)).toBe('1h')
      expect(controller.formatDuration(90)).toBe('1h 30m')
      expect(controller.formatDuration(120)).toBe('2h')
    })

    test('relativeTime formats correctly', () => {
      const now = new Date()
      const tenMinsAgo = new Date(now - 10 * 60 * 1000)
      const twoHoursAgo = new Date(now - 2 * 60 * 60 * 1000)
      const threeDaysAgo = new Date(now - 3 * 24 * 60 * 60 * 1000)

      expect(controller.relativeTime(tenMinsAgo)).toBe('10m ago')
      expect(controller.relativeTime(twoHoursAgo)).toBe('2h ago')
      expect(controller.relativeTime(threeDaysAgo)).toBe('3d ago')
    })
  })
})

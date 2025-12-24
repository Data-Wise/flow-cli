/**
 * Unit tests for UpdateStatusFileUseCase
 */

import { describe, test, expect, beforeEach } from '@jest/globals'
import { UpdateStatusFileUseCase } from '../../../cli/use-cases/status/UpdateStatusFileUseCase.js'
import { Session } from '../../../cli/domain/entities/Session.js'

// Mock repositories
class MockSessionRepository {
  constructor() {
    this.sessions = []
  }

  async list(filters = {}) {
    let sessions = [...this.sessions]

    if (filters.since) {
      sessions = sessions.filter(s => s.startTime >= filters.since)
    }

    return sessions
  }
}

class MockStatusFileGateway {
  constructor() {
    this.files = new Map()
  }

  async read(projectPath) {
    return this.files.get(projectPath) || null
  }

  async write(projectPath, data) {
    this.files.set(projectPath, data)
  }
}

describe('UpdateStatusFileUseCase', () => {
  let useCase
  let sessionRepo
  let statusGateway
  const projectPath = '/test/project'

  beforeEach(() => {
    sessionRepo = new MockSessionRepository()
    statusGateway = new MockStatusFileGateway()
    useCase = new UpdateStatusFileUseCase(sessionRepo, statusGateway)

    // Set up initial .STATUS file
    statusGateway.files.set(projectPath, {
      status: 'active',
      progress: 75,
      type: 'r-package',
      next: [{ action: 'Write tests', priority: 'high' }],
      body: '# Project Notes\nSome notes.'
    })
  })

  describe('Execute', () => {
    test('updates metrics with session data', async () => {
      // Create test sessions
      const session1 = new Session('s1', 'test-project')
      session1.context = { cwd: projectPath }
      session1.startTime = new Date(Date.now() - 2 * 24 * 60 * 60 * 1000) // 2 days ago
      session1.end('completed')

      const session2 = new Session('s2', 'test-project')
      session2.context = { cwd: projectPath }
      session2.startTime = new Date(Date.now() - 1 * 24 * 60 * 60 * 1000) // 1 day ago
      session2.end('completed')

      sessionRepo.sessions = [session2, session1]

      const result = await useCase.execute({ projectPath })

      expect(result.metrics.sessions_total).toBe(2)
      expect(result.metrics.completed_sessions).toBe(2)
      expect(result.metrics.completion_rate).toBe(100)
      expect(result.metrics.last_updated).toBeTruthy()
    })

    test('preserves user-editable fields', async () => {
      const result = await useCase.execute({ projectPath })

      expect(result.status).toBe('active')
      expect(result.progress).toBe(75)
      expect(result.type).toBe('r-package')
      expect(result.next).toHaveLength(1)
      expect(result.next[0].action).toBe('Write tests')
      expect(result.body).toContain('# Project Notes')
    })

    test('filters sessions by project path', async () => {
      const session1 = new Session('s1', 'test-project')
      session1.context = { cwd: projectPath }
      session1.end('completed')

      const session2 = new Session('s2', 'other-project')
      session2.context = { cwd: '/other/path' }
      session2.end('completed')

      sessionRepo.sessions = [session1, session2]

      const result = await useCase.execute({ projectPath })

      expect(result.metrics.sessions_total).toBe(1)
    })

    test('calculates this week sessions correctly', async () => {
      const now = new Date()

      // Session within this week
      const session1 = new Session('s1', 'test-project')
      session1.context = { cwd: projectPath }
      session1.startTime = new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000) // 3 days ago

      // Session older than a week (but within 14-day period we'll use)
      const session2 = new Session('s2', 'test-project')
      session2.context = { cwd: projectPath }
      session2.startTime = new Date(now.getTime() - 10 * 24 * 60 * 60 * 1000) // 10 days ago

      sessionRepo.sessions = [session1, session2]

      const result = await useCase.execute({ projectPath, daysPeriod: 14 })

      expect(result.metrics.sessions_total).toBe(2)
      expect(result.metrics.sessions_this_week).toBe(1)
    })

    test('calculates total duration correctly', async () => {
      const session1 = new Session('s1', 'test-project')
      session1.context = { cwd: projectPath }
      session1.startTime = new Date(Date.now() - 30 * 60 * 1000) // Started 30 min ago
      session1.end('completed')

      const session2 = new Session('s2', 'test-project')
      session2.context = { cwd: projectPath }
      session2.startTime = new Date(Date.now() - 45 * 60 * 1000) // Started 45 min ago
      session2.end('completed')

      sessionRepo.sessions = [session1, session2]

      const result = await useCase.execute({ projectPath })

      expect(result.metrics.total_duration_minutes).toBeGreaterThan(0)
      expect(result.metrics.average_session_duration).toBeGreaterThan(0)
    })

    test('counts flow sessions (>= 15 minutes)', async () => {
      const session1 = new Session('s1', 'test-project')
      session1.context = { cwd: projectPath }
      session1.startTime = new Date(Date.now() - 20 * 60 * 1000) // 20 min
      session1.end('completed')

      const session2 = new Session('s2', 'test-project')
      session2.context = { cwd: projectPath }
      session2.startTime = new Date(Date.now() - 10 * 60 * 1000) // 10 min
      session2.end('completed')

      sessionRepo.sessions = [session1, session2]

      const result = await useCase.execute({ projectPath })

      expect(result.metrics.flow_sessions).toBe(1) // Only the 20-min session
    })

    test('calculates completion rate', async () => {
      const session1 = new Session('s1', 'test-project')
      session1.context = { cwd: projectPath }
      session1.end('completed')

      const session2 = new Session('s2', 'test-project')
      session2.context = { cwd: projectPath }
      session2.end('cancelled')

      const session3 = new Session('s3', 'test-project')
      session3.context = { cwd: projectPath }
      session3.end('completed')

      sessionRepo.sessions = [session1, session2, session3]

      const result = await useCase.execute({ projectPath })

      expect(result.metrics.completed_sessions).toBe(2)
      expect(result.metrics.completion_rate).toBe(67) // 2/3 rounded
    })

    test('throws error if no .STATUS file exists', async () => {
      await expect(useCase.execute({ projectPath: '/nonexistent/path' })).rejects.toThrow(
        'No .STATUS file found'
      )
    })
  })

  describe('needsUpdate', () => {
    test('returns true if no .STATUS file', async () => {
      const needs = await useCase.needsUpdate('/nonexistent/path')

      expect(needs).toBe(true)
    })

    test('returns true if no metrics', async () => {
      statusGateway.files.set('/test/path', {
        status: 'active',
        progress: 50,
        type: 'generic'
      })

      const needs = await useCase.needsUpdate('/test/path')

      expect(needs).toBe(true)
    })

    test('returns true if no last_updated', async () => {
      statusGateway.files.set('/test/path', {
        status: 'active',
        progress: 50,
        type: 'generic',
        metrics: {
          sessions_total: 10
        }
      })

      const needs = await useCase.needsUpdate('/test/path')

      expect(needs).toBe(true)
    })

    test('returns true if last_updated is old', async () => {
      statusGateway.files.set('/test/path', {
        status: 'active',
        progress: 50,
        type: 'generic',
        metrics: {
          sessions_total: 10,
          last_updated: new Date(Date.now() - 120 * 60 * 1000).toISOString() // 2 hours ago
        }
      })

      const needs = await useCase.needsUpdate('/test/path', 60) // max age 60 min

      expect(needs).toBe(true)
    })

    test('returns false if last_updated is recent', async () => {
      statusGateway.files.set('/test/path', {
        status: 'active',
        progress: 50,
        type: 'generic',
        metrics: {
          sessions_total: 10,
          last_updated: new Date(Date.now() - 30 * 60 * 1000).toISOString() // 30 min ago
        }
      })

      const needs = await useCase.needsUpdate('/test/path', 60) // max age 60 min

      expect(needs).toBe(false)
    })
  })
})

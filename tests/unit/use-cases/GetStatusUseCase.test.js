/**
 * Unit tests for GetStatusUseCase
 */

import { GetStatusUseCase } from '../../../cli/use-cases/GetStatusUseCase.js'
import { Session } from '../../../cli/domain/entities/Session.js'
import { Project } from '../../../cli/domain/entities/Project.js'

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

    if (filters.orderBy === 'startTime') {
      sessions.sort((a, b) => {
        return filters.order === 'desc' ? b.startTime - a.startTime : a.startTime - b.startTime
      })
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
    return this.projects.filter(p => p.isRecentlyAccessed(hours)).slice(0, limit)
  }

  async findTopByDuration(limit) {
    return this.projects.sort((a, b) => b.totalDuration - a.totalDuration).slice(0, limit)
  }
}

describe('GetStatusUseCase', () => {
  let useCase
  let sessionRepo
  let projectRepo

  beforeEach(() => {
    sessionRepo = new MockSessionRepository()
    projectRepo = new MockProjectRepository()
    useCase = new GetStatusUseCase(sessionRepo, projectRepo)
  })

  describe('Active Session', () => {
    test('returns active session info', async () => {
      const session = new Session('session-1', 'rmediation', {
        task: 'Fix bug'
      })
      sessionRepo.sessions.push(session)

      const status = await useCase.execute()

      expect(status.activeSession).toBeTruthy()
      expect(status.activeSession.project).toBe('rmediation')
      expect(status.activeSession.task).toBe('Fix bug')
    })

    test('returns null when no active session', async () => {
      const status = await useCase.execute()

      expect(status.activeSession).toBeNull()
    })

    test('includes flow state information', async () => {
      const session = new Session('session-1', 'rmediation')
      // Simulate 20 minutes of work
      session.startTime = new Date(Date.now() - 20 * 60 * 1000)
      sessionRepo.sessions.push(session)

      const status = await useCase.execute()

      expect(status.activeSession.isFlowState).toBe(true)
    })
  })

  describe('Today Summary', () => {
    test('counts today sessions correctly', async () => {
      const today = new Date()
      today.setHours(10, 0, 0, 0)

      const session1 = new Session('s1', 'p1')
      session1.startTime = today

      const session2 = new Session('s2', 'p2')
      session2.startTime = today

      sessionRepo.sessions.push(session1, session2)

      const status = await useCase.execute()

      expect(status.today.sessions).toBe(2)
    })

    test('excludes yesterday sessions from today', async () => {
      const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000)
      const session = new Session('s1', 'p1')
      session.startTime = yesterday

      sessionRepo.sessions.push(session)

      const status = await useCase.execute()

      expect(status.today.sessions).toBe(0)
    })

    test('calculates total duration for today', async () => {
      const today = new Date()

      const session1 = new Session('s1', 'p1')
      session1.startTime = new Date(today.getTime() - 30 * 60 * 1000)
      session1.end('completed')

      const session2 = new Session('s2', 'p2')
      session2.startTime = new Date(today.getTime() - 45 * 60 * 1000)
      session2.end('completed')

      sessionRepo.sessions.push(session1, session2)

      const status = await useCase.execute()

      expect(status.today.totalDuration).toBeGreaterThanOrEqual(74)
      expect(status.today.totalDuration).toBeLessThanOrEqual(76)
    })

    test('counts completed sessions', async () => {
      const today = new Date()

      const s1 = new Session('s1', 'p1')
      s1.startTime = today
      s1.end('completed')

      const s2 = new Session('s2', 'p2')
      s2.startTime = today
      s2.end('cancelled')

      const s3 = new Session('s3', 'p3')
      s3.startTime = today

      sessionRepo.sessions.push(s1, s2, s3)

      const status = await useCase.execute()

      expect(status.today.completedSessions).toBe(1)
    })
  })

  describe('Recent Sessions', () => {
    test('includes recent sessions by default', async () => {
      const session = new Session('s1', 'p1')
      sessionRepo.sessions.push(session)

      const status = await useCase.execute()

      expect(status.recent).toBeTruthy()
      expect(status.recent.sessions).toBe(1)
    })

    test('excludes recent sessions when requested', async () => {
      const session = new Session('s1', 'p1')
      sessionRepo.sessions.push(session)

      const status = await useCase.execute({ includeRecentSessions: false })

      expect(status.recent).toBeNull()
    })

    test('filters by recent days', async () => {
      const recent = new Session('s1', 'p1')
      recent.startTime = new Date(Date.now() - 2 * 24 * 60 * 60 * 1000)

      const old = new Session('s2', 'p2')
      old.startTime = new Date(Date.now() - 10 * 24 * 60 * 60 * 1000)

      sessionRepo.sessions.push(recent, old)

      const status = await useCase.execute({ recentDays: 7 })

      expect(status.recent.sessions).toBe(1)
    })

    test('calculates average duration', async () => {
      const s1 = new Session('s1', 'p1')
      s1.startTime = new Date(Date.now() - 30 * 60 * 1000)
      s1.end('completed')

      const s2 = new Session('s2', 'p2')
      s2.startTime = new Date(Date.now() - 60 * 60 * 1000)
      s2.end('completed')

      sessionRepo.sessions.push(s1, s2)

      const status = await useCase.execute()

      // (30 + 60) / 2 = 45
      expect(status.recent.averageDuration).toBeGreaterThanOrEqual(44)
      expect(status.recent.averageDuration).toBeLessThanOrEqual(46)
    })
  })

  describe('Project Stats', () => {
    test('includes project stats by default', async () => {
      const project = new Project('p1', 'rmediation')
      projectRepo.projects.push(project)

      const status = await useCase.execute()

      expect(status.projects).toBeTruthy()
      expect(status.projects.total).toBe(1)
    })

    test('excludes project stats when requested', async () => {
      const status = await useCase.execute({ includeProjectStats: false })

      expect(status.projects).toBeNull()
    })
  })

  describe('Metrics', () => {
    test('calculates flow percentage', async () => {
      // Flow session (>= 15 min)
      const s1 = new Session('s1', 'p1')
      s1.startTime = new Date(Date.now() - 20 * 60 * 1000)
      s1.end('completed')

      // Non-flow session (< 15 min)
      const s2 = new Session('s2', 'p2')
      s2.startTime = new Date(Date.now() - 10 * 60 * 1000)
      s2.end('completed')

      sessionRepo.sessions.push(s1, s2)

      const status = await useCase.execute()

      expect(status.metrics.flowPercentage).toBe(50) // 1 out of 2
    })

    test('calculates completion rate', async () => {
      const s1 = new Session('s1', 'p1')
      s1.end('completed')

      const s2 = new Session('s2', 'p2')
      s2.end('completed')

      const s3 = new Session('s3', 'p3')
      s3.end('cancelled')

      sessionRepo.sessions.push(s1, s2, s3)

      const status = await useCase.execute()

      expect(status.metrics.completionRate).toBe(67) // 2 out of 3, rounded
    })

    test('calculates streak correctly', async () => {
      const today = new Date()
      today.setHours(12, 0, 0, 0)

      const yesterday = new Date(today)
      yesterday.setDate(yesterday.getDate() - 1)

      const s1 = new Session('s1', 'p1')
      s1.startTime = today

      const s2 = new Session('s2', 'p2')
      s2.startTime = yesterday

      sessionRepo.sessions.push(s1, s2)

      const status = await useCase.execute()

      expect(status.metrics.streak).toBe(2)
    })

    test('streak is 0 with no sessions', async () => {
      const status = await useCase.execute()

      expect(status.metrics.streak).toBe(0)
    })
  })
})

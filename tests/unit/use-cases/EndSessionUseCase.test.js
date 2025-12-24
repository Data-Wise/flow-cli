/**
 * Unit tests for EndSessionUseCase
 */

import { EndSessionUseCase } from '../../../cli/use-cases/EndSessionUseCase.js'
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

  async findById(id) {
    return this.sessions.find(s => s.id === id) || null
  }

  async save(session) {
    const index = this.sessions.findIndex(s => s.id === session.id)
    if (index >= 0) {
      this.sessions[index] = session
    } else {
      this.sessions.push(session)
    }
    return session
  }
}

class MockProjectRepository {
  constructor() {
    this.projects = []
  }

  async findById(id) {
    return this.projects.find(p => p.id === id) || null
  }

  async save(project) {
    const index = this.projects.findIndex(p => p.id === project.id)
    if (index >= 0) {
      this.projects[index] = project
    } else {
      this.projects.push(project)
    }
    return project
  }
}

describe('EndSessionUseCase', () => {
  let useCase
  let sessionRepo
  let projectRepo

  beforeEach(() => {
    sessionRepo = new MockSessionRepository()
    projectRepo = new MockProjectRepository()
    useCase = new EndSessionUseCase(sessionRepo, projectRepo)
  })

  describe('Success Cases - Active Session', () => {
    test('ends active session with default outcome', async () => {
      const session = new Session('session-1', 'rmediation')
      sessionRepo.sessions.push(session)

      const endedSession = await useCase.execute()

      expect(endedSession.state.isEnded()).toBe(true)
      expect(endedSession.outcome).toBe('completed')
      expect(endedSession.endTime).toBeInstanceOf(Date)
    })

    test('ends active session with specified outcome', async () => {
      const session = new Session('session-1', 'rmediation')
      sessionRepo.sessions.push(session)

      const endedSession = await useCase.execute({ outcome: 'cancelled' })

      expect(endedSession.outcome).toBe('cancelled')
    })

    test('saves ended session to repository', async () => {
      const session = new Session('session-1', 'rmediation')
      sessionRepo.sessions.push(session)

      await useCase.execute()

      const savedSession = sessionRepo.sessions.find(s => s.id === 'session-1')
      expect(savedSession.state.isEnded()).toBe(true)
    })

    test('updates project statistics when session ends', async () => {
      const session = new Session('session-1', 'rmediation')
      // Simulate 30 minutes of work
      session.startTime = new Date(Date.now() - 30 * 60 * 1000)
      sessionRepo.sessions.push(session)

      const project = new Project('rmediation', 'rmediation')
      projectRepo.projects.push(project)

      await useCase.execute()

      expect(project.totalSessions).toBe(1)
      expect(project.totalDuration).toBeGreaterThanOrEqual(29)
      expect(project.totalDuration).toBeLessThanOrEqual(31)
    })

    test('does not fail if project does not exist', async () => {
      const session = new Session('session-1', 'nonexistent-project')
      sessionRepo.sessions.push(session)

      await expect(useCase.execute()).resolves.toBeTruthy()
    })
  })

  describe('Success Cases - Specific Session', () => {
    test('ends session by ID', async () => {
      const session = new Session('session-123', 'rmediation')
      sessionRepo.sessions.push(session)

      const endedSession = await useCase.execute({ sessionId: 'session-123' })

      expect(endedSession.id).toBe('session-123')
      expect(endedSession.state.isEnded()).toBe(true)
    })

    test('can end paused session by ID', async () => {
      const session = new Session('session-1', 'rmediation')
      session.pause()
      sessionRepo.sessions.push(session)

      const endedSession = await useCase.execute({ sessionId: 'session-1' })

      expect(endedSession.state.isEnded()).toBe(true)
    })
  })

  describe('Validation', () => {
    test('throws error if no active session found', async () => {
      await expect(useCase.execute()).rejects.toThrow('No active session found to end')
    })

    test('throws error if session ID not found', async () => {
      await expect(useCase.execute({ sessionId: 'nonexistent' })).rejects.toThrow(
        'Session not found: nonexistent'
      )
    })

    test('throws error for invalid outcome', async () => {
      const session = new Session('session-1', 'rmediation')
      sessionRepo.sessions.push(session)

      await expect(useCase.execute({ outcome: 'invalid' })).rejects.toThrow(
        'Invalid outcome: invalid'
      )
    })

    test('accepts all valid outcomes', async () => {
      const outcomes = ['completed', 'cancelled', 'interrupted']

      for (const outcome of outcomes) {
        const session = new Session(`session-${outcome}`, 'rmediation')
        sessionRepo.sessions.push(session)

        const endedSession = await useCase.execute({
          sessionId: session.id,
          outcome
        })

        expect(endedSession.outcome).toBe(outcome)
      }
    })
  })

  describe('Business Rules', () => {
    test('throws error when ending already ended session', async () => {
      const session = new Session('session-1', 'rmediation')
      session.end('completed')
      sessionRepo.sessions.push(session)

      await expect(useCase.execute({ sessionId: 'session-1' })).rejects.toThrow(
        'Session is already ended'
      )
    })

    test('calculates duration correctly for ended session', async () => {
      const session = new Session('session-1', 'rmediation')
      // Simulate 45 minutes of work
      session.startTime = new Date(Date.now() - 45 * 60 * 1000)
      sessionRepo.sessions.push(session)

      const endedSession = await useCase.execute()

      const duration = endedSession.getDuration()
      expect(duration).toBeGreaterThanOrEqual(44)
      expect(duration).toBeLessThanOrEqual(46)
    })

    test('excludes paused time from duration', async () => {
      const session = new Session('session-1', 'rmediation')
      // Started 60 minutes ago
      session.startTime = new Date(Date.now() - 60 * 60 * 1000)
      // Paused for 30 minutes
      session.totalPausedTime = 30 * 60 * 1000
      sessionRepo.sessions.push(session)

      const endedSession = await useCase.execute()

      const duration = endedSession.getDuration()
      expect(duration).toBeGreaterThanOrEqual(29)
      expect(duration).toBeLessThanOrEqual(31)
    })
  })
})

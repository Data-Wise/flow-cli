/**
 * Unit tests for Session entity
 */

import { Session } from '../../../../cli/domain/entities/Session.js'
import { SessionState } from '../../../../cli/domain/value-objects/SessionState.js'
import {
  SessionStartedEvent,
  SessionEndedEvent,
  SessionPausedEvent,
  SessionResumedEvent
} from '../../../../cli/domain/events/SessionEvent.js'

describe('Session Entity', () => {
  describe('Construction', () => {
    test('creates session with required fields', () => {
      const session = new Session('id-1', 'rmediation')

      expect(session.id).toBe('id-1')
      expect(session.project).toBe('rmediation')
      expect(session.task).toBe('Work session') // default
      expect(session.state.isActive()).toBe(true)
      expect(session.startTime).toBeInstanceOf(Date)
    })

    test('creates session with optional fields', () => {
      const session = new Session('id-1', 'rmediation', {
        task: 'Fix bug #123',
        branch: 'fix/bug-123',
        context: { priority: 'high' }
      })

      expect(session.task).toBe('Fix bug #123')
      expect(session.branch).toBe('fix/bug-123')
      expect(session.context.priority).toBe('high')
    })

    test('emits SessionStartedEvent on creation', () => {
      const session = new Session('id-1', 'rmediation')
      const events = session.getEvents()

      expect(events).toHaveLength(1)
      expect(events[0]).toBeInstanceOf(SessionStartedEvent)
      expect(events[0].project).toBe('rmediation')
    })

    test('throws error if project name is empty', () => {
      expect(() => new Session('id-1', '')).toThrow('Session must have a project name')
    })

    test('throws error if project name is too long', () => {
      const longName = 'a'.repeat(101)
      expect(() => new Session('id-1', longName)).toThrow('Project name too long')
    })

    test('throws error if task description is too long', () => {
      const longTask = 'a'.repeat(501)
      expect(() => new Session('id-1', 'project', { task: longTask })).toThrow(
        'Task description too long'
      )
    })
  })

  describe('End Session', () => {
    test('ends active session successfully', () => {
      const session = new Session('id-1', 'rmediation')

      session.end('completed')

      expect(session.state.isEnded()).toBe(true)
      expect(session.outcome).toBe('completed')
      expect(session.endTime).toBeInstanceOf(Date)
    })

    test('emits SessionEndedEvent when ended', () => {
      const session = new Session('id-1', 'rmediation')
      session.clearEvents() // Clear creation event

      session.end('completed')

      const events = session.getEvents()
      expect(events).toHaveLength(1)
      expect(events[0]).toBeInstanceOf(SessionEndedEvent)
      expect(events[0].outcome).toBe('completed')
    })

    test('throws error when ending already ended session', () => {
      const session = new Session('id-1', 'rmediation')
      session.end('completed')

      expect(() => session.end('completed')).toThrow('Session is already ended')
    })

    test('throws error for invalid outcome', () => {
      const session = new Session('id-1', 'rmediation')

      expect(() => session.end('invalid')).toThrow('Invalid outcome')
    })

    test('allows valid outcomes', () => {
      const outcomes = ['completed', 'cancelled', 'interrupted']

      for (const outcome of outcomes) {
        const session = new Session(`id-${outcome}`, 'rmediation')
        expect(() => session.end(outcome)).not.toThrow()
        expect(session.outcome).toBe(outcome)
      }
    })
  })

  describe('Pause and Resume', () => {
    test('pauses active session', () => {
      const session = new Session('id-1', 'rmediation')

      session.pause()

      expect(session.state.isPaused()).toBe(true)
      expect(session.pausedAt).toBeInstanceOf(Date)
    })

    test('throws error when pausing non-active session', () => {
      const session = new Session('id-1', 'rmediation')
      session.pause()

      expect(() => session.pause()).toThrow('Can only pause active sessions')
    })

    test('resumes paused session', () => {
      const session = new Session('id-1', 'rmediation')
      session.pause()

      session.resume()

      expect(session.state.isActive()).toBe(true)
      expect(session.pausedAt).toBeNull()
      expect(session.resumedAt).toBeInstanceOf(Date)
    })

    test('throws error when resuming non-paused session', () => {
      const session = new Session('id-1', 'rmediation')

      expect(() => session.resume()).toThrow('Can only resume paused sessions')
    })

    test('tracks total paused time correctly', () => {
      const session = new Session('id-1', 'rmediation')

      // Pause for 100ms
      session.pause()
      const pausedAt = session.pausedAt
      session.pausedAt = new Date(pausedAt - 100)

      session.resume()

      expect(session.totalPausedTime).toBeGreaterThanOrEqual(100)
    })

    test('emits pause and resume events', () => {
      const session = new Session('id-1', 'rmediation')
      session.clearEvents()

      session.pause()
      session.resume()

      const events = session.getEvents()
      expect(events).toHaveLength(2)
      expect(events[0]).toBeInstanceOf(SessionPausedEvent)
      expect(events[1]).toBeInstanceOf(SessionResumedEvent)
    })
  })

  describe('Duration Calculation', () => {
    test('calculates duration for active session', () => {
      const session = new Session('id-1', 'rmediation')

      // Set start time to 30 minutes ago
      session.startTime = new Date(Date.now() - 30 * 60 * 1000)

      const duration = session.getDuration()
      expect(duration).toBeGreaterThanOrEqual(29)
      expect(duration).toBeLessThanOrEqual(31)
    })

    test('calculates duration for ended session', () => {
      const session = new Session('id-1', 'rmediation')

      // Session ran for exactly 45 minutes
      session.startTime = new Date(Date.now() - 45 * 60 * 1000)
      session.end('completed')

      const duration = session.getDuration()
      expect(duration).toBeGreaterThanOrEqual(44)
      expect(duration).toBeLessThanOrEqual(46)
    })

    test('excludes paused time from duration', () => {
      const session = new Session('id-1', 'rmediation')

      // Started 30 minutes ago
      session.startTime = new Date(Date.now() - 30 * 60 * 1000)

      // Was paused for 10 minutes
      session.totalPausedTime = 10 * 60 * 1000

      const duration = session.getDuration()
      expect(duration).toBeGreaterThanOrEqual(19)
      expect(duration).toBeLessThanOrEqual(21)
    })

    test('excludes current pause from duration', () => {
      const session = new Session('id-1', 'rmediation')

      // Started 30 minutes ago
      session.startTime = new Date(Date.now() - 30 * 60 * 1000)

      // Paused 5 minutes ago
      session.pause()
      session.pausedAt = new Date(Date.now() - 5 * 60 * 1000)

      const duration = session.getDuration()
      expect(duration).toBeGreaterThanOrEqual(24)
      expect(duration).toBeLessThanOrEqual(26)
    })

    test('never returns negative duration', () => {
      const session = new Session('id-1', 'rmediation')

      // Edge case: paused time exceeds total time (shouldn't happen, but defensive)
      session.totalPausedTime = 9999999999

      const duration = session.getDuration()
      expect(duration).toBe(0)
    })
  })

  describe('Flow State', () => {
    test('is not in flow state initially', () => {
      const session = new Session('id-1', 'rmediation')

      expect(session.isInFlowState()).toBe(false)
    })

    test('is in flow state after 15 minutes', () => {
      const session = new Session('id-1', 'rmediation')

      // Set start time to 20 minutes ago
      session.startTime = new Date(Date.now() - 20 * 60 * 1000)

      expect(session.isInFlowState()).toBe(true)
    })

    test('is not in flow state when paused', () => {
      const session = new Session('id-1', 'rmediation')

      // Set start time to 20 minutes ago
      session.startTime = new Date(Date.now() - 20 * 60 * 1000)

      session.pause()

      expect(session.isInFlowState()).toBe(false)
    })

    test('is not in flow state when ended', () => {
      const session = new Session('id-1', 'rmediation')

      // Set start time to 20 minutes ago
      session.startTime = new Date(Date.now() - 20 * 60 * 1000)

      session.end('completed')

      expect(session.isInFlowState()).toBe(false)
    })
  })

  describe('Context Management', () => {
    test('updates context', () => {
      const session = new Session('id-1', 'rmediation')

      session.updateContext({ priority: 'high', tags: ['bug'] })

      expect(session.context.priority).toBe('high')
      expect(session.context.tags).toEqual(['bug'])
    })

    test('merges context updates', () => {
      const session = new Session('id-1', 'rmediation', {
        context: { priority: 'low' }
      })

      session.updateContext({ tags: ['feature'] })

      expect(session.context.priority).toBe('low')
      expect(session.context.tags).toEqual(['feature'])
    })
  })

  describe('Event Management', () => {
    test('getEvents returns copy of events', () => {
      const session = new Session('id-1', 'rmediation')

      const events1 = session.getEvents()
      const events2 = session.getEvents()

      expect(events1).not.toBe(events2) // Different array instances
      expect(events1).toEqual(events2) // Same content
    })

    test('clearEvents removes all events', () => {
      const session = new Session('id-1', 'rmediation')

      expect(session.getEvents()).toHaveLength(1)

      session.clearEvents()

      expect(session.getEvents()).toHaveLength(0)
    })
  })

  describe('Summary', () => {
    test('getSummary returns session summary', () => {
      const session = new Session('id-1', 'rmediation', {
        task: 'Fix bug'
      })

      const summary = session.getSummary()

      expect(summary).toEqual({
        id: 'id-1',
        project: 'rmediation',
        task: 'Fix bug',
        duration: expect.any(Number),
        state: 'active',
        outcome: null,
        isFlowState: false
      })
    })
  })
})

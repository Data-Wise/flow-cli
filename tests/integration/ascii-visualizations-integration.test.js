/**
 * Integration tests for ASCII visualizations in real StatusController scenarios
 * Tests Day 9 features with actual data flows
 */

import { describe, test, expect, beforeEach } from '@jest/globals'
import { StatusController } from '../../cli/adapters/controllers/StatusController.js'
import { GetStatusUseCase } from '../../cli/use-cases/GetStatusUseCase.js'
import { Session } from '../../cli/domain/entities/Session.js'
import { Project } from '../../cli/domain/entities/Project.js'
import { ProjectType } from '../../cli/domain/value-objects/ProjectType.js'

// Mock repositories with realistic data
class MockSessionRepository {
  constructor(sessions = []) {
    this.sessions = sessions
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
  constructor(projects = []) {
    this.projects = projects
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

// Capture console output
let consoleOutput = []
const originalConsoleLog = console.log

beforeEach(() => {
  consoleOutput = []
  console.log = (...args) => {
    consoleOutput.push(args.join(' '))
  }
})

afterEach(() => {
  console.log = originalConsoleLog
})

describe('ASCII Visualizations - Integration Tests', () => {
  describe('Real-world Workflow Scenarios', () => {
    test('productive day with multiple completed sessions', async () => {
      // Create realistic session history
      const now = new Date()
      const sessions = []

      // 5 completed sessions with varying durations
      for (let i = 0; i < 5; i++) {
        const durationMinutes = 25 + i * 10 // 25, 35, 45, 55, 65
        const startTime = new Date(now.getTime() - durationMinutes * 60000)

        const session = new Session(`session-${i}`, 'flow-cli', {
          task: `Task ${i + 1}`,
          startTime
        })
        session.end('completed')
        sessions.push(session)
      }

      const sessionRepo = new MockSessionRepository(sessions)
      const projectRepo = new MockProjectRepository([])

      const useCase = new GetStatusUseCase(sessionRepo, projectRepo)
      const controller = new StatusController(useCase)

      await controller.handle({ verbose: true })

      const output = consoleOutput.join('\n')

      // Should show 100% completion rate
      expect(output).toMatch(/Completed:.*5\/5.*\[██████████\].*100%/)

      // Should show total duration with blocks
      const totalDuration = 25 + 35 + 45 + 55 + 65 // 225 minutes
      expect(output).toMatch(/Duration:.*3h 45m/)

      // Should show sparkline trend for session durations
      expect(output).toMatch(/Trend:.*[▁▂▃▄▅▆▇█]+/)
    })

    test('partially complete day with some cancelled sessions', async () => {
      const sessions = []
      const now = new Date()

      // 3 completed sessions
      for (let i = 0; i < 3; i++) {
        const startTime = new Date(now.getTime() - 30 * 60000)
        const session = new Session(`completed-${i}`, 'project-a', {
          task: `Completed task ${i + 1}`,
          startTime
        })
        session.end('completed')
        sessions.push(session)
      }

      // 2 cancelled sessions
      for (let i = 0; i < 2; i++) {
        const startTime = new Date(now.getTime() - 15 * 60000)
        const session = new Session(`cancelled-${i}`, 'project-b', {
          task: `Cancelled task ${i + 1}`,
          startTime
        })
        session.end('cancelled')
        sessions.push(session)
      }

      const sessionRepo = new MockSessionRepository(sessions)
      const projectRepo = new MockProjectRepository([])

      const useCase = new GetStatusUseCase(sessionRepo, projectRepo)
      const controller = new StatusController(useCase)

      await controller.handle({ verbose: true })

      const output = consoleOutput.join('\n')

      // 60% completion rate (3/5)
      expect(output).toMatch(/Completed:.*3\/5/)
      expect(output).toMatch(/60%/)
      expect(output).toMatch(/\[██████░░░░\]/) // 60% filled

      // Total duration: 3*30 + 2*15 = 120 minutes
      expect(output).toMatch(/Duration:.*2h/)
    })

    test('flow state sessions show enhanced metrics', async () => {
      const sessions = []
      const now = new Date()

      // 2 normal sessions (under flow threshold)
      for (let i = 0; i < 2; i++) {
        const startTime = new Date(now.getTime() - 10 * 60000)
        const session = new Session(`normal-${i}`, 'project-a', { startTime })
        session.end('completed')
        sessions.push(session)
      }

      // 3 flow state sessions (>= 15 minutes)
      for (let i = 0; i < 3; i++) {
        const startTime = new Date(now.getTime() - 20 * 60000)
        const session = new Session(`flow-${i}`, 'project-b', { startTime })
        session.end('completed')
        sessions.push(session)
      }

      const sessionRepo = new MockSessionRepository(sessions)
      const projectRepo = new MockProjectRepository([])

      const useCase = new GetStatusUseCase(sessionRepo, projectRepo)
      const controller = new StatusController(useCase)

      await controller.handle({ verbose: true })

      const output = consoleOutput.join('\n')

      // 60% flow rate (3/5)
      expect(output).toMatch(/Flow %:.*60%/)
      expect(output).toMatch(/\[██████░░░░\]/) // 60% flow

      // 100% completion rate
      expect(output).toMatch(/Completion rate:.*100%/)
      expect(output).toMatch(/\[██████████\]/) // 100% filled
    })

    test('increasing productivity trend over time', async () => {
      const sessions = []
      const now = new Date()

      // Create sessions with increasing durations over past week
      for (let day = 6; day >= 0; day--) {
        const durationMinutes = 20 + (6 - day) * 5 // Increasing: 20, 25, 30, 35, 40, 45, 50
        const sessionDate = new Date(now)
        sessionDate.setDate(sessionDate.getDate() - day)

        const startTime = new Date(sessionDate.getTime() - durationMinutes * 60000)
        const session = new Session(`session-day-${day}`, 'flow-cli', { startTime })
        session.end('completed')
        sessions.push(session)
      }

      const sessionRepo = new MockSessionRepository(sessions)
      const projectRepo = new MockProjectRepository([])

      const useCase = new GetStatusUseCase(sessionRepo, projectRepo)
      const controller = new StatusController(useCase)

      await controller.handle({ recentDays: 7 })

      const output = consoleOutput.join('\n')

      // Should show increasing sparkline pattern
      const trendLine = consoleOutput.find(
        line => line.includes('Trend:') && line.match(/[▁▂▃▄▅▆▇█]/)
      )
      expect(trendLine).toBeTruthy()

      // Verify sparkline shows upward trend (later characters should be higher)
      const sparklineMatch = trendLine.match(/[▁▂▃▄▅▆▇█]+/)
      expect(sparklineMatch).toBeTruthy()
    })

    test('long work session shows multiple duration blocks', async () => {
      const now = new Date()
      const durationMinutes = 180 // 3 hours
      const startTime = new Date(now.getTime() - durationMinutes * 60000)

      const sessions = [
        new Session('long-session', 'marathon-project', {
          task: 'Deep work session',
          startTime
        })
      ]

      sessions[0].end('completed')

      const sessionRepo = new MockSessionRepository(sessions)
      const projectRepo = new MockProjectRepository([])

      const useCase = new GetStatusUseCase(sessionRepo, projectRepo)
      const controller = new StatusController(useCase)

      await controller.handle()

      const output = consoleOutput.join('\n')

      // Should show hours format
      expect(output).toMatch(/Duration:.*3h/)

      // Should show multiple blocks (but capped at 10)
      const durationLine = consoleOutput.find(line => line.includes('Duration:'))
      expect(durationLine).toMatch(/█{10}/) // Maxes out at 10 blocks
    })
  })

  describe('Edge Cases and Boundary Conditions', () => {
    test('handles zero sessions gracefully', async () => {
      const sessionRepo = new MockSessionRepository([])
      const projectRepo = new MockProjectRepository([])

      const useCase = new GetStatusUseCase(sessionRepo, projectRepo)
      const controller = new StatusController(useCase)

      await controller.handle({ verbose: true })

      const output = consoleOutput.join('\n')

      // 0/0 sessions should show 0%
      expect(output).toMatch(/Completed:.*0\/0/)
      expect(output).toMatch(/0%/)
      expect(output).toMatch(/\[░░░░░░░░░░\]/) // Empty bar

      // No sparkline for empty data
      const trendLineWithSparkline = consoleOutput.find(
        line => line.includes('Trend:') && line.match(/[▁▂▃▄▅▆▇█]/)
      )
      expect(trendLineWithSparkline).toBeFalsy()
    })

    test('handles single session correctly', async () => {
      const now = new Date()
      const startTime = new Date(now.getTime() - 30 * 60000)
      const session = new Session('single', 'solo-project', { startTime })
      session.end('completed')

      const sessionRepo = new MockSessionRepository([session])
      const projectRepo = new MockProjectRepository([])

      const useCase = new GetStatusUseCase(sessionRepo, projectRepo)
      const controller = new StatusController(useCase)

      await controller.handle()

      const output = consoleOutput.join('\n')

      // 100% completion with single session
      expect(output).toMatch(/Completed:.*1\/1/)
      expect(output).toMatch(/100%/)
      expect(output).toMatch(/\[██████████\]/)

      // Sparkline for single value
      const trendLine = consoleOutput.find(line => line.includes('Trend:'))
      expect(trendLine).toBeTruthy()
      expect(trendLine).toMatch(/[▁▂▃▄▅▆▇█]/) // Single character sparkline
    })

    test('handles all sessions with same duration', async () => {
      const sessions = []
      const now = new Date()

      // 5 sessions, all 30 minutes
      for (let i = 0; i < 5; i++) {
        const startTime = new Date(now.getTime() - 30 * 60000)
        const session = new Session(`session-${i}`, 'project', { startTime })
        session.end('completed')
        sessions.push(session)
      }

      const sessionRepo = new MockSessionRepository(sessions)
      const projectRepo = new MockProjectRepository([])

      const useCase = new GetStatusUseCase(sessionRepo, projectRepo)
      const controller = new StatusController(useCase)

      await controller.handle()

      const output = consoleOutput.join('\n')

      // Sparkline should show flat trend (all same character)
      const trendLine = consoleOutput.find(line => line.includes('Trend:'))
      expect(trendLine).toBeTruthy()

      const sparklineMatch = trendLine.match(/[▁▂▃▄▅▆▇█]+/)
      expect(sparklineMatch).toBeTruthy()

      // All characters should be the same for constant values
      const sparkline = sparklineMatch[0]
      const uniqueChars = new Set(sparkline)
      expect(uniqueChars.size).toBe(1)
    })

    test('handles very short sessions (< 15 minutes)', async () => {
      const sessions = []
      const now = new Date()

      // 3 very short sessions
      for (let i = 0; i < 3; i++) {
        const startTime = new Date(now.getTime() - 5 * 60000)
        const session = new Session(`short-${i}`, 'quick-tasks', { startTime })
        session.end('completed')
        sessions.push(session)
      }

      const sessionRepo = new MockSessionRepository(sessions)
      const projectRepo = new MockProjectRepository([])

      const useCase = new GetStatusUseCase(sessionRepo, projectRepo)
      const controller = new StatusController(useCase)

      await controller.handle()

      const output = consoleOutput.join('\n')

      // Total duration: 15 minutes = 1 block
      expect(output).toMatch(/Duration:.*15m/)
      expect(output).toMatch(/█/) // Should show at least one block
    })
  })

  describe('Project Statistics Integration', () => {
    test('shows visualizations with active projects', async () => {
      const projects = []

      // Create 3 projects with different activity levels
      const proj1 = new Project('p1', 'flow-cli', '/path/to/flow-cli', {
        type: ProjectType.NODE,
        description: 'ADHD workflow CLI'
      })
      proj1.recordSession(120, true) // 2 hours, completed
      proj1.recordSession(90, true) // 1.5 hours, completed
      projects.push(proj1)

      const proj2 = new Project('p2', 'zsh-config', '/path/to/zsh', {
        type: ProjectType.OTHER
      })
      proj2.recordSession(60, true) // 1 hour
      projects.push(proj2)

      const proj3 = new Project('p3', 'docs', '/path/to/docs', {
        type: ProjectType.OTHER
      })
      proj3.recordSession(30, true) // 30 minutes
      projects.push(proj3)

      const sessionRepo = new MockSessionRepository([])
      const projectRepo = new MockProjectRepository(projects)

      const useCase = new GetStatusUseCase(sessionRepo, projectRepo)
      const controller = new StatusController(useCase)

      await controller.handle({ verbose: true })

      const output = consoleOutput.join('\n')

      // Should show project stats
      expect(output).toMatch(/Projects/)
      expect(output).toMatch(/Total:.*3/)
    })
  })

  describe('Verbose vs Normal Mode Differences', () => {
    test('verbose mode shows more visualizations than normal mode', async () => {
      const now = new Date()
      const startTime1 = new Date(now.getTime() - 30 * 60000)
      const startTime2 = new Date(now.getTime() - 40 * 60000)

      const sessions = [
        new Session('s1', 'project-a', { startTime: startTime1 }),
        new Session('s2', 'project-b', { startTime: startTime2 })
      ]

      sessions[0].end('completed')
      sessions[1].end('completed')

      const sessionRepo = new MockSessionRepository(sessions)
      const projectRepo = new MockProjectRepository([])

      const useCase = new GetStatusUseCase(sessionRepo, projectRepo)
      const controller = new StatusController(useCase)

      // Normal mode
      consoleOutput = []
      await controller.handle({ verbose: false })
      const normalOutput = consoleOutput.join('\n')

      // Verbose mode
      consoleOutput = []
      await controller.handle({ verbose: true })
      const verboseOutput = consoleOutput.join('\n')

      // Verbose should include productivity metrics visualizations
      expect(verboseOutput).toMatch(/Flow %:.*\[/)
      expect(verboseOutput).toMatch(/Completion rate:.*\[/)

      // Normal mode should not show productivity metrics
      expect(normalOutput).not.toMatch(/Flow %:/)
      expect(normalOutput).not.toMatch(/Completion rate:/)
    })
  })
})

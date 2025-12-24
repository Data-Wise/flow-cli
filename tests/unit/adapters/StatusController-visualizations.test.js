/**
 * Unit tests for StatusController ASCII visualization enhancements
 * Tests the Day 9 features: sparklines, progress bars, duration bars
 */

import { describe, test, expect, beforeEach } from '@jest/globals'
import { StatusController } from '../../../cli/adapters/controllers/StatusController.js'

// Mock console.log to capture output
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

// Simple mock for GetStatusUseCase
class MockGetStatusUseCase {
  constructor(statusData) {
    this.statusData = statusData
  }

  async execute() {
    return this.statusData
  }
}

describe('StatusController - ASCII Visualizations', () => {
  describe('displayTodaySummary - Progress Bars', () => {
    test('shows empty progress bar for 0% completion', async () => {
      const mockStatus = {
        today: {
          sessions: 5,
          totalDuration: 120,
          completedSessions: 0,
          flowSessions: 0
        }
      }

      const useCase = new MockGetStatusUseCase(mockStatus)
      const controller = new StatusController(useCase)

      await controller.handle()

      // Find the completion line
      const completionLine = consoleOutput.find(line => line.includes('Completed:'))
      expect(completionLine).toBeTruthy()
      expect(completionLine).toMatch(/0\/5/)
      expect(completionLine).toMatch(/\[░+\]/) // All empty blocks
      expect(completionLine).toMatch(/0%/)
    })

    test('shows full progress bar for 100% completion', async () => {
      const mockStatus = {
        today: {
          sessions: 5,
          totalDuration: 120,
          completedSessions: 5,
          flowSessions: 2
        }
      }

      const useCase = new MockGetStatusUseCase(mockStatus)
      const controller = new StatusController(useCase)

      await controller.handle()

      const completionLine = consoleOutput.find(line => line.includes('Completed:'))
      expect(completionLine).toBeTruthy()
      expect(completionLine).toMatch(/5\/5/)
      expect(completionLine).toMatch(/\[█+\]/) // All filled blocks
      expect(completionLine).toMatch(/100%/)
    })

    test('shows partial progress bar for 50% completion', async () => {
      const mockStatus = {
        today: {
          sessions: 10,
          totalDuration: 120,
          completedSessions: 5,
          flowSessions: 2
        }
      }

      const useCase = new MockGetStatusUseCase(mockStatus)
      const controller = new StatusController(useCase)

      await controller.handle()

      const completionLine = consoleOutput.find(line => line.includes('Completed:'))
      expect(completionLine).toBeTruthy()
      expect(completionLine).toMatch(/5\/10/)
      expect(completionLine).toMatch(/\[█+░+\]/) // Mixed filled and empty
      expect(completionLine).toMatch(/50%/)
    })
  })

  describe('displayTodaySummary - Duration Bars', () => {
    test('shows duration bar for short session', async () => {
      const mockStatus = {
        today: {
          sessions: 1,
          totalDuration: 30,
          completedSessions: 0,
          flowSessions: 0
        }
      }

      const useCase = new MockGetStatusUseCase(mockStatus)
      const controller = new StatusController(useCase)

      await controller.handle()

      const durationLine = consoleOutput.find(line => line.includes('Duration:'))
      expect(durationLine).toBeTruthy()
      expect(durationLine).toMatch(/30m/)
      expect(durationLine).toMatch(/█/) // Should have blocks
    })

    test('shows duration bar for long session with hours', async () => {
      const mockStatus = {
        today: {
          sessions: 1,
          totalDuration: 150, // 2h 30m
          completedSessions: 1,
          flowSessions: 0
        }
      }

      const useCase = new MockGetStatusUseCase(mockStatus)
      const controller = new StatusController(useCase)

      await controller.handle()

      const durationLine = consoleOutput.find(line => line.includes('Duration:'))
      expect(durationLine).toBeTruthy()
      expect(durationLine).toMatch(/2h 30m/)
      expect(durationLine).toMatch(/█+/) // Multiple blocks
    })

    test('handles zero duration', async () => {
      const mockStatus = {
        today: {
          sessions: 0,
          totalDuration: 0,
          completedSessions: 0,
          flowSessions: 0
        }
      }

      const useCase = new MockGetStatusUseCase(mockStatus)
      const controller = new StatusController(useCase)

      await controller.handle()

      const durationLine = consoleOutput.find(line => line.includes('Duration:'))
      expect(durationLine).toBeTruthy()
      expect(durationLine).toMatch(/0m/)
    })
  })

  describe('displayProductivityMetrics - Progress Bars', () => {
    test('shows progress bars for flow % and completion rate', async () => {
      const mockStatus = {
        today: {
          sessions: 1,
          totalDuration: 30,
          completedSessions: 1,
          flowSessions: 0
        },
        metrics: {
          flowPercentage: 25,
          completionRate: 75,
          streak: 5,
          trend: 'up'
        }
      }

      const useCase = new MockGetStatusUseCase(mockStatus)
      const controller = new StatusController(useCase)

      await controller.handle({ verbose: true })

      // Check flow percentage line
      const flowLine = consoleOutput.find(line => line.includes('Flow %:'))
      expect(flowLine).toBeTruthy()
      expect(flowLine).toMatch(/25%/)
      expect(flowLine).toMatch(/\[█+░+\]/) // Progress bar

      // Check completion rate line
      const completionLine = consoleOutput.find(line => line.includes('Completion rate:'))
      expect(completionLine).toBeTruthy()
      expect(completionLine).toMatch(/75%/)
      expect(completionLine).toMatch(/\[█+░+\]/) // Progress bar
    })

    test('shows 0% flow with empty progress bar', async () => {
      const mockStatus = {
        today: {
          sessions: 1,
          totalDuration: 30,
          completedSessions: 1,
          flowSessions: 0
        },
        metrics: {
          flowPercentage: 0,
          completionRate: 100,
          streak: 1,
          trend: 'up'
        }
      }

      const useCase = new MockGetStatusUseCase(mockStatus)
      const controller = new StatusController(useCase)

      await controller.handle({ verbose: true })

      const flowLine = consoleOutput.find(line => line.includes('Flow %:'))
      expect(flowLine).toBeTruthy()
      expect(flowLine).toMatch(/0%/)
      expect(flowLine).toMatch(/\[░+\]/) // Empty bar
    })

    test('shows 100% completion with full progress bar', async () => {
      const mockStatus = {
        today: {
          sessions: 1,
          totalDuration: 30,
          completedSessions: 1,
          flowSessions: 1
        },
        metrics: {
          flowPercentage: 100,
          completionRate: 100,
          streak: 7,
          trend: 'up'
        }
      }

      const useCase = new MockGetStatusUseCase(mockStatus)
      const controller = new StatusController(useCase)

      await controller.handle({ verbose: true })

      const completionLine = consoleOutput.find(line => line.includes('Completion rate:'))
      expect(completionLine).toBeTruthy()
      expect(completionLine).toMatch(/100%/)
      expect(completionLine).toMatch(/\[█+\]/) // Full bar
    })
  })

  describe('displayRecentSessions - Sparklines', () => {
    test('shows sparkline for recent session trends', async () => {
      const mockStatus = {
        today: {
          sessions: 1,
          totalDuration: 30,
          completedSessions: 1,
          flowSessions: 0
        },
        recent: {
          sessions: 5,
          totalDuration: 200,
          averageDuration: 40,
          period: 7,
          recentSessions: [
            { project: 'proj1', duration: 30, outcome: 'completed', endTime: new Date() },
            { project: 'proj2', duration: 45, outcome: 'completed', endTime: new Date() },
            { project: 'proj3', duration: 60, outcome: 'completed', endTime: new Date() },
            { project: 'proj4', duration: 50, outcome: 'completed', endTime: new Date() },
            { project: 'proj5', duration: 15, outcome: 'cancelled', endTime: new Date() }
          ]
        }
      }

      const useCase = new MockGetStatusUseCase(mockStatus)
      const controller = new StatusController(useCase)

      await controller.handle()

      const trendLine = consoleOutput.find(
        line => line.includes('Trend:') && line.match(/[▁▂▃▄▅▆▇█]/)
      )
      expect(trendLine).toBeTruthy()
      expect(trendLine).toMatch(/[▁▂▃▄▅▆▇█]+/) // Contains sparkline characters
    })

    test('shows sparkline for increasing trend', async () => {
      const mockStatus = {
        today: {
          sessions: 1,
          totalDuration: 30,
          completedSessions: 1,
          flowSessions: 0
        },
        recent: {
          sessions: 4,
          totalDuration: 100,
          averageDuration: 25,
          period: 7,
          recentSessions: [
            { project: 'proj1', duration: 10, outcome: 'completed', endTime: new Date() },
            { project: 'proj2', duration: 20, outcome: 'completed', endTime: new Date() },
            { project: 'proj3', duration: 30, outcome: 'completed', endTime: new Date() },
            { project: 'proj4', duration: 40, outcome: 'completed', endTime: new Date() }
          ]
        }
      }

      const useCase = new MockGetStatusUseCase(mockStatus)
      const controller = new StatusController(useCase)

      await controller.handle()

      const trendLine = consoleOutput.find(
        line => line.includes('Trend:') && line.match(/[▁▂▃▄▅▆▇█]/)
      )
      expect(trendLine).toBeTruthy()
      // Sparkline should show increasing pattern
      expect(trendLine).toMatch(/[▁▂▃▄▅▆▇█]+/)
    })

    test('handles single session without error', async () => {
      const mockStatus = {
        today: {
          sessions: 1,
          totalDuration: 30,
          completedSessions: 1,
          flowSessions: 0
        },
        recent: {
          sessions: 1,
          totalDuration: 30,
          averageDuration: 30,
          period: 7,
          recentSessions: [
            { project: 'proj1', duration: 30, outcome: 'completed', endTime: new Date() }
          ]
        }
      }

      const useCase = new MockGetStatusUseCase(mockStatus)
      const controller = new StatusController(useCase)

      await controller.handle()

      const trendLine = consoleOutput.find(line => line.includes('Trend:'))
      expect(trendLine).toBeTruthy()
      // Single value should still show sparkline
      expect(trendLine).toMatch(/[▁▂▃▄▅▆▇█]/)
    })

    test('handles no sessions gracefully', async () => {
      const mockStatus = {
        today: {
          sessions: 0,
          totalDuration: 0,
          completedSessions: 0,
          flowSessions: 0
        },
        recent: {
          sessions: 0,
          totalDuration: 0,
          averageDuration: 0,
          period: 7,
          recentSessions: []
        }
      }

      const useCase = new MockGetStatusUseCase(mockStatus)
      const controller = new StatusController(useCase)

      await controller.handle()

      // Should not crash, no trend line expected
      const trendLine = consoleOutput.find(
        line => line.includes('Trend:') && line.match(/[▁▂▃▄▅▆▇█]/)
      )
      expect(trendLine).toBeFalsy() // No sparkline for empty data
    })
  })

  describe('Verbose Mode - Full Visualization Suite', () => {
    test('verbose mode shows all visualizations', async () => {
      const mockStatus = {
        today: {
          sessions: 10,
          totalDuration: 240, // 4 hours
          completedSessions: 7,
          flowSessions: 3
        },
        metrics: {
          flowPercentage: 30,
          completionRate: 70,
          streak: 5,
          trend: 'up'
        },
        recent: {
          sessions: 20,
          totalDuration: 600,
          averageDuration: 30,
          period: 7,
          recentSessions: [
            { project: 'proj1', duration: 25, outcome: 'completed', endTime: new Date() },
            { project: 'proj2', duration: 35, outcome: 'completed', endTime: new Date() },
            { project: 'proj3', duration: 40, outcome: 'completed', endTime: new Date() },
            { project: 'proj4', duration: 30, outcome: 'completed', endTime: new Date() },
            { project: 'proj5', duration: 20, outcome: 'cancelled', endTime: new Date() }
          ]
        },
        projects: {
          total: 15,
          recentCount: 5,
          topProjects: [
            { name: 'flow-cli', totalDuration: 300 },
            { name: 'zsh-config', totalDuration: 200 }
          ]
        }
      }

      const useCase = new MockGetStatusUseCase(mockStatus)
      const controller = new StatusController(useCase)

      await controller.handle({ verbose: true })

      // Verify all visualization types are present
      const output = consoleOutput.join('\n')

      // Duration bars
      expect(output).toMatch(/4h.*█+/) // Hours with blocks

      // Progress bars for completion
      expect(output).toMatch(/7\/10.*\[█+░+\].*70%/) // Completion rate

      // Progress bars for metrics
      expect(output).toMatch(/Flow %:.*30%.*\[█+░+\]/)
      expect(output).toMatch(/Completion rate:.*70%.*\[█+░+\]/)

      // Sparklines for trends
      expect(output).toMatch(/Trend:.*[▁▂▃▄▅▆▇█]+/)
    })
  })

  describe('Integration with Display Methods', () => {
    test('displayTodaySummary uses durationBar utility', async () => {
      const mockStatus = {
        today: {
          sessions: 1,
          totalDuration: 45, // 3 blocks (15m each)
          completedSessions: 1,
          flowSessions: 0
        }
      }

      const useCase = new MockGetStatusUseCase(mockStatus)
      const controller = new StatusController(useCase)

      await controller.handle()

      const durationLine = consoleOutput.find(line => line.includes('Duration:'))
      expect(durationLine).toBeTruthy()
      expect(durationLine).toMatch(/45m/)
      expect(durationLine).toMatch(/█{3}/) // 3 blocks for 45 minutes
    })

    test('displayProductivityMetrics uses progressBar utility', async () => {
      const mockStatus = {
        today: {
          sessions: 1,
          totalDuration: 30,
          completedSessions: 1,
          flowSessions: 0
        },
        metrics: {
          flowPercentage: 40,
          completionRate: 80,
          streak: 3,
          trend: 'up'
        }
      }

      const useCase = new MockGetStatusUseCase(mockStatus)
      const controller = new StatusController(useCase)

      await controller.handle({ verbose: true })

      const output = consoleOutput.join('\n')

      // Both metrics should have progress bars
      expect(output).toMatch(/Flow %:.*40%.*\[/)
      expect(output).toMatch(/Completion rate:.*80%.*\[/)
    })

    test('displayRecentSessions uses sparkline utility', async () => {
      const mockStatus = {
        today: {
          sessions: 1,
          totalDuration: 30,
          completedSessions: 1,
          flowSessions: 0
        },
        recent: {
          sessions: 3,
          totalDuration: 90,
          averageDuration: 30,
          period: 7,
          recentSessions: [
            { project: 'proj1', duration: 20, outcome: 'completed', endTime: new Date() },
            { project: 'proj2', duration: 30, outcome: 'completed', endTime: new Date() },
            { project: 'proj3', duration: 40, outcome: 'completed', endTime: new Date() }
          ]
        }
      }

      const useCase = new MockGetStatusUseCase(mockStatus)
      const controller = new StatusController(useCase)

      await controller.handle()

      const trendLine = consoleOutput.find(line => line.includes('Trend:'))
      expect(trendLine).toBeTruthy()
      expect(trendLine).toMatch(/[▁▂▃▄▅▆▇█]{3}/) // 3 data points = 3 characters
    })
  })
})

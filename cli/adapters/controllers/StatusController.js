/**
 * StatusController
 *
 * CLI controller for the enhanced status command.
 * Uses GetStatusUseCase to retrieve comprehensive workflow status.
 *
 * Features:
 * - Active session display
 * - Today's session summary
 * - Recent session history
 * - Project statistics
 * - Productivity metrics
 * - Worklog integration
 */

import { homedir } from 'os'
import { join } from 'path'
import { readFile } from 'fs/promises'
import { existsSync } from 'fs'

export class StatusController {
  /**
   * @param {GetStatusUseCase} getStatusUseCase
   */
  constructor(getStatusUseCase) {
    this.getStatus = getStatusUseCase
  }

  /**
   * Handle status command
   * @param {Object} options
   * @param {boolean} options.verbose - Show detailed output
   * @param {boolean} options.includeWorklog - Include worklog entries
   * @param {number} options.recentDays - Days to include in recent history
   */
  async handle(options = {}) {
    const verbose = options.verbose || false
    const includeWorklog = options.includeWorklog !== false
    const recentDays = options.recentDays || 7

    try {
      // Get status from use case
      const status = await this.getStatus.execute({ recentDays })

      // Display active session
      if (status.activeSession) {
        this.displayActiveSession(status.activeSession, verbose)
      } else {
        this.displayNoActiveSession()
      }

      // Display today summary
      if (status.today) {
        console.log('')
        this.displayTodaySummary(status.today, verbose)
      }

      // Display productivity metrics
      if (status.metrics && verbose) {
        console.log('')
        this.displayProductivityMetrics(status.metrics)
      }

      // Display recent sessions
      if (status.recent && status.recent.sessions > 0) {
        console.log('')
        this.displayRecentSessions(status.recent, verbose)
      }

      // Display project stats
      if (status.projects && verbose) {
        console.log('')
        this.displayProjectStats(status.projects)
      }

      // Display worklog entries
      if (includeWorklog) {
        const worklog = await this.readWorklog()
        if (worklog.length > 0) {
          console.log('')
          this.displayWorklog(worklog.slice(0, 5))
        }
      }

      // Display quick actions
      if (status.activeSession) {
        console.log('')
        this.displayQuickActions()
      }

      return { success: true, status }
    } catch (error) {
      console.error(`status: error retrieving status: ${error.message}`)
      return { success: false, error: error.message }
    }
  }

  /**
   * Display active session information
   */
  displayActiveSession(session, verbose) {
    console.log('✅ Active Session')
    console.log(`   Project: ${session.project}`)
    console.log(`   Task: ${session.task || 'No task specified'}`)
    console.log(`   Duration: ${session.duration} min${session.isFlowState ? ' 🔥 IN FLOW' : ''}`)

    if (verbose) {
      console.log(`   Branch: ${session.branch || 'unknown'}`)
      console.log(`   Started: ${this.formatTime(session.startTime)}`)

      if (session.context && Object.keys(session.context).length > 0) {
        console.log('\n   📝 Context:')
        for (const [key, value] of Object.entries(session.context)) {
          console.log(`      ${key}: ${value}`)
        }
      }
    }
  }

  /**
   * Display no active session message
   */
  displayNoActiveSession() {
    console.log('❌ No active session')
    console.log('\n💡 Start a session with:')
    console.log('   flow work <project> [task]')
  }

  /**
   * Display today's summary
   */
  displayTodaySummary(today, verbose) {
    console.log('📊 Today')
    console.log(`   Sessions: ${today.sessions}`)
    console.log(`   Duration: ${this.formatDuration(today.totalDuration)}`)
    console.log(`   Completed: ${today.completedSessions}/${today.sessions}`)

    if (verbose && today.flowSessions !== undefined) {
      console.log(`   Flow sessions: ${today.flowSessions}`)
    }
  }

  /**
   * Display productivity metrics
   */
  displayProductivityMetrics(metrics) {
    console.log('📈 Productivity Metrics')
    console.log(`   Flow %: ${metrics.flowPercentage}%`)
    console.log(`   Completion rate: ${metrics.completionRate}%`)
    console.log(`   Current streak: ${metrics.streak} days`)

    const trendIcon = metrics.trend === 'up' ? '📈' :
                      metrics.trend === 'down' ? '📉' : '➡️'
    console.log(`   Trend: ${trendIcon} ${metrics.trend}`)
  }

  /**
   * Display recent sessions
   */
  displayRecentSessions(recent, verbose) {
    console.log(`📜 Recent Sessions (last ${recent.period} days)`)
    console.log(`   Total: ${recent.sessions}`)
    console.log(`   Duration: ${this.formatDuration(recent.totalDuration)}`)
    console.log(`   Average: ${this.formatDuration(recent.averageDuration)}`)

    if (verbose && recent.recentSessions) {
      console.log('\n   Last 3 sessions:')
      for (const session of recent.recentSessions.slice(0, 3)) {
        const icon = session.outcome === 'completed' ? '✓' :
                    session.outcome === 'cancelled' ? '✗' : '?'
        console.log(`   ${icon} ${session.project} (${session.duration}m) - ${this.relativeTime(session.endTime)}`)
      }
    }
  }

  /**
   * Display project statistics
   */
  displayProjectStats(projects) {
    console.log('📁 Projects')
    console.log(`   Total: ${projects.total}`)
    console.log(`   Recent: ${projects.recentCount || 0}`)

    if (projects.topProjects && projects.topProjects.length > 0) {
      console.log('\n   Top projects:')
      for (const project of projects.topProjects.slice(0, 3)) {
        console.log(`   • ${project.name} (${this.formatDuration(project.totalDuration)})`)
      }
    }
  }

  /**
   * Display worklog entries
   */
  displayWorklog(entries) {
    console.log('📝 Recent Worklog')
    for (const entry of entries) {
      const time = entry.timestamp ? this.formatTime(entry.timestamp) : 'unknown'
      console.log(`   ${time} - ${entry.action}: ${entry.details || ''}`)
    }
  }

  /**
   * Display quick actions menu
   */
  displayQuickActions() {
    console.log('⚡ Quick Actions')
    console.log('   [f] flow finish     - End session')
    console.log('   [p] flow pause      - Pause session')
    console.log('   [s] flow switch     - Switch project')
    console.log('   [t] flow task       - Add task')
  }

  /**
   * Read worklog entries
   */
  async readWorklog() {
    const worklogPath = join(homedir(), '.config', 'zsh', '.worklog')

    if (!existsSync(worklogPath)) {
      return []
    }

    try {
      const content = await readFile(worklogPath, 'utf-8')
      const lines = content.trim().split('\n').filter(Boolean)

      return lines.map(line => {
        const [timestamp, ...rest] = line.split(' ')
        const text = rest.join(' ')
        const [action, ...detailsParts] = text.split(':')

        return {
          timestamp: new Date(timestamp),
          action: action.trim(),
          details: detailsParts.join(':').trim()
        }
      }).reverse() // Most recent first
    } catch (error) {
      console.error(`Warning: Could not read worklog: ${error.message}`)
      return []
    }
  }

  /**
   * Format duration in minutes to human-readable string
   */
  formatDuration(minutes) {
    if (minutes < 60) {
      return `${minutes}m`
    }

    const hours = Math.floor(minutes / 60)
    const mins = minutes % 60

    if (mins === 0) {
      return `${hours}h`
    }

    return `${hours}h ${mins}m`
  }

  /**
   * Format time
   */
  formatTime(date) {
    if (!(date instanceof Date)) {
      date = new Date(date)
    }

    const hours = date.getHours().toString().padStart(2, '0')
    const minutes = date.getMinutes().toString().padStart(2, '0')

    return `${hours}:${minutes}`
  }

  /**
   * Format relative time (e.g., "2h ago")
   */
  relativeTime(date) {
    if (!(date instanceof Date)) {
      date = new Date(date)
    }

    const now = new Date()
    const diffMs = now - date
    const diffMins = Math.floor(diffMs / 60000)

    if (diffMins < 60) {
      return `${diffMins}m ago`
    }

    const diffHours = Math.floor(diffMins / 60)
    if (diffHours < 24) {
      return `${diffHours}h ago`
    }

    const diffDays = Math.floor(diffHours / 24)
    return `${diffDays}d ago`
  }
}

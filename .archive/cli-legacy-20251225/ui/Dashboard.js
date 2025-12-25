/**
 * Dashboard - Terminal UI Component
 *
 * Real-time interactive dashboard using blessed.
 * Displays workflow status, sessions, and metrics.
 *
 * Features:
 * - Real-time updates (configurable interval)
 * - Project filtering
 * - Interactive navigation
 * - Keyboard shortcuts
 *
 * Architecture:
 * - Follows Clean Architecture
 * - Uses GetStatusUseCase for business logic
 * - Pure presentation layer
 */

import blessed from 'blessed'
import contrib from 'blessed-contrib'

export class Dashboard {
  /**
   * @param {GetStatusUseCase} getStatusUseCase
   * @param {Object} options
   * @param {number} [options.refreshInterval=5000] - Auto-refresh interval in ms
   */
  constructor(getStatusUseCase, options = {}) {
    this.getStatusUseCase = getStatusUseCase
    this.refreshInterval = options.refreshInterval || 5000
    this.filterText = ''
    this.selectedIndex = 0
    this.isRunning = false
    this.refreshTimer = null

    // Create screen
    this.screen = blessed.screen({
      smartCSR: true,
      title: 'Flow Dashboard',
      fullUnicode: true
    })

    // Create grid layout
    this.grid = new contrib.grid({ rows: 12, cols: 12, screen: this.screen })

    // Create widgets
    this._createWidgets()

    // Set up keyboard shortcuts
    this._setupKeyBindings()
  }

  /**
   * Create all dashboard widgets
   * @private
   */
  _createWidgets() {
    // Top banner: Active Session (full width)
    this.activeSessionBox = this.grid.set(0, 0, 3, 12, blessed.box, {
      label: ' Active Session ',
      content: 'Loading...',
      tags: true,
      border: { type: 'line', fg: 'cyan' },
      style: {
        border: { fg: 'cyan' },
        focus: { border: { fg: 'yellow' } }
      }
    })

    // Left column: Metrics visualization (4 rows)
    this.metricsBar = this.grid.set(3, 0, 4, 6, contrib.bar, {
      label: " Today's Metrics ",
      barWidth: 8,
      barSpacing: 2,
      xOffset: 2,
      maxHeight: 10,
      border: { type: 'line' },
      style: {
        border: { fg: 'green' }
      }
    })

    // Right column: Stats summary
    this.statsBox = this.grid.set(3, 6, 4, 6, blessed.box, {
      label: ' Statistics ',
      content: 'Loading...',
      tags: true,
      border: { type: 'line' },
      style: {
        border: { fg: 'magenta' }
      },
      scrollable: true,
      alwaysScroll: true,
      keys: true,
      vi: true
    })

    // Bottom: Recent Sessions list (5 rows)
    this.sessionsTable = this.grid.set(7, 0, 5, 12, contrib.table, {
      keys: true,
      vi: true,
      fg: 'white',
      selectedFg: 'white',
      selectedBg: 'blue',
      interactive: true,
      label: ' Recent Sessions (↑/↓ to navigate) ',
      width: '100%',
      height: '100%',
      border: { type: 'line', fg: 'white' },
      columnSpacing: 3,
      columnWidth: [20, 30, 15, 12, 15]
    })

    // Focus sessions table by default
    this.sessionsTable.focus()

    // Render screen
    this.screen.render()
  }

  /**
   * Set up keyboard bindings
   * @private
   */
  _setupKeyBindings() {
    // Quit on q, Escape, or Ctrl-C
    this.screen.key(['q', 'escape', 'C-c'], () => {
      this.stop()
      process.exit(0)
    })

    // Refresh on r
    this.screen.key(['r'], async () => {
      await this.refresh()
    })

    // Filter on /
    this.screen.key(['/'], () => {
      this._promptFilter()
    })

    // Help on ?
    this.screen.key(['?', 'h'], () => {
      this._showHelp()
    })
  }

  /**
   * Show help overlay
   * @private
   */
  _showHelp() {
    const helpBox = blessed.box({
      top: 'center',
      left: 'center',
      width: '50%',
      height: '50%',
      content:
        '{bold}Flow Dashboard - Keyboard Shortcuts{/bold}\n\n' +
        '{cyan-fg}q, ESC, Ctrl-C{/} - Quit\n' +
        '{cyan-fg}r{/}              - Refresh data\n' +
        '{cyan-fg}/{/}              - Filter/search\n' +
        '{cyan-fg}↑/↓{/}            - Navigate sessions\n' +
        '{cyan-fg}?, h{/}           - Show this help\n\n' +
        'Press any key to close...',
      tags: true,
      border: { type: 'line' },
      style: {
        border: { fg: 'yellow' },
        bg: 'black'
      }
    })

    this.screen.append(helpBox)
    helpBox.focus()

    helpBox.key(['escape', 'q', 'enter', 'space'], () => {
      this.screen.remove(helpBox)
      this.sessionsTable.focus()
      this.screen.render()
    })

    this.screen.render()
  }

  /**
   * Prompt for filter text
   * @private
   */
  _promptFilter() {
    const inputBox = blessed.textbox({
      top: 'center',
      left: 'center',
      width: '50%',
      height: 3,
      label: ' Filter Projects (Enter to apply, ESC to cancel) ',
      border: { type: 'line' },
      style: {
        border: { fg: 'yellow' }
      },
      inputOnFocus: true
    })

    this.screen.append(inputBox)
    inputBox.focus()

    inputBox.on('submit', async value => {
      this.filterText = value
      this.screen.remove(inputBox)
      this.sessionsTable.focus()
      await this.refresh()
    })

    inputBox.on('cancel', () => {
      this.screen.remove(inputBox)
      this.sessionsTable.focus()
      this.screen.render()
    })

    this.screen.render()
  }

  /**
   * Start the dashboard
   */
  async start() {
    this.isRunning = true

    // Initial refresh
    await this.refresh()

    // Set up auto-refresh
    this.refreshTimer = setInterval(async () => {
      if (this.isRunning) {
        await this.refresh()
      }
    }, this.refreshInterval)
  }

  /**
   * Stop the dashboard
   */
  stop() {
    this.isRunning = false
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
      this.refreshTimer = null
    }
  }

  /**
   * Refresh dashboard data
   */
  async refresh() {
    try {
      const status = await this.getStatusUseCase.execute({
        includeRecentSessions: true,
        includeProjectStats: true,
        recentDays: 7
      })

      this._updateActiveSession(status.activeSession)
      this._updateMetrics(status.today, status.metrics)
      this._updateStats(status)
      this._updateSessions(status.recent)

      this.screen.render()
    } catch (error) {
      this._showError(error)
    }
  }

  /**
   * Update active session display
   * @private
   */
  _updateActiveSession(session) {
    if (!session) {
      this.activeSessionBox.setContent('{center}{yellow-fg}No active session{/yellow-fg}{/center}')
      this.activeSessionBox.style.border.fg = 'gray'
      return
    }

    const hours = Math.floor(session.duration / 60)
    const minutes = session.duration % 60
    const durationStr = hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`

    const flowIndicator = session.isFlowState ? '🔥' : '⏱️'
    const content =
      `{bold}${flowIndicator} ${session.project}{/bold}\n` +
      `Task: ${session.task || 'General work'}\n` +
      `Branch: ${session.branch || 'N/A'} | Duration: ${durationStr} | State: ${session.state}`

    this.activeSessionBox.setContent(content)
    this.activeSessionBox.style.border.fg = session.isFlowState ? 'green' : 'cyan'
  }

  /**
   * Update metrics bar chart
   * @private
   */
  _updateMetrics(today, metrics) {
    const data = {
      titles: ['Sessions', 'Flow', 'Completed', 'Minutes'],
      data: [today.sessions, today.flowSessions, today.completedSessions, today.totalDuration]
    }

    this.metricsBar.setData(data)
  }

  /**
   * Update statistics box
   * @private
   */
  _updateStats(status) {
    const { today, recent, metrics, projects } = status

    const content =
      `{bold}{cyan-fg}Today{/cyan-fg}{/bold}\n` +
      `  Sessions: ${today.sessions}\n` +
      `  Total Time: ${today.totalDuration}m\n` +
      `  Flow Sessions: ${today.flowSessions}\n\n` +
      `{bold}{magenta-fg}Recent (${recent.days} days){/magenta-fg}{/bold}\n` +
      `  Total Sessions: ${recent.sessions}\n` +
      `  Total Time: ${recent.totalDuration}m\n` +
      `  Avg Duration: ${recent.averageDuration}m\n\n` +
      `{bold}{green-fg}Metrics{/green-fg}{/bold}\n` +
      `  Daily Average: ${metrics.dailyAverage}m\n` +
      `  Flow %: ${metrics.flowPercentage}%\n` +
      `  Completion Rate: ${metrics.completionRate}%\n` +
      `  Streak: ${metrics.streak} days\n` +
      `  Trend: ${metrics.trend === 'up' ? '📈' : '📉'}\n\n` +
      `{bold}{yellow-fg}Projects{/yellow-fg}{/bold}\n` +
      `  Total: ${projects ? projects.total : 0}`

    this.statsBox.setContent(content)
  }

  /**
   * Update sessions table
   * @private
   */
  _updateSessions(recent) {
    if (!recent || !recent.recentSessions || recent.recentSessions.length === 0) {
      this.sessionsTable.setData({
        headers: ['Project', 'Task', 'Duration', 'Outcome', 'Start Time'],
        data: [['No recent sessions', '', '', '', '']]
      })
      return
    }

    let sessions = recent.recentSessions

    // Apply filter if set
    if (this.filterText) {
      const filter = this.filterText.toLowerCase()
      sessions = sessions.filter(s => s.project.toLowerCase().includes(filter))
    }

    const data = sessions.map(s => {
      const date = new Date(s.startTime)
      const timeStr = date.toLocaleTimeString('en-US', {
        hour: '2-digit',
        minute: '2-digit'
      })
      const dateStr = date.toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric'
      })

      return [
        s.project.substring(0, 18),
        (s.task || 'General').substring(0, 28),
        `${s.duration}m`,
        s.outcome || 'ongoing',
        `${dateStr} ${timeStr}`
      ]
    })

    this.sessionsTable.setData({
      headers: ['Project', 'Task', 'Duration', 'Outcome', 'Start Time'],
      data
    })
  }

  /**
   * Show error message
   * @private
   */
  _showError(error) {
    const errorBox = blessed.box({
      top: 'center',
      left: 'center',
      width: '60%',
      height: '30%',
      content: `{red-fg}{bold}Error{/bold}{/red-fg}\n\n${error.message}\n\nPress any key to close...`,
      tags: true,
      border: { type: 'line' },
      style: {
        border: { fg: 'red' }
      }
    })

    this.screen.append(errorBox)
    errorBox.focus()

    errorBox.key(['escape', 'q', 'enter', 'space'], () => {
      this.screen.remove(errorBox)
      this.sessionsTable.focus()
      this.screen.render()
    })

    this.screen.render()
  }

  /**
   * Destroy the dashboard
   */
  destroy() {
    this.stop()
    if (this.screen) {
      this.screen.destroy()
    }
  }
}

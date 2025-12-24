#!/usr/bin/env node

/**
 * Flow Dashboard Command
 *
 * Launch interactive TUI dashboard for real-time workflow monitoring.
 *
 * Usage:
 *   flow dashboard [options]
 *
 * Options:
 *   --interval <ms>    Auto-refresh interval in milliseconds (default: 5000)
 *   --help             Show this help
 *
 * Keyboard Shortcuts:
 *   q, ESC, Ctrl-C     Quit
 *   r                  Refresh data
 *   /                  Filter/search
 *   ↑/↓                Navigate sessions
 *   ?, h               Show help
 */

import { createContainer } from '../adapters/Container.js'
import { Dashboard } from '../ui/Dashboard.js'

// Parse arguments
const args = process.argv.slice(2)

// Show help
if (args.includes('--help') || args.includes('-h')) {
  showHelp()
  process.exit(0)
}

// Parse refresh interval
let refreshInterval = 5000
const intervalIndex = args.indexOf('--interval')
if (intervalIndex !== -1 && args[intervalIndex + 1]) {
  const parsed = parseInt(args[intervalIndex + 1], 10)
  if (!isNaN(parsed) && parsed > 0) {
    refreshInterval = parsed
  }
}

// Create container and use case
const container = createContainer()
const getStatusUseCase = container.getGetStatusUseCase()

// Create and start dashboard
const dashboard = new Dashboard(getStatusUseCase, { refreshInterval })

// Handle graceful shutdown
process.on('SIGINT', () => {
  dashboard.destroy()
  process.exit(0)
})

process.on('SIGTERM', () => {
  dashboard.destroy()
  process.exit(0)
})

// Start dashboard
await dashboard.start()

function showHelp() {
  console.log(`Usage: flow dashboard [options]

Interactive TUI Dashboard - Real-time workflow monitoring

Options:
  --interval <ms>    Auto-refresh interval in milliseconds (default: 5000)
  --help, -h         Show this help

Keyboard Shortcuts:
  q, ESC, Ctrl-C     Quit dashboard
  r                  Refresh data manually
  /                  Filter/search projects
  ↑/↓                Navigate sessions list
  ?, h               Show help overlay

Examples:
  flow dashboard              Start dashboard with default settings
  flow dashboard --interval 10000   Refresh every 10 seconds

The dashboard displays:
  - Active session with real-time duration
  - Today's metrics (bar chart)
  - Statistics summary (today, recent, metrics)
  - Recent sessions table (interactive)

Documentation:
  https://Data-Wise.github.io/flow-cli/commands/dashboard/`)
}

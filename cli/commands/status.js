#!/usr/bin/env node

/**
 * flow status command
 *
 * Enhanced status display with worklog integration.
 * Shows active session, today's summary, recent history, and productivity metrics.
 */

import { createContainer } from '../adapters/Container.js'
import { StatusController } from '../adapters/controllers/StatusController.js'

// Help text
function showHelp() {
  console.log(`Usage: flow status [options]

Shows comprehensive workflow status including active session, today's summary,
recent history, and productivity metrics.

Options:
  -h, --help         Show this help message
  -v, --verbose      Show detailed output with all metrics
  -d, --days <n>     Number of days for recent history (default: 7)
  --no-worklog       Skip worklog integration
  --web              Launch interactive web dashboard (opens browser)
  -p, --port <n>     Web dashboard port (default: 3737, requires --web)

Modes:
  Default (CLI):     Fast, scriptable ASCII output in terminal
  Web Dashboard:     Rich, interactive browser-based dashboard with charts

Examples:
  flow status                    # Show standard CLI status
  flow status -v                 # Show detailed CLI status with all metrics
  flow status -d 14              # Show last 14 days of history
  flow status --no-worklog       # Skip worklog entries
  flow status --web              # Launch web dashboard (opens browser)
  flow status --web -p 8080      # Launch web dashboard on custom port

See also: flow work, flow finish, flow list`)
}

// Parse command line arguments
function parseArgs(args) {
  const options = {
    verbose: false,
    recentDays: 7,
    includeWorklog: true,
    web: false,
    port: 3737
  }

  for (let i = 0; i < args.length; i++) {
    const arg = args[i]

    switch (arg) {
      case '-h':
      case '--help':
        showHelp()
        process.exit(0)
        break

      case '-v':
      case '--verbose':
        options.verbose = true
        break

      case '-d':
      case '--days':
        i++
        if (i >= args.length) {
          console.error('status: --days requires a number argument')
          console.error("Run 'flow status --help' for usage")
          process.exit(1)
        }
        options.recentDays = parseInt(args[i], 10)
        if (isNaN(options.recentDays) || options.recentDays < 1) {
          console.error('status: --days must be a positive number')
          console.error("Run 'flow status --help' for usage")
          process.exit(1)
        }
        break

      case '--no-worklog':
        options.includeWorklog = false
        break

      case '--web':
        options.web = true
        break

      case '-p':
      case '--port':
        i++
        if (i >= args.length) {
          console.error('status: --port requires a number argument')
          console.error("Run 'flow status --help' for usage")
          process.exit(1)
        }
        options.port = parseInt(args[i], 10)
        if (isNaN(options.port) || options.port < 1 || options.port > 65535) {
          console.error('status: --port must be a valid port number (1-65535)')
          console.error("Run 'flow status --help' for usage")
          process.exit(1)
        }
        break

      default:
        console.error(`status: unknown option '${arg}'`)
        console.error("Run 'flow status --help' for usage")
        process.exit(1)
    }
  }

  return options
}

// Main function
async function main() {
  try {
    // Parse arguments
    const args = process.argv.slice(2)
    const options = parseArgs(args)

    // Create container and controller
    const container = createContainer()
    const statusUseCase = container.getUseCases().getStatus

    // Create controller with event publisher for web dashboard mode
    const eventPublisher = container.getEventPublisher()
    const controller = new StatusController(statusUseCase, { eventPublisher })

    // Execute
    const result = await controller.handle(options)

    if (!result.success) {
      console.error(`status: ${result.error}`)
      process.exit(1)
    }

    process.exit(0)
  } catch (error) {
    console.error(`status: unexpected error: ${error.message}`)
    process.exit(1)
  }
}

// Run main function
main()

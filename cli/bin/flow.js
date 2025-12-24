#!/usr/bin/env node

/**
 * Flow CLI - Main executable
 *
 * Routes commands to their respective handlers:
 * - flow status [options]    -> commands/status.js
 * - flow work <project>      -> commands/work.js (future)
 * - flow finish [message]    -> commands/finish.js (future)
 * - flow help               -> Show help
 */

import { fileURLToPath } from 'url'
import { dirname, join } from 'path'
import { existsSync } from 'fs'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

const args = process.argv.slice(2)
const command = args[0]

// Show help if no command or --help
if (!command || command === 'help' || command === '--help' || command === '-h') {
  showHelp()
  process.exit(0)
}

// Show version
if (command === '--version' || command === '-v') {
  const pkg = await import('../package.json', { with: { type: 'json' } })
  console.log(`flow-cli v${pkg.default.version}`)
  process.exit(0)
}

// Route to command handlers
const commandsDir = join(__dirname, '..', 'commands')
const commandFile = join(commandsDir, `${command}.js`)

if (!existsSync(commandFile)) {
  console.error(`flow: unknown command '${command}'`)
  console.error("Run 'flow help' for usage")
  process.exit(1)
}

// Remove command name from argv so the command script gets the right args
// e.g., "flow status --web" becomes just "--web" for status.js
process.argv.splice(2, 1)

// Execute command
try {
  await import(commandFile)
} catch (error) {
  console.error(`flow: error executing command '${command}':`, error.message)
  process.exit(1)
}

function showHelp() {
  console.log(`Usage: flow <command> [options]

Flow CLI - ADHD-optimized workflow management

Commands:
  status [options]           Show workflow status
                            --web     Launch web dashboard
                            -v        Verbose output
                            --help    Show status help

  dashboard [options]        Launch interactive TUI dashboard
                            --interval <ms>   Auto-refresh interval
                            --help    Show dashboard help

  help                      Show this help message
  --version, -v             Show version

Examples:
  flow status               Show current status (CLI)
  flow status --web         Launch web dashboard
  flow dashboard            Launch interactive TUI dashboard
  flow status -v            Show detailed status
  flow help                 Show this help

Documentation:
  https://Data-Wise.github.io/flow-cli/

Report issues:
  https://github.com/Data-Wise/flow-cli/issues`)
}

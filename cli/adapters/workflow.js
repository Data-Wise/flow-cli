/**
 * Workflow Adapter
 *
 * Adapter for executing ZSH workflow commands.
 * Wraps work, finish, and other workflow-related commands.
 */

const { exec } = require('child_process')
const { promisify } = require('util')

const execAsync = promisify(exec)

/**
 * Execute a ZSH command with full shell environment
 * @param {string} command - The ZSH command to execute
 * @returns {Promise<Object>} {success, stdout, stderr, exitCode}
 */
async function executeZshCommand(command) {
  try {
    // Source .zshrc to load all functions and execute command
    const fullCommand = `zsh -c 'source ~/.zshrc && ${command}'`

    const { stdout, stderr } = await execAsync(fullCommand, {
      // Set timeout to prevent hanging
      timeout: 30000,
      // Use user's shell environment
      env: process.env
    })

    return {
      success: true,
      stdout: stdout.trim(),
      stderr: stderr.trim(),
      exitCode: 0
    }
  } catch (error) {
    return {
      success: false,
      stdout: error.stdout || '',
      stderr: error.stderr || error.message,
      exitCode: error.code || 1
    }
  }
}

/**
 * Start a work session
 * @param {string} project - Project name or path
 * @param {Object} options - Additional options
 * @param {string} options.editor - Editor to use (emacs, code, cursor, etc.)
 * @returns {Promise<Object>} Result with session info
 */
async function startWork(project, options = {}) {
  if (!project) {
    throw new Error('Project name is required')
  }

  // Build command with options
  let command = `work ${project}`
  if (options.editor) {
    command = `EDITOR=${options.editor} ${command}`
  }

  const result = await executeZshCommand(command)

  return {
    ...result,
    project,
    command,
    timestamp: new Date().toISOString()
  }
}

/**
 * End the current work session
 * @param {string} message - Optional commit message
 * @returns {Promise<Object>} Result with session end info
 */
async function finishWork(message = '') {
  let command = 'finish'
  if (message) {
    // Escape single quotes in message
    const escapedMessage = message.replace(/'/g, "'\\''")
    command = `finish '${escapedMessage}'`
  }

  const result = await executeZshCommand(command)

  return {
    ...result,
    command,
    timestamp: new Date().toISOString()
  }
}

/**
 * Get workflow context (what project type, what commands available)
 * @param {string} directory - Directory to check (defaults to cwd)
 * @returns {Promise<Object>} Context information
 */
async function getWorkflowContext(directory = process.cwd()) {
  // Use the ZSH project type detection
  const command = `cd ${directory} && project-type`
  const result = await executeZshCommand(command)

  if (result.success) {
    return {
      directory,
      projectType: result.stdout,
      timestamp: new Date().toISOString()
    }
  }

  return {
    directory,
    projectType: 'unknown',
    error: result.stderr,
    timestamp: new Date().toISOString()
  }
}

/**
 * Execute a smart command (pb, pv, pt)
 * @param {string} action - Action: 'build', 'view', or 'test'
 * @param {Object} options - Additional options
 * @returns {Promise<Object>} Result
 */
async function executeSmartCommand(action, options = {}) {
  const commandMap = {
    build: 'pb',
    view: 'pv',
    test: 'pt'
  }

  const command = commandMap[action]
  if (!command) {
    throw new Error(`Unknown action: ${action}. Must be build, view, or test`)
  }

  const result = await executeZshCommand(command)

  return {
    ...result,
    action,
    command,
    timestamp: new Date().toISOString()
  }
}

/**
 * Execute v/vibe dispatcher command
 * @param {string} subcommand - Subcommand (test, dash, status, etc.)
 * @param {Array<string>} args - Additional arguments
 * @returns {Promise<Object>} Result
 */
async function executeVibeCommand(subcommand, args = []) {
  const argsString = args.join(' ')
  const command = `v ${subcommand} ${argsString}`.trim()

  const result = await executeZshCommand(command)

  return {
    ...result,
    subcommand,
    command,
    timestamp: new Date().toISOString()
  }
}

/**
 * Get list of available aliases
 * @param {string} category - Optional category filter (r, claude, git, etc.)
 * @returns {Promise<Object>} Aliases
 */
async function getAliases(category = '') {
  const command = category ? `ah ${category}` : 'ah'
  const result = await executeZshCommand(command)

  return {
    ...result,
    category: category || 'all',
    timestamp: new Date().toISOString()
  }
}

/**
 * Get workflow dashboard output
 * @returns {Promise<Object>} Dashboard info
 */
async function getDashboard() {
  const command = 'dash'
  const result = await executeZshCommand(command)

  return {
    ...result,
    timestamp: new Date().toISOString()
  }
}

module.exports = {
  executeZshCommand,
  startWork,
  finishWork,
  getWorkflowContext,
  executeSmartCommand,
  executeVibeCommand,
  getAliases,
  getDashboard
}

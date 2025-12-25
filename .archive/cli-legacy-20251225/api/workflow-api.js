/**
 * Workflow API
 *
 * Higher-level API for workflow control.
 * Builds on workflow adapter to provide app-friendly workflow management.
 */

const workflowAdapter = require('../adapters/workflow')
const statusAdapter = require('../adapters/status')

/**
 * Start a new work session with validation
 * @param {string} project - Project name
 * @param {Object} options - Session options
 * @returns {Promise<Object>} Session start result
 */
async function startSession(project, options = {}) {
  // Check if already in a session
  const existingSession = await statusAdapter.getCurrentSession()
  if (existingSession && existingSession.project) {
    return {
      success: false,
      error: 'Already in an active session',
      currentSession: existingSession
    }
  }

  // Start the session
  const result = await workflowAdapter.startWork(project, options)

  if (result.success) {
    // Verify session was created
    const newSession = await statusAdapter.getCurrentSession()
    return {
      success: true,
      session: newSession,
      output: result.stdout,
      timestamp: result.timestamp
    }
  }

  return {
    success: false,
    error: result.stderr || 'Failed to start session',
    timestamp: result.timestamp
  }
}

/**
 * End the current work session with validation
 * @param {Object} options - End session options
 * @param {string} options.message - Commit message
 * @param {boolean} options.force - Force end even if there are uncommitted changes
 * @returns {Promise<Object>} Session end result
 */
async function endSession(options = {}) {
  // Check if there is an active session
  const session = await statusAdapter.getCurrentSession()
  if (!session || !session.project) {
    return {
      success: false,
      error: 'No active session to end'
    }
  }

  // End the session
  const result = await workflowAdapter.finishWork(options.message)

  if (result.success) {
    // Calculate final duration
    const duration = session.duration_minutes || 0

    return {
      success: true,
      session: {
        project: session.project,
        duration: `${duration} minutes`,
        endTime: result.timestamp
      },
      output: result.stdout,
      timestamp: result.timestamp
    }
  }

  return {
    success: false,
    error: result.stderr || 'Failed to end session',
    session,
    timestamp: result.timestamp
  }
}

/**
 * Execute a context-aware build
 * @returns {Promise<Object>} Build result
 */
async function build() {
  const result = await workflowAdapter.executeSmartCommand('build')

  return {
    ...result,
    action: 'build'
  }
}

/**
 * Execute a context-aware preview/view
 * @returns {Promise<Object>} Preview result
 */
async function preview() {
  const result = await workflowAdapter.executeSmartCommand('view')

  return {
    ...result,
    action: 'preview'
  }
}

/**
 * Execute context-aware tests
 * @returns {Promise<Object>} Test result
 */
async function test() {
  const result = await workflowAdapter.executeSmartCommand('test')

  return {
    ...result,
    action: 'test'
  }
}

/**
 * Get available commands for current project
 * @param {string} directory - Project directory
 * @returns {Promise<Object>} Available commands
 */
async function getAvailableCommands(directory = process.cwd()) {
  const context = await workflowAdapter.getWorkflowContext(directory)

  // Map project types to available commands
  const commandMap = {
    r: ['build', 'test', 'view', 'load', 'document', 'check'],
    quarto: ['preview', 'render', 'build'],
    node: ['test', 'build', 'start'],
    python: ['test', 'run'],
    unknown: ['build', 'test', 'view']
  }

  const projectType = context.projectType.toLowerCase()
  const commands = commandMap[projectType] || commandMap['unknown']

  return {
    projectType,
    commands,
    context
  }
}

/**
 * Execute v/vibe dispatcher with error handling
 * @param {string} subcommand - Subcommand to execute
 * @param {Array<string>} args - Arguments
 * @returns {Promise<Object>} Result
 */
async function executeVibe(subcommand, args = []) {
  const result = await workflowAdapter.executeVibeCommand(subcommand, args)

  return {
    success: result.success,
    subcommand,
    output: result.stdout,
    error: result.stderr,
    timestamp: result.timestamp
  }
}

/**
 * Get workflow dashboard (formatted)
 * @returns {Promise<Object>} Dashboard data
 */
async function getDashboard() {
  const result = await workflowAdapter.getDashboard()

  return {
    success: result.success,
    dashboard: result.stdout,
    error: result.stderr,
    timestamp: result.timestamp
  }
}

/**
 * Get help for a specific category
 * @param {string} category - Category (r, claude, git, etc.)
 * @returns {Promise<Object>} Help text
 */
async function getHelp(category = '') {
  const result = await workflowAdapter.getAliases(category)

  return {
    success: result.success,
    category: result.category,
    help: result.stdout,
    error: result.stderr,
    timestamp: result.timestamp
  }
}

/**
 * Validate workflow command before execution
 * @param {string} command - Command to validate
 * @returns {Promise<Object>} Validation result
 */
async function validateCommand(command) {
  // Check if command exists in ZSH
  const checkResult = await workflowAdapter.executeZshCommand(`type ${command}`)

  return {
    valid: checkResult.success,
    command,
    info: checkResult.stdout,
    timestamp: new Date().toISOString()
  }
}

/**
 * Get workflow suggestions based on current state
 * @returns {Promise<Object>} Workflow suggestions
 */
async function getSuggestions() {
  const [session, context] = await Promise.all([
    statusAdapter.getCurrentSession(),
    workflowAdapter.getWorkflowContext()
  ])

  const suggestions = []

  // No active session - suggest starting one
  if (!session) {
    suggestions.push({
      action: 'start',
      command: 'work <project>',
      reason: 'No active work session',
      priority: 'high'
    })
  }

  // Active session - suggest build/test/preview
  if (session && context.projectType !== 'unknown') {
    if (context.projectType === 'r') {
      suggestions.push(
        { action: 'test', command: 'pt', reason: 'Run R package tests', priority: 'medium' },
        { action: 'build', command: 'pb', reason: 'Build R package', priority: 'medium' }
      )
    } else if (context.projectType === 'quarto') {
      suggestions.push({
        action: 'preview',
        command: 'pv',
        reason: 'Preview Quarto document',
        priority: 'high'
      })
    }
  }

  return {
    suggestions,
    session: session
      ? {
          active: true,
          project: session.project,
          duration: session.duration_minutes
        }
      : {
          active: false
        },
    context: {
      projectType: context.projectType,
      directory: context.directory
    }
  }
}

module.exports = {
  startSession,
  endSession,
  build,
  preview,
  test,
  getAvailableCommands,
  executeVibe,
  getDashboard,
  getHelp,
  validateCommand,
  getSuggestions
}

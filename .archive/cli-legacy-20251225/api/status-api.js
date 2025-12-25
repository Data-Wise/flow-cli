/**
 * Status API
 *
 * Higher-level API for status queries.
 * Builds on status adapter to provide formatted, app-ready data.
 */

const statusAdapter = require('../adapters/status')

/**
 * Get dashboard data for UI
 * @param {string} projectPath - Path to project
 * @returns {Promise<Object>} Dashboard-ready data
 */
async function getDashboardData(projectPath = process.cwd()) {
  const status = await statusAdapter.getCompleteStatus(projectPath)

  // Format for dashboard display
  return {
    session: formatSessionData(status.session),
    project: formatProjectData(status.project),
    timestamp: status.timestamp
  }
}

/**
 * Format session data for display
 * @param {Object|null} session - Raw session data
 * @returns {Object} Formatted session
 */
function formatSessionData(session) {
  if (!session) {
    return {
      active: false,
      message: 'No active work session'
    }
  }

  return {
    active: true,
    project: session.project || 'Unknown',
    startTime: session.start_time,
    duration: formatDuration(session.duration_minutes),
    durationMinutes: session.duration_minutes,
    context: session.context || '',
    editor: session.editor || 'unknown'
  }
}

/**
 * Format project data for display
 * @param {Object} project - Raw project data
 * @returns {Object} Formatted project
 */
function formatProjectData(project) {
  if (project.error) {
    return {
      hasStatus: false,
      error: project.error,
      path: project.path
    }
  }

  return {
    hasStatus: true,
    location: project.location,
    lastUpdated: project.lastUpdated,
    currentStatus: project.currentStatus,
    progress: project.progress || [],
    nextActions: parseNextActions(project.nextActions),
    recentWins: extractRecentWins(project.wins)
  }
}

/**
 * Parse next actions section into structured data
 * @param {string} nextActions - Raw next actions text
 * @returns {Array<Object>} Parsed actions
 */
function parseNextActions(nextActions) {
  if (!nextActions) return []

  const actions = []
  const lines = nextActions.split('\n')

  for (const line of lines) {
    // Match patterns like: A) **Task name** 🟢 [est. X hours]
    const match = line.match(/([A-C])\)\s+\*\*(.+?)\*\*\s+([🟢🟡🔴⚡])\s+\[est\.\s+(.+?)\]/)
    if (match) {
      actions.push({
        option: match[1],
        task: match[2],
        status: match[3],
        estimate: match[4],
        raw: line
      })
    }
  }

  return actions
}

/**
 * Extract recent wins (last 3)
 * @param {string} wins - Raw wins text
 * @returns {Array<string>} Recent wins
 */
function extractRecentWins(wins) {
  if (!wins) return []

  const lines = wins.split('\n').filter(line => line.trim().startsWith('✅'))
  return lines.slice(0, 3).map(line => line.replace('✅', '').trim())
}

/**
 * Format duration in human-readable form
 * @param {number} minutes - Duration in minutes
 * @returns {string} Formatted duration
 */
function formatDuration(minutes) {
  if (!minutes) return '0 min'

  const hours = Math.floor(minutes / 60)
  const mins = minutes % 60

  if (hours === 0) return `${mins} min`
  if (mins === 0) return `${hours}h`
  return `${hours}h ${mins}min`
}

/**
 * Get session status (quick check)
 * @returns {Promise<Object>} Session status
 */
async function getSessionStatus() {
  const session = await statusAdapter.getCurrentSession()
  return formatSessionData(session)
}

/**
 * Get project progress summary
 * @param {string} projectPath - Path to project
 * @returns {Promise<Object>} Progress summary
 */
async function getProgressSummary(projectPath = process.cwd()) {
  const project = await statusAdapter.getProjectStatus(projectPath)

  if (project.error) {
    return {
      error: project.error,
      hasProgress: false
    }
  }

  const progress = project.progress || []
  const completed = progress.filter(p => p.progress === 100).length
  const total = progress.length
  const inProgress = progress.filter(p => p.progress > 0 && p.progress < 100).length

  return {
    hasProgress: true,
    phases: progress,
    summary: {
      total,
      completed,
      inProgress,
      pending: total - completed - inProgress,
      percentComplete: total > 0 ? Math.round((completed / total) * 100) : 0
    }
  }
}

/**
 * Get current task recommendations
 * @param {string} projectPath - Path to project
 * @returns {Promise<Object>} Recommended tasks
 */
async function getTaskRecommendations(projectPath = process.cwd()) {
  const project = await statusAdapter.getProjectStatus(projectPath)

  if (project.error) {
    return {
      error: project.error,
      recommendations: []
    }
  }

  const actions = parseNextActions(project.nextActions)

  // Prioritize quick wins (⚡), then ready (🟢), then others
  const sorted = actions.sort((a, b) => {
    const priority = { '⚡': 0, '🟢': 1, '🟡': 2, '🔴': 3 }
    return (priority[a.status] || 99) - (priority[b.status] || 99)
  })

  return {
    recommendations: sorted,
    suggested: sorted[0] || null,
    quickWins: sorted.filter(a => a.status === '⚡'),
    ready: sorted.filter(a => a.status === '🟢')
  }
}

/**
 * Check if user is in flow state
 * @returns {Promise<Object>} Flow state info
 */
async function checkFlowState() {
  const session = await statusAdapter.getCurrentSession()

  if (!session) {
    return {
      inFlow: false,
      reason: 'No active session'
    }
  }

  const duration = session.duration_minutes || 0

  // Consider "in flow" if session is 15+ minutes
  return {
    inFlow: duration >= 15,
    duration: formatDuration(duration),
    durationMinutes: duration,
    reason: duration >= 15 ? 'Active session running' : 'Session just started'
  }
}

module.exports = {
  getDashboardData,
  getSessionStatus,
  getProgressSummary,
  getTaskRecommendations,
  checkFlowState
}

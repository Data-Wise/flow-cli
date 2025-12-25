/**
 * Status Adapter
 *
 * Read-only adapter for querying ZSH workflow status.
 * Reads worklog and .STATUS files to provide current session and project status.
 */

const fs = require('fs').promises
const path = require('path')
const os = require('os')

/**
 * Read the current work session from worklog
 * @returns {Promise<Object|null>} Current session data or null if no active session
 */
async function getCurrentSession() {
  const worklogPath = path.join(os.homedir(), '.config/zsh/.worklog')

  try {
    const content = await fs.readFile(worklogPath, 'utf-8')
    const session = JSON.parse(content)

    // Calculate duration if session is active
    if (session.start_time) {
      const startTime = new Date(session.start_time)
      const now = new Date()
      session.duration_minutes = Math.floor((now - startTime) / 1000 / 60)
    }

    return session
  } catch (error) {
    if (error.code === 'ENOENT') {
      return null // No active session
    }
    throw new Error(`Failed to read worklog: ${error.message}`)
  }
}

/**
 * Read project status from .STATUS file
 * @param {string} projectPath - Path to project directory
 * @returns {Promise<Object>} Parsed status data
 */
async function getProjectStatus(projectPath) {
  const statusPath = path.join(projectPath, '.STATUS')

  try {
    const content = await fs.readFile(statusPath, 'utf-8')

    // Parse .STATUS file (simple parser for key sections)
    const status = {
      raw: content,
      location: extractSection(content, '📍 LOCATION'),
      lastUpdated: extractSection(content, '⏰ LAST UPDATED'),
      currentStatus: extractSection(content, '🎯 CURRENT STATUS'),
      progress: extractProgressBars(content),
      nextActions: extractSection(content, '📋 NEXT ACTIONS'),
      keyFiles: extractSection(content, '📁 KEY FILES'),
      wins: extractSection(content, '🎉 WINS')
    }

    return status
  } catch (error) {
    if (error.code === 'ENOENT') {
      return {
        error: 'No .STATUS file found',
        path: statusPath
      }
    }
    throw new Error(`Failed to read .STATUS file: ${error.message}`)
  }
}

/**
 * Extract a section from .STATUS file
 * @param {string} content - Full .STATUS content
 * @param {string} header - Section header to find
 * @returns {string} Section content
 */
function extractSection(content, header) {
  const lines = content.split('\n')
  const headerIndex = lines.findIndex(line => line.includes(header))

  if (headerIndex === -1) return ''

  // Find next section (line with dashes or next emoji header)
  let endIndex = lines.length
  for (let i = headerIndex + 1; i < lines.length; i++) {
    if (lines[i].includes('────') || /^[📍⏰🎯📊📋📁🎉]/.test(lines[i])) {
      endIndex = i
      break
    }
  }

  return lines
    .slice(headerIndex + 1, endIndex)
    .join('\n')
    .trim()
}

/**
 * Extract progress bars from progress section
 * @param {string} content - Full .STATUS content
 * @returns {Array<Object>} Array of {phase, progress, status}
 */
function extractProgressBars(content) {
  const progressSection = extractSection(content, '📊 PROGRESS')
  const progressBars = []

  const lines = progressSection.split('\n')
  for (const line of lines) {
    // Match pattern: Phase P0: Setup ████████████████████ 100% ✅
    const match = line.match(/Phase (P\d+[A-Z]?): (.+?)\s+[█░]+\s+(\d+)%\s+([✅🚧📋⬜])/)
    if (match) {
      progressBars.push({
        phase: match[1],
        name: match[2].trim(),
        progress: parseInt(match[3]),
        status: match[4]
      })
    }
  }

  return progressBars
}

/**
 * Get complete status (session + project)
 * @param {string} projectPath - Path to project directory (defaults to cwd)
 * @returns {Promise<Object>} Combined status data
 */
async function getCompleteStatus(projectPath = process.cwd()) {
  const [session, project] = await Promise.all([getCurrentSession(), getProjectStatus(projectPath)])

  return {
    session,
    project,
    timestamp: new Date().toISOString()
  }
}

/**
 * Check if a work session is currently active
 * @returns {Promise<boolean>}
 */
async function isSessionActive() {
  const session = await getCurrentSession()
  return session !== null && session.project
}

module.exports = {
  getCurrentSession,
  getProjectStatus,
  getCompleteStatus,
  isSessionActive
}

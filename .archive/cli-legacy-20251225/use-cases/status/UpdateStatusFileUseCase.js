/**
 * UpdateStatusFileUseCase
 *
 * Use Case: Update .STATUS file with auto-generated metrics
 *
 * Responsibilities:
 * - Read existing .STATUS file
 * - Retrieve session metrics from repository
 * - Update metrics section with latest data
 * - Preserve user-editable fields (status, progress, next actions, body)
 * - Write updated .STATUS file back to disk
 *
 * This use case ensures .STATUS files stay in sync with actual session data.
 */

export class UpdateStatusFileUseCase {
  /**
   * @param {ISessionRepository} sessionRepository
   * @param {StatusFileGateway} statusFileGateway
   */
  constructor(sessionRepository, statusFileGateway) {
    this.sessionRepository = sessionRepository
    this.statusFileGateway = statusFileGateway
  }

  /**
   * Execute the use case
   *
   * @param {Object} input
   * @param {string} input.projectPath - Path to project directory
   * @param {number} [input.daysPeriod=7] - Days to include in metrics calculation
   * @returns {Promise<Object>} Updated status data
   */
  async execute({ projectPath, daysPeriod = 7 }) {
    // Read existing .STATUS file
    const existingStatus = await this.statusFileGateway.read(projectPath)

    if (!existingStatus) {
      throw new Error(`No .STATUS file found at ${projectPath}`)
    }

    // Get sessions for this project
    const since = new Date(Date.now() - daysPeriod * 24 * 60 * 60 * 1000)
    const allSessions = await this.sessionRepository.list({
      since,
      orderBy: 'startTime',
      order: 'desc'
    })

    // Filter sessions for this project path
    const projectSessions = allSessions.filter(session => session.context?.cwd === projectPath)

    // Calculate metrics
    const metrics = this._calculateMetrics(projectSessions, daysPeriod)

    // Update status data (preserve user-editable fields)
    const updatedStatus = {
      ...existingStatus,
      metrics: {
        ...metrics,
        last_updated: new Date().toISOString()
      }
    }

    // Write back to file
    await this.statusFileGateway.write(projectPath, updatedStatus)

    return updatedStatus
  }

  /**
   * Calculate session metrics
   * @private
   */
  _calculateMetrics(sessions, daysPeriod) {
    const now = new Date()

    // Total sessions
    const sessions_total = sessions.length

    // This week's sessions
    const oneWeekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)
    const sessions_this_week = sessions.filter(s => s.startTime >= oneWeekAgo).length

    // Total duration in minutes
    const total_duration_minutes = sessions.reduce((sum, s) => sum + s.getDuration(), 0)

    // Last session time
    const last_session = sessions.length > 0 ? sessions[0].startTime.toISOString() : null

    // Average session duration
    const average_session_duration =
      sessions.length > 0 ? Math.round(total_duration_minutes / sessions.length) : 0

    // Flow sessions (>= 15 minutes)
    const flow_sessions = sessions.filter(s => s.getDuration() >= 15).length

    // Completed sessions
    const completed_sessions = sessions.filter(s => s.outcome === 'completed').length

    // Completion rate
    const completion_rate =
      sessions.length > 0 ? Math.round((completed_sessions / sessions.length) * 100) : 0

    return {
      sessions_total,
      sessions_this_week,
      total_duration_minutes,
      last_session,
      average_session_duration,
      flow_sessions,
      completed_sessions,
      completion_rate
    }
  }

  /**
   * Check if a project needs metrics update
   * @param {string} projectPath - Path to project directory
   * @param {number} [maxAgeMinutes=60] - Maximum age in minutes before update needed
   * @returns {Promise<boolean>}
   */
  async needsUpdate(projectPath, maxAgeMinutes = 60) {
    const status = await this.statusFileGateway.read(projectPath)

    if (!status || !status.metrics || !status.metrics.last_updated) {
      return true
    }

    const lastUpdated = new Date(status.metrics.last_updated)
    const ageMinutes = (Date.now() - lastUpdated.getTime()) / (60 * 1000)

    return ageMinutes >= maxAgeMinutes
  }
}

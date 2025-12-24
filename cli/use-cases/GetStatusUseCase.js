/**
 * GetStatusUseCase
 *
 * Use Case: Get comprehensive workflow status
 *
 * Responsibilities:
 * - Get active session information
 * - Get recent sessions summary
 * - Get project statistics
 * - Calculate productivity metrics
 * - Return formatted status data
 *
 * This is pure business logic - the presentation layer decides how to display it.
 */

export class GetStatusUseCase {
  /**
   * @param {ISessionRepository} sessionRepository
   * @param {IProjectRepository} projectRepository
   * @param {GitGateway} [gitGateway] - Optional git gateway for git status
   * @param {StatusFileGateway} [statusFileGateway] - Optional gateway for .STATUS files
   */
  constructor(sessionRepository, projectRepository, gitGateway = null, statusFileGateway = null) {
    this.sessionRepository = sessionRepository
    this.projectRepository = projectRepository
    this.gitGateway = gitGateway
    this.statusFileGateway = statusFileGateway
  }

  /**
   * Execute the use case
   *
   * @param {Object} input
   * @param {boolean} [input.includeRecentSessions=true] - Include recent sessions
   * @param {boolean} [input.includeProjectStats=true] - Include project statistics
   * @param {number} [input.recentDays=7] - Days to consider for recent sessions
   * @returns {Promise<Object>} Status information
   */
  async execute(input = {}) {
    const includeRecentSessions = input.includeRecentSessions !== false
    const includeProjectStats = input.includeProjectStats !== false
    const recentDays = input.recentDays || 7

    // Get active session
    const activeSession = await this.sessionRepository.findActive()

    // Get git status for active session project if git gateway is available
    let gitStatus = null
    if (activeSession && this.gitGateway && activeSession.context?.cwd) {
      gitStatus = await this.gitGateway.getStatus(activeSession.context.cwd)
    }

    // Get .STATUS file for active session project if status file gateway is available
    let statusFile = null
    if (activeSession && this.statusFileGateway && activeSession.context?.cwd) {
      statusFile = await this.statusFileGateway.read(activeSession.context.cwd)
    }

    // Get recent sessions if requested
    let recentSessions = []
    let todaySessions = []
    if (includeRecentSessions) {
      const since = new Date(Date.now() - recentDays * 24 * 60 * 60 * 1000)
      recentSessions = await this.sessionRepository.list({
        since,
        orderBy: 'startTime',
        order: 'desc'
      })

      // Filter today's sessions
      const todayStart = new Date()
      todayStart.setHours(0, 0, 0, 0)
      todaySessions = recentSessions.filter(s => s.startTime >= todayStart)
    }

    // Get project statistics if requested
    let projectStats = null
    if (includeProjectStats) {
      const allProjects = await this.projectRepository.findAll()
      const recentProjects = await this.projectRepository.findRecent(24, 5)
      const topByDuration = await this.projectRepository.findTopByDuration(5)

      projectStats = {
        total: allProjects.length,
        recentProjects: recentProjects.map(p => p.getSummary()),
        topByDuration: topByDuration.map(p => p.getSummary())
      }
    }

    // Calculate productivity metrics
    const metrics = this._calculateMetrics(todaySessions, recentSessions)

    // Build status response
    return {
      activeSession: activeSession
        ? {
            id: activeSession.id,
            project: activeSession.project,
            task: activeSession.task,
            branch: activeSession.branch,
            duration: activeSession.getDuration(),
            isFlowState: activeSession.isInFlowState(),
            state: activeSession.state.value,
            startTime: activeSession.startTime,
            context: activeSession.context,
            gitStatus,
            statusFile
          }
        : null,

      today: {
        sessions: todaySessions.length,
        totalDuration: todaySessions.reduce((sum, s) => sum + s.getDuration(), 0),
        completedSessions: todaySessions.filter(s => s.outcome === 'completed').length,
        flowSessions: todaySessions.filter(s => s.getDuration() >= 15).length
      },

      recent: includeRecentSessions
        ? {
            days: recentDays,
            sessions: recentSessions.length,
            totalDuration: recentSessions.reduce((sum, s) => sum + s.getDuration(), 0),
            averageDuration:
              recentSessions.length > 0
                ? Math.round(
                    recentSessions.reduce((sum, s) => sum + s.getDuration(), 0) /
                      recentSessions.length
                  )
                : 0,
            recentSessions: recentSessions.slice(0, 5).map(s => ({
              id: s.id,
              project: s.project,
              task: s.task,
              duration: s.getDuration(),
              outcome: s.outcome,
              startTime: s.startTime
            }))
          }
        : null,

      projects: projectStats,

      metrics
    }
  }

  /**
   * Calculate productivity metrics
   * @private
   */
  _calculateMetrics(todaySessions, recentSessions) {
    // Today's metrics
    const todayMinutes = todaySessions.reduce((sum, s) => sum + s.getDuration(), 0)

    // Recent average
    const recentDays =
      recentSessions.length > 0
        ? Math.ceil(
            (Date.now() - recentSessions[recentSessions.length - 1].startTime) /
              (24 * 60 * 60 * 1000)
          )
        : 1

    const recentMinutes = recentSessions.reduce((sum, s) => sum + s.getDuration(), 0)
    const dailyAverage = Math.round(recentMinutes / Math.max(recentDays, 1))

    // Flow state percentage
    const flowSessions = recentSessions.filter(s => s.getDuration() >= 15).length
    const flowPercentage =
      recentSessions.length > 0 ? Math.round((flowSessions / recentSessions.length) * 100) : 0

    // Completion rate
    const completedSessions = recentSessions.filter(s => s.outcome === 'completed').length
    const completionRate =
      recentSessions.length > 0 ? Math.round((completedSessions / recentSessions.length) * 100) : 0

    // Streak (consecutive days with sessions)
    const streak = this._calculateStreak(recentSessions)

    return {
      todayMinutes,
      dailyAverage,
      flowPercentage,
      completionRate,
      streak,
      trend: todayMinutes >= dailyAverage ? 'up' : 'down'
    }
  }

  /**
   * Calculate consecutive days streak
   * @private
   */
  _calculateStreak(sessions) {
    if (sessions.length === 0) return 0

    // Group sessions by day
    const daysSeen = new Set()
    for (const session of sessions) {
      const day = new Date(session.startTime)
      day.setHours(0, 0, 0, 0)
      daysSeen.add(day.getTime())
    }

    // Check consecutive days from today backwards
    let streak = 0
    const today = new Date()
    today.setHours(0, 0, 0, 0)

    let currentDay = today.getTime()
    while (daysSeen.has(currentDay)) {
      streak++
      currentDay -= 24 * 60 * 60 * 1000
    }

    return streak
  }
}

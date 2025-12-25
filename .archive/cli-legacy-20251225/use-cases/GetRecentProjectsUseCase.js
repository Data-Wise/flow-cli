/**
 * GetRecentProjectsUseCase
 *
 * Use Case: Get recent and top projects for quick selection
 *
 * Responsibilities:
 * - Get recently accessed projects
 * - Get top projects by session count
 * - Get top projects by duration
 * - Combine and rank for picker display
 * - Return formatted project list
 */

export class GetRecentProjectsUseCase {
  /**
   * @param {IProjectRepository} projectRepository
   */
  constructor(projectRepository) {
    this.projectRepository = projectRepository
  }

  /**
   * Execute the use case
   *
   * @param {Object} input
   * @param {number} [input.limit=10] - Maximum number of projects to return
   * @param {number} [input.recentHours=168] - Hours to consider "recent" (default: 7 days)
   * @param {boolean} [input.includeStats=true] - Include project statistics
   * @returns {Promise<Object>} Project list with rankings
   */
  async execute(input = {}) {
    const limit = input.limit || 10
    const recentHours = input.recentHours || 168 // 7 days
    const includeStats = input.includeStats !== false

    // Get different project rankings
    const [recent, topByDuration, topBySessions] = await Promise.all([
      this.projectRepository.findRecent(recentHours, limit),
      this.projectRepository.findTopByDuration(limit),
      this.projectRepository.findTopBySessionCount(limit)
    ])

    // Combine and score projects
    const scoredProjects = this._scoreProjects(recent, topByDuration, topBySessions)

    // Sort by score and limit
    const rankedProjects = scoredProjects.sort((a, b) => b.score - a.score).slice(0, limit)

    // Format response
    const projects = rankedProjects.map(item => {
      const summary = item.project.getSummary()

      return {
        ...summary,
        score: item.score,
        ranking: {
          isRecent: item.reasons.includes('recent'),
          isTopDuration: item.reasons.includes('duration'),
          isTopSessions: item.reasons.includes('sessions')
        }
      }
    })

    return {
      projects,
      stats: includeStats
        ? {
            totalProjects: await this.projectRepository.count(),
            recentCount: recent.length,
            evaluated: scoredProjects.length
          }
        : null
    }
  }

  /**
   * Score and rank projects
   * @private
   */
  _scoreProjects(recent, topByDuration, topBySessions) {
    const projectMap = new Map()

    // Score recent projects (highest weight)
    recent.forEach((project, index) => {
      const score = 100 - index * 5 // 100, 95, 90, ...
      this._addProjectScore(projectMap, project, score, 'recent')
    })

    // Score top by duration
    topByDuration.forEach((project, index) => {
      const score = 50 - index * 3 // 50, 47, 44, ...
      this._addProjectScore(projectMap, project, score, 'duration')
    })

    // Score top by sessions
    topBySessions.forEach((project, index) => {
      const score = 30 - index * 2 // 30, 28, 26, ...
      this._addProjectScore(projectMap, project, score, 'sessions')
    })

    return Array.from(projectMap.values())
  }

  /**
   * Add score to project in map
   * @private
   */
  _addProjectScore(projectMap, project, score, reason) {
    if (projectMap.has(project.id)) {
      const existing = projectMap.get(project.id)
      existing.score += score
      existing.reasons.push(reason)
    } else {
      projectMap.set(project.id, {
        project,
        score,
        reasons: [reason]
      })
    }
  }
}

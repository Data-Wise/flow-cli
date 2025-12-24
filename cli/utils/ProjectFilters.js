/**
 * ProjectFilters
 *
 * Smart filtering utilities for project collections.
 *
 * Features:
 * - Type-based filtering (Node, R, Quarto, etc.)
 * - Status-based filtering (active, archived, etc.)
 * - Recency filtering (last accessed within N hours/days)
 * - Composite filters (combine multiple criteria)
 * - Performance optimized (early exit, minimal allocations)
 *
 * Usage:
 * ```js
 * const filters = new ProjectFilters()
 *
 * // Single filter
 * const nodeProjects = filters.byType(projects, 'node')
 *
 * // Composite filter
 * const recentActive = filters.composite(projects, {
 *   types: ['node', 'r-package'],
 *   recentHours: 24,
 *   minSessions: 1
 * })
 * ```
 */

export class ProjectFilters {
  /**
   * Filter projects by type
   * @param {Array} projects - Projects to filter
   * @param {string|string[]} types - Type or array of types to match
   * @returns {Array} Filtered projects
   */
  byType(projects, types) {
    if (!projects || projects.length === 0) {
      return []
    }

    const typeArray = Array.isArray(types) ? types : [types]
    const typeSet = new Set(typeArray.map(t => t.toLowerCase()))

    return projects.filter(project => {
      const projectType = project.type?.value?.toLowerCase() || 'other'
      return typeSet.has(projectType)
    })
  }

  /**
   * Filter projects by tags
   * @param {Array} projects - Projects to filter
   * @param {string|string[]} tags - Tag or array of tags (any match)
   * @param {boolean} [matchAll=false] - If true, require all tags
   * @returns {Array} Filtered projects
   */
  byTags(projects, tags, matchAll = false) {
    if (!projects || projects.length === 0) {
      return []
    }

    const tagArray = Array.isArray(tags) ? tags : [tags]

    return projects.filter(project => {
      if (!project.tags || project.tags.length === 0) {
        return false
      }

      if (matchAll) {
        // All tags must be present
        return tagArray.every(tag => project.hasTag(tag))
      } else {
        // At least one tag must be present
        return tagArray.some(tag => project.hasTag(tag))
      }
    })
  }

  /**
   * Filter projects by recent access
   * @param {Array} projects - Projects to filter
   * @param {number} hours - Hours since last access
   * @returns {Array} Recently accessed projects
   */
  byRecentAccess(projects, hours = 24) {
    if (!projects || projects.length === 0) {
      return []
    }

    return projects.filter(project => {
      return project.isRecentlyAccessed(hours)
    })
  }

  /**
   * Filter projects by minimum session count
   * @param {Array} projects - Projects to filter
   * @param {number} minSessions - Minimum number of sessions
   * @returns {Array} Filtered projects
   */
  byMinSessions(projects, minSessions) {
    if (!projects || projects.length === 0) {
      return []
    }

    return projects.filter(project => {
      return project.totalSessions >= minSessions
    })
  }

  /**
   * Filter projects by minimum duration
   * @param {Array} projects - Projects to filter
   * @param {number} minDuration - Minimum total duration in minutes
   * @returns {Array} Filtered projects
   */
  byMinDuration(projects, minDuration) {
    if (!projects || projects.length === 0) {
      return []
    }

    return projects.filter(project => {
      return project.totalDuration >= minDuration
    })
  }

  /**
   * Filter projects by name pattern
   * @param {Array} projects - Projects to filter
   * @param {string|RegExp} pattern - Name pattern to match
   * @returns {Array} Filtered projects
   */
  byNamePattern(projects, pattern) {
    if (!projects || projects.length === 0) {
      return []
    }

    const regex = pattern instanceof RegExp ? pattern : new RegExp(pattern, 'i')

    return projects.filter(project => {
      return regex.test(project.name)
    })
  }

  /**
   * Filter projects by path pattern
   * @param {Array} projects - Projects to filter
   * @param {string|RegExp} pattern - Path pattern to match
   * @returns {Array} Filtered projects
   */
  byPathPattern(projects, pattern) {
    if (!projects || projects.length === 0) {
      return []
    }

    const regex = pattern instanceof RegExp ? pattern : new RegExp(pattern, 'i')

    return projects.filter(project => {
      return regex.test(project.path)
    })
  }

  /**
   * Get active projects (recently accessed with sessions)
   * @param {Array} projects - Projects to filter
   * @param {Object} options - Filter options
   * @param {number} [options.hours=168] - Hours threshold (default: 1 week)
   * @param {number} [options.minSessions=1] - Minimum sessions (default: 1)
   * @returns {Array} Active projects
   */
  active(projects, options = {}) {
    const hours = options.hours || 168 // 1 week default
    const minSessions = options.minSessions || 1

    if (!projects || projects.length === 0) {
      return []
    }

    return projects.filter(project => {
      return project.isRecentlyAccessed(hours) && project.totalSessions >= minSessions
    })
  }

  /**
   * Get stale projects (not accessed recently, or no sessions)
   * @param {Array} projects - Projects to filter
   * @param {Object} options - Filter options
   * @param {number} [options.hours=720] - Hours threshold (default: 30 days)
   * @returns {Array} Stale projects
   */
  stale(projects, options = {}) {
    const hours = options.hours || 720 // 30 days default

    if (!projects || projects.length === 0) {
      return []
    }

    return projects.filter(project => {
      return !project.isRecentlyAccessed(hours)
    })
  }

  /**
   * Composite filter - combine multiple criteria
   * @param {Array} projects - Projects to filter
   * @param {Object} criteria - Filter criteria
   * @param {string|string[]} [criteria.types] - Project types
   * @param {string|string[]} [criteria.tags] - Required tags
   * @param {boolean} [criteria.matchAllTags=false] - Match all tags
   * @param {number} [criteria.recentHours] - Recent access hours
   * @param {number} [criteria.minSessions] - Minimum sessions
   * @param {number} [criteria.minDuration] - Minimum duration (minutes)
   * @param {string|RegExp} [criteria.namePattern] - Name pattern
   * @param {string|RegExp} [criteria.pathPattern] - Path pattern
   * @returns {Array} Filtered projects
   */
  composite(projects, criteria) {
    if (!projects || projects.length === 0) {
      return []
    }

    let filtered = projects

    // Apply each filter in sequence
    if (criteria.types) {
      filtered = this.byType(filtered, criteria.types)
    }

    if (criteria.tags) {
      filtered = this.byTags(filtered, criteria.tags, criteria.matchAllTags)
    }

    if (criteria.recentHours !== undefined) {
      filtered = this.byRecentAccess(filtered, criteria.recentHours)
    }

    if (criteria.minSessions !== undefined) {
      filtered = this.byMinSessions(filtered, criteria.minSessions)
    }

    if (criteria.minDuration !== undefined) {
      filtered = this.byMinDuration(filtered, criteria.minDuration)
    }

    if (criteria.namePattern) {
      filtered = this.byNamePattern(filtered, criteria.namePattern)
    }

    if (criteria.pathPattern) {
      filtered = this.byPathPattern(filtered, criteria.pathPattern)
    }

    return filtered
  }

  /**
   * Get top N projects by session count
   * @param {Array} projects - Projects to rank
   * @param {number} limit - Number of projects to return
   * @returns {Array} Top N projects
   */
  topBySessions(projects, limit = 10) {
    if (!projects || projects.length === 0) {
      return []
    }

    return [...projects]
      .sort((a, b) => b.totalSessions - a.totalSessions)
      .slice(0, limit)
  }

  /**
   * Get top N projects by total duration
   * @param {Array} projects - Projects to rank
   * @param {number} limit - Number of projects to return
   * @returns {Array} Top N projects
   */
  topByDuration(projects, limit = 10) {
    if (!projects || projects.length === 0) {
      return []
    }

    return [...projects]
      .sort((a, b) => b.totalDuration - a.totalDuration)
      .slice(0, limit)
  }

  /**
   * Get top N projects by average session duration
   * @param {Array} projects - Projects to rank
   * @param {number} limit - Number of projects to return
   * @returns {Array} Top N projects
   */
  topByAverageDuration(projects, limit = 10) {
    if (!projects || projects.length === 0) {
      return []
    }

    return [...projects]
      .sort((a, b) => b.getAverageDuration() - a.getAverageDuration())
      .slice(0, limit)
  }

  /**
   * Get top N projects by recency
   * @param {Array} projects - Projects to rank
   * @param {number} limit - Number of projects to return
   * @returns {Array} Most recently accessed projects
   */
  topByRecency(projects, limit = 10) {
    if (!projects || projects.length === 0) {
      return []
    }

    return [...projects]
      .sort((a, b) => b.lastAccessedAt.getTime() - a.lastAccessedAt.getTime())
      .slice(0, limit)
  }
}

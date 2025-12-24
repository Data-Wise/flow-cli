/**
 * Project Entity
 *
 * Represents a project that can have sessions.
 * Enforces business rules for project management.
 */

import { ProjectType } from '../value-objects/ProjectType.js'

export class Project {
  /**
   * Create a new project
   * @param {string} id - Unique project identifier (usually directory path)
   * @param {string} name - Project name
   * @param {Object} options - Optional configuration
   */
  constructor(id, name, options = {}) {
    // Required properties
    this.id = id
    this.name = name

    // Optional properties with defaults
    this.type =
      options.type instanceof ProjectType
        ? options.type
        : new ProjectType(options.type || ProjectType.GENERAL)

    this.path = options.path || id
    this.description = options.description || ''
    this.tags = options.tags || []
    this.metadata = options.metadata || {}

    // Timestamps
    this.createdAt = options.createdAt || new Date()
    this.lastAccessedAt = options.lastAccessedAt || new Date()

    // Statistics (for analytics)
    this.totalSessions = options.totalSessions || 0
    this.totalDuration = options.totalDuration || 0 // in minutes

    // Validate on creation
    this.validate()
  }

  /**
   * Business Rule: Validate project data
   */
  validate() {
    if (!this.id || this.id.trim() === '') {
      throw new Error('Project must have an ID')
    }

    if (!this.name || this.name.trim() === '') {
      throw new Error('Project must have a name')
    }

    if (this.name.length > 100) {
      throw new Error('Project name too long (max 100 characters)')
    }

    if (this.description && this.description.length > 500) {
      throw new Error('Project description too long (max 500 characters)')
    }

    if (!Array.isArray(this.tags)) {
      throw new Error('Project tags must be an array')
    }

    if (this.tags.some(tag => typeof tag !== 'string')) {
      throw new Error('Project tags must be strings')
    }
  }

  /**
   * Business Rule: Update last accessed time
   */
  touch() {
    this.lastAccessedAt = new Date()
  }

  /**
   * Business Rule: Record a session completion
   * @param {number} duration - Session duration in minutes
   */
  recordSession(duration) {
    if (typeof duration !== 'number' || duration < 0) {
      throw new Error('Duration must be a non-negative number')
    }

    this.totalSessions += 1
    this.totalDuration += duration
    this.touch()
  }

  /**
   * Get average session duration
   * @returns {number} Average duration in minutes
   */
  getAverageSessionDuration() {
    if (this.totalSessions === 0) return 0
    return Math.round(this.totalDuration / this.totalSessions)
  }

  /**
   * Check if project is recently accessed
   * @param {number} hours - Number of hours to consider "recent"
   * @returns {boolean}
   */
  isRecentlyAccessed(hours = 24) {
    const hoursAgo = new Date(Date.now() - hours * 60 * 60 * 1000)
    return this.lastAccessedAt > hoursAgo
  }

  /**
   * Check if project has a specific tag
   * @param {string} tag - Tag to check
   * @returns {boolean}
   */
  hasTag(tag) {
    return this.tags.includes(tag)
  }

  /**
   * Add a tag to the project
   * @param {string} tag - Tag to add
   */
  addTag(tag) {
    if (typeof tag !== 'string') {
      throw new Error('Tag must be a string')
    }

    if (!this.tags.includes(tag)) {
      this.tags.push(tag)
    }
  }

  /**
   * Remove a tag from the project
   * @param {string} tag - Tag to remove
   */
  removeTag(tag) {
    this.tags = this.tags.filter(t => t !== tag)
  }

  /**
   * Update project metadata
   * @param {Object} updates - Metadata updates
   */
  updateMetadata(updates) {
    this.metadata = { ...this.metadata, ...updates }
  }

  /**
   * Get project summary
   * @returns {Object} Project summary
   */
  getSummary() {
    return {
      id: this.id,
      name: this.name,
      type: this.type.value,
      typeIcon: this.type.getIcon(),
      typeDisplayName: this.type.getDisplayName(),
      path: this.path,
      description: this.description,
      tags: [...this.tags],
      totalSessions: this.totalSessions,
      totalDuration: this.totalDuration,
      averageDuration: this.getAverageSessionDuration(),
      lastAccessed: this.lastAccessedAt,
      isRecent: this.isRecentlyAccessed()
    }
  }

  /**
   * Check if this project matches a search query
   * @param {string} query - Search query
   * @returns {boolean}
   */
  matchesSearch(query) {
    if (!query) return true

    const lowerQuery = query.toLowerCase()

    return (
      this.name.toLowerCase().includes(lowerQuery) ||
      this.description.toLowerCase().includes(lowerQuery) ||
      this.path.toLowerCase().includes(lowerQuery) ||
      this.tags.some(tag => tag.toLowerCase().includes(lowerQuery)) ||
      this.type.getDisplayName().toLowerCase().includes(lowerQuery)
    )
  }
}

/**
 * Task Entity
 *
 * Represents a task within a project or session.
 * Enforces business rules for task management.
 */

import { TaskPriority } from '../value-objects/TaskPriority.js'

export class Task {
  /**
   * Create a new task
   * @param {string} id - Unique task identifier
   * @param {string} description - Task description
   * @param {Object} options - Optional configuration
   */
  constructor(id, description, options = {}) {
    // Required properties
    this.id = id
    this.description = description

    // Optional properties with defaults
    this.priority =
      options.priority instanceof TaskPriority
        ? options.priority
        : new TaskPriority(options.priority || TaskPriority.MEDIUM)

    this.projectId = options.projectId || null
    this.sessionId = options.sessionId || null
    this.completed = options.completed || false
    this.completedAt = options.completedAt || null
    this.tags = options.tags || []
    this.metadata = options.metadata || {}

    // Timestamps
    this.createdAt = options.createdAt || new Date()
    this.updatedAt = options.updatedAt || new Date()
    this.dueDate = options.dueDate || null

    // Estimate and tracking
    this.estimatedMinutes = options.estimatedMinutes || null
    this.actualMinutes = options.actualMinutes || null

    // Validate on creation
    this.validate()
  }

  /**
   * Business Rule: Validate task data
   */
  validate() {
    if (!this.id || this.id.trim() === '') {
      throw new Error('Task must have an ID')
    }

    if (!this.description || this.description.trim() === '') {
      throw new Error('Task must have a description')
    }

    if (this.description.length > 500) {
      throw new Error('Task description too long (max 500 characters)')
    }

    if (!Array.isArray(this.tags)) {
      throw new Error('Task tags must be an array')
    }

    if (this.tags.some(tag => typeof tag !== 'string')) {
      throw new Error('Task tags must be strings')
    }

    if (
      this.estimatedMinutes !== null &&
      (typeof this.estimatedMinutes !== 'number' || this.estimatedMinutes < 0)
    ) {
      throw new Error('Estimated minutes must be a non-negative number')
    }

    if (
      this.actualMinutes !== null &&
      (typeof this.actualMinutes !== 'number' || this.actualMinutes < 0)
    ) {
      throw new Error('Actual minutes must be a non-negative number')
    }
  }

  /**
   * Business Rule: Mark task as complete
   */
  complete() {
    if (this.completed) {
      throw new Error('Task is already completed')
    }

    this.completed = true
    this.completedAt = new Date()
    this.updatedAt = new Date()
  }

  /**
   * Business Rule: Mark task as incomplete
   */
  uncomplete() {
    if (!this.completed) {
      throw new Error('Task is not completed')
    }

    this.completed = false
    this.completedAt = null
    this.updatedAt = new Date()
  }

  /**
   * Business Rule: Update task description
   * @param {string} newDescription
   */
  updateDescription(newDescription) {
    if (!newDescription || newDescription.trim() === '') {
      throw new Error('Description cannot be empty')
    }

    if (newDescription.length > 500) {
      throw new Error('Task description too long (max 500 characters)')
    }

    this.description = newDescription
    this.updatedAt = new Date()
  }

  /**
   * Business Rule: Update task priority
   * @param {TaskPriority} newPriority
   */
  updatePriority(newPriority) {
    if (!(newPriority instanceof TaskPriority)) {
      throw new Error('Priority must be a TaskPriority instance')
    }

    this.priority = newPriority
    this.updatedAt = new Date()
  }

  /**
   * Set estimated duration
   * @param {number} minutes
   */
  setEstimate(minutes) {
    if (typeof minutes !== 'number' || minutes < 0) {
      throw new Error('Estimate must be a non-negative number')
    }

    this.estimatedMinutes = minutes
    this.updatedAt = new Date()
  }

  /**
   * Record actual time spent
   * @param {number} minutes
   */
  recordActualTime(minutes) {
    if (typeof minutes !== 'number' || minutes < 0) {
      throw new Error('Actual time must be a non-negative number')
    }

    this.actualMinutes = minutes
    this.updatedAt = new Date()
  }

  /**
   * Set due date
   * @param {Date} date
   */
  setDueDate(date) {
    if (!(date instanceof Date)) {
      throw new Error('Due date must be a Date instance')
    }

    this.dueDate = date
    this.updatedAt = new Date()
  }

  /**
   * Clear due date
   */
  clearDueDate() {
    this.dueDate = null
    this.updatedAt = new Date()
  }

  /**
   * Check if task is overdue
   * @returns {boolean}
   */
  isOverdue() {
    if (!this.dueDate || this.completed) {
      return false
    }

    return new Date() > this.dueDate
  }

  /**
   * Check if task is due soon
   * @param {number} hours - Number of hours to consider "soon"
   * @returns {boolean}
   */
  isDueSoon(hours = 24) {
    if (!this.dueDate || this.completed) {
      return false
    }

    const soonDate = new Date(Date.now() + hours * 60 * 60 * 1000)
    return this.dueDate <= soonDate && this.dueDate >= new Date()
  }

  /**
   * Get time variance (actual - estimated)
   * @returns {number|null} Minutes difference, or null if data unavailable
   */
  getTimeVariance() {
    if (this.estimatedMinutes === null || this.actualMinutes === null) {
      return null
    }

    return this.actualMinutes - this.estimatedMinutes
  }

  /**
   * Check if task went over estimate
   * @returns {boolean}
   */
  isOverEstimate() {
    const variance = this.getTimeVariance()
    return variance !== null && variance > 0
  }

  /**
   * Add a tag to the task
   * @param {string} tag
   */
  addTag(tag) {
    if (typeof tag !== 'string') {
      throw new Error('Tag must be a string')
    }

    if (!this.tags.includes(tag)) {
      this.tags.push(tag)
      this.updatedAt = new Date()
    }
  }

  /**
   * Remove a tag from the task
   * @param {string} tag
   */
  removeTag(tag) {
    const newTags = this.tags.filter(t => t !== tag)

    if (newTags.length !== this.tags.length) {
      this.tags = newTags
      this.updatedAt = new Date()
    }
  }

  /**
   * Update task metadata
   * @param {Object} updates
   */
  updateMetadata(updates) {
    this.metadata = { ...this.metadata, ...updates }
    this.updatedAt = new Date()
  }

  /**
   * Get task summary
   * @returns {Object}
   */
  getSummary() {
    return {
      id: this.id,
      description: this.description,
      priority: this.priority.value,
      priorityIcon: this.priority.getIcon(),
      priorityColor: this.priority.getColor(),
      completed: this.completed,
      completedAt: this.completedAt,
      projectId: this.projectId,
      sessionId: this.sessionId,
      tags: [...this.tags],
      dueDate: this.dueDate,
      isOverdue: this.isOverdue(),
      isDueSoon: this.isDueSoon(),
      estimatedMinutes: this.estimatedMinutes,
      actualMinutes: this.actualMinutes,
      timeVariance: this.getTimeVariance(),
      isOverEstimate: this.isOverEstimate(),
      createdAt: this.createdAt,
      updatedAt: this.updatedAt
    }
  }

  /**
   * Check if task matches search query
   * @param {string} query
   * @returns {boolean}
   */
  matchesSearch(query) {
    if (!query) return true

    const lowerQuery = query.toLowerCase()

    const descriptionMatch = this.description.toLowerCase().includes(lowerQuery)
    const tagMatch = this.tags.some(tag => tag.toLowerCase().includes(lowerQuery))
    const priorityMatch = this.priority.value.toLowerCase().includes(lowerQuery)
    const projectMatch = this.projectId ? this.projectId.toLowerCase().includes(lowerQuery) : false

    return descriptionMatch || tagMatch || priorityMatch || projectMatch
  }
}

/**
 * Session Entity
 *
 * Represents a work session with identity and behavior.
 * Enforces business rules for session management.
 */

import { SessionState } from '../value-objects/SessionState.js'
import {
  SessionStartedEvent,
  SessionEndedEvent,
  SessionPausedEvent,
  SessionResumedEvent,
  SessionContextUpdatedEvent
} from '../events/SessionEvent.js'

export class Session {
  /**
   * Create a new session
   * @param {string} id - Unique session identifier
   * @param {string} project - Project name
   * @param {Object} options - Optional configuration
   */
  constructor(id, project, options = {}) {
    // Required properties
    this.id = id
    this.project = project

    // Optional properties with defaults
    this.task = options.task || 'Work session'
    this.branch = options.branch || 'main'
    this.startTime = options.startTime || new Date()
    this.endTime = null
    this.pausedAt = null
    this.resumedAt = null
    this.totalPausedTime = 0
    this.state = new SessionState(SessionState.ACTIVE)
    this.outcome = null
    this.context = options.context || {}

    // Domain events (not persisted)
    this._events = []

    // Validate on creation
    this.validate()

    // Emit creation event
    if (!options._skipEvents) {
      this._events.push(new SessionStartedEvent(this.id, this.project, this.task))
    }
  }

  /**
   * Business Rule: Validate session data
   */
  validate() {
    if (!this.project || this.project.trim() === '') {
      throw new Error('Session must have a project name')
    }

    if (this.project.length > 100) {
      throw new Error('Project name too long (max 100 characters)')
    }

    if (this.task && this.task.length > 500) {
      throw new Error('Task description too long (max 500 characters)')
    }
  }

  /**
   * Business Rule: End active session
   * @param {string} outcome - Session outcome (completed, cancelled, interrupted)
   */
  end(outcome = 'completed') {
    if (this.state.isEnded()) {
      throw new Error('Session is already ended')
    }

    const validOutcomes = ['completed', 'cancelled', 'interrupted']
    if (!validOutcomes.includes(outcome)) {
      throw new Error(`Invalid outcome: ${outcome}. Must be one of: ${validOutcomes.join(', ')}`)
    }

    this.endTime = new Date()
    this.state = new SessionState(SessionState.ENDED)
    this.outcome = outcome

    this._events.push(new SessionEndedEvent(this.id, outcome, this.getDuration()))
  }

  /**
   * Business Rule: Pause active session
   */
  pause() {
    if (!this.state.isActive()) {
      throw new Error('Can only pause active sessions')
    }

    this.pausedAt = new Date()
    this.state = new SessionState(SessionState.PAUSED)

    this._events.push(new SessionPausedEvent(this.id))
  }

  /**
   * Business Rule: Resume paused session
   */
  resume() {
    if (!this.state.isPaused()) {
      throw new Error('Can only resume paused sessions')
    }

    if (this.pausedAt) {
      const pauseDuration = new Date() - this.pausedAt
      this.totalPausedTime += pauseDuration
    }

    this.resumedAt = new Date()
    this.pausedAt = null
    this.state = new SessionState(SessionState.ACTIVE)

    this._events.push(new SessionResumedEvent(this.id))
  }

  /**
   * Get session duration in minutes (excluding paused time)
   * @returns {number} Duration in minutes
   */
  getDuration() {
    const end = this.endTime || new Date()
    let duration = end - this.startTime

    // Subtract total paused time
    duration -= this.totalPausedTime

    // If currently paused, subtract current pause duration
    if (this.state.isPaused() && this.pausedAt) {
      duration -= new Date() - this.pausedAt
    }

    return Math.max(0, Math.floor(duration / 60000)) // minutes
  }

  /**
   * Get active work duration (excluding pauses)
   * @returns {number} Active duration in minutes
   */
  getActiveDuration() {
    return this.getDuration()
  }

  /**
   * Business Rule: Session is in flow state after 15 minutes of active work
   * @returns {boolean}
   */
  isInFlowState() {
    return this.state.isActive() && this.getDuration() >= 15
  }

  /**
   * Update session context (metadata)
   * @param {Object} updates - Context updates
   */
  updateContext(updates) {
    this.context = { ...this.context, ...updates }
    this._events.push(new SessionContextUpdatedEvent(this.id, updates))
  }

  /**
   * Get pending domain events
   * @returns {Array} Domain events
   */
  getEvents() {
    return [...this._events]
  }

  /**
   * Clear events after publishing
   */
  clearEvents() {
    this._events = []
  }

  /**
   * Get session summary
   * @returns {Object} Session summary
   */
  getSummary() {
    return {
      id: this.id,
      project: this.project,
      task: this.task,
      duration: this.getDuration(),
      state: this.state.value,
      outcome: this.outcome,
      isFlowState: this.isInFlowState()
    }
  }
}

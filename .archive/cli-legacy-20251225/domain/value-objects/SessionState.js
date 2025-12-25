/**
 * SessionState Value Object
 *
 * Represents the state of a work session.
 * Immutable - once created, cannot be changed.
 */

export class SessionState {
  static ACTIVE = 'active'
  static PAUSED = 'paused'
  static ENDED = 'ended'

  /**
   * Create a session state
   * @param {string} value - One of: active, paused, ended
   */
  constructor(value) {
    const validStates = [SessionState.ACTIVE, SessionState.PAUSED, SessionState.ENDED]

    if (!validStates.includes(value)) {
      throw new Error(`Invalid session state: ${value}. Must be one of: ${validStates.join(', ')}`)
    }

    this._value = value
    Object.freeze(this) // Make immutable
  }

  /**
   * Get the state value
   */
  get value() {
    return this._value
  }

  /**
   * Check if session is active
   */
  isActive() {
    return this._value === SessionState.ACTIVE
  }

  /**
   * Check if session is paused
   */
  isPaused() {
    return this._value === SessionState.PAUSED
  }

  /**
   * Check if session is ended
   */
  isEnded() {
    return this._value === SessionState.ENDED
  }

  /**
   * Check if state can transition to new state
   * @param {SessionState} newState
   */
  canTransitionTo(newState) {
    const validTransitions = {
      [SessionState.ACTIVE]: [SessionState.PAUSED, SessionState.ENDED],
      [SessionState.PAUSED]: [SessionState.ACTIVE, SessionState.ENDED],
      [SessionState.ENDED]: [] // Cannot transition from ended
    }

    return validTransitions[this._value]?.includes(newState.value) || false
  }

  /**
   * Compare with another SessionState
   */
  equals(other) {
    return other instanceof SessionState && this._value === other._value
  }

  /**
   * String representation
   */
  toString() {
    return this._value
  }
}

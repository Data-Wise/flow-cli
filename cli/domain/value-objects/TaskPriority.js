/**
 * TaskPriority Value Object
 *
 * Represents task priority levels.
 * Immutable - once created, cannot be changed.
 */

export class TaskPriority {
  static LOW = 'low'
  static MEDIUM = 'medium'
  static HIGH = 'high'
  static URGENT = 'urgent'

  /**
   * Create a task priority
   * @param {string} value - One of: low, medium, high, urgent
   */
  constructor(value) {
    const validPriorities = [
      TaskPriority.LOW,
      TaskPriority.MEDIUM,
      TaskPriority.HIGH,
      TaskPriority.URGENT
    ]

    if (!validPriorities.includes(value)) {
      throw new Error(
        `Invalid task priority: ${value}. Must be one of: ${validPriorities.join(', ')}`
      )
    }

    this._value = value
    Object.freeze(this) // Make immutable
  }

  /**
   * Get the priority value
   */
  get value() {
    return this._value
  }

  /**
   * Get numeric value for sorting (higher = more urgent)
   */
  getNumericValue() {
    const values = {
      [TaskPriority.LOW]: 1,
      [TaskPriority.MEDIUM]: 2,
      [TaskPriority.HIGH]: 3,
      [TaskPriority.URGENT]: 4
    }
    return values[this._value]
  }

  /**
   * Get display color for this priority
   */
  getColor() {
    const colors = {
      [TaskPriority.LOW]: 'gray',
      [TaskPriority.MEDIUM]: 'blue',
      [TaskPriority.HIGH]: 'yellow',
      [TaskPriority.URGENT]: 'red'
    }
    return colors[this._value]
  }

  /**
   * Get display icon for this priority
   */
  getIcon() {
    const icons = {
      [TaskPriority.LOW]: '⬇️',
      [TaskPriority.MEDIUM]: '➡️',
      [TaskPriority.HIGH]: '⬆️',
      [TaskPriority.URGENT]: '🔥'
    }
    return icons[this._value]
  }

  /**
   * Compare with another TaskPriority
   */
  equals(other) {
    return other instanceof TaskPriority && this._value === other._value
  }

  /**
   * Check if this priority is higher than another
   * @param {TaskPriority} other
   * @returns {boolean}
   */
  isHigherThan(other) {
    return this.getNumericValue() > other.getNumericValue()
  }

  /**
   * String representation
   */
  toString() {
    return this._value
  }
}

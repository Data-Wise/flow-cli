/**
 * StatusFileValidator
 *
 * Domain validator for .STATUS file format (v2 YAML frontmatter)
 *
 * Validates:
 * - Required fields (status, progress, type)
 * - Field value constraints (status enum, progress 0-100)
 * - Next actions structure
 * - Metrics structure (auto-updated fields)
 */

export class StatusFileValidator {
  /**
   * Valid status values
   */
  static VALID_STATUSES = ['active', 'paused', 'archived', 'complete']

  /**
   * Valid project types
   */
  static VALID_TYPES = [
    'r-package',
    'quarto',
    'research',
    'node',
    'python',
    'mcp',
    'spacemacs',
    'generic'
  ]

  /**
   * Valid priority levels
   */
  static VALID_PRIORITIES = ['low', 'medium', 'high', 'urgent']

  /**
   * Validate .STATUS file data
   * @param {Object} data - Parsed .STATUS data
   * @returns {Object} { valid: boolean, errors: string[] }
   */
  validate(data) {
    const errors = []

    // Check required fields
    if (!data.status) {
      errors.push('Missing required field: status')
    }

    if (data.progress === undefined || data.progress === null) {
      errors.push('Missing required field: progress')
    }

    if (!data.type) {
      errors.push('Missing required field: type')
    }

    // Validate status value
    if (data.status && !StatusFileValidator.VALID_STATUSES.includes(data.status)) {
      errors.push(
        `Invalid status: "${data.status}". Must be one of: ${StatusFileValidator.VALID_STATUSES.join(', ')}`
      )
    }

    // Validate progress range
    if (data.progress !== undefined && data.progress !== null) {
      const progress = parseInt(data.progress, 10)
      if (isNaN(progress) || progress < 0 || progress > 100) {
        errors.push('Progress must be a number between 0 and 100')
      }
    }

    // Validate type
    if (data.type && !StatusFileValidator.VALID_TYPES.includes(data.type)) {
      errors.push(
        `Invalid type: "${data.type}". Must be one of: ${StatusFileValidator.VALID_TYPES.join(', ')}`
      )
    }

    // Validate next actions if present
    if (data.next) {
      if (!Array.isArray(data.next)) {
        errors.push('Field "next" must be an array')
      } else {
        this._validateNextActions(data.next, errors)
      }
    }

    // Validate metrics if present (should be auto-updated, but check structure)
    if (data.metrics) {
      if (typeof data.metrics !== 'object' || Array.isArray(data.metrics)) {
        errors.push('Field "metrics" must be an object')
      } else {
        this._validateMetrics(data.metrics, errors)
      }
    }

    return {
      valid: errors.length === 0,
      errors
    }
  }

  /**
   * Validate next actions array
   * @private
   */
  _validateNextActions(actions, errors) {
    for (let i = 0; i < actions.length; i++) {
      const action = actions[i]

      if (typeof action !== 'object' || Array.isArray(action)) {
        errors.push(`next[${i}]: must be an object`)
        continue
      }

      // Required: action field
      if (!action.action || typeof action.action !== 'string') {
        errors.push(`next[${i}]: missing or invalid "action" field`)
      }

      // Optional: estimate
      if (action.estimate && typeof action.estimate !== 'string') {
        errors.push(`next[${i}]: "estimate" must be a string`)
      }

      // Optional: priority
      if (action.priority && !StatusFileValidator.VALID_PRIORITIES.includes(action.priority)) {
        errors.push(
          `next[${i}]: invalid priority "${action.priority}". Must be one of: ${StatusFileValidator.VALID_PRIORITIES.join(', ')}`
        )
      }

      // Optional: blockers
      if (action.blockers && !Array.isArray(action.blockers)) {
        errors.push(`next[${i}]: "blockers" must be an array`)
      }
    }
  }

  /**
   * Validate metrics structure
   * @private
   */
  _validateMetrics(metrics, errors) {
    // Metrics should contain numeric fields
    const numericFields = ['sessions_total', 'sessions_this_week', 'total_duration_minutes']

    for (const field of numericFields) {
      if (metrics[field] !== undefined) {
        const value = parseInt(metrics[field], 10)
        if (isNaN(value) || value < 0) {
          errors.push(`metrics.${field} must be a non-negative number`)
        }
      }
    }

    // Validate date fields if present
    const dateFields = ['last_session', 'last_updated']
    for (const field of dateFields) {
      if (metrics[field] !== undefined) {
        const date = new Date(metrics[field])
        if (isNaN(date.getTime())) {
          errors.push(`metrics.${field} must be a valid date`)
        }
      }
    }
  }

  /**
   * Quick validation - returns boolean only
   * @param {Object} data - Parsed .STATUS data
   * @returns {boolean}
   */
  isValid(data) {
    return this.validate(data).valid
  }

  /**
   * Get validation error messages
   * @param {Object} data - Parsed .STATUS data
   * @returns {string[]}
   */
  getErrors(data) {
    return this.validate(data).errors
  }
}

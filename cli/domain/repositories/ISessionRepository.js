/**
 * ISessionRepository - Port (Interface)
 *
 * Defines the contract for session persistence.
 * Implementations will be in the adapters layer.
 *
 * This is the Dependency Inversion Principle in action:
 * - Domain defines WHAT it needs (this interface)
 * - Adapters provide HOW (FileSystem, Database, etc.)
 */

export class ISessionRepository {
  /**
   * Find session by ID
   * @param {string} sessionId
   * @returns {Promise<Session|null>}
   */
  async findById(sessionId) {
    throw new Error('findById() not implemented')
  }

  /**
   * Find currently active session
   * @returns {Promise<Session|null>}
   */
  async findActive() {
    throw new Error('findActive() not implemented')
  }

  /**
   * Find sessions by project name
   * @param {string} projectName
   * @returns {Promise<Session[]>}
   */
  async findByProject(projectName) {
    throw new Error('findByProject() not implemented')
  }

  /**
   * Save (create or update) a session
   * @param {Session} session
   * @returns {Promise<Session>}
   */
  async save(session) {
    throw new Error('save() not implemented')
  }

  /**
   * Delete a session
   * @param {string} sessionId
   * @returns {Promise<boolean>} True if deleted, false if not found
   */
  async delete(sessionId) {
    throw new Error('delete() not implemented')
  }

  /**
   * List sessions with optional filters
   * @param {Object} filters - Optional filters
   * @param {string} filters.state - Filter by state (active, paused, ended)
   * @param {string} filters.project - Filter by project name
   * @param {Date} filters.since - Filter by start time (sessions after this date)
   * @param {Date} filters.until - Filter by start time (sessions before this date)
   * @param {number} filters.limit - Maximum number of results
   * @param {string} filters.orderBy - Field to order by (startTime, duration)
   * @param {string} filters.order - Order direction (asc, desc)
   * @returns {Promise<Session[]>}
   */
  async list(filters = {}) {
    throw new Error('list() not implemented')
  }

  /**
   * Count sessions matching filters
   * @param {Object} filters - Same as list()
   * @returns {Promise<number>}
   */
  async count(filters = {}) {
    throw new Error('count() not implemented')
  }

  /**
   * Get sessions for a date range
   * @param {Date} startDate
   * @param {Date} endDate
   * @returns {Promise<Session[]>}
   */
  async findByDateRange(startDate, endDate) {
    throw new Error('findByDateRange() not implemented')
  }
}

/**
 * ITaskRepository - Port (Interface)
 *
 * Defines the contract for task persistence.
 * Implementations will be in the adapters layer.
 */

export class ITaskRepository {
  /**
   * Find task by ID
   * @param {string} taskId
   * @returns {Promise<Task|null>}
   */
  async findById(taskId) {
    throw new Error('findById() not implemented')
  }

  /**
   * Find all tasks
   * @returns {Promise<Task[]>}
   */
  async findAll() {
    throw new Error('findAll() not implemented')
  }

  /**
   * Find tasks by project
   * @param {string} projectId
   * @returns {Promise<Task[]>}
   */
  async findByProject(projectId) {
    throw new Error('findByProject() not implemented')
  }

  /**
   * Find tasks by session
   * @param {string} sessionId
   * @returns {Promise<Task[]>}
   */
  async findBySession(sessionId) {
    throw new Error('findBySession() not implemented')
  }

  /**
   * Find incomplete tasks
   * @returns {Promise<Task[]>}
   */
  async findIncomplete() {
    throw new Error('findIncomplete() not implemented')
  }

  /**
   * Find completed tasks
   * @returns {Promise<Task[]>}
   */
  async findCompleted() {
    throw new Error('findCompleted() not implemented')
  }

  /**
   * Find tasks by priority
   * @param {string} priority - Priority level
   * @returns {Promise<Task[]>}
   */
  async findByPriority(priority) {
    throw new Error('findByPriority() not implemented')
  }

  /**
   * Find overdue tasks
   * @returns {Promise<Task[]>}
   */
  async findOverdue() {
    throw new Error('findOverdue() not implemented')
  }

  /**
   * Find tasks due soon
   * @param {number} hours - Number of hours to consider "soon"
   * @returns {Promise<Task[]>}
   */
  async findDueSoon(hours = 24) {
    throw new Error('findDueSoon() not implemented')
  }

  /**
   * Find tasks with a specific tag
   * @param {string} tag
   * @returns {Promise<Task[]>}
   */
  async findByTag(tag) {
    throw new Error('findByTag() not implemented')
  }

  /**
   * Search tasks by query
   * @param {string} query
   * @returns {Promise<Task[]>}
   */
  async search(query) {
    throw new Error('search() not implemented')
  }

  /**
   * Save (create or update) a task
   * @param {Task} task
   * @returns {Promise<Task>}
   */
  async save(task) {
    throw new Error('save() not implemented')
  }

  /**
   * Delete a task
   * @param {string} taskId
   * @returns {Promise<boolean>} True if deleted, false if not found
   */
  async delete(taskId) {
    throw new Error('delete() not implemented')
  }

  /**
   * Count tasks matching filters
   * @param {Object} filters
   * @returns {Promise<number>}
   */
  async count(filters = {}) {
    throw new Error('count() not implemented')
  }
}

/**
 * IProjectRepository - Port (Interface)
 *
 * Defines the contract for project persistence.
 * Implementations will be in the adapters layer.
 *
 * This is the Dependency Inversion Principle in action:
 * - Domain defines WHAT it needs (this interface)
 * - Adapters provide HOW (FileSystem, Database, etc.)
 */

export class IProjectRepository {
  /**
   * Find project by ID
   * @param {string} projectId
   * @returns {Promise<Project|null>}
   */
  async findById(projectId) {
    throw new Error('findById() not implemented')
  }

  /**
   * Find project by path
   * @param {string} path
   * @returns {Promise<Project|null>}
   */
  async findByPath(path) {
    throw new Error('findByPath() not implemented')
  }

  /**
   * Find all projects
   * @returns {Promise<Project[]>}
   */
  async findAll() {
    throw new Error('findAll() not implemented')
  }

  /**
   * Find projects by type
   * @param {string} type - Project type
   * @returns {Promise<Project[]>}
   */
  async findByType(type) {
    throw new Error('findByType() not implemented')
  }

  /**
   * Find projects with a specific tag
   * @param {string} tag
   * @returns {Promise<Project[]>}
   */
  async findByTag(tag) {
    throw new Error('findByTag() not implemented')
  }

  /**
   * Search projects by query
   * @param {string} query - Search query
   * @returns {Promise<Project[]>}
   */
  async search(query) {
    throw new Error('search() not implemented')
  }

  /**
   * Find recently accessed projects
   * @param {number} hours - Number of hours to consider "recent"
   * @param {number} limit - Maximum number of results
   * @returns {Promise<Project[]>}
   */
  async findRecent(hours = 24, limit = 10) {
    throw new Error('findRecent() not implemented')
  }

  /**
   * Find top projects by session count
   * @param {number} limit - Maximum number of results
   * @returns {Promise<Project[]>}
   */
  async findTopBySessionCount(limit = 10) {
    throw new Error('findTopBySessionCount() not implemented')
  }

  /**
   * Find top projects by total duration
   * @param {number} limit - Maximum number of results
   * @returns {Promise<Project[]>}
   */
  async findTopByDuration(limit = 10) {
    throw new Error('findTopByDuration() not implemented')
  }

  /**
   * Save (create or update) a project
   * @param {Project} project
   * @returns {Promise<Project>}
   */
  async save(project) {
    throw new Error('save() not implemented')
  }

  /**
   * Delete a project
   * @param {string} projectId
   * @returns {Promise<boolean>} True if deleted, false if not found
   */
  async delete(projectId) {
    throw new Error('delete() not implemented')
  }

  /**
   * Check if project exists
   * @param {string} projectId
   * @returns {Promise<boolean>}
   */
  async exists(projectId) {
    throw new Error('exists() not implemented')
  }

  /**
   * Count total projects
   * @returns {Promise<number>}
   */
  async count() {
    throw new Error('count() not implemented')
  }

  /**
   * Scan filesystem for projects
   * @param {string} rootPath - Root directory to scan
   * @returns {Promise<Project[]>} Discovered projects
   */
  async scan(rootPath) {
    throw new Error('scan() not implemented')
  }
}

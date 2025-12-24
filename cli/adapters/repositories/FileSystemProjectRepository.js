/**
 * FileSystemProjectRepository
 *
 * Adapter: Implements IProjectRepository using JSON file storage
 *
 * Persistence Strategy:
 * - Single JSON file: ~/.flow-cli/projects.json
 * - Array of project objects
 * - Atomic writes (write to temp file, then rename)
 * - Scanning delegates to project-detector vendored script
 *
 * This is the adapter layer - it knows about files, paths, and JSON serialization.
 * The domain layer knows nothing about this implementation.
 */

import { promises as fs } from 'fs'
import { join, dirname } from 'path'
import { exec } from 'child_process'
import { promisify } from 'util'
import { Project } from '../../domain/entities/Project.js'
import { ProjectType } from '../../domain/value-objects/ProjectType.js'
import { IProjectRepository } from '../../domain/repositories/IProjectRepository.js'
import { ProjectScanCache } from '../../utils/ProjectScanCache.js'

const execAsync = promisify(exec)

export class FileSystemProjectRepository extends IProjectRepository {
  /**
   * @param {string} filePath - Path to projects.json file
   * @param {string} [detectorScriptPath] - Optional path to project-detector script
   * @param {Object} [cacheOptions] - Cache configuration
   * @param {number} [cacheOptions.ttl=3600000] - Cache TTL in ms (default: 1 hour)
   * @param {number} [cacheOptions.maxSize=1000] - Max cache entries
   */
  constructor(filePath, detectorScriptPath = null, cacheOptions = {}) {
    super()
    this.filePath = filePath
    this.detectorScriptPath = detectorScriptPath

    // Initialize cache with 1-hour TTL by default
    this.scanCache = new ProjectScanCache({
      ttl: cacheOptions.ttl || 3600000, // 1 hour default
      maxSize: cacheOptions.maxSize || 1000
    })

    // Scan timeout for individual directory scans (5 seconds)
    this.scanTimeout = 5000
  }

  /**
   * Load all projects from file
   * @private
   */
  async _loadProjects() {
    try {
      const data = await fs.readFile(this.filePath, 'utf-8')
      const projectsData = JSON.parse(data)

      return projectsData.map(data => this._deserializeProject(data))
    } catch (error) {
      if (error.code === 'ENOENT') {
        // File doesn't exist yet - return empty array
        return []
      }
      throw new Error(`Failed to load projects: ${error.message}`)
    }
  }

  /**
   * Save all projects to file
   * @private
   */
  async _saveProjects(projects) {
    try {
      // Ensure directory exists
      await fs.mkdir(dirname(this.filePath), { recursive: true })

      // Serialize projects
      const projectsData = projects.map(project => this._serializeProject(project))

      // Atomic write: write to temp file, then rename
      const tempFile = `${this.filePath}.tmp`
      await fs.writeFile(tempFile, JSON.stringify(projectsData, null, 2), 'utf-8')
      await fs.rename(tempFile, this.filePath)
    } catch (error) {
      throw new Error(`Failed to save projects: ${error.message}`)
    }
  }

  /**
   * Serialize Project entity to plain object
   * @private
   */
  _serializeProject(project) {
    return {
      id: project.id,
      name: project.name,
      type: project.type.value,
      path: project.path,
      description: project.description,
      tags: project.tags,
      metadata: project.metadata,
      createdAt: project.createdAt.toISOString(),
      lastAccessedAt: project.lastAccessedAt.toISOString(),
      totalSessions: project.totalSessions,
      totalDuration: project.totalDuration
    }
  }

  /**
   * Deserialize plain object to Project entity
   * @private
   */
  _deserializeProject(data) {
    return new Project(data.id, data.name, {
      type: data.type,
      path: data.path,
      description: data.description,
      tags: data.tags,
      metadata: data.metadata,
      createdAt: new Date(data.createdAt),
      lastAccessedAt: new Date(data.lastAccessedAt),
      totalSessions: data.totalSessions,
      totalDuration: data.totalDuration
    })
  }

  // IProjectRepository implementation

  async findById(projectId) {
    const projects = await this._loadProjects()
    return projects.find(p => p.id === projectId) || null
  }

  async findByPath(path) {
    const projects = await this._loadProjects()
    return projects.find(p => p.path === path) || null
  }

  async findAll() {
    return await this._loadProjects()
  }

  async findByType(type) {
    const projects = await this._loadProjects()
    return projects.filter(p => p.type.value === type)
  }

  async findByTag(tag) {
    const projects = await this._loadProjects()
    return projects.filter(p => p.hasTag(tag))
  }

  async search(query) {
    const projects = await this._loadProjects()
    return projects.filter(p => p.matchesSearch(query))
  }

  async findRecent(hours = 24, limit = 10) {
    const projects = await this._loadProjects()

    const recent = projects
      .filter(p => p.isRecentlyAccessed(hours))
      .sort((a, b) => b.lastAccessedAt - a.lastAccessedAt)
      .slice(0, limit)

    return recent
  }

  async findTopBySessionCount(limit = 10) {
    const projects = await this._loadProjects()

    return projects.sort((a, b) => b.totalSessions - a.totalSessions).slice(0, limit)
  }

  async findTopByDuration(limit = 10) {
    const projects = await this._loadProjects()

    return projects.sort((a, b) => b.totalDuration - a.totalDuration).slice(0, limit)
  }

  async save(project) {
    const projects = await this._loadProjects()

    const index = projects.findIndex(p => p.id === project.id)
    if (index >= 0) {
      projects[index] = project
    } else {
      projects.push(project)
    }

    await this._saveProjects(projects)
    return project
  }

  async delete(projectId) {
    const projects = await this._loadProjects()

    const index = projects.findIndex(p => p.id === projectId)
    if (index >= 0) {
      projects.splice(index, 1)
      await this._saveProjects(projects)
      return true
    }

    return false
  }

  async exists(projectId) {
    const project = await this.findById(projectId)
    return project !== null
  }

  async count() {
    const projects = await this._loadProjects()
    return projects.length
  }

  /**
   * Scan filesystem for projects
   *
   * If detectorScriptPath is provided, delegates to that script.
   * Otherwise, does a basic scan looking for common project markers.
   *
   * @param {string} rootPath - Root directory to scan
   * @param {Object} [options] - Scan options
   * @param {boolean} [options.useCache=true] - Use cached results if available
   * @param {boolean} [options.forceRefresh=false] - Force refresh (bypass cache)
   * @param {Function} [options.progressCallback] - Progress callback (project) => void
   * @returns {Promise<Project[]>} Array of discovered projects
   */
  async scan(rootPath, options = {}) {
    const useCache = options.useCache !== false
    const forceRefresh = options.forceRefresh === true

    // Check cache first (unless force refresh)
    if (useCache && !forceRefresh) {
      const cached = this.scanCache.get(rootPath)
      if (cached) {
        return cached
      }
    }

    // Perform actual scan
    let projects
    if (this.detectorScriptPath) {
      projects = await this._scanWithScript(rootPath)
    } else {
      projects = await this._scanBasic(rootPath, options.progressCallback)
    }

    // Cache the results
    if (useCache) {
      this.scanCache.set(rootPath, projects)
    }

    return projects
  }

  /**
   * Scan multiple root paths in parallel
   *
   * @param {string[]} rootPaths - Array of root directories to scan
   * @param {Object} [options] - Scan options (same as scan())
   * @returns {Promise<Map<string, Project[]>>} Map of path -> projects
   */
  async scanParallel(rootPaths, options = {}) {
    const scanPromises = rootPaths.map(rootPath =>
      this.scan(rootPath, options).then(projects => [rootPath, projects])
    )

    const results = await Promise.all(scanPromises)
    return new Map(results)
  }

  /**
   * Get cache statistics
   * @returns {Object} Cache stats
   */
  getCacheStats() {
    return this.scanCache.getStats()
  }

  /**
   * Clear scan cache
   */
  clearCache() {
    this.scanCache.clear()
  }

  /**
   * Invalidate cache for specific path
   * @param {string} rootPath - Path to invalidate
   */
  invalidateCache(rootPath) {
    this.scanCache.invalidate(rootPath)
  }

  /**
   * Scan using external script (vendored project-detector)
   * @private
   */
  async _scanWithScript(rootPath) {
    try {
      const { stdout } = await execAsync(`bash "${this.detectorScriptPath}" "${rootPath}"`)

      // Parse script output (assumes JSON format)
      const projectsData = JSON.parse(stdout)

      return projectsData.map(
        data =>
          new Project(
            data.path, // Use path as ID
            data.name || dirname(data.path),
            {
              type: data.type || ProjectType.GENERAL,
              path: data.path,
              description: data.description || ''
            }
          )
      )
    } catch (error) {
      throw new Error(`Project scan failed: ${error.message}`)
    }
  }

  /**
   * Basic scan without external script
   * Looks for common project markers (package.json, DESCRIPTION, etc.)
   * @private
   * @param {string} rootPath - Root directory to scan
   * @param {Function} [progressCallback] - Progress callback for each project found
   */
  async _scanBasic(rootPath, progressCallback = null) {
    try {
      const entries = await fs.readdir(rootPath, { withFileTypes: true })
      const directories = entries.filter(entry => entry.isDirectory())

      // Scan directories in parallel with timeout
      const scanPromises = directories.map(entry =>
        this._scanDirectory(rootPath, entry, progressCallback)
      )

      const results = await Promise.all(scanPromises)

      // Filter out null results (non-projects or failed scans)
      return results.filter(project => project !== null)
    } catch (error) {
      throw new Error(`Basic scan failed: ${error.message}`)
    }
  }

  /**
   * Scan a single directory for project markers
   * @private
   */
  async _scanDirectory(rootPath, entry, progressCallback) {
    const projectPath = join(rootPath, entry.name)

    try {
      // Detect project type with timeout
      const type = await this._withTimeout(
        this._detectProjectType(projectPath),
        this.scanTimeout,
        null // Return null on timeout
      )

      if (type) {
        const project = new Project(
          projectPath, // Use path as ID
          entry.name,
          {
            type,
            path: projectPath
          }
        )

        if (progressCallback) {
          progressCallback(project)
        }

        return project
      }
    } catch (error) {
      // Silently skip directories that fail to scan
      return null
    }

    return null
  }

  /**
   * Execute a promise with timeout
   * @private
   */
  async _withTimeout(promise, timeoutMs, defaultValue = null) {
    return Promise.race([
      promise,
      new Promise(resolve => setTimeout(() => resolve(defaultValue), timeoutMs))
    ])
  }

  /**
   * Detect project type by checking for marker files
   * @private
   */
  async _detectProjectType(projectPath) {
    // Check for various project markers
    const markers = [
      { file: 'package.json', type: ProjectType.NODE },
      { file: 'DESCRIPTION', type: ProjectType.R_PACKAGE },
      { file: '_quarto.yml', type: ProjectType.QUARTO },
      { file: 'pyproject.toml', type: ProjectType.PYTHON },
      { file: 'setup.py', type: ProjectType.PYTHON },
      { file: '.spacemacs', type: ProjectType.SPACEMACS },
      { file: '.zshrc', type: ProjectType.ZSH }
    ]

    for (const { file, type } of markers) {
      try {
        await fs.access(join(projectPath, file))
        return type
      } catch {
        // File doesn't exist, continue
      }
    }

    // Check for MCP server (has mcp.json or server.py in specific structure)
    try {
      await fs.access(join(projectPath, 'mcp.json'))
      return ProjectType.MCP
    } catch {}

    // If no markers found, return null (not a recognized project)
    return null
  }
}

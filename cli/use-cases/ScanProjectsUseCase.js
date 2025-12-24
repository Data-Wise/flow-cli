/**
 * ScanProjectsUseCase
 *
 * Use Case: Scan filesystem for projects and sync with repository
 *
 * Responsibilities:
 * - Scan root directory for projects
 * - Detect project types
 * - Create or update Project entities
 * - Persist to repository
 * - Return discovered projects
 *
 * This is a pure business logic layer with no framework dependencies.
 */

import { Project } from '../domain/entities/Project.js'
import { ProjectType } from '../domain/value-objects/ProjectType.js'

export class ScanProjectsUseCase {
  /**
   * @param {IProjectRepository} projectRepository
   */
  constructor(projectRepository) {
    this.projectRepository = projectRepository
  }

  /**
   * Execute the use case
   *
   * @param {Object} input
   * @param {string} input.rootPath - Root directory to scan
   * @param {boolean} [input.updateExisting=true] - Update existing projects
   * @param {boolean} [input.removeStale=false] - Remove projects not found in scan
   * @param {boolean} [input.useCache=true] - Use cached scan results if available
   * @param {boolean} [input.forceRefresh=false] - Force refresh (bypass cache)
   * @param {Function} [input.progressCallback] - Progress callback for scan
   * @param {Object} [input.filters] - Optional filters to apply (ProjectFilters criteria)
   * @returns {Promise<{discovered: Project[], updated: Project[], removed: string[], cacheStats: Object}>}
   */
  async execute(input) {
    // Validate input
    this.validateInput(input)

    const rootPath = input.rootPath
    const updateExisting = input.updateExisting !== false
    const removeStale = input.removeStale === true
    const useCache = input.useCache !== false
    const forceRefresh = input.forceRefresh === true

    // Scan filesystem with caching support
    const scannedProjects = await this.projectRepository.scan(rootPath, {
      useCache,
      forceRefresh,
      progressCallback: input.progressCallback
    })

    // Apply filters if provided
    let filteredProjects = scannedProjects
    if (input.filters) {
      const { ProjectFilters } = await import('../utils/ProjectFilters.js')
      const filters = new ProjectFilters()
      filteredProjects = await filters.composite(scannedProjects, input.filters)
    }

    const discovered = []
    const updated = []

    // Process each scanned project
    for (const scannedProject of filteredProjects) {
      const existingProject = await this.projectRepository.findById(scannedProject.id)

      if (existingProject) {
        // Update existing project if requested
        if (updateExisting) {
          // Merge scanned data with existing data
          existingProject.touch()

          // Update metadata but preserve statistics
          if (scannedProject.description) {
            existingProject.description = scannedProject.description
          }
          if (scannedProject.type) {
            existingProject.type = scannedProject.type
          }

          await this.projectRepository.save(existingProject)
          updated.push(existingProject)
        }
      } else {
        // Create new project
        await this.projectRepository.save(scannedProject)
        discovered.push(scannedProject)
      }
    }

    // Remove stale projects if requested
    const removed = []
    if (removeStale) {
      const allProjects = await this.projectRepository.findAll()
      const scannedIds = new Set(filteredProjects.map(p => p.id))

      for (const project of allProjects) {
        if (!scannedIds.has(project.id)) {
          await this.projectRepository.delete(project.id)
          removed.push(project.id)
        }
      }
    }

    // Get cache statistics
    const cacheStats = this.projectRepository.getCacheStats
      ? this.projectRepository.getCacheStats()
      : null

    return {
      discovered,
      updated,
      removed,
      cacheStats
    }
  }

  /**
   * Validate use case input
   * @private
   */
  validateInput(input) {
    if (!input) {
      throw new Error('ScanProjectsUseCase: input is required')
    }

    if (!input.rootPath || typeof input.rootPath !== 'string') {
      throw new Error('ScanProjectsUseCase: rootPath must be a non-empty string')
    }

    if (input.updateExisting !== undefined && typeof input.updateExisting !== 'boolean') {
      throw new Error('ScanProjectsUseCase: updateExisting must be a boolean')
    }

    if (input.removeStale !== undefined && typeof input.removeStale !== 'boolean') {
      throw new Error('ScanProjectsUseCase: removeStale must be a boolean')
    }
  }
}

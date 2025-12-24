/**
 * Unit tests for ScanProjectsUseCase
 */

import { ScanProjectsUseCase } from '../../../cli/use-cases/ScanProjectsUseCase.js'
import { Project } from '../../../cli/domain/entities/Project.js'
import { ProjectType } from '../../../cli/domain/value-objects/ProjectType.js'

// Mock repository
class MockProjectRepository {
  constructor() {
    this.projects = []
    this.scannedProjects = [] // Simulated scan results
  }

  async findAll() {
    return [...this.projects]
  }

  async findById(id) {
    return this.projects.find(p => p.id === id) || null
  }

  async save(project) {
    const index = this.projects.findIndex(p => p.id === project.id)
    if (index >= 0) {
      this.projects[index] = project
    } else {
      this.projects.push(project)
    }
    return project
  }

  async delete(id) {
    const index = this.projects.findIndex(p => p.id === id)
    if (index >= 0) {
      this.projects.splice(index, 1)
      return true
    }
    return false
  }

  async scan(rootPath) {
    // Return pre-configured scanned projects
    return [...this.scannedProjects]
  }
}

describe('ScanProjectsUseCase', () => {
  let useCase
  let projectRepo

  beforeEach(() => {
    projectRepo = new MockProjectRepository()
    useCase = new ScanProjectsUseCase(projectRepo)
  })

  describe('Success Cases - New Projects', () => {
    test('discovers and saves new projects', async () => {
      projectRepo.scannedProjects = [
        new Project('project-1', 'rmediation', {
          type: ProjectType.R_PACKAGE,
          path: '/path/to/rmediation'
        }),
        new Project('project-2', 'flow-cli', {
          type: ProjectType.NODE,
          path: '/path/to/flow-cli'
        })
      ]

      const result = await useCase.execute({ rootPath: '/path/to/projects' })

      expect(result.discovered).toHaveLength(2)
      expect(result.discovered[0].name).toBe('rmediation')
      expect(result.discovered[1].name).toBe('flow-cli')
      expect(projectRepo.projects).toHaveLength(2)
    })

    test('saves all discovered projects to repository', async () => {
      projectRepo.scannedProjects = [
        new Project('project-1', 'test1'),
        new Project('project-2', 'test2'),
        new Project('project-3', 'test3')
      ]

      await useCase.execute({ rootPath: '/path' })

      expect(projectRepo.projects).toHaveLength(3)
    })
  })

  describe('Success Cases - Existing Projects', () => {
    test('updates existing projects by default', async () => {
      // Existing project in repository
      const existingProject = new Project('project-1', 'rmediation', {
        type: ProjectType.R_PACKAGE,
        totalSessions: 5,
        totalDuration: 150
      })
      projectRepo.projects.push(existingProject)

      // Same project found in scan
      projectRepo.scannedProjects = [
        new Project('project-1', 'rmediation', {
          type: ProjectType.R_PACKAGE,
          description: 'Updated description'
        })
      ]

      const result = await useCase.execute({ rootPath: '/path' })

      expect(result.discovered).toHaveLength(0)
      expect(result.updated).toHaveLength(1)
      expect(result.updated[0].description).toBe('Updated description')
      // Statistics should be preserved
      expect(result.updated[0].totalSessions).toBe(5)
      expect(result.updated[0].totalDuration).toBe(150)
    })

    test('touches last accessed time for existing projects', async () => {
      const existingProject = new Project('project-1', 'test')
      const originalTime = existingProject.lastAccessedAt
      projectRepo.projects.push(existingProject)

      projectRepo.scannedProjects = [new Project('project-1', 'test')]

      // Wait a bit
      await new Promise(resolve => setTimeout(resolve, 10))

      await useCase.execute({ rootPath: '/path' })

      expect(existingProject.lastAccessedAt).not.toEqual(originalTime)
    })

    test('does not update existing projects when updateExisting=false', async () => {
      const existingProject = new Project('project-1', 'test', {
        description: 'Original description'
      })
      projectRepo.projects.push(existingProject)

      projectRepo.scannedProjects = [
        new Project('project-1', 'test', {
          description: 'New description'
        })
      ]

      const result = await useCase.execute({
        rootPath: '/path',
        updateExisting: false
      })

      expect(result.updated).toHaveLength(0)
      expect(existingProject.description).toBe('Original description')
    })
  })

  describe('Success Cases - Stale Projects', () => {
    test('removes stale projects when removeStale=true', async () => {
      // Existing projects
      projectRepo.projects.push(new Project('project-1', 'active'))
      projectRepo.projects.push(new Project('project-2', 'stale'))

      // Only project-1 found in scan
      projectRepo.scannedProjects = [new Project('project-1', 'active')]

      const result = await useCase.execute({
        rootPath: '/path',
        removeStale: true
      })

      expect(result.removed).toHaveLength(1)
      expect(result.removed).toContain('project-2')
      expect(projectRepo.projects).toHaveLength(1)
      expect(projectRepo.projects[0].id).toBe('project-1')
    })

    test('does not remove stale projects by default', async () => {
      projectRepo.projects.push(new Project('project-1', 'active'))
      projectRepo.projects.push(new Project('project-2', 'stale'))

      projectRepo.scannedProjects = [new Project('project-1', 'active')]

      const result = await useCase.execute({ rootPath: '/path' })

      expect(result.removed).toHaveLength(0)
      expect(projectRepo.projects).toHaveLength(2)
    })
  })

  describe('Mixed Scenarios', () => {
    test('handles discovering, updating, and removing in one scan', async () => {
      // Existing projects
      projectRepo.projects.push(new Project('existing-1', 'keep'))
      projectRepo.projects.push(new Project('existing-2', 'remove'))

      // Scan finds one existing and one new
      projectRepo.scannedProjects = [
        new Project('existing-1', 'keep'),
        new Project('new-1', 'new-project')
      ]

      const result = await useCase.execute({
        rootPath: '/path',
        updateExisting: true,
        removeStale: true
      })

      expect(result.discovered).toHaveLength(1)
      expect(result.discovered[0].name).toBe('new-project')
      expect(result.updated).toHaveLength(1)
      expect(result.updated[0].name).toBe('keep')
      expect(result.removed).toHaveLength(1)
      expect(result.removed).toContain('existing-2')
    })
  })

  describe('Validation', () => {
    test('throws error if input is missing', async () => {
      await expect(useCase.execute()).rejects.toThrow('input is required')
    })

    test('throws error if rootPath is missing', async () => {
      await expect(useCase.execute({})).rejects.toThrow('rootPath must be a non-empty string')
    })

    test('throws error if rootPath is not a string', async () => {
      await expect(useCase.execute({ rootPath: 123 })).rejects.toThrow(
        'rootPath must be a non-empty string'
      )
    })

    test('throws error if updateExisting is not a boolean', async () => {
      await expect(
        useCase.execute({
          rootPath: '/path',
          updateExisting: 'yes'
        })
      ).rejects.toThrow('updateExisting must be a boolean')
    })

    test('throws error if removeStale is not a boolean', async () => {
      await expect(
        useCase.execute({
          rootPath: '/path',
          removeStale: 'yes'
        })
      ).rejects.toThrow('removeStale must be a boolean')
    })
  })

  describe('Edge Cases', () => {
    test('handles empty scan results', async () => {
      projectRepo.scannedProjects = []

      const result = await useCase.execute({ rootPath: '/path' })

      expect(result.discovered).toHaveLength(0)
      expect(result.updated).toHaveLength(0)
      expect(result.removed).toHaveLength(0)
    })

    test('handles scanning with no existing projects', async () => {
      projectRepo.scannedProjects = [new Project('project-1', 'test')]

      const result = await useCase.execute({ rootPath: '/path' })

      expect(result.discovered).toHaveLength(1)
      expect(result.updated).toHaveLength(0)
    })
  })
})

/**
 * Unit tests for CreateSessionUseCase
 */

import { CreateSessionUseCase } from '../../../cli/use-cases/CreateSessionUseCase.js'
import { Session } from '../../../cli/domain/entities/Session.js'
import { Project } from '../../../cli/domain/entities/Project.js'

// Mock repositories
class MockSessionRepository {
  constructor() {
    this.sessions = []
  }

  async findActive() {
    return this.sessions.find(s => s.state.isActive()) || null
  }

  async save(session) {
    this.sessions.push(session)
    return session
  }
}

class MockProjectRepository {
  constructor() {
    this.projects = []
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
}

describe('CreateSessionUseCase', () => {
  let useCase
  let sessionRepo
  let projectRepo

  beforeEach(() => {
    sessionRepo = new MockSessionRepository()
    projectRepo = new MockProjectRepository()
    useCase = new CreateSessionUseCase(sessionRepo, projectRepo)
  })

  describe('Success Cases', () => {
    test('creates session with minimal input', async () => {
      const input = { project: 'rmediation' }

      const session = await useCase.execute(input)

      expect(session).toBeInstanceOf(Session)
      expect(session.project).toBe('rmediation')
      expect(session.state.isActive()).toBe(true)
      expect(sessionRepo.sessions).toHaveLength(1)
    })

    test('creates session with all optional fields', async () => {
      const input = {
        project: 'rmediation',
        task: 'Fix bug in mediation function',
        branch: 'fix/mediation-bug',
        context: { priority: 'high' }
      }

      const session = await useCase.execute(input)

      expect(session.project).toBe('rmediation')
      expect(session.task).toBe('Fix bug in mediation function')
      expect(session.branch).toBe('fix/mediation-bug')
      expect(session.context.priority).toBe('high')
    })

    test('generates unique session ID', async () => {
      const input = { project: 'rmediation' }

      const session1 = await useCase.execute(input)
      // End first session to allow creating second
      session1.end('completed')

      // Wait 1ms to ensure different timestamp
      await new Promise(resolve => setTimeout(resolve, 1))

      const session2 = await useCase.execute(input)

      expect(session1.id).not.toBe(session2.id)
    })

    test('saves session to repository', async () => {
      const input = { project: 'rmediation' }

      await useCase.execute(input)

      expect(sessionRepo.sessions).toHaveLength(1)
      expect(sessionRepo.sessions[0].project).toBe('rmediation')
    })

    test('updates project last accessed time if project exists', async () => {
      const project = new Project('rmediation', 'rmediation', {
        path: '/path/to/project'
      })
      projectRepo.projects.push(project)

      const originalTime = project.lastAccessedAt

      // Wait a bit
      await new Promise(resolve => setTimeout(resolve, 10))

      const input = { project: 'rmediation' }
      await useCase.execute(input)

      expect(project.lastAccessedAt).not.toEqual(originalTime)
    })

    test('does not fail if project does not exist', async () => {
      const input = { project: 'nonexistent' }

      await expect(useCase.execute(input)).resolves.toBeTruthy()
    })
  })

  describe('Validation', () => {
    test('throws error if input is missing', async () => {
      await expect(useCase.execute()).rejects.toThrow('input is required')
    })

    test('throws error if project is missing', async () => {
      await expect(useCase.execute({})).rejects.toThrow('project name is required')
    })

    test('throws error if project is empty string', async () => {
      await expect(useCase.execute({ project: '' })).rejects.toThrow('project name is required')
    })

    test('throws error if project is only whitespace', async () => {
      await expect(useCase.execute({ project: '   ' })).rejects.toThrow('project name is required')
    })

    test('throws error if task is not a string', async () => {
      await expect(useCase.execute({ project: 'test', task: 123 })).rejects.toThrow(
        'task must be a string'
      )
    })

    test('throws error if branch is not a string', async () => {
      await expect(useCase.execute({ project: 'test', branch: 123 })).rejects.toThrow(
        'branch must be a string'
      )
    })

    test('throws error if context is not an object', async () => {
      await expect(useCase.execute({ project: 'test', context: 'invalid' })).rejects.toThrow(
        'context must be an object'
      )
    })
  })

  describe('Business Rules', () => {
    test('throws error if active session already exists', async () => {
      // Create first session
      await useCase.execute({ project: 'rmediation' })

      // Try to create second session
      await expect(useCase.execute({ project: 'other-project' })).rejects.toThrow(
        'Cannot create session: Active session exists'
      )
    })

    test('error message includes active session project name', async () => {
      await useCase.execute({ project: 'rmediation' })

      await expect(useCase.execute({ project: 'other' })).rejects.toThrow(
        'Active session exists for project "rmediation"'
      )
    })

    test('can create session after ending previous one', async () => {
      // Create and end first session
      const session1 = await useCase.execute({ project: 'rmediation' })
      session1.end('completed')

      // Should be able to create second session
      const session2 = await useCase.execute({ project: 'other-project' })

      expect(session2).toBeInstanceOf(Session)
      expect(session2.project).toBe('other-project')
    })
  })
})

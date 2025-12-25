/**
 * CreateSessionUseCase
 *
 * Use Case: Create a new work session
 *
 * Responsibilities:
 * - Validate inputs
 * - Check for existing active session
 * - Create new Session entity
 * - Persist via repository
 * - Return created session
 *
 * This is a pure business logic layer with no framework dependencies.
 */

import { Session } from '../domain/entities/Session.js'

export class CreateSessionUseCase {
  /**
   * @param {ISessionRepository} sessionRepository
   * @param {IProjectRepository} projectRepository
   */
  constructor(sessionRepository, projectRepository) {
    this.sessionRepository = sessionRepository
    this.projectRepository = projectRepository
  }

  /**
   * Execute the use case
   *
   * @param {Object} input
   * @param {string} input.project - Project name or ID
   * @param {string} [input.task] - Optional task description
   * @param {string} [input.branch] - Optional git branch
   * @param {Object} [input.context] - Optional metadata
   * @returns {Promise<Session>} Created session
   */
  async execute(input) {
    // Validate input
    this.validateInput(input)

    // Business Rule: Only one active session allowed at a time
    const activeSession = await this.sessionRepository.findActive()
    if (activeSession) {
      throw new Error(
        `Cannot create session: Active session exists for project "${activeSession.project}". ` +
          `End the current session first or use pause/resume.`
      )
    }

    // Generate unique ID with timestamp + random component to avoid collisions
    const random = Math.random().toString(36).substring(2, 15)
    const sessionId = `session-${Date.now()}-${random}`

    // Create Session entity (domain layer handles validation)
    const session = new Session(sessionId, input.project, {
      task: input.task,
      branch: input.branch,
      context: input.context
    })

    // Persist the session
    const savedSession = await this.sessionRepository.save(session)

    // Update project's last accessed time if project exists
    if (input.project) {
      try {
        const project = await this.projectRepository.findById(input.project)
        if (project) {
          project.touch()
          await this.projectRepository.save(project)
        }
      } catch (error) {
        // Non-critical: Project touch failure shouldn't prevent session creation
        console.warn(`Failed to update project last accessed time: ${error.message}`)
      }
    }

    return savedSession
  }

  /**
   * Validate use case input
   * @private
   */
  validateInput(input) {
    if (!input) {
      throw new Error('CreateSessionUseCase: input is required')
    }

    if (!input.project || input.project.trim() === '') {
      throw new Error('CreateSessionUseCase: project name is required')
    }

    if (input.task !== undefined && typeof input.task !== 'string') {
      throw new Error('CreateSessionUseCase: task must be a string')
    }

    if (input.branch !== undefined && typeof input.branch !== 'string') {
      throw new Error('CreateSessionUseCase: branch must be a string')
    }

    if (input.context !== undefined && typeof input.context !== 'object') {
      throw new Error('CreateSessionUseCase: context must be an object')
    }
  }
}

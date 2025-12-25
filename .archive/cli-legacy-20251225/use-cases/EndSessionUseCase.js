/**
 * EndSessionUseCase
 *
 * Use Case: End an active work session
 *
 * Responsibilities:
 * - Find active session
 * - End the session (domain logic)
 * - Update project statistics
 * - Persist changes
 * - Return ended session
 *
 * This is a pure business logic layer with no framework dependencies.
 */

export class EndSessionUseCase {
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
   * @param {string} [input.sessionId] - Optional session ID (defaults to active session)
   * @param {string} [input.outcome] - Session outcome (completed, cancelled, interrupted)
   * @returns {Promise<Session>} Ended session
   */
  async execute(input = {}) {
    // Find the session to end
    let session
    if (input.sessionId) {
      session = await this.sessionRepository.findById(input.sessionId)
      if (!session) {
        throw new Error(`Session not found: ${input.sessionId}`)
      }
    } else {
      // Default to active session
      session = await this.sessionRepository.findActive()
      if (!session) {
        throw new Error('No active session found to end')
      }
    }

    // Validate outcome if provided
    const outcome = input.outcome || 'completed'
    const validOutcomes = ['completed', 'cancelled', 'interrupted']
    if (!validOutcomes.includes(outcome)) {
      throw new Error(`Invalid outcome: ${outcome}. Must be one of: ${validOutcomes.join(', ')}`)
    }

    // End the session (domain logic handles validation)
    session.end(outcome)

    // Update project statistics
    if (session.project) {
      try {
        const project = await this.projectRepository.findById(session.project)
        if (project) {
          const duration = session.getDuration()
          project.recordSession(duration)
          await this.projectRepository.save(project)
        }
      } catch (error) {
        // Non-critical: Project statistics update failure shouldn't prevent session ending
        console.warn(`Failed to update project statistics: ${error.message}`)
      }
    }

    // Persist the ended session
    const savedSession = await this.sessionRepository.save(session)

    return savedSession
  }
}

/**
 * Unit tests for GetRecentProjectsUseCase
 */

import { GetRecentProjectsUseCase } from '../../../cli/use-cases/GetRecentProjectsUseCase.js'
import { Project } from '../../../cli/domain/entities/Project.js'
import { ProjectType } from '../../../cli/domain/value-objects/ProjectType.js'

// Mock repository
class MockProjectRepository {
  constructor() {
    this.projects = []
  }

  async findRecent(hours, limit) {
    return this.projects
      .filter(p => p.isRecentlyAccessed(hours))
      .sort((a, b) => b.lastAccessedAt - a.lastAccessedAt)
      .slice(0, limit)
  }

  async findTopByDuration(limit) {
    return this.projects.sort((a, b) => b.totalDuration - a.totalDuration).slice(0, limit)
  }

  async findTopBySessionCount(limit) {
    return this.projects.sort((a, b) => b.totalSessions - a.totalSessions).slice(0, limit)
  }

  async count() {
    return this.projects.length
  }
}

describe('GetRecentProjectsUseCase', () => {
  let useCase
  let projectRepo

  beforeEach(() => {
    projectRepo = new MockProjectRepository()
    useCase = new GetRecentProjectsUseCase(projectRepo)
  })

  describe('Project Ranking', () => {
    test('returns projects sorted by score', async () => {
      const p1 = new Project('p1', 'recent-project')
      p1.recordSession(10)

      const p2 = new Project('p2', 'old-project')
      p2.recordSession(100)
      p2.recordSession(50)
      p2.lastAccessedAt = new Date(Date.now() - 48 * 60 * 60 * 1000)

      projectRepo.projects.push(p1, p2)

      const result = await useCase.execute({ limit: 5 })

      expect(result.projects).toHaveLength(2)
      // Recent project should rank higher
      expect(result.projects[0].name).toBe('recent-project')
    })

    test('includes ranking reasons', async () => {
      const project = new Project('p1', 'test')
      project.recordSession(100)
      projectRepo.projects.push(project)

      const result = await useCase.execute()

      const ranked = result.projects[0]
      expect(ranked.ranking).toBeTruthy()
      expect(ranked.ranking.isRecent).toBeTruthy()
    })

    test('limits results correctly', async () => {
      for (let i = 0; i < 20; i++) {
        const project = new Project(`p${i}`, `project-${i}`)
        project.recordSession(10)
        projectRepo.projects.push(project)
      }

      const result = await useCase.execute({ limit: 5 })

      expect(result.projects).toHaveLength(5)
    })

    test('combines multiple ranking signals', async () => {
      const highScorer = new Project('p1', 'high-scorer')
      highScorer.recordSession(100)
      highScorer.recordSession(90)
      highScorer.recordSession(80)

      const lowScorer = new Project('p2', 'low-scorer')
      lowScorer.recordSession(5)
      lowScorer.lastAccessedAt = new Date(Date.now() - 72 * 60 * 60 * 1000)

      projectRepo.projects.push(highScorer, lowScorer)

      const result = await useCase.execute()

      const first = result.projects[0]
      expect(first.name).toBe('high-scorer')
      expect(first.ranking.isRecent).toBe(true)
      expect(first.ranking.isTopDuration).toBe(true)
      expect(first.ranking.isTopSessions).toBe(true)
    })
  })

  describe('Stats', () => {
    test('includes stats by default', async () => {
      const project = new Project('p1', 'test')
      projectRepo.projects.push(project)

      const result = await useCase.execute()

      expect(result.stats).toBeTruthy()
      expect(result.stats.totalProjects).toBe(1)
    })

    test('excludes stats when requested', async () => {
      const result = await useCase.execute({ includeStats: false })

      expect(result.stats).toBeNull()
    })
  })

  describe('Edge Cases', () => {
    test('handles empty project list', async () => {
      const result = await useCase.execute()

      expect(result.projects).toHaveLength(0)
    })

    test('handles single project', async () => {
      const project = new Project('p1', 'only-project')
      projectRepo.projects.push(project)

      const result = await useCase.execute()

      expect(result.projects).toHaveLength(1)
      expect(result.projects[0].name).toBe('only-project')
    })
  })
})

/**
 * Unit tests for Project entity
 */

import { Project } from '../../../../cli/domain/entities/Project.js'
import { ProjectType } from '../../../../cli/domain/value-objects/ProjectType.js'

describe('Project Entity', () => {
  describe('Construction', () => {
    test('creates project with required fields', () => {
      const project = new Project('id-1', 'rmediation')

      expect(project.id).toBe('id-1')
      expect(project.name).toBe('rmediation')
      expect(project.type.value).toBe(ProjectType.GENERAL)
      expect(project.path).toBe('id-1')
      expect(project.description).toBe('')
      expect(project.tags).toEqual([])
      expect(project.totalSessions).toBe(0)
      expect(project.totalDuration).toBe(0)
    })

    test('creates project with optional fields', () => {
      const project = new Project('id-1', 'rmediation', {
        type: ProjectType.R_PACKAGE,
        path: '/Users/dt/projects/r-packages/active/rmediation',
        description: 'Mediation analysis package',
        tags: ['r', 'statistics'],
        metadata: { priority: 'high' }
      })

      expect(project.type.value).toBe(ProjectType.R_PACKAGE)
      expect(project.path).toBe('/Users/dt/projects/r-packages/active/rmediation')
      expect(project.description).toBe('Mediation analysis package')
      expect(project.tags).toEqual(['r', 'statistics'])
      expect(project.metadata.priority).toBe('high')
    })

    test('accepts ProjectType instance', () => {
      const type = new ProjectType(ProjectType.NODE)
      const project = new Project('id-1', 'flow-cli', { type })

      expect(project.type).toBe(type)
      expect(project.type.value).toBe(ProjectType.NODE)
    })

    test('throws error if ID is empty', () => {
      expect(() => new Project('', 'name')).toThrow('Project must have an ID')
    })

    test('throws error if name is empty', () => {
      expect(() => new Project('id-1', '')).toThrow('Project must have a name')
    })

    test('throws error if name is too long', () => {
      const longName = 'a'.repeat(101)
      expect(() => new Project('id-1', longName)).toThrow('Project name too long')
    })

    test('throws error if description is too long', () => {
      const longDesc = 'a'.repeat(501)
      expect(() => new Project('id-1', 'name', { description: longDesc })).toThrow(
        'Project description too long'
      )
    })

    test('throws error if tags is not an array', () => {
      expect(() => new Project('id-1', 'name', { tags: 'invalid' })).toThrow(
        'Project tags must be an array'
      )
    })

    test('throws error if tags contains non-strings', () => {
      expect(() => new Project('id-1', 'name', { tags: ['valid', 123] })).toThrow(
        'Project tags must be strings'
      )
    })
  })

  describe('Touch (Update Last Accessed)', () => {
    test('updates lastAccessedAt', () => {
      const project = new Project('id-1', 'test')
      const originalTime = project.lastAccessedAt

      // Wait a tiny bit
      const delay = () => new Promise(resolve => setTimeout(resolve, 10))
      return delay().then(() => {
        project.touch()
        expect(project.lastAccessedAt).not.toEqual(originalTime)
        expect(project.lastAccessedAt).toBeInstanceOf(Date)
      })
    })
  })

  describe('Record Session', () => {
    test('records session completion', () => {
      const project = new Project('id-1', 'test')

      project.recordSession(30)

      expect(project.totalSessions).toBe(1)
      expect(project.totalDuration).toBe(30)
    })

    test('accumulates multiple sessions', () => {
      const project = new Project('id-1', 'test')

      project.recordSession(30)
      project.recordSession(45)
      project.recordSession(15)

      expect(project.totalSessions).toBe(3)
      expect(project.totalDuration).toBe(90)
    })

    test('throws error for negative duration', () => {
      const project = new Project('id-1', 'test')

      expect(() => project.recordSession(-10)).toThrow('Duration must be a non-negative number')
    })

    test('throws error for invalid duration type', () => {
      const project = new Project('id-1', 'test')

      expect(() => project.recordSession('invalid')).toThrow(
        'Duration must be a non-negative number'
      )
    })

    test('updates lastAccessedAt when recording session', () => {
      const project = new Project('id-1', 'test')
      const originalTime = project.lastAccessedAt

      const delay = () => new Promise(resolve => setTimeout(resolve, 10))
      return delay().then(() => {
        project.recordSession(30)
        expect(project.lastAccessedAt).not.toEqual(originalTime)
      })
    })
  })

  describe('Average Session Duration', () => {
    test('returns 0 for no sessions', () => {
      const project = new Project('id-1', 'test')

      expect(project.getAverageSessionDuration()).toBe(0)
    })

    test('calculates average correctly', () => {
      const project = new Project('id-1', 'test')

      project.recordSession(30)
      project.recordSession(60)
      project.recordSession(45)

      // (30 + 60 + 45) / 3 = 45
      expect(project.getAverageSessionDuration()).toBe(45)
    })

    test('rounds to nearest minute', () => {
      const project = new Project('id-1', 'test')

      project.recordSession(10)
      project.recordSession(11)

      // (10 + 11) / 2 = 10.5, rounded to 11
      expect(project.getAverageSessionDuration()).toBe(11)
    })
  })

  describe('Recently Accessed', () => {
    test('returns true for just created project', () => {
      const project = new Project('id-1', 'test')

      expect(project.isRecentlyAccessed()).toBe(true)
    })

    test('returns false for old project', () => {
      const project = new Project('id-1', 'test')

      // Set last accessed to 48 hours ago
      project.lastAccessedAt = new Date(Date.now() - 48 * 60 * 60 * 1000)

      expect(project.isRecentlyAccessed(24)).toBe(false)
    })

    test('respects custom hour threshold', () => {
      const project = new Project('id-1', 'test')

      // Set last accessed to 10 hours ago
      project.lastAccessedAt = new Date(Date.now() - 10 * 60 * 60 * 1000)

      expect(project.isRecentlyAccessed(12)).toBe(true)
      expect(project.isRecentlyAccessed(8)).toBe(false)
    })
  })

  describe('Tag Management', () => {
    test('checks if project has tag', () => {
      const project = new Project('id-1', 'test', {
        tags: ['r', 'statistics']
      })

      expect(project.hasTag('r')).toBe(true)
      expect(project.hasTag('python')).toBe(false)
    })

    test('adds tag', () => {
      const project = new Project('id-1', 'test')

      project.addTag('important')

      expect(project.tags).toContain('important')
    })

    test('does not add duplicate tags', () => {
      const project = new Project('id-1', 'test', {
        tags: ['r']
      })

      project.addTag('r')

      expect(project.tags).toEqual(['r'])
    })

    test('throws error for invalid tag type', () => {
      const project = new Project('id-1', 'test')

      expect(() => project.addTag(123)).toThrow('Tag must be a string')
    })

    test('removes tag', () => {
      const project = new Project('id-1', 'test', {
        tags: ['r', 'statistics', 'mediation']
      })

      project.removeTag('statistics')

      expect(project.tags).toEqual(['r', 'mediation'])
    })

    test('removing non-existent tag does not error', () => {
      const project = new Project('id-1', 'test', {
        tags: ['r']
      })

      expect(() => project.removeTag('nonexistent')).not.toThrow()
      expect(project.tags).toEqual(['r'])
    })
  })

  describe('Metadata Management', () => {
    test('updates metadata', () => {
      const project = new Project('id-1', 'test')

      project.updateMetadata({ priority: 'high', status: 'active' })

      expect(project.metadata.priority).toBe('high')
      expect(project.metadata.status).toBe('active')
    })

    test('merges metadata updates', () => {
      const project = new Project('id-1', 'test', {
        metadata: { priority: 'low' }
      })

      project.updateMetadata({ status: 'active' })

      expect(project.metadata.priority).toBe('low')
      expect(project.metadata.status).toBe('active')
    })
  })

  describe('Summary', () => {
    test('returns project summary', () => {
      const project = new Project('id-1', 'rmediation', {
        type: ProjectType.R_PACKAGE,
        path: '/path/to/project',
        description: 'R package for mediation',
        tags: ['r', 'statistics']
      })

      project.recordSession(30)

      const summary = project.getSummary()

      expect(summary).toEqual({
        id: 'id-1',
        name: 'rmediation',
        type: ProjectType.R_PACKAGE,
        typeIcon: '📊',
        typeDisplayName: 'R Package',
        path: '/path/to/project',
        description: 'R package for mediation',
        tags: ['r', 'statistics'],
        totalSessions: 1,
        totalDuration: 30,
        averageDuration: 30,
        lastAccessed: expect.any(Date),
        isRecent: true
      })
    })

    test('summary does not mutate tags', () => {
      const project = new Project('id-1', 'test', {
        tags: ['r']
      })

      const summary = project.getSummary()
      summary.tags.push('modified')

      expect(project.tags).toEqual(['r'])
    })
  })

  describe('Search Matching', () => {
    test('matches by name', () => {
      const project = new Project('id-1', 'rmediation')

      expect(project.matchesSearch('rmed')).toBe(true)
      expect(project.matchesSearch('RMED')).toBe(true)
      expect(project.matchesSearch('python')).toBe(false)
    })

    test('matches by description', () => {
      const project = new Project('id-1', 'test', {
        description: 'Mediation analysis package'
      })

      expect(project.matchesSearch('mediation')).toBe(true)
      expect(project.matchesSearch('analysis')).toBe(true)
    })

    test('matches by path', () => {
      const project = new Project('id-1', 'test', {
        path: '/Users/dt/projects/r-packages/active/rmediation'
      })

      expect(project.matchesSearch('r-packages')).toBe(true)
      expect(project.matchesSearch('active')).toBe(true)
    })

    test('matches by tags', () => {
      const project = new Project('id-1', 'test', {
        tags: ['r', 'statistics', 'mediation']
      })

      expect(project.matchesSearch('statistics')).toBe(true)
      expect(project.matchesSearch('STAT')).toBe(true)
    })

    test('matches by type display name', () => {
      const project = new Project('id-1', 'test', {
        type: ProjectType.R_PACKAGE
      })

      expect(project.matchesSearch('package')).toBe(true)
      expect(project.matchesSearch('R Pack')).toBe(true)
    })

    test('matches empty query', () => {
      const project = new Project('id-1', 'test')

      expect(project.matchesSearch('')).toBe(true)
      expect(project.matchesSearch(null)).toBe(true)
    })

    test('is case insensitive', () => {
      const project = new Project('id-1', 'TestProject')

      expect(project.matchesSearch('test')).toBe(true)
      expect(project.matchesSearch('TEST')).toBe(true)
      expect(project.matchesSearch('TeStPrOjEcT')).toBe(true)
    })
  })
})

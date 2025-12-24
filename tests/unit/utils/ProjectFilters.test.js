/**
 * Tests for ProjectFilters
 */

import { describe, test, expect, beforeEach } from '@jest/globals'
import { ProjectFilters } from '../../../cli/utils/ProjectFilters.js'
import { Project } from '../../../cli/domain/entities/Project.js'
import { ProjectType } from '../../../cli/domain/value-objects/ProjectType.js'

describe('ProjectFilters', () => {
  let filters
  let projects

  beforeEach(() => {
    filters = new ProjectFilters()

    // Create test projects
    const now = new Date()

    // Recent Node project with sessions
    const p1 = new Project('p1', 'flow-cli', {
      type: ProjectType.NODE,
      path: '/path/to/flow-cli',
      description: 'Workflow CLI'
    })
    p1.recordSession(60, true)
    p1.lastAccessedAt = new Date(now.getTime() - 2 * 60 * 60 * 1000) // 2 hours ago

    // Old R package with no sessions
    const p2 = new Project('p2', 'rmediation', {
      type: ProjectType.R_PACKAGE,
      path: '/path/to/rmediation'
    })
    p2.lastAccessedAt = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000) // 30 days ago

    // Recent Quarto with tags
    const p3 = new Project('p3', 'docs-site', {
      type: ProjectType.QUARTO,
      path: '/path/to/docs',
      tags: ['documentation', 'public']
    })
    p3.recordSession(30, true)
    p3.recordSession(45, true)
    p3.lastAccessedAt = new Date(now.getTime() - 1 * 60 * 60 * 1000) // 1 hour ago

    // Node project with many sessions
    const p4 = new Project('p4', 'api-server', {
      type: ProjectType.NODE,
      path: '/path/to/api',
      tags: ['backend']
    })
    for (let i = 0; i < 10; i++) {
      p4.recordSession(30, true)
    }
    p4.lastAccessedAt = new Date(now.getTime() - 6 * 60 * 60 * 1000) // 6 hours ago

    projects = [p1, p2, p3, p4]
  })

  describe('byType()', () => {
    test('filters by single type', () => {
      const result = filters.byType(projects, 'node')
      expect(result).toHaveLength(2)
      expect(result.every(p => p.type.value === 'node')).toBe(true)
    })

    test('filters by multiple types', () => {
      const result = filters.byType(projects, ['node', 'quarto'])
      expect(result).toHaveLength(3)
    })

    test('handles empty projects array', () => {
      const result = filters.byType([], 'node')
      expect(result).toEqual([])
    })

    test('handles null projects', () => {
      const result = filters.byType(null, 'node')
      expect(result).toEqual([])
    })

    test('is case-insensitive', () => {
      const result = filters.byType(projects, 'NODE')
      expect(result).toHaveLength(2)
    })
  })

  describe('byTags()', () => {
    test('filters by single tag (any match)', () => {
      const result = filters.byTags(projects, 'documentation')
      expect(result).toHaveLength(1)
      expect(result[0].name).toBe('docs-site')
    })

    test('filters by multiple tags (any match)', () => {
      const result = filters.byTags(projects, ['documentation', 'backend'])
      expect(result).toHaveLength(2)
    })

    test('filters by multiple tags (all match)', () => {
      const result = filters.byTags(projects, ['documentation', 'public'], true)
      expect(result).toHaveLength(1)
      expect(result[0].name).toBe('docs-site')
    })

    test('returns empty for no tag matches', () => {
      const result = filters.byTags(projects, 'nonexistent')
      expect(result).toEqual([])
    })
  })

  describe('byRecentAccess()', () => {
    test('filters recent projects (24 hours)', () => {
      const result = filters.byRecentAccess(projects, 24)
      expect(result).toHaveLength(3) // p1, p3, p4
    })

    test('filters recent projects (1 hour)', () => {
      const result = filters.byRecentAccess(projects, 1)
      expect(result).toHaveLength(0) // None within 1 hour
    })

    test('filters recent projects (3 hours)', () => {
      const result = filters.byRecentAccess(projects, 3)
      expect(result).toHaveLength(2) // p1, p3
    })
  })

  describe('byMinSessions()', () => {
    test('filters by minimum sessions', () => {
      const result = filters.byMinSessions(projects, 2)
      expect(result).toHaveLength(2) // p3, p4
    })

    test('filters by 0 sessions', () => {
      const result = filters.byMinSessions(projects, 0)
      expect(result).toHaveLength(4) // All projects
    })

    test('filters by high session count', () => {
      const result = filters.byMinSessions(projects, 10)
      expect(result).toHaveLength(1) // Only p4
    })
  })

  describe('byMinDuration()', () => {
    test('filters by minimum duration', () => {
      const result = filters.byMinDuration(projects, 60)
      expect(result).toHaveLength(3) // p1, p3, p4
    })

    test('filters by high duration', () => {
      const result = filters.byMinDuration(projects, 200)
      expect(result).toHaveLength(1) // Only p4
    })
  })

  describe('byNamePattern()', () => {
    test('filters by regex pattern', () => {
      const result = filters.byNamePattern(projects, /^api/)
      expect(result).toHaveLength(1)
      expect(result[0].name).toBe('api-server')
    })

    test('filters by string pattern (case-insensitive)', () => {
      const result = filters.byNamePattern(projects, 'CLI')
      expect(result).toHaveLength(1)
      expect(result[0].name).toBe('flow-cli')
    })
  })

  describe('byPathPattern()', () => {
    test('filters by path pattern', () => {
      const result = filters.byPathPattern(projects, /\/api$/)
      expect(result).toHaveLength(1)
      expect(result[0].name).toBe('api-server')
    })
  })

  describe('active()', () => {
    test('returns active projects (default: 1 week, 1+ sessions)', () => {
      const result = filters.active(projects)
      expect(result).toHaveLength(3) // p1, p3, p4 (all recent with sessions)
    })

    test('uses custom hours threshold', () => {
      const result = filters.active(projects, { hours: 3 })
      expect(result).toHaveLength(2) // p1, p3
    })

    test('uses custom minSessions', () => {
      const result = filters.active(projects, { minSessions: 2 })
      expect(result).toHaveLength(2) // p3, p4
    })
  })

  describe('stale()', () => {
    test('returns stale projects (default: 30 days)', () => {
      const result = filters.stale(projects)
      expect(result).toHaveLength(1) // Only p2
    })

    test('uses custom hours threshold', () => {
      const result = filters.stale(projects, { hours: 5 })
      expect(result).toHaveLength(2) // p2 (30 days), p4 (6 hours > 5 threshold)
    })
  })

  describe('composite()', () => {
    test('combines multiple filters', async () => {
      const result = await filters.composite(projects, {
        types: ['node'],
        recentHours: 24,
        minSessions: 1
      })
      expect(result).toHaveLength(2) // p1, p4
    })

    test('handles all filter types', async () => {
      const result = await filters.composite(projects, {
        types: ['node', 'quarto'],
        tags: ['documentation'],
        recentHours: 24,
        minSessions: 2
      })
      expect(result).toHaveLength(1) // Only p3
    })

    test('returns empty for impossible criteria', async () => {
      const result = await filters.composite(projects, {
        types: ['nonexistent'],
        minSessions: 100
      })
      expect(result).toEqual([])
    })
  })

  describe('Top N Rankings', () => {
    test('topBySessions returns most active', () => {
      const result = filters.topBySessions(projects, 2)
      expect(result).toHaveLength(2)
      expect(result[0].name).toBe('api-server') // 10 sessions
      expect(result[1].name).toBe('docs-site') // 2 sessions
    })

    test('topByDuration returns longest worked', () => {
      const result = filters.topByDuration(projects, 2)
      expect(result).toHaveLength(2)
      expect(result[0].name).toBe('api-server') // 300 minutes
    })

    test('topByRecency returns most recent', () => {
      const result = filters.topByRecency(projects, 2)
      expect(result).toHaveLength(2)
      expect(result[0].name).toBe('docs-site') // 1 hour ago
      expect(result[1].name).toBe('flow-cli') // 2 hours ago
    })

    test('respects limit parameter', () => {
      const result = filters.topBySessions(projects, 1)
      expect(result).toHaveLength(1)
    })
  })

  describe('Edge Cases', () => {
    test('handles empty project array', () => {
      expect(filters.byType([], 'node')).toEqual([])
      expect(filters.active([])).toEqual([])
      expect(filters.topBySessions([])).toEqual([])
    })

    test('handles null project array', () => {
      expect(filters.byType(null, 'node')).toEqual([])
      expect(filters.byTags(null, 'tag')).toEqual([])
    })

    test('handles projects without tags', () => {
      const noTagsProjects = [projects[0], projects[1]] // p1, p2 have no tags
      const result = filters.byTags(noTagsProjects, 'any-tag')
      expect(result).toEqual([])
    })
  })
})

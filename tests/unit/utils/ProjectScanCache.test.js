/**
 * Tests for ProjectScanCache
 */

import { describe, test, expect, beforeEach } from '@jest/globals'
import { ProjectScanCache } from '../../../cli/utils/ProjectScanCache.js'

describe('ProjectScanCache', () => {
  let cache

  beforeEach(() => {
    cache = new ProjectScanCache({ ttl: 1000 }) // 1 second for testing
  })

  describe('Basic Operations', () => {
    test('creates cache with default options', () => {
      const defaultCache = new ProjectScanCache()
      expect(defaultCache.ttl).toBe(300000) // 5 minutes
      expect(defaultCache.maxSize).toBe(1000)
    })

    test('creates cache with custom options', () => {
      const customCache = new ProjectScanCache({ ttl: 60000, maxSize: 100 })
      expect(customCache.ttl).toBe(60000)
      expect(customCache.maxSize).toBe(100)
    })

    test('stores and retrieves projects', () => {
      const projects = [{ id: 'p1', name: 'Project 1' }]
      cache.set('/path/to/projects', projects)

      const cached = cache.get('/path/to/projects')
      expect(cached).toEqual(projects)
    })

    test('returns null for missing path', () => {
      const result = cache.get('/nonexistent')
      expect(result).toBeNull()
    })

    test('has() returns true for cached path', () => {
      cache.set('/path', [])
      expect(cache.has('/path')).toBe(true)
    })

    test('has() returns false for missing path', () => {
      expect(cache.has('/nonexistent')).toBe(false)
    })
  })

  describe('TTL and Expiration', () => {
    test('expires cache after TTL', async () => {
      cache.set('/path', [{ id: 'p1' }])

      // Wait for expiration
      await new Promise(resolve => setTimeout(resolve, 1100))

      const result = cache.get('/path')
      expect(result).toBeNull()
    })

    test('has() returns false for expired entry', async () => {
      cache.set('/path', [])

      await new Promise(resolve => setTimeout(resolve, 1100))

      expect(cache.has('/path')).toBe(false)
    })

    test('returns valid cache before expiration', async () => {
      const projects = [{ id: 'p1' }]
      cache.set('/path', projects)

      // Wait half the TTL
      await new Promise(resolve => setTimeout(resolve, 500))

      const result = cache.get('/path')
      expect(result).toEqual(projects)
    })

    test('getTimeToExpire returns remaining time', () => {
      cache.set('/path', [])

      const timeLeft = cache.getTimeToExpire('/path')
      expect(timeLeft).toBeGreaterThan(0)
      expect(timeLeft).toBeLessThanOrEqual(1000)
    })

    test('getTimeToExpire returns null for missing path', () => {
      expect(cache.getTimeToExpire('/nonexistent')).toBeNull()
    })
  })

  describe('Invalidation and Cleanup', () => {
    test('invalidate() removes specific entry', () => {
      cache.set('/path1', [{ id: 'p1' }])
      cache.set('/path2', [{ id: 'p2' }])

      cache.invalidate('/path1')

      expect(cache.get('/path1')).toBeNull()
      expect(cache.get('/path2')).not.toBeNull()
    })

    test('clear() removes all entries', () => {
      cache.set('/path1', [])
      cache.set('/path2', [])

      cache.clear()

      expect(cache.get('/path1')).toBeNull()
      expect(cache.get('/path2')).toBeNull()
    })

    test('clear() resets statistics', () => {
      cache.set('/path', [])
      cache.get('/path') // Hit
      cache.get('/missing') // Miss

      cache.clear()

      const stats = cache.getStats()
      expect(stats.hits).toBe(0)
      expect(stats.misses).toBe(0)
      expect(stats.sets).toBe(0)
    })

    test('cleanup() removes expired entries', async () => {
      cache.set('/path1', [])
      cache.set('/path2', [])

      // Wait for expiration
      await new Promise(resolve => setTimeout(resolve, 1100))

      const removed = cache.cleanup()
      expect(removed).toBe(2)
    })

    test('cleanup() keeps valid entries', async () => {
      cache.set('/path1', [])

      await new Promise(resolve => setTimeout(resolve, 500))

      cache.set('/path2', []) // Fresh entry

      await new Promise(resolve => setTimeout(resolve, 600))

      const removed = cache.cleanup()
      expect(removed).toBe(1) // Only path1 expired

      expect(cache.get('/path1')).toBeNull()
      expect(cache.get('/path2')).not.toBeNull()
    })
  })

  describe('Statistics and Metrics', () => {
    test('tracks cache hits', () => {
      cache.set('/path', [])
      cache.get('/path') // Hit
      cache.get('/path') // Hit

      const stats = cache.getStats()
      expect(stats.hits).toBe(2)
    })

    test('tracks cache misses', () => {
      cache.get('/missing1') // Miss
      cache.get('/missing2') // Miss

      const stats = cache.getStats()
      expect(stats.misses).toBe(2)
    })

    test('calculates hit rate', () => {
      cache.set('/path', [])
      cache.get('/path') // Hit
      cache.get('/missing') // Miss

      const stats = cache.getStats()
      expect(stats.hitRateNumeric).toBe(50) // 1 hit, 1 miss = 50%
    })

    test('tracks set operations', () => {
      cache.set('/path1', [])
      cache.set('/path2', [])

      const stats = cache.getStats()
      expect(stats.sets).toBe(2)
    })

    test('tracks cache size', () => {
      cache.set('/path1', [])
      cache.set('/path2', [])

      const stats = cache.getStats()
      expect(stats.size).toBe(2)
    })

    test('getSizeMetrics returns entry and project counts', () => {
      cache.set('/path1', [{ id: 'p1' }, { id: 'p2' }])
      cache.set('/path2', [{ id: 'p3' }])

      const metrics = cache.getSizeMetrics()
      expect(metrics.entries).toBe(2)
      expect(metrics.totalProjects).toBe(3)
    })

    test('getSizeMetrics estimates memory usage', () => {
      cache.set('/path', [{ id: 'p1' }, { id: 'p2' }])

      const metrics = cache.getSizeMetrics()
      expect(parseFloat(metrics.estimatedMemoryKB)).toBeGreaterThan(0)
    })
  })

  describe('Size Limits and Eviction', () => {
    test('enforces maxSize limit', () => {
      const smallCache = new ProjectScanCache({ maxSize: 3 })

      smallCache.set('/path1', [])
      smallCache.set('/path2', [])
      smallCache.set('/path3', [])
      smallCache.set('/path4', []) // Triggers eviction

      const stats = smallCache.getStats()
      expect(stats.size).toBe(3)
    })

    test('evicts oldest entry (LRU)', () => {
      const smallCache = new ProjectScanCache({ maxSize: 2 })

      smallCache.set('/path1', [])
      smallCache.set('/path2', [])
      smallCache.set('/path3', []) // Should evict path1

      expect(smallCache.get('/path1')).toBeNull()
      expect(smallCache.get('/path2')).not.toBeNull()
      expect(smallCache.get('/path3')).not.toBeNull()
    })

    test('tracks evictions', () => {
      const smallCache = new ProjectScanCache({ maxSize: 2 })

      smallCache.set('/path1', [])
      smallCache.set('/path2', [])
      smallCache.set('/path3', [])

      const stats = smallCache.getStats()
      expect(stats.evictions).toBe(1)
    })
  })

  describe('getCachedPaths()', () => {
    test('returns all cached paths', () => {
      cache.set('/path1', [])
      cache.set('/path2', [])
      cache.set('/path3', [])

      const paths = cache.getCachedPaths()
      expect(paths).toHaveLength(3)
      expect(paths).toContain('/path1')
      expect(paths).toContain('/path2')
      expect(paths).toContain('/path3')
    })

    test('returns empty array when cache is empty', () => {
      expect(cache.getCachedPaths()).toEqual([])
    })
  })

  describe('Edge Cases', () => {
    test('handles empty project arrays', () => {
      cache.set('/path', [])

      const result = cache.get('/path')
      expect(result).toEqual([])
    })

    test('handles large project arrays', () => {
      const largeArray = Array.from({ length: 1000 }, (_, i) => ({
        id: `p${i}`,
        name: `Project ${i}`
      }))

      cache.set('/path', largeArray)

      const result = cache.get('/path')
      expect(result).toHaveLength(1000)
    })

    test('handles multiple gets without increment', () => {
      cache.set('/path', [{ id: 'p1' }])

      const result1 = cache.get('/path')
      const result2 = cache.get('/path')

      // Should return same data
      expect(result1).toEqual(result2)
    })

    test('handles rapid set/get operations', () => {
      for (let i = 0; i < 100; i++) {
        cache.set(`/path${i}`, [{ id: `p${i}` }])
      }

      // Cache should enforce maxSize
      const stats = cache.getStats()
      expect(stats.size).toBeLessThanOrEqual(cache.maxSize)
    })

    test('handles same path multiple sets (update)', () => {
      cache.set('/path', [{ id: 'p1' }])
      cache.set('/path', [{ id: 'p2' }])

      const result = cache.get('/path')
      expect(result).toEqual([{ id: 'p2' }])
    })
  })

  describe('Real-world Scenarios', () => {
    test('typical scan-cache workflow', () => {
      const projects1 = [{ id: 'p1', name: 'flow-cli' }]
      const projects2 = [{ id: 'p2', name: 'zsh-config' }]

      // First scan
      cache.set('/home/user/projects', projects1)
      expect(cache.get('/home/user/projects')).toEqual(projects1)

      // Second path
      cache.set('/home/user/dev', projects2)
      expect(cache.get('/home/user/dev')).toEqual(projects2)

      // Both should be cached
      expect(cache.getCachedPaths()).toHaveLength(2)
    })

    test('cache hit rate improves with repeated access', () => {
      cache.set('/path', [])

      // First access - miss
      cache.get('/nonexistent')

      // Multiple hits
      cache.get('/path')
      cache.get('/path')
      cache.get('/path')

      const stats = cache.getStats()
      expect(stats.hitRateNumeric).toBe(75) // 3 hits, 1 miss
    })
  })
})

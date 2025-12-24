/**
 * Tests for MRUTracker
 */

import { describe, test, expect, beforeEach } from '@jest/globals'
import { MRUTracker } from '../../../cli/utils/MRUTracker.js'

describe('MRUTracker', () => {
  let tracker

  beforeEach(() => {
    tracker = new MRUTracker({ maxSize: 5 })
  })

  describe('Basic Operations', () => {
    test('creates tracker with default options', () => {
      const defaultTracker = new MRUTracker()
      expect(defaultTracker.maxSize).toBe(50)
    })

    test('creates tracker with custom maxSize', () => {
      const customTracker = new MRUTracker({ maxSize: 20 })
      expect(customTracker.maxSize).toBe(20)
    })

    test('tracks project access', () => {
      tracker.access('project-1')
      expect(tracker.has('project-1')).toBe(true)
    })

    test('returns most recent project', () => {
      tracker.access('project-1')
      tracker.access('project-2')

      const recent = tracker.getRecent(1)
      expect(recent).toEqual(['project-2'])
    })

    test('returns multiple recent projects', () => {
      tracker.access('project-1')
      tracker.access('project-2')
      tracker.access('project-3')

      const recent = tracker.getRecent(3)
      expect(recent).toEqual(['project-3', 'project-2', 'project-1'])
    })
  })

  describe('Access Order', () => {
    test('moves accessed project to most recent', () => {
      tracker.access('project-1')
      tracker.access('project-2')
      tracker.access('project-3')
      tracker.access('project-1') // Re-access

      const recent = tracker.getRecent(3)
      expect(recent).toEqual(['project-1', 'project-3', 'project-2'])
    })

    test('maintains correct order after multiple accesses', () => {
      tracker.access('a')
      tracker.access('b')
      tracker.access('c')
      tracker.access('b') // Move b to top
      tracker.access('a') // Move a to top

      expect(tracker.getRecent()).toEqual(['a', 'b', 'c'])
    })
  })

  describe('Metadata Support', () => {
    test('stores metadata with access', () => {
      tracker.access('project-1', { branch: 'main', task: 'Fix bug' })

      const recent = tracker.getRecentWithMetadata(1)
      expect(recent[0].projectId).toBe('project-1')
      expect(recent[0].branch).toBe('main')
      expect(recent[0].task).toBe('Fix bug')
    })

    test('includes timestamp in metadata', () => {
      const beforeAccess = Date.now()
      tracker.access('project-1')
      const afterAccess = Date.now()

      const recent = tracker.getRecentWithMetadata(1)
      expect(recent[0].timestamp).toBeGreaterThanOrEqual(beforeAccess)
      expect(recent[0].timestamp).toBeLessThanOrEqual(afterAccess)
    })

    test('updates metadata on re-access', () => {
      tracker.access('project-1', { version: 1 })
      tracker.access('project-1', { version: 2 })

      const recent = tracker.getRecentWithMetadata(1)
      expect(recent[0].version).toBe(2)
    })
  })

  describe('Size Limits and Eviction', () => {
    test('enforces maxSize limit', () => {
      tracker.access('p1')
      tracker.access('p2')
      tracker.access('p3')
      tracker.access('p4')
      tracker.access('p5')
      tracker.access('p6') // Exceeds maxSize

      expect(tracker.size()).toBe(5)
    })

    test('evicts oldest entry (LRU)', () => {
      tracker.access('p1')
      tracker.access('p2')
      tracker.access('p3')
      tracker.access('p4')
      tracker.access('p5')
      tracker.access('p6') // Should evict p1

      expect(tracker.has('p1')).toBe(false)
      expect(tracker.has('p6')).toBe(true)
    })

    test('evicts correct order with multiple overflows', () => {
      tracker.access('p1')
      tracker.access('p2')
      tracker.access('p3')
      tracker.access('p4')
      tracker.access('p5')
      tracker.access('p6') // Evicts p1
      tracker.access('p7') // Evicts p2

      expect(tracker.has('p1')).toBe(false)
      expect(tracker.has('p2')).toBe(false)
      expect(tracker.has('p3')).toBe(true)
    })
  })

  describe('Position Tracking', () => {
    test('getPosition returns correct position', () => {
      tracker.access('p1')
      tracker.access('p2')
      tracker.access('p3')

      expect(tracker.getPosition('p3')).toBe(0) // Most recent
      expect(tracker.getPosition('p2')).toBe(1)
      expect(tracker.getPosition('p1')).toBe(2)
    })

    test('getPosition returns -1 for missing project', () => {
      expect(tracker.getPosition('nonexistent')).toBe(-1)
    })

    test('getPosition updates after re-access', () => {
      tracker.access('p1')
      tracker.access('p2')
      tracker.access('p3')
      tracker.access('p1') // Move to position 0

      expect(tracker.getPosition('p1')).toBe(0)
      expect(tracker.getPosition('p3')).toBe(1)
      expect(tracker.getPosition('p2')).toBe(2)
    })
  })

  describe('Removal and Clearing', () => {
    test('remove() deletes specific entry', () => {
      tracker.access('p1')
      tracker.access('p2')

      const removed = tracker.remove('p1')
      expect(removed).toBe(true)
      expect(tracker.has('p1')).toBe(false)
      expect(tracker.size()).toBe(1)
    })

    test('remove() returns false for missing entry', () => {
      const removed = tracker.remove('nonexistent')
      expect(removed).toBe(false)
    })

    test('clear() removes all entries', () => {
      tracker.access('p1')
      tracker.access('p2')
      tracker.access('p3')

      tracker.clear()

      expect(tracker.size()).toBe(0)
      expect(tracker.getAll()).toEqual([])
    })
  })

  describe('Serialization', () => {
    test('toJSON exports state', () => {
      tracker.access('p1')
      tracker.access('p2')

      const json = tracker.toJSON()
      expect(json.maxSize).toBe(5)
      expect(json.entries).toHaveLength(2)
    })

    test('fromJSON restores state', () => {
      tracker.access('p1')
      tracker.access('p2', { task: 'Test' })

      const json = tracker.toJSON()
      const restored = MRUTracker.fromJSON(json)

      expect(restored.size()).toBe(2)
      expect(restored.getRecent()).toEqual(['p2', 'p1'])
      const withMeta = restored.getRecentWithMetadata(1)
      expect(withMeta[0].task).toBe('Test')
    })

    test('roundtrip preserves order', () => {
      tracker.access('a')
      tracker.access('b')
      tracker.access('c')

      const json = tracker.toJSON()
      const restored = MRUTracker.fromJSON(json)

      expect(restored.getRecent()).toEqual(['c', 'b', 'a'])
    })
  })

  describe('Statistics', () => {
    test('getStats returns basic stats', () => {
      tracker.access('p1')
      tracker.access('p2')

      const stats = tracker.getStats()
      expect(stats.size).toBe(2)
      expect(stats.maxSize).toBe(5)
    })

    test('getStats calculates age metrics', () => {
      tracker.access('p1')

      const stats = tracker.getStats()
      expect(stats.oldestAge).toBeGreaterThanOrEqual(0)
      expect(stats.newestAge).toBeGreaterThanOrEqual(0)
      expect(stats.averageAge).toBeGreaterThanOrEqual(0)
    })

    test('getStats handles empty tracker', () => {
      const stats = tracker.getStats()
      expect(stats.size).toBe(0)
      expect(stats.oldestAge).toBe(0)
      expect(stats.newestAge).toBe(0)
      expect(stats.averageAge).toBe(0)
    })
  })

  describe('Cleanup', () => {
    test('cleanup() removes old entries', async () => {
      tracker.access('p1')
      await new Promise(resolve => setTimeout(resolve, 100))
      tracker.access('p2')

      const removed = tracker.cleanup(50) // 50ms threshold
      expect(removed).toBe(1)
      expect(tracker.has('p1')).toBe(false)
      expect(tracker.has('p2')).toBe(true)
    })

    test('cleanup() keeps recent entries', async () => {
      tracker.access('p1')
      tracker.access('p2')

      const removed = tracker.cleanup(1000) // 1 second threshold
      expect(removed).toBe(0)
      expect(tracker.size()).toBe(2)
    })
  })

  describe('Merge', () => {
    test('merge() combines two trackers (latest strategy)', async () => {
      tracker.access('p1', { version: 1 })
      await new Promise(resolve => setTimeout(resolve, 10))
      tracker.access('p2')

      const other = new MRUTracker({ maxSize: 5 })
      await new Promise(resolve => setTimeout(resolve, 10))
      other.access('p1', { version: 2 })
      other.access('p3')

      tracker.merge(other, 'latest')

      expect(tracker.size()).toBe(3)
      expect(tracker.has('p3')).toBe(true)
      const meta = tracker.getRecentWithMetadata().find(e => e.projectId === 'p1')
      expect(meta.version).toBe(2) // Latest version
    })

    test('merge() keeps existing (keep strategy)', () => {
      tracker.access('p1', { version: 1 })
      tracker.access('p2')

      const other = new MRUTracker({ maxSize: 5 })
      other.access('p1', { version: 2 })
      other.access('p3')

      tracker.merge(other, 'keep')

      const meta = tracker.getRecentWithMetadata().find(e => e.projectId === 'p1')
      expect(meta.version).toBe(1) // Kept existing
    })

    test('merge() enforces size limit', () => {
      for (let i = 0; i < 5; i++) {
        tracker.access(`p${i}`)
      }

      const other = new MRUTracker({ maxSize: 5 })
      for (let i = 5; i < 10; i++) {
        other.access(`p${i}`)
      }

      tracker.merge(other)

      expect(tracker.size()).toBe(5) // maxSize enforced
    })
  })

  describe('getAll()', () => {
    test('returns all project IDs', () => {
      tracker.access('p1')
      tracker.access('p2')
      tracker.access('p3')

      expect(tracker.getAll()).toEqual(['p3', 'p2', 'p1'])
    })

    test('returns empty array when empty', () => {
      expect(tracker.getAll()).toEqual([])
    })
  })

  describe('Edge Cases', () => {
    test('handles single entry', () => {
      tracker.access('p1')

      expect(tracker.getRecent(1)).toEqual(['p1'])
      expect(tracker.size()).toBe(1)
    })

    test('handles accessing same project repeatedly', () => {
      tracker.access('p1')
      tracker.access('p1')
      tracker.access('p1')

      expect(tracker.size()).toBe(1)
      expect(tracker.getRecent()).toEqual(['p1'])
    })

    test('handles maxSize of 1', () => {
      const tiny = new MRUTracker({ maxSize: 1 })
      tiny.access('p1')
      tiny.access('p2')

      expect(tiny.size()).toBe(1)
      expect(tiny.has('p1')).toBe(false)
      expect(tiny.has('p2')).toBe(true)
    })

    test('handles requesting more than available', () => {
      tracker.access('p1')
      tracker.access('p2')

      const result = tracker.getRecent(10)
      expect(result).toHaveLength(2)
    })
  })

  describe('Real-world Scenarios', () => {
    test('typical project switching workflow', () => {
      // User works on multiple projects
      tracker.access('flow-cli', { task: 'Implement caching' })
      tracker.access('docs-site', { task: 'Update guides' })
      tracker.access('zsh-config', { task: 'Add aliases' })
      tracker.access('flow-cli', { task: 'Write tests' }) // Switch back

      // Most recent should be flow-cli
      const recent = tracker.getRecent(1)
      expect(recent[0]).toBe('flow-cli')

      // Should have 3 unique projects
      expect(tracker.size()).toBe(3)
    })

    test('project picker optimization', () => {
      // Create tracker with larger size for this test
      const bigTracker = new MRUTracker({ maxSize: 50 })

      // Simulate 20 recent projects
      for (let i = 0; i < 20; i++) {
        bigTracker.access(`project-${i}`)
      }

      // Get top 10 for picker
      const top10 = bigTracker.getRecent(10)
      expect(top10).toHaveLength(10)
      expect(top10[0]).toBe('project-19') // Most recent
    })
  })
})

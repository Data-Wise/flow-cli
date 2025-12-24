/**
 * Integration Tests for Parallel Scanning with Caching
 */

import { describe, test, expect, beforeEach, afterEach } from '@jest/globals'
import { promises as fs } from 'fs'
import { join } from 'path'
import os from 'os'
import { FileSystemProjectRepository } from '../../cli/adapters/repositories/FileSystemProjectRepository.js'
import { ProjectType } from '../../cli/domain/value-objects/ProjectType.js'

describe('Parallel Scanning with Caching (Integration)', () => {
  let tempDir
  let repository
  let projectsFile

  beforeEach(async () => {
    // Create temp directory for test projects
    // Use PID + timestamp + random to ensure uniqueness in parallel execution
    const uniqueId = `${process.pid}-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`
    tempDir = join(os.tmpdir(), `flow-cli-test-${uniqueId}`)
    await fs.mkdir(tempDir, { recursive: true })

    // Create temp file for projects.json
    projectsFile = join(tempDir, 'projects.json')

    // Initialize repository with short TTL for testing
    repository = new FileSystemProjectRepository(projectsFile, null, { ttl: 2000 })
  })

  afterEach(async () => {
    // Cleanup
    try {
      await fs.rm(tempDir, { recursive: true, force: true })
    } catch {}
  })

  describe('Parallel Scanning', () => {
    test('scans multiple directories in parallel', async () => {
      // Create test projects
      const dir1 = join(tempDir, 'projects1')
      const dir2 = join(tempDir, 'projects2')
      await fs.mkdir(dir1, { recursive: true })
      await fs.mkdir(dir2, { recursive: true })

      // Create Node project in dir1
      await fs.mkdir(join(dir1, 'node-app'), { recursive: true })
      await fs.writeFile(join(dir1, 'node-app', 'package.json'), '{}')

      // Create R package in dir2
      await fs.mkdir(join(dir2, 'r-pkg'), { recursive: true })
      await fs.writeFile(join(dir2, 'r-pkg', 'DESCRIPTION'), '')

      // Scan in parallel
      const startTime = Date.now()
      const results = await repository.scanParallel([dir1, dir2])
      const duration = Date.now() - startTime

      expect(results.size).toBe(2)
      expect(results.get(dir1)).toHaveLength(1)
      expect(results.get(dir2)).toHaveLength(1)
      expect(results.get(dir1)[0].type.value).toBe(ProjectType.NODE)
      expect(results.get(dir2)[0].type.value).toBe(ProjectType.R_PACKAGE)

      // Should be fast (parallel)
      expect(duration).toBeLessThan(1000)
    })

    test('handles empty directories in parallel scan', async () => {
      const dir1 = join(tempDir, 'empty1')
      const dir2 = join(tempDir, 'empty2')
      await fs.mkdir(dir1, { recursive: true })
      await fs.mkdir(dir2, { recursive: true })

      const results = await repository.scanParallel([dir1, dir2])

      expect(results.size).toBe(2)
      expect(results.get(dir1)).toEqual([])
      expect(results.get(dir2)).toEqual([])
    })
  })

  describe('Caching Behavior', () => {
    test('caches scan results', async () => {
      // Create test project
      const projectsDir = join(tempDir, 'projects')
      await fs.mkdir(projectsDir, { recursive: true })
      await fs.mkdir(join(projectsDir, 'test-app'))
      await fs.writeFile(join(projectsDir, 'test-app', 'package.json'), '{}')

      // First scan (cache miss)
      const result1 = await repository.scan(projectsDir)
      expect(result1).toHaveLength(1)

      const stats1 = repository.getCacheStats()
      expect(stats1.sets).toBe(1)
      expect(stats1.misses).toBeGreaterThan(0)

      // Second scan (cache hit)
      const result2 = await repository.scan(projectsDir)
      expect(result2).toHaveLength(1)

      const stats2 = repository.getCacheStats()
      expect(stats2.hits).toBeGreaterThan(0)

      // Results should be identical
      expect(result2[0].name).toBe(result1[0].name)
    })

    test('force refresh bypasses cache', async () => {
      const projectsDir = join(tempDir, 'projects')
      await fs.mkdir(projectsDir, { recursive: true })
      await fs.mkdir(join(projectsDir, 'app1'))
      await fs.writeFile(join(projectsDir, 'app1', 'package.json'), '{}')

      // First scan
      await repository.scan(projectsDir)
      const stats1 = repository.getCacheStats()

      // Force refresh
      await repository.scan(projectsDir, { forceRefresh: true })
      const stats2 = repository.getCacheStats()

      // Should have more sets (forced new scan)
      expect(stats2.sets).toBeGreaterThan(stats1.sets)
    })

    test('cache expires after TTL', async () => {
      const projectsDir = join(tempDir, 'projects')
      await fs.mkdir(projectsDir, { recursive: true })
      await fs.mkdir(join(projectsDir, 'app1'))
      await fs.writeFile(join(projectsDir, 'app1', 'package.json'), '{}')

      // First scan
      await repository.scan(projectsDir)

      // Wait for cache expiration (TTL is 2000ms in test)
      await new Promise(resolve => setTimeout(resolve, 2100))

      // Ensure directory still exists before second scan (in case of cleanup race)
      await fs.mkdir(projectsDir, { recursive: true })
      await fs.mkdir(join(projectsDir, 'app1'), { recursive: true })
      await fs.writeFile(join(projectsDir, 'app1', 'package.json'), '{}')

      // Scan again (should be cache miss due to expiration)
      await repository.scan(projectsDir)
      const stats = repository.getCacheStats()

      // Should have 2 sets (expired cache doesn't count as hit)
      expect(stats.sets).toBe(2)
    }, 10000)

    test('useCache=false bypasses cache', async () => {
      const projectsDir = join(tempDir, 'projects')
      await fs.mkdir(projectsDir, { recursive: true })
      await fs.mkdir(join(projectsDir, 'app1'))
      await fs.writeFile(join(projectsDir, 'app1', 'package.json'), '{}')

      // Scan with caching disabled
      await repository.scan(projectsDir, { useCache: false })
      const stats1 = repository.getCacheStats()

      // Should have 0 sets (caching disabled)
      expect(stats1.sets).toBe(0)

      // Second scan with caching disabled
      await repository.scan(projectsDir, { useCache: false })
      const stats2 = repository.getCacheStats()

      // Still 0 sets, 0 hits
      expect(stats2.sets).toBe(0)
      expect(stats2.hits).toBe(0)
    })

    test('clearCache removes all cached entries', async () => {
      const dir1 = join(tempDir, 'dir1')
      const dir2 = join(tempDir, 'dir2')
      await fs.mkdir(dir1, { recursive: true })
      await fs.mkdir(dir2, { recursive: true })

      // Scan both directories
      await repository.scan(dir1)
      await repository.scan(dir2)

      const stats1 = repository.getCacheStats()
      expect(stats1.size).toBe(2)

      // Clear cache
      repository.clearCache()

      const stats2 = repository.getCacheStats()
      expect(stats2.size).toBe(0)
      expect(stats2.hits).toBe(0)
      expect(stats2.misses).toBe(0)
    })

    test('invalidateCache removes specific entry', async () => {
      const dir1 = join(tempDir, 'dir1')
      const dir2 = join(tempDir, 'dir2')
      await fs.mkdir(dir1, { recursive: true })
      await fs.mkdir(dir2, { recursive: true })

      // Scan both
      await repository.scan(dir1)
      await repository.scan(dir2)

      // Invalidate dir1 only
      repository.invalidateCache(dir1)

      // dir1 should be cache miss, dir2 should be cache hit
      await repository.scan(dir1)
      await repository.scan(dir2)

      const stats = repository.getCacheStats()
      expect(stats.hits).toBeGreaterThan(0) // dir2 hit
      expect(stats.sets).toBeGreaterThan(2) // dir1 re-scanned
    })
  })

  describe('Progress Callback', () => {
    test('calls progress callback for each project found', async () => {
      const projectsDir = join(tempDir, 'projects')
      await fs.mkdir(projectsDir, { recursive: true })

      // Create 3 projects
      await fs.mkdir(join(projectsDir, 'app1'))
      await fs.writeFile(join(projectsDir, 'app1', 'package.json'), '{}')

      await fs.mkdir(join(projectsDir, 'app2'))
      await fs.writeFile(join(projectsDir, 'app2', 'package.json'), '{}')

      await fs.mkdir(join(projectsDir, 'app3'))
      await fs.writeFile(join(projectsDir, 'app3', 'package.json'), '{}')

      const progressCalls = []
      await repository.scan(projectsDir, {
        progressCallback: project => progressCalls.push(project.name)
      })

      expect(progressCalls).toHaveLength(3)
      expect(progressCalls).toContain('app1')
      expect(progressCalls).toContain('app2')
      expect(progressCalls).toContain('app3')
    })
  })

  describe('Performance', () => {
    test('parallel scanning completes successfully', async () => {
      // Create 5 directories with projects
      const dirs = []
      for (let i = 1; i <= 5; i++) {
        const dir = join(tempDir, `dir${i}`)
        dirs.push(dir)
        await fs.mkdir(dir, { recursive: true })

        // Add 2 projects per directory
        await fs.mkdir(join(dir, `app${i}-1`))
        await fs.writeFile(join(dir, `app${i}-1`, 'package.json'), '{}')

        await fs.mkdir(join(dir, `app${i}-2`))
        await fs.writeFile(join(dir, `app${i}-2`, 'package.json'), '{}')
      }

      // Parallel scan
      const results = await repository.scanParallel(dirs)

      // Verify all directories scanned
      expect(results.size).toBe(5)
      for (const [path, projects] of results) {
        expect(projects).toHaveLength(2)
        expect(projects.every(p => p.type.value === 'node')).toBe(true)
      }
    })
  })

  describe('Cache Statistics', () => {
    test('getCacheStats returns accurate statistics', async () => {
      const dir1 = join(tempDir, 'dir1')
      await fs.mkdir(dir1, { recursive: true })
      await fs.mkdir(join(dir1, 'app1'))
      await fs.writeFile(join(dir1, 'app1', 'package.json'), '{}')

      // Cache miss
      await repository.scan(dir1)

      // Cache hit
      await repository.scan(dir1)
      await repository.scan(dir1)

      const stats = repository.getCacheStats()

      expect(stats.sets).toBe(1)
      expect(stats.hits).toBe(2)
      expect(stats.misses).toBeGreaterThan(0)
      expect(stats.size).toBe(1)
      expect(stats.hitRateNumeric).toBeGreaterThan(0)
    })
  })
})

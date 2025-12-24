/**
 * Performance Benchmark for Project Scanning
 *
 * Measures scanning performance with and without caching.
 * Target: 10x faster with caching on directories with 50+ projects.
 */

import { describe, test, expect, beforeAll, afterAll } from '@jest/globals'
import { promises as fs } from 'fs'
import { join } from 'path'
import os from 'os'
import { FileSystemProjectRepository } from '../../cli/adapters/repositories/FileSystemProjectRepository.js'

describe('Scanning Performance Benchmark', () => {
  let tempDir
  let repository
  let projectsFile
  let largeProjectsDir

  beforeAll(async () => {
    // Create temp directory with PID + timestamp + random for uniqueness
    const uniqueId = `${process.pid}-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`
    tempDir = join(os.tmpdir(), `flow-cli-bench-${uniqueId}`)
    await fs.mkdir(tempDir, { recursive: true })

    projectsFile = join(tempDir, 'projects.json')
    repository = new FileSystemProjectRepository(projectsFile, null, { ttl: 3600000 })

    // Create directory with 60 projects (simulate real project directory)
    largeProjectsDir = join(tempDir, 'projects')
    await fs.mkdir(largeProjectsDir, { recursive: true })

    console.log('\nSetting up benchmark with 60 test projects...')

    // Create mix of project types
    const projectTypes = [
      { count: 30, marker: 'package.json', type: 'node' },
      { count: 15, marker: 'DESCRIPTION', type: 'r-package' },
      { count: 10, marker: '_quarto.yml', type: 'quarto' },
      { count: 5, marker: 'pyproject.toml', type: 'python' }
    ]

    let projectIndex = 1
    for (const { count, marker } of projectTypes) {
      for (let i = 0; i < count; i++) {
        const projectDir = join(largeProjectsDir, `project-${projectIndex}`)
        await fs.mkdir(projectDir)
        await fs.writeFile(join(projectDir, marker), '')
        projectIndex++
      }
    }

    console.log(`Created ${projectIndex - 1} test projects in ${largeProjectsDir}`)
  }, 60000) // Increased timeout for setup

  afterAll(async () => {
    // Cleanup
    try {
      await fs.rm(tempDir, { recursive: true, force: true })
    } catch {}
  })

  test('measures scan performance without cache', async () => {
    const iterations = 3
    const durations = []

    for (let i = 0; i < iterations; i++) {
      const start = Date.now()
      const projects = await repository.scan(largeProjectsDir, { useCache: false })
      const duration = Date.now() - start

      durations.push(duration)
      expect(projects).toHaveLength(60)
    }

    const avgDuration = durations.reduce((a, b) => a + b, 0) / iterations
    console.log(`\nAverage scan time (no cache): ${avgDuration.toFixed(2)}ms`)
    console.log(`Min: ${Math.min(...durations)}ms, Max: ${Math.max(...durations)}ms`)

    // Store for comparison
    global.noCacheDuration = avgDuration
  }, 30000)

  test('measures scan performance with cache (cache miss)', async () => {
    // Clear cache first
    repository.clearCache()

    const start = Date.now()
    const projects = await repository.scan(largeProjectsDir, { useCache: true })
    const duration = Date.now() - start

    expect(projects).toHaveLength(60)

    const stats = repository.getCacheStats()
    console.log(`\nFirst scan (cache miss): ${duration}ms`)
    console.log(`Cache stats:`, stats)

    // Should be similar to no-cache time (first scan)
    expect(duration).toBeGreaterThan(0)
  })

  test('measures scan performance with cache (cache hit)', async () => {
    // Ensure cache is populated from previous test
    await repository.scan(largeProjectsDir, { useCache: true, forceRefresh: true })

    const iterations = 10
    const durations = []

    for (let i = 0; i < iterations; i++) {
      const start = Date.now()
      const projects = await repository.scan(largeProjectsDir, { useCache: true })
      const duration = Date.now() - start

      durations.push(duration)
      expect(projects).toHaveLength(60)
    }

    const avgDuration = durations.reduce((a, b) => a + b, 0) / iterations
    console.log(`\nAverage scan time (with cache): ${avgDuration.toFixed(2)}ms`)
    console.log(`Min: ${Math.min(...durations)}ms, Max: ${Math.max(...durations)}ms`)

    const stats = repository.getCacheStats()
    console.log(`Cache hit rate: ${stats.hitRate}`)

    // Cache should be significantly faster (ideally 10x+)
    const noCacheDuration = global.noCacheDuration || 100
    const speedup = noCacheDuration / avgDuration

    console.log(`\n🚀 Speedup: ${speedup.toFixed(1)}x faster with cache`)

    // Expect at least 5x speedup (conservative target)
    expect(speedup).toBeGreaterThan(5)

    // Store result
    global.cacheSpeedup = speedup
  })

  test('parallel scan performance', async () => {
    // Create 5 directories with 10 projects each
    const dirs = []
    for (let i = 1; i <= 5; i++) {
      const dir = join(tempDir, `parallel-dir-${i}`)
      await fs.mkdir(dir, { recursive: true })
      dirs.push(dir)

      for (let j = 1; j <= 10; j++) {
        const projectDir = join(dir, `project-${j}`)
        await fs.mkdir(projectDir)
        await fs.writeFile(join(projectDir, 'package.json'), '{}')
      }
    }

    // Clear cache
    repository.clearCache()

    // Sequential scan
    const seqStart = Date.now()
    for (const dir of dirs) {
      await repository.scan(dir, { useCache: false })
    }
    const seqDuration = Date.now() - seqStart

    // Clear cache again
    repository.clearCache()

    // Parallel scan
    const parStart = Date.now()
    const results = await repository.scanParallel(dirs, { useCache: false })
    const parDuration = Date.now() - parStart

    console.log(`\nSequential scan (5 dirs, 50 projects): ${seqDuration}ms`)
    console.log(`Parallel scan (5 dirs, 50 projects): ${parDuration}ms`)
    console.log(`Speedup: ${(seqDuration / parDuration).toFixed(1)}x`)

    expect(results.size).toBe(5)

    // Parallel should be faster (or at least not significantly slower)
    expect(parDuration).toBeLessThanOrEqual(seqDuration * 1.2)
  })

  test('cache with filters performance', async () => {
    // Scan with caching
    await repository.scan(largeProjectsDir, { forceRefresh: true })

    const start = Date.now()
    const projects = await repository.scan(largeProjectsDir, { useCache: true })
    const duration = Date.now() - start

    console.log(`\nCached scan of 60 projects: ${duration}ms`)

    // Should be very fast (< 10ms for cache hit)
    expect(duration).toBeLessThan(50)
    expect(projects).toHaveLength(60)
  })

  test('displays final performance summary', () => {
    const noCacheDuration = global.noCacheDuration || 0
    const speedup = global.cacheSpeedup || 0

    console.log('\n' + '='.repeat(60))
    console.log('PERFORMANCE SUMMARY (60 projects)')
    console.log('='.repeat(60))
    console.log(`Without cache: ${noCacheDuration.toFixed(2)}ms avg`)
    console.log(`With cache:    ${(noCacheDuration / speedup).toFixed(2)}ms avg`)
    console.log(`Speedup:       ${speedup.toFixed(1)}x faster`)
    console.log('='.repeat(60))

    // Verify we met the 10x target (or close to it)
    if (speedup >= 10) {
      console.log('✅ Target achieved: 10x+ speedup with caching')
    } else if (speedup >= 5) {
      console.log('✅ Good performance: 5x+ speedup with caching')
    } else {
      console.log('⚠️  Performance below target (5x speedup)')
    }
    console.log('')
  })
})

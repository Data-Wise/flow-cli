/**
 * Integration tests for FileSystemSessionRepository
 *
 * These tests use actual file system I/O (in a temp directory)
 */

import { promises as fs } from 'fs'
import { join } from 'path'
import { tmpdir } from 'os'
import { FileSystemSessionRepository } from '../../cli/adapters/repositories/FileSystemSessionRepository.js'
import { Session } from '../../cli/domain/entities/Session.js'

describe('FileSystemSessionRepository Integration', () => {
  let repo
  let testDir
  let testFile

  beforeEach(async () => {
    // Create temp directory for each test with PID + timestamp + random to avoid collisions
    const uniqueId = `${process.pid}-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`
    testDir = join(tmpdir(), `flow-cli-test-${uniqueId}`)
    await fs.mkdir(testDir, { recursive: true })
    testFile = join(testDir, 'sessions.json')

    repo = new FileSystemSessionRepository(testFile)
  })

  afterEach(async () => {
    // Clean up temp directory
    try {
      await fs.rm(testDir, { recursive: true, force: true })
    } catch (error) {
      // Ignore cleanup errors
    }
  })

  describe('Save and Load', () => {
    test('saves session to file', async () => {
      const session = new Session('session-1', 'rmediation', {
        task: 'Fix bug'
      })

      await repo.save(session)

      // Verify file exists
      const fileExists = await fs
        .access(testFile)
        .then(() => true)
        .catch(() => false)
      expect(fileExists).toBe(true)
    })

    test('loads session from file', async () => {
      const session = new Session('session-1', 'rmediation', {
        task: 'Fix bug'
      })

      await repo.save(session)

      const loaded = await repo.findById('session-1')

      expect(loaded).toBeTruthy()
      expect(loaded.id).toBe('session-1')
      expect(loaded.project).toBe('rmediation')
      expect(loaded.task).toBe('Fix bug')
    })

    test('preserves session state on save/load', async () => {
      const session = new Session('session-1', 'rmediation')
      session.pause()

      await repo.save(session)

      const loaded = await repo.findById('session-1')

      expect(loaded.state.isPaused()).toBe(true)
    })

    test('preserves timestamps on save/load', async () => {
      const session = new Session('session-1', 'rmediation')
      const originalStartTime = session.startTime

      await repo.save(session)

      const loaded = await repo.findById('session-1')

      expect(loaded.startTime.getTime()).toBe(originalStartTime.getTime())
    })

    test('updates existing session', async () => {
      const session = new Session('session-1', 'rmediation')

      await repo.save(session)

      session.end('completed')
      await repo.save(session)

      const loaded = await repo.findById('session-1')

      expect(loaded.state.isEnded()).toBe(true)
      expect(loaded.outcome).toBe('completed')
    })

    test('handles multiple sessions', async () => {
      const session1 = new Session('session-1', 'project-1')
      const session2 = new Session('session-2', 'project-2')
      const session3 = new Session('session-3', 'project-3')

      await repo.save(session1)
      await repo.save(session2)
      await repo.save(session3)

      const loaded1 = await repo.findById('session-1')
      const loaded2 = await repo.findById('session-2')
      const loaded3 = await repo.findById('session-3')

      expect(loaded1).toBeTruthy()
      expect(loaded2).toBeTruthy()
      expect(loaded3).toBeTruthy()
    })
  })

  describe('Find Operations', () => {
    test('findActive returns active session', async () => {
      const session = new Session('session-1', 'rmediation')
      await repo.save(session)

      const active = await repo.findActive()

      expect(active).toBeTruthy()
      expect(active.id).toBe('session-1')
    })

    test('findActive returns null when no active session', async () => {
      const session = new Session('session-1', 'rmediation')
      session.end('completed')
      await repo.save(session)

      const active = await repo.findActive()

      expect(active).toBeNull()
    })

    test('findByProject returns all sessions for project', async () => {
      const session1 = new Session('session-1', 'rmediation')
      const session2 = new Session('session-2', 'rmediation')
      const session3 = new Session('session-3', 'other-project')

      await repo.save(session1)
      await repo.save(session2)
      await repo.save(session3)

      const sessions = await repo.findByProject('rmediation')

      expect(sessions).toHaveLength(2)
      expect(sessions.map(s => s.id).sort()).toEqual(['session-1', 'session-2'])
    })

    test('findById returns null for non-existent session', async () => {
      const session = await repo.findById('nonexistent')

      expect(session).toBeNull()
    })
  })

  describe('Delete', () => {
    test('deletes existing session', async () => {
      const session = new Session('session-1', 'rmediation')
      await repo.save(session)

      const deleted = await repo.delete('session-1')

      expect(deleted).toBe(true)

      const loaded = await repo.findById('session-1')
      expect(loaded).toBeNull()
    })

    test('returns false for non-existent session', async () => {
      const deleted = await repo.delete('nonexistent')

      expect(deleted).toBe(false)
    })
  })

  describe('List and Filters', () => {
    beforeEach(async () => {
      // Create test data
      const session1 = new Session('session-1', 'project-1')
      session1.startTime = new Date('2025-01-01')

      const session2 = new Session('session-2', 'project-2')
      session2.startTime = new Date('2025-01-02')
      session2.end('completed')

      const session3 = new Session('session-3', 'project-1')
      session3.startTime = new Date('2025-01-03')

      // Save sequentially and ensure each completes before next starts
      // to avoid race condition in read-modify-write cycle
      await repo.save(session1)
      // Small delay to ensure file write completes
      await new Promise(resolve => setTimeout(resolve, 10))

      await repo.save(session2)
      await new Promise(resolve => setTimeout(resolve, 10))

      await repo.save(session3)
      // Extra delay before tests run to ensure final write completes
      await new Promise(resolve => setTimeout(resolve, 10))
    })

    test('lists all sessions', async () => {
      const sessions = await repo.list()

      expect(sessions).toHaveLength(3)
    })

    test('filters by state', async () => {
      const active = await repo.list({ state: 'active' })
      const ended = await repo.list({ state: 'ended' })

      expect(active).toHaveLength(2)
      expect(ended).toHaveLength(1)
    })

    test('filters by project', async () => {
      const sessions = await repo.list({ project: 'project-1' })

      expect(sessions).toHaveLength(2)
    })

    test('applies limit', async () => {
      const sessions = await repo.list({ limit: 2 })

      expect(sessions).toHaveLength(2)
    })

    test('sorts by startTime descending', async () => {
      const sessions = await repo.list({ order: 'desc' })

      expect(sessions[0].id).toBe('session-3')
      expect(sessions[1].id).toBe('session-2')
      expect(sessions[2].id).toBe('session-1')
    })

    test('counts sessions with filters', async () => {
      const count = await repo.count({ state: 'active' })

      expect(count).toBe(2)
    })
  })

  describe('Edge Cases', () => {
    test('handles missing file (creates on first save)', async () => {
      // Don't create the file first
      const session = new Session('session-1', 'rmediation')

      await repo.save(session)

      const loaded = await repo.findById('session-1')
      expect(loaded).toBeTruthy()
    })

    test('handles empty file', async () => {
      await fs.writeFile(testFile, '[]', 'utf-8')

      const active = await repo.findActive()

      expect(active).toBeNull()
    })

    test('creates directory if missing', async () => {
      const deepPath = join(testDir, 'deep', 'nested', 'sessions.json')
      const deepRepo = new FileSystemSessionRepository(deepPath)

      const session = new Session('session-1', 'rmediation')
      await deepRepo.save(session)

      const fileExists = await fs
        .access(deepPath)
        .then(() => true)
        .catch(() => false)
      expect(fileExists).toBe(true)
    })
  })
})

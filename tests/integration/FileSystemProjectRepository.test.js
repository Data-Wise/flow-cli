/**
 * Integration tests for FileSystemProjectRepository
 *
 * These tests use actual file system I/O (in a temp directory)
 */

import { promises as fs } from 'fs'
import { join } from 'path'
import { tmpdir } from 'os'
import { FileSystemProjectRepository } from '../../cli/adapters/repositories/FileSystemProjectRepository.js'
import { Project } from '../../cli/domain/entities/Project.js'
import { ProjectType } from '../../cli/domain/value-objects/ProjectType.js'

describe('FileSystemProjectRepository Integration', () => {
  let repo
  let testDir
  let testFile

  beforeEach(async () => {
    // Create temp directory for each test
    // Use PID + timestamp + random to ensure uniqueness in parallel execution
    const uniqueId = `${process.pid}-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`
    testDir = join(tmpdir(), `flow-cli-test-${uniqueId}`)
    await fs.mkdir(testDir, { recursive: true })
    testFile = join(testDir, 'projects.json')

    repo = new FileSystemProjectRepository(testFile)
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
    test('saves project to file', async () => {
      const project = new Project('project-1', 'rmediation', {
        type: ProjectType.R_PACKAGE
      })

      await repo.save(project)

      const fileExists = await fs
        .access(testFile)
        .then(() => true)
        .catch(() => false)
      expect(fileExists).toBe(true)
    })

    test('loads project from file', async () => {
      const project = new Project('project-1', 'rmediation', {
        type: ProjectType.R_PACKAGE,
        description: 'Mediation analysis'
      })

      await repo.save(project)

      const loaded = await repo.findById('project-1')

      expect(loaded).toBeTruthy()
      expect(loaded.name).toBe('rmediation')
      expect(loaded.type.value).toBe(ProjectType.R_PACKAGE)
      expect(loaded.description).toBe('Mediation analysis')
    })

    test('preserves project statistics', async () => {
      const project = new Project('project-1', 'rmediation')
      project.recordSession(30)
      project.recordSession(45)

      await repo.save(project)

      const loaded = await repo.findById('project-1')

      expect(loaded.totalSessions).toBe(2)
      expect(loaded.totalDuration).toBe(75)
    })

    test('updates existing project', async () => {
      const project = new Project('project-1', 'rmediation')

      await repo.save(project)

      project.addTag('statistics')
      await repo.save(project)

      const loaded = await repo.findById('project-1')

      expect(loaded.tags).toContain('statistics')
    })
  })

  describe('Find Operations', () => {
    beforeEach(async () => {
      // Create test data
      const p1 = new Project('p1', 'rmediation', {
        type: ProjectType.R_PACKAGE,
        tags: ['r', 'statistics']
      })
      p1.recordSession(30)

      const p2 = new Project('p2', 'flow-cli', {
        type: ProjectType.NODE,
        tags: ['node', 'cli']
      })
      p2.recordSession(60)
      p2.recordSession(45)

      const p3 = new Project('p3', 'quarto-doc', {
        type: ProjectType.QUARTO
      })

      await repo.save(p1)
      await repo.save(p2)
      await repo.save(p3)
    })

    test('findAll returns all projects', async () => {
      const projects = await repo.findAll()

      expect(projects).toHaveLength(3)
    })

    test('findByType filters by type', async () => {
      const rPackages = await repo.findByType(ProjectType.R_PACKAGE)

      expect(rPackages).toHaveLength(1)
      expect(rPackages[0].name).toBe('rmediation')
    })

    test('findByTag finds projects with tag', async () => {
      const projects = await repo.findByTag('cli')

      expect(projects).toHaveLength(1)
      expect(projects[0].name).toBe('flow-cli')
    })

    test('search matches project names', async () => {
      const projects = await repo.search('rmed')

      expect(projects).toHaveLength(1)
      expect(projects[0].name).toBe('rmediation')
    })

    test('findTopBySessionCount returns most active', async () => {
      const top = await repo.findTopBySessionCount(2)

      expect(top).toHaveLength(2)
      expect(top[0].name).toBe('flow-cli') // 2 sessions
      expect(top[1].name).toBe('rmediation') // 1 session
    })

    test('findTopByDuration returns longest worked', async () => {
      const top = await repo.findTopByDuration(2)

      expect(top).toHaveLength(2)
      expect(top[0].name).toBe('flow-cli') // 105 minutes
      expect(top[1].name).toBe('rmediation') // 30 minutes
    })

    test('exists returns true for existing project', async () => {
      const exists = await repo.exists('p1')

      expect(exists).toBe(true)
    })

    test('exists returns false for non-existent project', async () => {
      const exists = await repo.exists('nonexistent')

      expect(exists).toBe(false)
    })

    test('count returns total number of projects', async () => {
      const count = await repo.count()

      expect(count).toBe(3)
    })
  })

  describe('Delete', () => {
    test('deletes existing project', async () => {
      const project = new Project('project-1', 'test')
      await repo.save(project)

      const deleted = await repo.delete('project-1')

      expect(deleted).toBe(true)

      const loaded = await repo.findById('project-1')
      expect(loaded).toBeNull()
    })

    test('returns false for non-existent project', async () => {
      const deleted = await repo.delete('nonexistent')

      expect(deleted).toBe(false)
    })
  })

  describe('Basic Scan', () => {
    let scanDir

    beforeEach(async () => {
      scanDir = join(testDir, 'scan-test')
      await fs.mkdir(scanDir, { recursive: true })
    })

    test('detects Node.js projects', async () => {
      const nodeDir = join(scanDir, 'node-project')
      await fs.mkdir(nodeDir)
      await fs.writeFile(join(nodeDir, 'package.json'), '{}')

      const projects = await repo.scan(scanDir)

      expect(projects).toHaveLength(1)
      expect(projects[0].type.value).toBe(ProjectType.NODE)
    })

    test('detects R packages', async () => {
      const rDir = join(scanDir, 'r-package')
      await fs.mkdir(rDir)
      await fs.writeFile(join(rDir, 'DESCRIPTION'), 'Package: test')

      const projects = await repo.scan(scanDir)

      expect(projects).toHaveLength(1)
      expect(projects[0].type.value).toBe(ProjectType.R_PACKAGE)
    })

    test('ignores non-project directories', async () => {
      const regularDir = join(scanDir, 'not-a-project')
      await fs.mkdir(regularDir)
      await fs.writeFile(join(regularDir, 'some-file.txt'), 'content')

      const projects = await repo.scan(scanDir)

      expect(projects).toHaveLength(0)
    })

    test('detects multiple projects', async () => {
      // Create Node project
      const nodeDir = join(scanDir, 'node-app')
      await fs.mkdir(nodeDir)
      await fs.writeFile(join(nodeDir, 'package.json'), '{}')

      // Create R package
      const rDir = join(scanDir, 'r-pkg')
      await fs.mkdir(rDir)
      await fs.writeFile(join(rDir, 'DESCRIPTION'), 'Package: test')

      const projects = await repo.scan(scanDir)

      expect(projects).toHaveLength(2)
    })
  })

  describe('Edge Cases', () => {
    test('handles empty file', async () => {
      await fs.writeFile(testFile, '[]', 'utf-8')

      const projects = await repo.findAll()

      expect(projects).toHaveLength(0)
    })

    test('creates directory if missing', async () => {
      const deepPath = join(testDir, 'deep', 'nested', 'projects.json')
      const deepRepo = new FileSystemProjectRepository(deepPath)

      const project = new Project('p1', 'test')
      await deepRepo.save(project)

      const fileExists = await fs
        .access(deepPath)
        .then(() => true)
        .catch(() => false)
      expect(fileExists).toBe(true)
    })
  })
})

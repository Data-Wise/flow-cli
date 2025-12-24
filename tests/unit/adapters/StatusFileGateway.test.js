/**
 * Unit tests for StatusFileGateway
 */

import { describe, test, expect, beforeEach, afterEach } from '@jest/globals'
import { StatusFileGateway } from '../../../cli/adapters/gateways/StatusFileGateway.js'
import { writeFile, unlink, mkdir } from 'fs/promises'
import { existsSync } from 'fs'
import { join } from 'path'
import { tmpdir } from 'os'

describe('StatusFileGateway', () => {
  let gateway
  let testDir

  beforeEach(async () => {
    gateway = new StatusFileGateway()
    testDir = join(tmpdir(), `status-test-${Date.now()}`)
    await mkdir(testDir, { recursive: true })
  })

  afterEach(async () => {
    // Clean up test files
    const statusPath = join(testDir, '.STATUS')
    if (existsSync(statusPath)) {
      await unlink(statusPath)
    }
  })

  describe('YAML Format Parsing', () => {
    test('parses YAML frontmatter format correctly', async () => {
      const yamlContent = `---
status: active
progress: 75
type: r-package

next:
  - action: "Write tests for bootstrap function"
    estimate: "2h"
    priority: high

metrics:
  sessions_total: 45
  sessions_this_week: 5
---

# Project Notes
Some additional notes here.
`

      await writeFile(join(testDir, '.STATUS'), yamlContent)
      const status = await gateway.read(testDir)

      expect(status).toBeTruthy()
      expect(status.format).toBe('yaml')
      expect(status.status).toBe('active')
      expect(status.progress).toBe(75)
      expect(status.type).toBe('r-package')
      expect(status.next).toHaveLength(1)
      expect(status.next[0].action).toBe('Write tests for bootstrap function')
      expect(status.next[0].estimate).toBe('2h')
      expect(status.next[0].priority).toBe('high')
      expect(status.metrics.sessions_total).toBe(45)
      expect(status.metrics.sessions_this_week).toBe(5)
      expect(status.body).toContain('# Project Notes')
    })

    test('handles multiple next actions', async () => {
      const yamlContent = `---
status: active
progress: 50

next:
  - action: "First task"
    priority: high
  - action: "Second task"
    priority: medium
  - action: "Third task"
    priority: low
---
`

      await writeFile(join(testDir, '.STATUS'), yamlContent)
      const status = await gateway.read(testDir)

      expect(status.next).toHaveLength(3)
      expect(status.next[0].action).toBe('First task')
      expect(status.next[1].action).toBe('Second task')
      expect(status.next[2].action).toBe('Third task')
    })

    test('ignores comments in YAML frontmatter', async () => {
      const yamlContent = `---
# This is a comment
status: active
# Another comment
progress: 80
---
`

      await writeFile(join(testDir, '.STATUS'), yamlContent)
      const status = await gateway.read(testDir)

      expect(status.status).toBe('active')
      expect(status.progress).toBe(80)
    })
  })

  describe('Legacy Format Parsing', () => {
    test('parses legacy plain text format', async () => {
      const legacyContent = `status: active
progress: 85%

next: Implement feature X

Some additional notes about the project status.
`

      await writeFile(join(testDir, '.STATUS'), legacyContent)
      const status = await gateway.read(testDir)

      expect(status).toBeTruthy()
      expect(status.format).toBe('legacy')
      expect(status.status).toBe('active')
      expect(status.progress).toBe(85)
      expect(status.next).toHaveLength(1)
      expect(status.next[0].action).toBe('Implement feature X')
    })

    test('extracts status from various formats', async () => {
      const legacyContent = `Status: Paused
Progress: 50%
`

      await writeFile(join(testDir, '.STATUS'), legacyContent)
      const status = await gateway.read(testDir)

      expect(status.status).toBe('paused')
      expect(status.progress).toBe(50)
    })

    test('handles missing status gracefully', async () => {
      const legacyContent = `Some random notes without structured data.`

      await writeFile(join(testDir, '.STATUS'), legacyContent)
      const status = await gateway.read(testDir)

      expect(status.format).toBe('legacy')
      expect(status.status).toBe('unknown')
      expect(status.progress).toBe(0)
    })
  })

  describe('File Operations', () => {
    test('returns null for missing .STATUS file', async () => {
      const status = await gateway.read(testDir)

      expect(status).toBeNull()
    })

    test('returns null for non-existent directory', async () => {
      const status = await gateway.read('/nonexistent/path')

      expect(status).toBeNull()
    })

    test('hasStatusFile returns true when file exists', async () => {
      await writeFile(join(testDir, '.STATUS'), 'status: active')

      const hasFile = gateway.hasStatusFile(testDir)

      expect(hasFile).toBe(true)
    })

    test('hasStatusFile returns false when file missing', () => {
      const hasFile = gateway.hasStatusFile(testDir)

      expect(hasFile).toBe(false)
    })
  })

  describe('Write Operations', () => {
    test('writes YAML format correctly', async () => {
      const data = {
        status: 'active',
        progress: 75,
        type: 'r-package',
        next: [
          {
            action: 'Write tests',
            estimate: '2h',
            priority: 'high'
          }
        ],
        metrics: {
          sessions_total: 45,
          sessions_this_week: 5
        },
        body: '# Project Notes\nSome notes here.'
      }

      await gateway.write(testDir, data)

      // Read back and verify
      const readBack = await gateway.read(testDir)
      expect(readBack.status).toBe('active')
      expect(readBack.progress).toBe(75)
      expect(readBack.type).toBe('r-package')
      expect(readBack.next).toHaveLength(1)
      expect(readBack.next[0].action).toBe('Write tests')
      expect(readBack.next[0].estimate).toBe('2h')
      expect(readBack.next[0].priority).toBe('high')
      expect(readBack.metrics.sessions_total).toBe(45)
      expect(readBack.body).toContain('# Project Notes')
    })

    test('writes minimal file correctly', async () => {
      const data = {
        status: 'active',
        progress: 50,
        type: 'generic'
      }

      await gateway.write(testDir, data)

      const readBack = await gateway.read(testDir)
      expect(readBack.status).toBe('active')
      expect(readBack.progress).toBe(50)
      expect(readBack.type).toBe('generic')
    })

    test('preserves body content when updating', async () => {
      const data = {
        status: 'active',
        progress: 50,
        type: 'r-package',
        body: '# Original Notes\nKeep these notes.'
      }

      await gateway.write(testDir, data)

      // Update metrics only
      const updated = {
        ...data,
        metrics: { sessions_total: 10 }
      }

      await gateway.write(testDir, updated)

      const readBack = await gateway.read(testDir)
      expect(readBack.body).toContain('# Original Notes')
      expect(readBack.metrics.sessions_total).toBe(10)
    })

    test('handles multiple next actions', async () => {
      const data = {
        status: 'active',
        progress: 50,
        type: 'r-package',
        next: [
          { action: 'First task', priority: 'high' },
          { action: 'Second task', priority: 'medium' },
          { action: 'Third task', priority: 'low' }
        ]
      }

      await gateway.write(testDir, data)

      const readBack = await gateway.read(testDir)
      expect(readBack.next).toHaveLength(3)
      expect(readBack.next[0].action).toBe('First task')
      expect(readBack.next[1].action).toBe('Second task')
      expect(readBack.next[2].action).toBe('Third task')
    })
  })
})

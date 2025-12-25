# Flow CLI - Interactive Code Examples

**Version:** 2.0.0-beta.1
**Last Updated:** 2025-12-24

---

## Table of Contents

- [Quick Start Examples](#quick-start-examples)
- [Session Management](#session-management)
- [Project Tracking](#project-tracking)
- [Status and Metrics](#status-and-metrics)
- [Custom Integrations](#custom-integrations)
- [Advanced Patterns](#advanced-patterns)
- [Testing Examples](#testing-examples)

---

## Quick Start Examples

### Example 1: Basic Session Workflow

**Use Case:** Create a session, do some work, end the session.

```javascript
#!/usr/bin/env node
import { createRequire } from 'module'
const require = createRequire(import.meta.url)

// Import from flow-cli
import { Session } from './domain/entities/Session.js'
import { FileSystemSessionRepository } from './adapters/repositories/FileSystemSessionRepository.js'
import { CreateSessionUseCase } from './use-cases/CreateSessionUseCase.js'
import { EndSessionUseCase } from './use-cases/EndSessionUseCase.js'

async function basicWorkflow() {
  // Setup repositories
  const sessionRepo = new FileSystemSessionRepository()
  const projectRepo = new FileSystemProjectRepository()

  // Create a new session
  console.log('Starting work session...')
  const createUseCase = new CreateSessionUseCase(sessionRepo, projectRepo)

  const { session } = await createUseCase.execute({
    project: 'flow-cli',
    task: 'Write interactive examples',
    branch: 'feature/interactive-docs'
  })

  console.log(`✓ Session started: ${session.id}`)
  console.log(`  Project: ${session.project}`)
  console.log(`  Task: ${session.task}`)
  console.log(`  Branch: ${session.branch}`)

  // Simulate work (wait 5 seconds)
  console.log('\nDoing work...')
  await new Promise(resolve => setTimeout(resolve, 5000))

  // Check duration
  console.log(`\nCurrent duration: ${session.getDuration()} minutes`)

  // End the session
  console.log('\nEnding session...')
  const endUseCase = new EndSessionUseCase(sessionRepo, projectRepo)

  const { duration } = await endUseCase.execute({
    outcome: 'completed',
    notes: 'Created interactive examples documentation'
  })

  console.log(`✓ Session completed: ${duration} minutes`)
}

// Run the example
basicWorkflow().catch(console.error)
```

**Expected Output:**

```
Starting work session...
✓ Session started: a1b2c3d4-e5f6-7890-abcd-ef1234567890
  Project: flow-cli
  Task: Write interactive examples
  Branch: feature/interactive-docs

Doing work...

Current duration: 0 minutes

Ending session...
✓ Session completed: 0 minutes
```

---

### Example 2: Check Current Status

**Use Case:** Get comprehensive workflow status with metrics.

```javascript
#!/usr/bin/env node
import { GetStatusUseCase } from './use-cases/GetStatusUseCase.js'
import { FileSystemSessionRepository } from './adapters/repositories/FileSystemSessionRepository.js'
import { FileSystemProjectRepository } from './adapters/repositories/FileSystemProjectRepository.js'
import { GitGateway } from './adapters/gateways/GitGateway.js'
import { StatusFileGateway } from './adapters/gateways/StatusFileGateway.js'

async function checkStatus() {
  // Setup dependencies
  const sessionRepo = new FileSystemSessionRepository()
  const projectRepo = new FileSystemProjectRepository()
  const gitGateway = new GitGateway()
  const statusFileGateway = new StatusFileGateway()

  // Create use case
  const useCase = new GetStatusUseCase(sessionRepo, projectRepo, gitGateway, statusFileGateway)

  // Get status
  console.log('Fetching status...\n')
  const status = await useCase.execute({
    includeRecentSessions: true,
    includeProjectStats: true,
    recentDays: 7
  })

  // Display status
  if (status.activeSession) {
    console.log('🔥 ACTIVE SESSION')
    console.log(`   Project: ${status.activeSession.project}`)
    console.log(`   Task: ${status.activeSession.task}`)
    console.log(`   Duration: ${status.activeSession.duration} minutes`)
    console.log(`   Flow State: ${status.activeSession.isFlowState ? '🔥 YES' : '❄️  Not yet'}`)
    console.log(`   Branch: ${status.activeSession.branch}`)

    if (status.activeSession.gitStatus) {
      console.log(`   Git: ${status.activeSession.gitStatus.dirty ? 'Modified' : 'Clean'}`)
    }
  } else {
    console.log('No active session')
  }

  console.log('\n📊 TODAY')
  console.log(`   Sessions: ${status.today.sessions}`)
  console.log(`   Total time: ${status.today.totalDuration} minutes`)
  console.log(`   Completed: ${status.today.completedSessions}`)
  console.log(`   Flow sessions: ${status.today.flowSessions}`)

  console.log('\n📈 METRICS (7 days)')
  console.log(`   Daily average: ${status.metrics.dailyAverage} minutes`)
  console.log(`   Flow percentage: ${status.metrics.flowPercentage}%`)
  console.log(`   Completion rate: ${status.metrics.completionRate}%`)
  console.log(`   Streak: ${status.metrics.streak} days`)
  console.log(`   Trend: ${status.metrics.trend === 'up' ? '📈 Up' : '📉 Down'}`)

  if (status.recent && status.recent.recentSessions.length > 0) {
    console.log('\n🕐 RECENT SESSIONS')
    status.recent.recentSessions.slice(0, 3).forEach(s => {
      console.log(`   ${s.project} - ${s.duration}min (${s.outcome})`)
    })
  }
}

// Run the example
checkStatus().catch(console.error)
```

**Expected Output:**

```
Fetching status...

🔥 ACTIVE SESSION
   Project: flow-cli
   Task: Write interactive examples
   Duration: 12 minutes
   Flow State: ❄️  Not yet
   Branch: feature/interactive-docs
   Git: Modified

📊 TODAY
   Sessions: 2
   Total time: 45 minutes
   Completed: 1
   Flow sessions: 0

📈 METRICS (7 days)
   Daily average: 120 minutes
   Flow percentage: 65%
   Completion rate: 85%
   Streak: 5 days
   Trend: 📉 Down

🕐 RECENT SESSIONS
   flow-cli - 33min (completed)
   research/collider - 87min (completed)
   teaching/stat-440 - 25min (completed)
```

---

## Session Management

### Example 3: Pause and Resume Session

**Use Case:** Pause work for a break, then resume.

```javascript
#!/usr/bin/env node
import { FileSystemSessionRepository } from './adapters/repositories/FileSystemSessionRepository.js'

async function pauseResumeDemo() {
  const sessionRepo = new FileSystemSessionRepository()

  // Get active session
  const session = await sessionRepo.findActive()
  if (!session) {
    console.log('No active session to pause')
    return
  }

  console.log(`Active session: ${session.project}`)
  console.log(`Duration before pause: ${session.getDuration()} minutes\n`)

  // Pause the session
  console.log('Pausing session for break...')
  session.pause()
  await sessionRepo.save(session)
  console.log('✓ Session paused\n')

  // Simulate break (5 seconds)
  console.log('Taking a break...')
  await new Promise(resolve => setTimeout(resolve, 5000))

  // Resume the session
  console.log('\nResuming session...')
  session.resume()
  await sessionRepo.save(session)
  console.log('✓ Session resumed\n')

  console.log(`Duration after resume: ${session.getDuration()} minutes`)
  console.log(`Total paused time: ${Math.floor(session.totalPausedTime / 60000)} minutes`)
}

// Run the example
pauseResumeDemo().catch(console.error)
```

**Expected Output:**

```
Active session: flow-cli
Duration before pause: 12 minutes

Pausing session for break...
✓ Session paused

Taking a break...

Resuming session...
✓ Session resumed

Duration after resume: 12 minutes
Total paused time: 0 minutes
```

---

### Example 4: Track Flow State

**Use Case:** Monitor when a session enters flow state.

```javascript
#!/usr/bin/env node
import { FileSystemSessionRepository } from './adapters/repositories/FileSystemSessionRepository.js'

async function monitorFlowState() {
  const sessionRepo = new FileSystemSessionRepository()

  // Get active session
  const session = await sessionRepo.findActive()
  if (!session) {
    console.log('No active session')
    return
  }

  console.log(`Monitoring flow state for: ${session.project}\n`)

  // Check every 30 seconds
  const checkInterval = setInterval(async () => {
    // Reload session from disk
    const currentSession = await sessionRepo.findById(session.id)

    const duration = currentSession.getDuration()
    const isFlow = currentSession.isInFlowState()

    console.log(`Duration: ${duration} min | Flow: ${isFlow ? '🔥 YES' : '❄️  Not yet'}`)

    if (isFlow && !session.isInFlowState()) {
      console.log('\n🎉 ENTERED FLOW STATE! Keep going! 🔥\n')
      clearInterval(checkInterval)
    }
  }, 30000)

  // Stop after 20 minutes
  setTimeout(
    () => {
      clearInterval(checkInterval)
      console.log('\nMonitoring stopped')
    },
    20 * 60 * 1000
  )
}

// Run the example
monitorFlowState().catch(console.error)
```

---

## Project Tracking

### Example 5: Scan Projects with Filters

**Use Case:** Find all active R package projects.

```javascript
#!/usr/bin/env node
import { ScanProjectsUseCase } from './use-cases/ScanProjectsUseCase.js'
import { FileSystemProjectRepository } from './adapters/repositories/FileSystemProjectRepository.js'
import { ProjectScanCache } from './utils/ProjectScanCache.js'

async function scanActiveRPackages() {
  // Setup
  const projectRepo = new FileSystemProjectRepository()
  const cache = new ProjectScanCache()
  const scanUseCase = new ScanProjectsUseCase(projectRepo, cache)

  console.log('Scanning for active R packages...\n')

  const result = await scanUseCase.execute({
    basePath: '/Users/dt/projects',
    filters: {
      type: 'r-package',
      status: 'active'
    },
    useCache: true,
    onProgress: (current, total) => {
      process.stdout.write(`\rScanning: ${current}/${total}`)
    }
  })

  console.log(`\n\n✓ Found ${result.projects.length} active R packages`)
  console.log(`Cache hit: ${result.cacheStats.hit ? 'YES' : 'NO'}`)

  if (result.cacheStats.hit) {
    console.log(`Cache age: ${Math.floor(result.cacheStats.age / 1000)}s`)
  }

  console.log('\n📦 PROJECTS:\n')

  result.projects.forEach((project, i) => {
    console.log(`${i + 1}. ${project.name}`)
    console.log(`   Path: ${project.path}`)
    console.log(`   Sessions: ${project.totalSessions}`)
    console.log(`   Total time: ${project.totalDuration} min`)
    console.log(`   Avg session: ${project.getAverageSessionDuration()} min`)
    console.log(`   Tags: ${project.tags.join(', ') || 'none'}`)
    console.log()
  })
}

// Run the example
scanActiveRPackages().catch(console.error)
```

**Expected Output:**

```
Scanning for active R packages...

Scanning: 60/60

✓ Found 6 active R packages
Cache hit: YES
Cache age: 45s

📦 PROJECTS:

1. mediationverse
   Path: /Users/dt/projects/r-packages/active/mediationverse
   Sessions: 42
   Total time: 1250 min
   Avg session: 30 min
   Tags: ecosystem, meta-package

2. medfit
   Path: /Users/dt/projects/r-packages/active/medfit
   Sessions: 38
   Total time: 1120 min
   Avg session: 29 min
   Tags: estimation, package

...
```

---

### Example 6: Project Search

**Use Case:** Search projects by keyword.

```javascript
#!/usr/bin/env node
import { FileSystemProjectRepository } from './adapters/repositories/FileSystemProjectRepository.js'

async function searchProjects(query) {
  const projectRepo = new FileSystemProjectRepository()

  console.log(`Searching for: "${query}"\n`)

  // Get all projects
  const allProjects = await projectRepo.findAll()

  // Filter using matchesSearch
  const results = allProjects.filter(p => p.matchesSearch(query))

  console.log(`Found ${results.length} matching projects:\n`)

  results.forEach(project => {
    console.log(`📁 ${project.name}`)
    console.log(`   ${project.description || 'No description'}`)
    console.log(`   Type: ${project.type.getDisplayName()}`)
    console.log(`   Path: ${project.path}`)
    console.log()
  })
}

// Run the example
searchProjects('mediation').catch(console.error)
```

---

## Status and Metrics

### Example 7: Custom Metrics Calculator

**Use Case:** Calculate productivity trends over time.

```javascript
#!/usr/bin/env node
import { FileSystemSessionRepository } from './adapters/repositories/FileSystemSessionRepository.js'

async function analyzeProductivity() {
  const sessionRepo = new FileSystemSessionRepository()

  // Get sessions for last 30 days
  const since = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
  const sessions = await sessionRepo.list({ since })

  console.log('📊 PRODUCTIVITY ANALYSIS (30 days)\n')

  // Group by week
  const weeks = {}
  sessions.forEach(session => {
    const weekNum = Math.floor((Date.now() - session.startTime) / (7 * 24 * 60 * 60 * 1000))
    const weekKey = `Week ${4 - weekNum}`

    if (!weeks[weekKey]) {
      weeks[weekKey] = {
        sessions: [],
        totalDuration: 0,
        flowSessions: 0,
        completedSessions: 0
      }
    }

    weeks[weekKey].sessions.push(session)
    weeks[weekKey].totalDuration += session.getDuration()

    if (session.getDuration() >= 15) {
      weeks[weekKey].flowSessions++
    }

    if (session.outcome === 'completed') {
      weeks[weekKey].completedSessions++
    }
  })

  // Display weekly breakdown
  Object.keys(weeks)
    .sort()
    .reverse()
    .forEach(weekKey => {
      const week = weeks[weekKey]
      const avgDuration =
        week.sessions.length > 0 ? Math.round(week.totalDuration / week.sessions.length) : 0

      console.log(`${weekKey}:`)
      console.log(`  Sessions: ${week.sessions.length}`)
      console.log(`  Total time: ${week.totalDuration} min`)
      console.log(`  Avg duration: ${avgDuration} min`)
      console.log(`  Flow rate: ${Math.round((week.flowSessions / week.sessions.length) * 100)}%`)
      console.log(
        `  Completion: ${Math.round((week.completedSessions / week.sessions.length) * 100)}%`
      )
      console.log()
    })

  // Calculate trends
  const weekKeys = Object.keys(weeks).sort().reverse()
  if (weekKeys.length >= 2) {
    const thisWeek = weeks[weekKeys[0]]
    const lastWeek = weeks[weekKeys[1]]

    const sessionChange =
      ((thisWeek.sessions.length - lastWeek.sessions.length) / lastWeek.sessions.length) * 100
    const timeChange =
      ((thisWeek.totalDuration - lastWeek.totalDuration) / lastWeek.totalDuration) * 100

    console.log('📈 TRENDS (this week vs last week):')
    console.log(`  Sessions: ${sessionChange > 0 ? '📈' : '📉'} ${sessionChange.toFixed(1)}%`)
    console.log(`  Total time: ${timeChange > 0 ? '📈' : '📉'} ${timeChange.toFixed(1)}%`)
  }
}

// Run the example
analyzeProductivity().catch(console.error)
```

---

## Custom Integrations

### Example 8: Slack Integration

**Use Case:** Send Slack notification when entering flow state.

```javascript
#!/usr/bin/env node
import { FileSystemSessionRepository } from './adapters/repositories/FileSystemSessionRepository.js'
import { WebClient } from '@slack/web-api'

const slack = new WebClient(process.env.SLACK_TOKEN)

async function monitorFlowWithSlack() {
  const sessionRepo = new FileSystemSessionRepository()

  setInterval(async () => {
    const session = await sessionRepo.findActive()

    if (session && session.isInFlowState()) {
      // Check if we already notified
      if (!session.context?.flowNotified) {
        // Send Slack notification
        await slack.chat.postMessage({
          channel: '#productivity',
          text: `🔥 ${session.project} entered flow state! ${session.getDuration()} minutes in.`
        })

        // Mark as notified
        session.updateContext({ flowNotified: true })
        await sessionRepo.save(session)

        console.log('✓ Sent flow state notification to Slack')
      }
    }
  }, 60000) // Check every minute
}

// Run the integration
monitorFlowWithSlack().catch(console.error)
```

---

### Example 9: Export to CSV

**Use Case:** Export session history to CSV for analysis.

```javascript
#!/usr/bin/env node
import { FileSystemSessionRepository } from './adapters/repositories/FileSystemSessionRepository.js'
import { writeFileSync } from 'fs'

async function exportSessionsToCSV() {
  const sessionRepo = new FileSystemSessionRepository()

  // Get all sessions from last 90 days
  const since = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000)
  const sessions = await sessionRepo.list({ since, orderBy: 'startTime' })

  console.log(`Exporting ${sessions.length} sessions to CSV...\n`)

  // CSV header
  const csv = ['Date,Project,Task,Duration (min),Flow State,Outcome,Branch,Start Time,End Time']

  // Add rows
  sessions.forEach(session => {
    const row = [
      session.startTime.toISOString().split('T')[0],
      `"${session.project}"`,
      `"${session.task}"`,
      session.getDuration(),
      session.isInFlowState() ? 'Yes' : 'No',
      session.outcome || 'N/A',
      `"${session.branch}"`,
      session.startTime.toISOString(),
      session.endTime ? session.endTime.toISOString() : 'N/A'
    ]
    csv.push(row.join(','))
  })

  // Write to file
  const filename = `sessions-export-${Date.now()}.csv`
  writeFileSync(filename, csv.join('\n'))

  console.log(`✓ Exported to ${filename}`)
}

// Run the export
exportSessionsToCSV().catch(console.error)
```

---

## Advanced Patterns

### Example 10: Custom Repository Implementation

**Use Case:** Implement PostgreSQL repository.

```javascript
import { ISessionRepository } from './domain/repositories/ISessionRepository.js'
import { Session } from './domain/entities/Session.js'
import { SessionState } from './domain/value-objects/SessionState.js'
import pkg from 'pg'
const { Pool } = pkg

export class PostgresSessionRepository extends ISessionRepository {
  constructor(connectionString) {
    super()
    this.pool = new Pool({ connectionString })
  }

  async save(session) {
    const query = `
      INSERT INTO sessions (
        id, project, task, branch, state, outcome,
        start_time, end_time, paused_at, total_paused_time, context
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
      ON CONFLICT (id) DO UPDATE SET
        state = EXCLUDED.state,
        outcome = EXCLUDED.outcome,
        end_time = EXCLUDED.end_time,
        paused_at = EXCLUDED.paused_at,
        total_paused_time = EXCLUDED.total_paused_time,
        context = EXCLUDED.context
    `

    await this.pool.query(query, [
      session.id,
      session.project,
      session.task,
      session.branch,
      session.state.value,
      session.outcome,
      session.startTime,
      session.endTime,
      session.pausedAt,
      session.totalPausedTime,
      JSON.stringify(session.context)
    ])
  }

  async findById(id) {
    const result = await this.pool.query('SELECT * FROM sessions WHERE id = $1', [id])

    if (result.rows.length === 0) return null

    return this._rowToSession(result.rows[0])
  }

  async findActive() {
    const result = await this.pool.query(`
      SELECT * FROM sessions WHERE state = 'active' ORDER BY start_time DESC LIMIT 1
    `)

    if (result.rows.length === 0) return null

    return this._rowToSession(result.rows[0])
  }

  async list(options = {}) {
    let query = 'SELECT * FROM sessions WHERE 1=1'
    const params = []

    if (options.since) {
      params.push(options.since)
      query += ` AND start_time >= $${params.length}`
    }

    if (options.until) {
      params.push(options.until)
      query += ` AND start_time <= $${params.length}`
    }

    if (options.project) {
      params.push(options.project)
      query += ` AND project = $${params.length}`
    }

    query += ` ORDER BY start_time ${options.order === 'asc' ? 'ASC' : 'DESC'}`

    if (options.limit) {
      params.push(options.limit)
      query += ` LIMIT $${params.length}`
    }

    const result = await this.pool.query(query, params)

    return result.rows.map(row => this._rowToSession(row))
  }

  async delete(id) {
    await this.pool.query('DELETE FROM sessions WHERE id = $1', [id])
  }

  _rowToSession(row) {
    return new Session(row.id, row.project, {
      task: row.task,
      branch: row.branch,
      startTime: row.start_time,
      context: row.context,
      _skipEvents: true
    })
  }
}

// Usage example
async function usePostgresRepo() {
  const repo = new PostgresSessionRepository(process.env.DATABASE_URL)

  // Works exactly like FileSystemSessionRepository
  const session = await repo.findActive()
  console.log(session ? `Active: ${session.project}` : 'No active session')
}
```

---

### Example 11: Event Publisher with Webhooks

**Use Case:** Publish domain events to webhooks.

```javascript
import fetch from 'node-fetch'

export class WebhookEventPublisher {
  constructor(webhookUrl) {
    this.webhookUrl = webhookUrl
  }

  async publish(event) {
    const payload = {
      eventType: event.eventType,
      occurredAt: event.occurredAt.toISOString(),
      aggregateId: event.aggregateId,
      payload: event.payload
    }

    const response = await fetch(this.webhookUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    })

    if (!response.ok) {
      throw new Error(`Webhook failed: ${response.statusText}`)
    }

    console.log(`✓ Published ${event.eventType} to webhook`)
  }
}

// Usage with CreateSessionUseCase
async function createSessionWithWebhook() {
  const sessionRepo = new FileSystemSessionRepository()
  const projectRepo = new FileSystemProjectRepository()
  const eventPublisher = new WebhookEventPublisher('https://example.com/webhooks/flow-cli')

  const useCase = new CreateSessionUseCase(sessionRepo, projectRepo, eventPublisher)

  const { session } = await useCase.execute({
    project: 'flow-cli',
    task: 'Test webhooks'
  })

  // SessionStartedEvent is automatically published to webhook
  console.log(`Session created and published: ${session.id}`)
}
```

---

## Testing Examples

### Example 12: Unit Test for Session Entity

```javascript
import { Session } from '../domain/entities/Session.js'
import { SessionState } from '../domain/value-objects/SessionState.js'

describe('Session Entity', () => {
  describe('constructor', () => {
    it('should create valid session with required fields', () => {
      const session = new Session('test-id', 'flow-cli')

      expect(session.id).toBe('test-id')
      expect(session.project).toBe('flow-cli')
      expect(session.state.isActive()).toBe(true)
      expect(session.task).toBe('Work session')
    })

    it('should throw error if project name is empty', () => {
      expect(() => {
        new Session('test-id', '')
      }).toThrow('Session must have a project name')
    })
  })

  describe('end', () => {
    it('should end active session', () => {
      const session = new Session('test-id', 'flow-cli')

      session.end('completed')

      expect(session.state.isEnded()).toBe(true)
      expect(session.outcome).toBe('completed')
      expect(session.endTime).toBeDefined()
    })

    it('should throw error if session already ended', () => {
      const session = new Session('test-id', 'flow-cli')
      session.end('completed')

      expect(() => {
        session.end('completed')
      }).toThrow('Session is already ended')
    })
  })

  describe('flow state', () => {
    it('should not be in flow initially', () => {
      const session = new Session('test-id', 'flow-cli')
      expect(session.isInFlowState()).toBe(false)
    })

    it('should be in flow after 15 minutes', () => {
      const session = new Session('test-id', 'flow-cli')

      // Mock 16 minutes of work
      session.startTime = new Date(Date.now() - 16 * 60 * 1000)

      expect(session.isInFlowState()).toBe(true)
    })
  })
})
```

---

### Example 13: Integration Test for Use Case

```javascript
import { GetStatusUseCase } from '../use-cases/GetStatusUseCase.js'
import { InMemorySessionRepository } from '../test/mocks/InMemorySessionRepository.js'
import { InMemoryProjectRepository } from '../test/mocks/InMemoryProjectRepository.js'
import { Session } from '../domain/entities/Session.js'

describe('GetStatusUseCase', () => {
  let useCase
  let sessionRepo
  let projectRepo

  beforeEach(() => {
    sessionRepo = new InMemorySessionRepository()
    projectRepo = new InMemoryProjectRepository()
    useCase = new GetStatusUseCase(sessionRepo, projectRepo)
  })

  it('should return null active session when none exists', async () => {
    const result = await useCase.execute()

    expect(result.activeSession).toBeNull()
  })

  it('should return active session when one exists', async () => {
    // Create and save active session
    const session = new Session('test-id', 'flow-cli', {
      task: 'Test task',
      _skipEvents: true
    })
    await sessionRepo.save(session)

    const result = await useCase.execute()

    expect(result.activeSession).toBeDefined()
    expect(result.activeSession.project).toBe('flow-cli')
    expect(result.activeSession.task).toBe('Test task')
  })

  it('should calculate metrics correctly', async () => {
    // Create multiple sessions
    const now = Date.now()

    for (let i = 0; i < 5; i++) {
      const session = new Session(`test-${i}`, 'flow-cli', {
        startTime: new Date(now - i * 24 * 60 * 60 * 1000),
        _skipEvents: true
      })
      session.end('completed')
      await sessionRepo.save(session)
    }

    const result = await useCase.execute({ recentDays: 7 })

    expect(result.recent.sessions).toBe(5)
    expect(result.metrics).toBeDefined()
    expect(result.metrics.completionRate).toBe(100)
  })
})
```

---

## Next Steps

- [Complete API Reference](API-REFERENCE.md)
- [Architecture Diagrams](../architecture/ARCHITECTURE-DIAGRAM.md)
- [Testing Guide](../development/TESTING.md)
- [Contributing Guide](../../CONTRIBUTING.md)

---

**Version:** 2.0.0-beta.1
**License:** MIT

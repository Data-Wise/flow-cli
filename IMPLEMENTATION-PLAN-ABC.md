# Implementation Plan: Options A + B + C Combined
**Timeframe:** 2 weeks
**Approach:** Incremental delivery with quick wins

---

## 🎯 Overview

Combining three strategic initiatives:
- **Option A:** Architecture Refactoring (Clean Architecture implementation)
- **Option B:** Enhanced Features (immediate user value)
- **Option C:** P6 CLI Enhancements (roadmap completion)

**Key Principle:** Build foundation while delivering user value continuously

---

## 📅 Week 1: Foundation + Quick Wins

### Day 1-2: Domain Layer Foundation (Option A)

**Goal:** Implement core domain entities with business rules

#### Tasks

**1. Create Directory Structure**
```bash
mkdir -p cli/domain/{entities,value-objects,repositories,services}
mkdir -p cli/use-cases/{session,project,task,dashboard}
mkdir -p cli/adapters/{repositories,gateways,controllers,presenters}
mkdir -p cli/frameworks/{di,config}
```

**2. Implement Session Entity**
```javascript
// cli/domain/entities/Session.js
export class Session {
  constructor(id, project, options = {}) {
    this.id = id
    this.project = project
    this.task = options.task || 'Work session'
    this.branch = options.branch || 'main'
    this.startTime = options.startTime || new Date()
    this.endTime = null
    this.state = SessionState.ACTIVE
    this.context = options.context || {}
    this._events = []

    this.validate()
  }

  // Business Rules
  validate() {
    if (!this.project || this.project.trim() === '') {
      throw new ValidationError('Project name required')
    }
  }

  end(outcome = 'completed') {
    if (this.state !== SessionState.ACTIVE) {
      throw new Error('Can only end active sessions')
    }

    this.endTime = new Date()
    this.state = SessionState.ENDED
    this.outcome = outcome

    this._events.push(new SessionEndedEvent(this.id, outcome))
  }

  getDuration() {
    const end = this.endTime || new Date()
    return Math.floor((end - this.startTime) / 60000) // minutes
  }

  isInFlowState() {
    return this.state === SessionState.ACTIVE && this.getDuration() >= 15
  }
}
```

**3. Create Value Objects**
```javascript
// cli/domain/value-objects/SessionState.js
export class SessionState {
  static ACTIVE = 'active'
  static PAUSED = 'paused'
  static ENDED = 'ended'

  constructor(value) {
    if (![SessionState.ACTIVE, SessionState.PAUSED, SessionState.ENDED].includes(value)) {
      throw new Error(`Invalid session state: ${value}`)
    }
    this._value = value
    Object.freeze(this)
  }

  get value() { return this._value }
  isActive() { return this._value === SessionState.ACTIVE }
}

// cli/domain/value-objects/ProjectType.js
export class ProjectType {
  static R_PACKAGE = 'r-package'
  static QUARTO = 'quarto'
  static RESEARCH = 'research'
  static GENERIC = 'generic'
  static UNKNOWN = 'unknown'

  constructor(value) {
    this._value = value
    Object.freeze(this)
  }

  isResearch() { return this._value === ProjectType.RESEARCH }
  isRPackage() { return this._value === ProjectType.R_PACKAGE }
}
```

**4. Define Repository Interfaces**
```javascript
// cli/domain/repositories/ISessionRepository.js
export class ISessionRepository {
  async findById(sessionId) { throw new Error('Not implemented') }
  async findActive() { throw new Error('Not implemented') }
  async save(session) { throw new Error('Not implemented') }
  async delete(sessionId) { throw new Error('Not implemented') }
  async list(filters = {}) { throw new Error('Not implemented') }
}
```

**✅ Quick Win:** Run architecture dashboard - should show clean domain layer with zero violations

**Testing:**
```bash
npm run arch-dashboard
# Should show: Domain layer created, 0 violations
```

---

### Day 2-3: Essential Use Cases (Option A)

**Goal:** Implement application workflows

#### Tasks

**1. CreateSessionUseCase**
```javascript
// cli/use-cases/session/CreateSessionUseCase.js
import { Session } from '../../domain/entities/Session.js'
import { SessionState } from '../../domain/value-objects/SessionState.js'

export class CreateSessionUseCase {
  constructor(sessionRepository, projectRepository, eventPublisher) {
    this.sessionRepository = sessionRepository
    this.projectRepository = projectRepository
    this.eventPublisher = eventPublisher
  }

  async execute({ project, task, branch, context = {} }) {
    // Validate: Only one active session
    const activeSession = await this.sessionRepository.findActive()
    if (activeSession) {
      throw new SessionAlreadyActiveError(activeSession)
    }

    // Validate: Project exists (optional)
    const projectEntity = await this.projectRepository.findByName(project)
    if (projectEntity) {
      projectEntity.recordAccess()
      await this.projectRepository.save(projectEntity)
    }

    // Create domain entity
    const session = new Session(this.generateId(), project, {
      task,
      branch,
      context
    })

    // Persist
    const saved = await this.sessionRepository.save(session)

    // Publish events
    for (const event of session.getEvents()) {
      await this.eventPublisher.publish(event)
    }
    session.clearEvents()

    return saved
  }

  generateId() {
    return `session-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
  }
}
```

**2. EndSessionUseCase**
```javascript
// cli/use-cases/session/EndSessionUseCase.js
export class EndSessionUseCase {
  constructor(sessionRepository, eventPublisher) {
    this.sessionRepository = sessionRepository
    this.eventPublisher = eventPublisher
  }

  async execute({ sessionId, outcome = 'completed', summary }) {
    // Get session
    const session = sessionId
      ? await this.sessionRepository.findById(sessionId)
      : await this.sessionRepository.findActive()

    if (!session) {
      throw new SessionNotFoundError(sessionId || 'active')
    }

    // End session (business rules enforced in entity)
    session.end(outcome)

    if (summary) {
      session.context.summary = summary
    }

    // Persist
    await this.sessionRepository.save(session)

    // Publish events
    for (const event of session.getEvents()) {
      await this.eventPublisher.publish(event)
    }

    return session
  }
}
```

**3. ScanProjectsUseCase**
```javascript
// cli/use-cases/project/ScanProjectsUseCase.js
export class ScanProjectsUseCase {
  constructor(projectRepository, projectDetectorGateway, fileSystemGateway) {
    this.projectRepository = projectRepository
    this.projectDetector = projectDetectorGateway
    this.fileSystem = fileSystemGateway
  }

  async execute({ basePath, maxDepth = 3, types = [] }) {
    // Find directories
    const directories = await this.fileSystem.findDirectories(basePath, {
      maxDepth,
      excludeHidden: true
    })

    // Detect types in parallel
    const detections = await this.projectDetector.detectMultiple(directories)

    // Create domain entities
    const projects = []
    for (const [path, typeStr] of Object.entries(detections)) {
      if (types.length > 0 && !types.includes(typeStr)) continue

      const projectType = new ProjectType(typeStr)
      const project = new Project(
        this.generateId(path),
        this.extractName(path),
        path,
        projectType
      )

      // Load metadata
      const metadata = await this.fileSystem.extractMetadata(path, projectType)
      project.metadata = metadata

      // Load status
      const status = await this.fileSystem.readStatus(path)
      if (status) project.updateStatus(status)

      projects.push(project)
      await this.projectRepository.save(project)
    }

    return { projects, count: projects.length }
  }

  generateId(path) {
    return `project-${path.split('/').pop()}`
  }

  extractName(path) {
    return path.split('/').pop()
  }
}
```

**✅ Quick Win:** Use cases work with in-memory repositories (testable without I/O)

---

### Day 3: File System Adapters (Option A)

**Goal:** Persistent storage for entities

#### Tasks

**1. FileSystemSessionRepository**
```javascript
// cli/adapters/repositories/FileSystemSessionRepository.js
import { ISessionRepository } from '../../domain/repositories/ISessionRepository.js'
import { Session } from '../../domain/entities/Session.js'
import { readFile, writeFile, readdir, mkdir } from 'fs/promises'
import { join } from 'path'
import { existsSync } from 'fs'

export class FileSystemSessionRepository extends ISessionRepository {
  constructor(storageDir = '~/.config/flow-cli/sessions') {
    super()
    this.storageDir = storageDir.replace('~', process.env.HOME)
    this.ensureDir()
  }

  async ensureDir() {
    if (!existsSync(this.storageDir)) {
      await mkdir(this.storageDir, { recursive: true })
    }
  }

  async save(session) {
    const filePath = join(this.storageDir, `${session.id}.json`)
    const data = this.toJSON(session)
    await writeFile(filePath, JSON.stringify(data, null, 2))
    return session
  }

  async findById(sessionId) {
    try {
      const filePath = join(this.storageDir, `${sessionId}.json`)
      const content = await readFile(filePath, 'utf-8')
      return this.toEntity(JSON.parse(content))
    } catch (error) {
      if (error.code === 'ENOENT') return null
      throw error
    }
  }

  async findActive() {
    const all = await this.list({ state: 'active' })
    return all[0] || null
  }

  async list(filters = {}) {
    const files = await readdir(this.storageDir)
    const sessions = []

    for (const file of files) {
      if (!file.endsWith('.json')) continue

      const session = await this.findById(file.replace('.json', ''))
      if (session && this.matchesFilters(session, filters)) {
        sessions.push(session)
      }
    }

    return sessions
  }

  toJSON(session) {
    return {
      id: session.id,
      project: session.project,
      task: session.task,
      branch: session.branch,
      context: session.context,
      startTime: session.startTime.toISOString(),
      endTime: session.endTime?.toISOString() || null,
      state: session.state,
      outcome: session.outcome
    }
  }

  toEntity(json) {
    const session = new Session(json.id, json.project, {
      task: json.task,
      branch: json.branch,
      context: json.context,
      startTime: new Date(json.startTime)
    })

    if (json.endTime) session.endTime = new Date(json.endTime)
    session.state = json.state
    session.outcome = json.outcome

    return session
  }

  matchesFilters(session, filters) {
    if (filters.state && session.state !== filters.state) return false
    if (filters.project && session.project !== filters.project) return false
    return true
  }
}
```

**2. Dependency Injection Container**
```javascript
// cli/frameworks/di/container.js
import { CreateSessionUseCase } from '../../use-cases/session/CreateSessionUseCase.js'
import { EndSessionUseCase } from '../../use-cases/session/EndSessionUseCase.js'
import { FileSystemSessionRepository } from '../../adapters/repositories/FileSystemSessionRepository.js'
import { SimpleEventPublisher } from '../events/SimpleEventPublisher.js'

export function createContainer() {
  // Repositories
  const sessionRepository = new FileSystemSessionRepository()

  // Services
  const eventPublisher = new SimpleEventPublisher()

  // Use Cases
  const createSession = new CreateSessionUseCase(
    sessionRepository,
    null, // projectRepository - implement later
    eventPublisher
  )

  const endSession = new EndSessionUseCase(
    sessionRepository,
    eventPublisher
  )

  return {
    repositories: {
      sessionRepository
    },
    useCases: {
      createSession,
      endSession
    }
  }
}
```

**✅ Quick Win:** Sessions persist to `~/.config/flow-cli/sessions/` directory

**Testing:**
```bash
# Create test script
node -e "
import { createContainer } from './cli/frameworks/di/container.js'

const container = createContainer()
const session = await container.useCases.createSession.execute({
  project: 'test',
  task: 'Testing persistence'
})

console.log('Created session:', session.id)

# Check file exists
ls ~/.config/flow-cli/sessions/
"
```

---

### Day 4-5: Enhanced Features (Option B)

**Goal:** Immediate user-facing improvements

#### 1. Enhanced Status Command

**Features:**
- Current session info
- Session duration (live)
- Project context
- Recent sessions
- Quick actions

```javascript
// cli/adapters/controllers/StatusController.js
export class StatusController {
  constructor(getSessionUseCase, listSessionsUseCase) {
    this.getSession = getSessionUseCase
    this.listSessions = listSessionsUseCase
  }

  async handle() {
    const active = await this.getSession.execute()

    if (!active) {
      console.log('❌ No active session')
      await this.showRecent()
      return
    }

    // Active session display
    console.log('✅ Active Session')
    console.log(`   Project: ${active.project}`)
    console.log(`   Task: ${active.task}`)
    console.log(`   Duration: ${active.getDuration()} min`)
    console.log(`   Branch: ${active.branch}`)

    if (active.isInFlowState()) {
      console.log('   🔥 IN FLOW STATE')
    }

    // Context
    if (Object.keys(active.context).length > 0) {
      console.log('\n📝 Context:')
      for (const [key, value] of Object.entries(active.context)) {
        console.log(`   ${key}: ${value}`)
      }
    }

    await this.showRecent(active.id)
  }

  async showRecent(excludeId) {
    const recent = await this.listSessions.execute({
      limit: 5,
      orderBy: 'startTime',
      order: 'desc'
    })

    const filtered = recent.filter(s => s.id !== excludeId)

    if (filtered.length > 0) {
      console.log('\n📜 Recent Sessions:')
      for (const session of filtered.slice(0, 3)) {
        console.log(`   ${session.project} (${session.getDuration()} min)`)
      }
    }
  }
}
```

#### 2. Better Project Picker

**Features:**
- Filter by type
- Filter by status (active/draft/complete)
- Sort by last accessed
- Show project metadata
- Quick search

```javascript
// cli/adapters/controllers/ProjectPickerController.js
export class ProjectPickerController {
  constructor(scanProjectsUseCase, fuzzySearchService) {
    this.scanProjects = scanProjectsUseCase
    this.fuzzySearch = fuzzySearchService
  }

  async handle(options = {}) {
    const { filter, type, status, search } = options

    // Scan projects
    let projects = await this.scanProjects.execute({
      basePath: '~/projects',
      types: type ? [type] : []
    })

    // Filter by status
    if (status) {
      projects = projects.filter(p =>
        p.status?.currentStatus === status
      )
    }

    // Search
    if (search) {
      projects = this.fuzzySearch.search(projects, search, ['name', 'path'])
    }

    // Sort by last accessed
    projects.sort((a, b) =>
      (b.lastAccessed || 0) - (a.lastAccessed || 0)
    )

    // Display with fzf
    return await this.displayWithFzf(projects)
  }

  async displayWithFzf(projects) {
    // Use fzf for selection
    // Implementation uses existing fzf integration
  }
}
```

#### 3. Task Management Basics

```javascript
// cli/domain/entities/Task.js
export class Task {
  constructor(id, description, options = {}) {
    this.id = id
    this.description = description
    this.completed = false
    this.priority = options.priority || 'medium'
    this.project = options.project || null
    this.createdAt = new Date()
    this.completedAt = null
  }

  complete() {
    if (this.completed) {
      throw new Error('Task already completed')
    }
    this.completed = true
    this.completedAt = new Date()
  }

  reopen() {
    if (!this.completed) {
      throw new Error('Task not completed')
    }
    this.completed = false
    this.completedAt = null
  }
}

// cli/use-cases/task/CreateTaskUseCase.js
export class CreateTaskUseCase {
  constructor(taskRepository) {
    this.taskRepository = taskRepository
  }

  async execute({ description, priority, project }) {
    const task = new Task(this.generateId(), description, {
      priority,
      project
    })

    await this.taskRepository.save(task)
    return task
  }

  generateId() {
    return `task-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
  }
}
```

**✅ Quick Win:** Working enhanced commands with real user value

---

## 📅 Week 2: P6 CLI Enhancements (Option C)

### Day 6: Enhanced Status Command ✅ COMPLETE

**Goal:** Professional status display with all context

**Completed:** 2025-12-23
- ✅ StatusController (266 lines)
- ✅ CLI command with full help system
- ✅ Worklog integration
- ✅ 9 integration tests (274 total tests passing)
- ✅ Follows HELP-CREATION-WORKFLOW.md standards

### Day 7: Status Command Polish + .STATUS v2

**Goal:** Visual enhancements + Modern .STATUS format

**See Also:**
- docs/planning/proposals/STATUS-COMMAND-ENHANCEMENTS.md (106 enhancement ideas)
- docs/planning/proposals/PROJECT-COORDINATION-SYSTEM.md (cross-project coordination)

#### Part 1: Visual Polish (Morning, 2h)

**1. Color-Coded Output with Chalk**
```javascript
// cli/adapters/controllers/StatusController.js
import chalk from 'chalk'

displayActiveSession(session, verbose) {
  console.log(chalk.green.bold('✅ Active Session'))
  console.log(chalk.cyan(`   Project: ${session.project}`))
  console.log(chalk.yellow(`   Task: ${session.task || 'No task specified'}`))

  const flowIndicator = session.isFlowState ? chalk.red.bold(' 🔥 IN FLOW') : ''
  console.log(chalk.white(`   Duration: ${session.duration} min${flowIndicator}`))
}
```

**2. Box Drawing Characters**
```javascript
// Structure output with unicode box chars
console.log('╭─────────────────────────────────────╮')
console.log('│ 🔥 ACTIVE SESSION                   │')
console.log('├─────────────────────────────────────┤')
console.log(`│ Project: ${session.project.padEnd(24)} │`)
console.log('╰─────────────────────────────────────╯')
```

**3. Git Status Integration**
```javascript
// cli/adapters/gateways/GitGateway.js
export class GitGateway {
  async getStatus(projectPath) {
    // Run git status --porcelain
    // Return { branch, ahead, behind, dirty, uncommittedFiles: [...] }
  }
}

// In StatusController
if (verbose && session.gitStatus) {
  console.log(chalk.yellow(`   Uncommitted changes: ${session.gitStatus.uncommittedFiles.length}`))
}
```

**4. .STATUS File Parsing**
```javascript
// cli/adapters/gateways/StatusFileGateway.js
export class StatusFileGateway {
  async read(projectPath) {
    // Read .STATUS file
    // Parse YAML frontmatter if present
    // Return { status, progress, next: [...] }
  }
}

// In StatusController
if (status.nextActions && status.nextActions.length > 0) {
  console.log(chalk.magenta('📌 Next Action:'))
  console.log(`   ${status.nextActions[0].action}`)
}
```

#### Part 2: .STATUS v2 Foundation (Afternoon, 2h)

**1. YAML Frontmatter Format**
```yaml
---
# .STATUS v2 format
status: active | paused | archived | complete
progress: 0-100
type: r-package | quarto | research | node | python | generic

# Next actions (user-editable)
next:
  - action: "Write tests for bootstrap function"
    estimate: "2h"
    priority: high
    blockers: []

# Auto-updated fields (do not edit manually)
metrics:
  sessions_total: 45
  sessions_this_week: 5
  total_duration_minutes: 2340
  last_session: 2025-12-23T10:00:00Z
  last_updated: 2025-12-23T18:30:00Z
---

# Project Status Notes
Manual notes go here...
```

**2. .STATUS Validator**
```javascript
// cli/domain/validators/StatusFileValidator.js
export class StatusFileValidator {
  validate(content) {
    const { frontmatter, body } = this.parse(content)

    // Required fields
    if (!['active', 'paused', 'archived', 'complete'].includes(frontmatter.status)) {
      return { valid: false, error: 'Invalid status value' }
    }

    if (frontmatter.progress < 0 || frontmatter.progress > 100) {
      return { valid: false, error: 'Progress must be 0-100' }
    }

    // Validate next actions structure
    if (frontmatter.next) {
      for (const action of frontmatter.next) {
        if (!action.action) {
          return { valid: false, error: 'Next action missing "action" field' }
        }
      }
    }

    return { valid: true }
  }
}
```

**3. Auto-Update Mechanism**
```javascript
// cli/use-cases/status/UpdateStatusFileUseCase.js
export class UpdateStatusFileUseCase {
  async execute({ projectPath }) {
    // Read existing .STATUS
    const status = await this.statusFileGateway.read(projectPath)

    // Get session metrics from repository
    const sessions = await this.sessionRepository.list({
      project: projectPath,
      since: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) // 7 days
    })

    // Update metrics
    status.metrics = {
      sessions_total: sessions.length,
      sessions_this_week: sessions.filter(s => s.isThisWeek()).length,
      total_duration_minutes: sessions.reduce((sum, s) => sum + s.getDuration(), 0),
      last_session: sessions[0]?.startTime,
      last_updated: new Date()
    }

    // Write back to file
    await this.statusFileGateway.write(projectPath, status)
  }
}
```

**Deliverables:**
- [ ] Chalk integration (color-coded output)
- [ ] Box drawing characters for structure
- [ ] Git status integration in verbose mode
- [ ] .STATUS file parsing for next action display
- [ ] .STATUS v2 YAML format specification
- [ ] StatusFileValidator with tests
- [ ] UpdateStatusFileUseCase with auto-update
- [ ] Tests for all new features

---

### Day 8-9: Hybrid Dashboard (CLI + Web)

**Goal:** Flexible dashboard with default CLI + optional rich web UI

**Decision:** After analyzing TUI cons (terminal compatibility, ADHD concerns, maintenance burden), we're implementing a hybrid approach that gives users choice without breaking changes.

**See Also:**
- docs/planning/proposals/TUI-ALTERNATIVES-ANALYSIS.md (decision rationale)

#### Architecture

**1. Default Mode: Enhanced CLI**
```bash
flow status        # Fast ASCII output (current behavior)
flow status -v     # Verbose with ASCII charts
```

**2. Optional Web Dashboard**
```bash
flow status --web  # Opens browser with rich dashboard
```

#### Phase 1: Web Dashboard Foundation (1.5 hours)

**1. Express Server + WebSocket**
```javascript
// cli/web/WebDashboard.js
import express from 'express'
import { WebSocketServer } from 'ws'
import { fileURLToPath } from 'url'
import { dirname, join } from 'path'

export class WebDashboard {
  constructor(getStatusUseCase, eventPublisher) {
    this.getStatus = getStatusUseCase
    this.eventPublisher = eventPublisher
    this.app = express()
    this.wss = null
    this.server = null
  }

  async start(port = 3737) {
    // Serve static dashboard HTML
    const __dirname = dirname(fileURLToPath(import.meta.url))
    this.app.use(express.static(join(__dirname, 'public')))

    // API endpoint
    this.app.get('/api/status', async (req, res) => {
      const status = await this.getStatus.execute()
      res.json(status)
    })

    // Start server
    this.server = this.app.listen(port)

    // Setup WebSocket for live updates
    this.wss = new WebSocketServer({ server: this.server })

    this.wss.on('connection', (ws) => {
      // Send initial status
      this.sendStatus(ws)

      // Subscribe to events
      const listener = () => this.sendStatus(ws)
      this.eventPublisher.on('session:updated', listener)

      ws.on('close', () => {
        this.eventPublisher.off('session:updated', listener)
      })
    })

    return `http://localhost:${port}`
  }

  async sendStatus(ws) {
    const status = await this.getStatus.execute()
    ws.send(JSON.stringify({ type: 'status', data: status }))
  }

  stop() {
    this.wss?.close()
    this.server?.close()
  }
}
```

**2. Single-File HTML Dashboard**
```html
<!-- cli/web/public/index.html -->
<!DOCTYPE html>
<html>
<head>
  <title>Flow CLI Dashboard</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4"></script>
  <style>
    body {
      font-family: -apple-system, system-ui, sans-serif;
      background: #1e1e1e;
      color: #d4d4d4;
      margin: 0;
      padding: 20px;
    }
    .container { max-width: 1200px; margin: 0 auto; }
    .card {
      background: #2d2d2d;
      border-radius: 8px;
      padding: 20px;
      margin-bottom: 20px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.3);
    }
    .session-active { border-left: 4px solid #00ff00; }
    .session-inactive { border-left: 4px solid #666; }
    h1 { margin-top: 0; }
    .metric { display: inline-block; margin-right: 30px; }
    .metric-value { font-size: 2em; font-weight: bold; }
    .metric-label { color: #888; font-size: 0.9em; }
  </style>
</head>
<body>
  <div class="container">
    <h1>🚀 Flow CLI Dashboard</h1>

    <div id="active-session" class="card"></div>
    <div id="metrics" class="card"></div>
    <div id="charts" class="card">
      <canvas id="sessionChart"></canvas>
    </div>
    <div id="projects" class="card"></div>
  </div>

  <script>
    const ws = new WebSocket('ws://localhost:3737')
    let chart = null

    ws.onmessage = (event) => {
      const { type, data } = JSON.parse(event.data)
      if (type === 'status') updateDashboard(data)
    }

    function updateDashboard(status) {
      updateActiveSession(status.activeSession)
      updateMetrics(status.metrics)
      updateChart(status.history)
      updateProjects(status.projects)
    }

    function updateActiveSession(session) {
      const el = document.getElementById('active-session')
      if (!session) {
        el.className = 'card session-inactive'
        el.innerHTML = '<h2>❌ No Active Session</h2>'
        return
      }

      el.className = 'card session-active'
      const flowBadge = session.isFlowState ? '🔥 IN FLOW' : ''
      el.innerHTML = `
        <h2>✅ Active Session ${flowBadge}</h2>
        <p><strong>Project:</strong> ${session.project}</p>
        <p><strong>Task:</strong> ${session.task || 'No task specified'}</p>
        <p><strong>Duration:</strong> ${session.duration} min</p>
        <p><strong>Branch:</strong> ${session.branch}</p>
      `
    }

    function updateMetrics(metrics) {
      const el = document.getElementById('metrics')
      el.innerHTML = `
        <h2>📊 Metrics</h2>
        <div class="metric">
          <div class="metric-value">${metrics.totalSessions}</div>
          <div class="metric-label">Total Sessions</div>
        </div>
        <div class="metric">
          <div class="metric-value">${metrics.flowSessions}</div>
          <div class="metric-label">Flow Sessions</div>
        </div>
        <div class="metric">
          <div class="metric-value">${Math.round(metrics.totalDuration / 60)}h</div>
          <div class="metric-label">Total Time</div>
        </div>
      `
    }

    function updateChart(history) {
      const ctx = document.getElementById('sessionChart')

      if (chart) chart.destroy()

      chart = new Chart(ctx, {
        type: 'line',
        data: {
          labels: history.map(h => h.date),
          datasets: [{
            label: 'Session Duration (min)',
            data: history.map(h => h.duration),
            borderColor: '#00ff00',
            backgroundColor: 'rgba(0, 255, 0, 0.1)'
          }]
        },
        options: {
          responsive: true,
          plugins: { legend: { labels: { color: '#d4d4d4' } } },
          scales: {
            x: { ticks: { color: '#888' } },
            y: { ticks: { color: '#888' } }
          }
        }
      })
    }
  </script>
</body>
</html>
```

**3. Integration in StatusController**
```javascript
// cli/adapters/controllers/StatusController.js
import { WebDashboard } from '../../web/WebDashboard.js'
import open from 'open'

async handle(options = {}) {
  if (options.web) {
    return await this.launchWebDashboard()
  }

  // Default CLI output
  return await this.displayCLI(options)
}

async launchWebDashboard() {
  const dashboard = new WebDashboard(this.getStatus, this.eventPublisher)
  const url = await dashboard.start()

  console.log(chalk.green(`✅ Dashboard started at ${url}`))
  console.log(chalk.gray('Opening browser...'))

  await open(url)

  console.log(chalk.yellow('Press Ctrl+C to stop dashboard'))

  // Keep process alive
  await new Promise(() => {})
}
```

#### Phase 2: Rich Visualizations (1 hour)

**1. Chart.js Integration**
- Session duration over time (line chart)
- Project distribution (pie chart)
- Flow sessions vs regular (bar chart)
- Completion rate trends (area chart)

**2. Real-Time Updates**
- Session duration updates every second
- Live metrics refresh on session events
- Smooth chart animations

#### Phase 3: Enhanced CLI (30 min)

**1. ASCII Sparklines**
```bash
Session Trend: ▁▂▃▅▇█▇▅▃▂▁ (last 10 days)
```

**2. Progress Bars**
```bash
Progress: [████████████░░░░░░░░] 60%
```

**Deliverables:**
- [ ] Express server with WebSocket support
- [ ] Single-file HTML dashboard with Chart.js
- [ ] --web flag in status command
- [ ] Auto-open browser functionality
- [ ] Real-time updates via WebSocket
- [ ] ASCII enhancements for CLI mode
- [ ] Tests for web dashboard
- [ ] Documentation for both modes

**Benefits of Hybrid Approach:**
- ✅ No breaking changes (CLI still works)
- ✅ Users choose complexity level
- ✅ Best of both worlds
- ✅ ADHD-friendly (can switch based on need)
- ✅ Scriptable CLI + rich monitoring

---

### Day 10: Advanced Project Scanning

**Goal:** Fast, smart, cached project discovery

#### Optimizations

**1. Parallel Scanning**
```javascript
// Scan multiple directories in parallel
const results = await Promise.all([
  scanDirectory('~/projects/r-packages'),
  scanDirectory('~/projects/quarto'),
  scanDirectory('~/projects/research')
])
```

**2. Cache Layer**
```javascript
// cli/adapters/cache/ProjectCache.js
export class ProjectCache {
  constructor(ttl = 3600000) { // 1 hour
    this.cache = new Map()
    this.ttl = ttl
  }

  get(path) {
    const entry = this.cache.get(path)
    if (!entry) return null

    if (Date.now() - entry.timestamp > this.ttl) {
      this.cache.delete(path)
      return null
    }

    return entry.data
  }

  set(path, data) {
    this.cache.set(path, {
      data,
      timestamp: Date.now()
    })
  }
}
```

**3. Smart Filters**
```javascript
// Filter by:
// - Type (r-package, quarto, research)
// - Status (active, draft, complete)
// - Last accessed (today, this week, this month)
// - Has tasks (yes/no)
```

**4. Recent Projects Tracking**
```javascript
// Track in ~/.config/flow-cli/recent-projects.json
// Sort by:
// - Last accessed (MRU)
// - Most sessions
// - Total time spent
```

**✅ Quick Win:** Project picker is 10x faster with caching

---

## 🎯 Success Metrics

### Week 1 Success Criteria

- [ ] Domain layer exists with 0 violations (arch-dashboard)
- [ ] Can create/end sessions via use cases
- [ ] Sessions persist to file system
- [ ] Enhanced status command works
- [ ] Project picker has filters
- [ ] Basic task management works

### Week 2 Success Criteria

- [ ] Status command shows full context + history
- [ ] TUI dashboard runs and updates in real-time
- [ ] Project scanning uses cache (3x faster)
- [ ] All features tested and working
- [ ] Documentation updated
- [ ] Architecture dashboard shows green (no violations)

---

## 🧪 Testing Strategy

### Unit Tests (Domain)
```javascript
// tests/domain/entities/Session.test.js
describe('Session Entity', () => {
  test('cannot end inactive session', () => {
    const session = new Session('id', 'project')
    session.end()
    expect(() => session.end()).toThrow()
  })
})
```

### Integration Tests (Use Cases)
```javascript
// tests/use-cases/CreateSessionUseCase.test.js
describe('CreateSessionUseCase', () => {
  test('creates session successfully', async () => {
    const repo = new InMemorySessionRepository()
    const useCase = new CreateSessionUseCase(repo)

    const session = await useCase.execute({ project: 'test' })
    expect(session.project).toBe('test')
  })
})
```

### E2E Tests (CLI)
```bash
# tests/e2e/session-workflow.test.sh
flow work rmediation "Fix bug"
flow status  # Should show active session
flow finish "Bug fixed"
flow status  # Should show no active session
```

---

## 📝 Documentation Updates

### After Week 1
- [ ] Update GETTING-STARTED.md with real implementation
- [ ] Add implementation examples to CODE-EXAMPLES.md
- [ ] Document new commands in README.md
- [ ] Update .STATUS with progress

### After Week 2
- [ ] Create TUI-DASHBOARD.md user guide
- [ ] Update PROJECT-HUB.md (mark P6 complete)
- [ ] Write blog post about implementation
- [ ] Record demo video

---

## 🚀 Deployment Plan

### Phase 1: Alpha Release (After Week 1)
```bash
git checkout -b feature/clean-architecture-implementation
# Commit daily progress
git push origin feature/clean-architecture-implementation
# Create PR for review
```

### Phase 2: Beta Release (After Week 2)
```bash
# Merge to dev
git checkout dev
git merge feature/clean-architecture-implementation

# Tag release
git tag v0.2.0-beta
git push origin v0.2.0-beta

# Publish to npm (beta)
npm publish --tag beta
```

### Phase 3: Production (After testing)
```bash
# Merge to main
git checkout main
git merge dev

# Tag stable release
git tag v0.2.0
git push origin v0.2.0

# Publish to npm
npm publish
```

---

## 🎉 Expected Outcomes

### Technical
- ✅ Clean Architecture fully implemented
- ✅ 100% test coverage on domain layer
- ✅ Zero architecture violations
- ✅ Fast, cached project scanning
- ✅ Professional TUI interface

### User Experience
- ✅ Enhanced status command with full context
- ✅ Better project picker (10x faster)
- ✅ Task management basics
- ✅ Beautiful terminal dashboard
- ✅ All P6 features delivered

### Development
- ✅ Codebase matches documentation
- ✅ Easy to add new features
- ✅ High maintainability
- ✅ Clear testing strategy
- ✅ Production-ready quality

---

**Ready to start?**

**Next Command:**
```bash
mkdir -p cli/domain/{entities,value-objects,repositories}
```

Then we'll build the Session entity together! 🚀

---

**Last Updated:** 2025-12-23
**Status:** Ready to implement
**Estimated Completion:** 2 weeks

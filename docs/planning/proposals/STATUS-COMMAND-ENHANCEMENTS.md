# Status Command Enhancements - Comprehensive Proposal

**Created:** 2025-12-23
**Status:** Planning
**Priority:** High
**Estimated Effort:** 2-3 weeks

---

## 🎯 Executive Summary

This proposal outlines enhancements to the `flow status` command and project management files (.STATUS, PROJECT.yml, etc.) to create a comprehensive, ADHD-friendly workflow management system.

**Key Goals:**
1. Make status command visually appealing and scannable
2. Add intelligent insights and recommendations
3. Standardize project metadata across ecosystem
4. Enable cross-project coordination
5. Reduce cognitive load for ADHD developers

---

## 📊 Priority Matrix

### Tier 1: Quick Wins (Week 2 Day 7) ⚡
**High value + Low effort - Implement immediately**

| Feature | Effort | Impact | Status |
|---------|--------|--------|--------|
| Color-coded output | 30min | High | ⏳ Planned |
| Box drawing characters | 1h | High | ⏳ Planned |
| Git status integration | 1-2h | High | ⏳ Planned |
| Parse .STATUS file | 1h | High | ⏳ Planned |
| Better worklog display | 1h | Medium | ⏳ Planned |
| YAML .STATUS format | 1-2h | High | ⏳ Planned |
| .STATUS validator | 1h | Medium | ⏳ Planned |
| Auto-update .STATUS | 2h | High | ⏳ Planned |

**Total Tier 1 Effort:** ~10 hours (1-2 days)

### Tier 2: Medium-Term (Days 8-10) 📅
**High value + Medium effort**

| Feature | Effort | Impact |
|---------|--------|--------|
| Interactive TUI dashboard | 6-8h | Very High |
| Smart suggestions engine | 4-6h | High |
| Project graph visualization | 2-3h | Medium |
| Unified project registry | 3-4h | High |
| Cross-project sync | 3-4h | Medium |
| Advanced scanning/caching | 3-4h | Medium |

**Total Tier 2 Effort:** ~24 hours (3 days)

### Tier 3: Strategic (Week 3+) 🎯
**High value + High effort - Plan ahead**

| Feature | Effort | Impact |
|---------|--------|--------|
| ML-based recommendations | 1-2 weeks | Very High |
| Team collaboration | 1-2 weeks | Medium |
| Multi-device sync | 1 week | Medium |
| Ecosystem health monitoring | 3-5 days | High |
| GitHub integration | 3-5 days | Medium |

---

## 🎨 Part 1: Visual & UX Enhancements

### A1. Color-Coded Output ⚡ TIER 1

**Implementation:**
```javascript
import chalk from 'chalk'

// Color scheme
const colors = {
  active: chalk.green,
  paused: chalk.yellow,
  ended: chalk.gray,
  flow: chalk.bold.red,
  success: chalk.green,
  warning: chalk.yellow,
  error: chalk.red,
  info: chalk.blue,
  metric: chalk.cyan
}

// Usage
console.log(colors.active('✅ Active Session'))
console.log(colors.flow('🔥 IN FLOW STATE'))
```

**Benefit:** Immediate visual scanning, 80% faster information location

### A2. Box Drawing Characters ⚡ TIER 1

**Implementation:**
```javascript
// Use Unicode box drawing
const box = {
  topLeft: '┌',
  topRight: '┐',
  bottomLeft: '└',
  bottomRight: '┘',
  horizontal: '─',
  vertical: '│',
  divider: '├─'
}

// Example output:
┌─────────────────────────────────────┐
│ ✅ Active Session                   │
│    Project: rmediation              │
│    Duration: 45m 🔥 IN FLOW         │
└─────────────────────────────────────┘
```

**Benefit:** Structured, scannable, professional appearance

### A3. Progress Bars

**Implementation:**
```javascript
import cliProgress from 'cli-progress'

// Show today's goal progress
const bar = new cliProgress.SingleBar({
  format: 'Today |{bar}| {percentage}% | {value}/{total} sessions'
})
bar.start(5, 3) // Goal: 5, current: 3
```

**Benefit:** Visual progress feedback, motivation

### A4. Sparklines for Trends

**Implementation:**
```javascript
import sparkly from 'sparkly'

// Last 7 days session duration
const data = [30, 45, 60, 40, 55, 70, 45]
console.log(`Trend: ${sparkly(data)}`)
// Output: Trend: ▁▃▅▂▄▇▃
```

---

## 📈 Part 2: Data & Intelligence

### B1. Focus Quality Score ⚡ TIER 1

**Algorithm:**
```javascript
calculateFocusScore(sessions) {
  const weights = {
    flowPercentage: 0.4,
    completionRate: 0.3,
    averageDuration: 0.2,
    streak: 0.1
  }

  const score =
    (sessions.flowPercentage * weights.flowPercentage) +
    (sessions.completionRate * weights.completionRate) +
    (Math.min(sessions.avgDuration / 60, 1) * weights.averageDuration * 100) +
    (Math.min(sessions.streak / 7, 1) * weights.streak * 100)

  return Math.round(score)
}

// Display
console.log(`Focus Quality: ${score}/100 ${getGrade(score)}`)
// Output: Focus Quality: 87/100 🏆 Excellent
```

**Grades:**
- 90-100: 🏆 Excellent
- 75-89: ⭐ Great
- 60-74: 👍 Good
- 40-59: 📊 Average
- 0-39: 📉 Needs Work

### B2. Smart Suggestions 📅 TIER 2

**Pattern Detection:**
```javascript
// Analyze historical data
const patterns = {
  bestHours: detectBestWorkingHours(sessions),
  preferredDuration: calculateOptimalDuration(sessions),
  productiveProjects: rankByProductivity(sessions),
  breakNeeds: detectBreakPatterns(sessions)
}

// Generate suggestions
if (currentTime in patterns.bestHours) {
  suggest("You're in your peak productivity window!")
}

if (currentDuration > patterns.preferredDuration) {
  suggest("You usually work best in shorter sessions. Take a break?")
}
```

### B3. Burnout Detection

**Indicators:**
```javascript
const burnoutRisk = {
  tooManyLongSessions: sessions.filter(s => s.duration > 120).length > 3,
  noBreaks: timeSinceLastBreak > 180,
  weekendWork: sessionsOnWeekend.length > 5,
  rapidSwitching: uniqueProjects > 8
}

if (burnoutRisk.tooManyLongSessions) {
  warn("⚠️  You've had 3+ long sessions. Consider shorter, focused work.")
}
```

---

## 🔗 Part 3: Integration Features

### C1. Git Integration ⚡ TIER 1

**Implementation:**
```javascript
import { execSync } from 'child_process'

async function getGitStatus(projectPath) {
  try {
    const status = execSync('git status --porcelain', {
      cwd: projectPath,
      encoding: 'utf-8'
    })

    const branch = execSync('git branch --show-current', {
      cwd: projectPath,
      encoding: 'utf-8'
    }).trim()

    const ahead = execSync('git rev-list --count @{u}..HEAD 2>/dev/null || echo 0', {
      cwd: projectPath,
      encoding: 'utf-8'
    }).trim()

    return {
      branch,
      uncommitted: status.split('\n').filter(Boolean).length,
      ahead: parseInt(ahead),
      clean: status.length === 0
    }
  } catch (error) {
    return null
  }
}

// Display
const git = await getGitStatus(activeSession.projectPath)
if (git && !git.clean) {
  console.log(`   Git: ${git.uncommitted} uncommitted changes`)
}
if (git && git.ahead > 0) {
  console.log(`   Git: ${git.ahead} commits ahead of origin`)
}
```

### C2. .STATUS File Parsing ⚡ TIER 1

**Implementation:**
```javascript
import { readFile } from 'fs/promises'
import yaml from 'yaml'

async function parseStatusFile(projectPath) {
  const statusPath = join(projectPath, '.STATUS')

  if (!existsSync(statusPath)) return null

  const content = await readFile(statusPath, 'utf-8')

  // Parse YAML frontmatter
  const match = content.match(/^---\n([\s\S]*?)\n---/)
  if (match) {
    const frontmatter = yaml.parse(match[1])
    const body = content.slice(match[0].length).trim()

    return { ...frontmatter, body }
  }

  // Fallback: parse old format
  const lines = content.split('\n')
  const status = {}
  for (const line of lines) {
    const [key, value] = line.split(':').map(s => s.trim())
    if (key && value) status[key] = value
  }

  return status
}

// Display
const status = await parseStatusFile(activeSession.projectPath)
if (status?.next) {
  console.log(`   Next: ${status.next}`)
}
```

### C3. Worklog Enhanced Display

**Implementation:**
```javascript
// Group worklog by action type
function summarizeWorklog(entries) {
  const summary = {
    commits: [],
    sessions: [],
    milestones: []
  }

  for (const entry of entries) {
    if (entry.action.includes('commit')) {
      summary.commits.push(entry)
    } else if (entry.action.includes('session')) {
      summary.sessions.push(entry)
    }
  }

  return summary
}

// Display
const worklog = await readWorklog()
const summary = summarizeWorklog(worklog.slice(0, 10))

console.log('📝 Recent Activity')
console.log(`   ${summary.commits.length} commits`)
console.log(`   ${summary.sessions.length} sessions`)
if (summary.commits.length > 0) {
  console.log(`   Last commit: ${summary.commits[0].details}`)
}
```

---

## 🗂️ Part 4: Project Management Files

### D1. .STATUS v2 Format (YAML) ⚡ TIER 1

**Schema:**
```yaml
---
# Required fields
status: active | paused | archived | complete
progress: 0-100
type: r-package | quarto | research | node | python | generic

# Priority & timing
priority: p0 | p1 | p2 | p3
deadline: 2025-12-31  # ISO date or null
estimated_completion: 2025-02-15

# Ownership
owner: DT
team: solo | small | large
visibility: private | team | public

# Next actions
next:
  - action: "Write tests for bootstrap function"
    estimate: "2h"
    priority: high
    blockers: []
  - action: "Update documentation"
    estimate: "1h"
    priority: medium

# Metadata
tags: [statistics, production, r]
phase: development | testing | documentation | maintenance

# Auto-updated fields (do not edit manually)
metrics:
  sessions_total: 45
  sessions_this_week: 5
  total_duration_minutes: 2340
  last_session: 2025-12-23T10:00:00Z
  last_updated: 2025-12-23T18:30:00Z
  avg_session_duration: 52

# Related projects
related:
  dependencies: [medfit, probmed]
  dependents: [mediationverse]
  docs: [quarto-mediation-guide]

# Links
links:
  repository: https://github.com/user/rmediation
  ci: https://github.com/user/rmediation/actions
  docs: https://user.github.io/rmediation
  issues: https://github.com/user/rmediation/issues
---

# Project Status Notes

## Current Sprint (Week of 2025-12-23)

### In Progress
- [ ] Bootstrap variance estimation
- [ ] Add unit tests for edge cases

### Completed This Week
- [x] Implemented basic mediation function
- [x] Added documentation examples

### Blocked
- [ ] Bayesian extension (waiting on methodology decision)

## Recent Decisions
- 2025-12-20: Chose percentile bootstrap over BCa (simpler implementation)
- 2025-12-18: Decided against multilevel mediation (scope creep)

## Notes
The bootstrap implementation is working well. Edge case with zero-variance mediators needs attention.
```

**Migration Script:**
```javascript
// Convert old .STATUS to new format
async function migrateStatus(oldStatusPath) {
  const content = await readFile(oldStatusPath, 'utf-8')
  const lines = content.split('\n')

  const newStatus = {
    status: 'active',
    progress: 0,
    type: 'generic',
    priority: 'p1',
    next: [],
    tags: [],
    metrics: {},
    related: {},
    links: {}
  }

  // Parse old format
  for (const line of lines) {
    const [key, value] = line.split(':').map(s => s.trim())
    if (key === 'status') newStatus.status = value
    if (key === 'progress') newStatus.progress = parseInt(value)
    if (key === 'next') newStatus.next.push({ action: value, estimate: null })
    // ... more mappings
  }

  // Write new format
  const yaml = YAML.stringify(newStatus)
  await writeFile(oldStatusPath, `---\n${yaml}---\n\n# Notes\n`)
}
```

### D2. .STATUS Validator ⚡ TIER 1

**Implementation:**
```javascript
function validateStatus(status) {
  const errors = []
  const warnings = []

  // Required fields
  if (!status.status) errors.push('Missing required field: status')
  if (status.progress === undefined) errors.push('Missing required field: progress')
  if (!status.type) errors.push('Missing required field: type')

  // Value validation
  if (status.progress < 0 || status.progress > 100) {
    errors.push('progress must be between 0 and 100')
  }

  const validStatuses = ['active', 'paused', 'archived', 'complete']
  if (!validStatuses.includes(status.status)) {
    errors.push(`status must be one of: ${validStatuses.join(', ')}`)
  }

  // Staleness check
  if (status.metrics?.last_updated) {
    const daysSince = (Date.now() - new Date(status.metrics.last_updated)) / (1000 * 60 * 60 * 24)
    if (daysSince > 7) {
      warnings.push(`.STATUS hasn't been updated in ${Math.floor(daysSince)} days`)
    }
  }

  // Next action check
  if (status.status === 'active' && (!status.next || status.next.length === 0)) {
    warnings.push('Active project should have next actions defined')
  }

  return { valid: errors.length === 0, errors, warnings }
}

// CLI command
async function validateCommand() {
  const statusPath = '.STATUS'
  const status = await parseStatusFile('.')

  const result = validateStatus(status)

  if (result.valid) {
    console.log(chalk.green('✓ .STATUS file is valid'))
  } else {
    console.log(chalk.red('✗ .STATUS file has errors:'))
    result.errors.forEach(e => console.log(`  - ${e}`))
  }

  if (result.warnings.length > 0) {
    console.log(chalk.yellow('\n⚠ Warnings:'))
    result.warnings.forEach(w => console.log(`  - ${w}`))
  }
}
```

### D3. Auto-Update .STATUS ⚡ TIER 1

**Implementation:**
```javascript
// In EndSessionUseCase
async function updateProjectStatus(session, projectPath) {
  const statusPath = join(projectPath, '.STATUS')

  if (!existsSync(statusPath)) return

  const status = await parseStatusFile(projectPath)

  // Update metrics
  if (!status.metrics) status.metrics = {}

  status.metrics.sessions_total = (status.metrics.sessions_total || 0) + 1
  status.metrics.total_duration_minutes =
    (status.metrics.total_duration_minutes || 0) + session.getDuration()
  status.metrics.last_session = session.endTime.toISOString()
  status.metrics.last_updated = new Date().toISOString()
  status.metrics.avg_session_duration = Math.round(
    status.metrics.total_duration_minutes / status.metrics.sessions_total
  )

  // Update this week counter (reset on Monday)
  const now = new Date()
  const weekStart = new Date(now)
  weekStart.setDate(now.getDate() - now.getDay())
  weekStart.setHours(0, 0, 0, 0)

  if (new Date(status.metrics.last_updated) < weekStart) {
    status.metrics.sessions_this_week = 1
  } else {
    status.metrics.sessions_this_week =
      (status.metrics.sessions_this_week || 0) + 1
  }

  // Write back
  const yaml = YAML.stringify(status)
  const body = status.body || '\n# Notes\n'
  await writeFile(statusPath, `---\n${yaml}---\n${body}`)
}
```

---

## 🚀 Implementation Roadmap

### Day 7 - Morning (2h): Polish Status Command ⚡

**Tasks:**
1. Add chalk for color-coded output (30min)
2. Implement box drawing characters (30min)
3. Add git status integration (1h)

**Deliverable:** Visually enhanced status command

### Day 7 - Afternoon (2h): .STATUS Foundation ⚡

**Tasks:**
1. Design & document YAML format (30min)
2. Create .STATUS validator (1h)
3. Implement auto-update from sessions (30min)

**Deliverable:** Modern .STATUS v2 format with auto-sync

### Days 8-9: Interactive TUI Dashboard 📅

**Tasks:**
1. Set up blessed/ink framework (2h)
2. Create dashboard layout (2h)
3. Add real-time updates (2h)
4. Implement keyboard shortcuts (2h)

**Deliverable:** Full-screen interactive dashboard

### Day 10: Advanced Features 📅

**Tasks:**
1. Project graph visualization (2h)
2. Advanced caching for scanning (2h)
3. Cross-project operations (2h)

**Deliverable:** Production-ready Week 2 completion

---

## 📋 Success Criteria

### Week 2 Complete When:
- ✅ Status command has colors, boxes, git integration
- ✅ .STATUS v2 format defined and documented
- ✅ .STATUS auto-updates from sessions
- ✅ Validator catches common errors
- ✅ All tests passing (280+ tests)
- ✅ Documentation updated
- ✅ Migration guide for .STATUS v1 → v2

### Bonus Goals:
- Interactive TUI dashboard working
- Project graph visualization
- Cross-project sync helpers

---

## 🔮 Future Vision (Week 3+)

- Smart ML-based suggestions
- Team collaboration features
- GitHub/GitLab integration
- Calendar/email integration
- Multi-device sync
- Ecosystem health monitoring
- Achievement system & gamification

---

**Last Updated:** 2025-12-23
**Next Review:** After Day 7 completion

# Project Coordination System - Cross-Project Management

**Created:** 2025-12-23
**Status:** Planning
**Priority:** Medium
**Estimated Effort:** 2-3 weeks

---

## 🎯 Problem Statement

Currently managing 30+ projects across 5 categories (r-packages, quarto, research, teaching, dev-tools) with:

- Inconsistent project metadata
- Manual status tracking
- No cross-project dependency awareness
- Difficult to answer "what should I work on next?"
- Hard to detect related work across projects

**Goal:** Create a unified system for cross-project coordination and intelligent workflow management.

---

## 🏗️ Architecture Overview

```
~/.flow-cli/
├── registry.json           # Central project registry
├── workspaces.json         # Workspace definitions
├── templates/              # Project file templates
│   ├── .STATUS.yml
│   ├── PROJECT.yml
│   └── ROADMAP.yml
└── cache/                  # Scan results, graphs
    ├── project-graph.json
    └── dependencies.json

~/projects/
└── <category>/
    └── <project>/
        ├── .STATUS          # YAML frontmatter format
        ├── PROJECT.yml      # Optional: detailed metadata
        ├── ROADMAP.yml      # Optional: planning
        └── CONTEXT.md       # Optional: quick context
```

---

## 📁 File Specifications

### 1. Central Registry (~/.flow-cli/registry.json)

**Purpose:** Single source of truth for all projects

**Schema:**

```json
{
  "version": "2.0",
  "last_updated": "2025-12-23T18:00:00Z",
  "projects": [
    {
      "id": "rmediation",
      "name": "rmediation",
      "path": "/Users/dt/projects/r-packages/active/rmediation",
      "type": "r-package",
      "status": "active",
      "priority": "p0",
      "progress": 75,
      "tags": ["statistics", "r", "production"],
      "category": "r-packages",
      "workspace": "research",

      "git": {
        "repository": "https://github.com/user/rmediation",
        "branch": "main",
        "remote": "origin"
      },

      "metadata": {
        "description": "Causal mediation analysis with bootstrap",
        "owner": "DT",
        "team_size": "solo",
        "created": "2023-01-15",
        "last_accessed": "2025-12-23T10:00:00Z"
      },

      "metrics": {
        "sessions_total": 145,
        "sessions_this_week": 5,
        "total_duration_minutes": 6780,
        "avg_session_duration": 47,
        "last_session": "2025-12-23T10:00:00Z",
        "completion_rate": 0.82,
        "flow_percentage": 0.65
      },

      "dependencies": {
        "depends_on": ["medfit", "probmed"],
        "depended_by": ["mediationverse"],
        "related_docs": ["quarto-mediation-guide"]
      },

      "status_file": ".STATUS",
      "project_file": null,
      "roadmap_file": null,

      "health": {
        "score": 85,
        "issues": [],
        "warnings": ["No commits in 3 days"],
        "last_check": "2025-12-23T18:00:00Z"
      }
    }
  ],

  "workspaces": {
    "research": {
      "name": "Research Projects",
      "projects": ["rmediation", "medfit", "probmed", "collider"],
      "default_type": "r-package",
      "tags": ["statistics", "research"]
    },
    "teaching": {
      "name": "Teaching Courses",
      "projects": ["stat-440", "causal-inference"],
      "default_type": "quarto",
      "tags": ["teaching", "course"]
    },
    "dev-tools": {
      "name": "Development Tools",
      "projects": ["flow-cli", "zsh-claude-workflow", "claude-statistical-research"],
      "default_type": "node",
      "tags": ["tools", "automation"]
    }
  },

  "categories": {
    "r-packages": {
      "path": "~/projects/r-packages/active",
      "type": "r-package",
      "scan_depth": 2
    },
    "quarto": {
      "path": "~/projects/quarto",
      "type": "quarto",
      "scan_depth": 3
    },
    "research": {
      "path": "~/projects/research",
      "type": "research",
      "scan_depth": 2
    },
    "teaching": {
      "path": "~/projects/teaching",
      "type": "quarto",
      "scan_depth": 2
    },
    "dev-tools": {
      "path": "~/projects/dev-tools",
      "type": "generic",
      "scan_depth": 2
    }
  }
}
```

**Auto-Update Triggers:**

- Daily scan (cron or on first `flow` command of day)
- After session end
- Manual: `flow scan --force`

---

### 2. Project File (PROJECT.yml) - Optional

**Purpose:** Detailed project metadata (for complex projects)

**Schema:**

```yaml
---
# Basic info
id: rmediation
name: rmediation R Package
description: |
  Causal mediation analysis with bootstrap confidence intervals.
  Implements Baron & Kenny, Sobel test, and modern bootstrap methods.

# Classification
type: r-package
category: r-packages
workspace: research
tags: [statistics, r, production, mediation, causal-inference]

# Ownership
owner: DT
team:
  - name: DT
    role: lead
contributors: []
visibility: public

# Repository
repository:
  url: https://github.com/user/rmediation
  type: github
  default_branch: main
  ci_provider: github-actions

# Paths (relative to project root)
paths:
  source: R/
  tests: tests/testthat/
  docs: man/
  vignettes: vignettes/
  data: data/
  scripts: scripts/

# Dependencies
dependencies:
  system:
    - name: R
      version: '>= 4.0.0'
    - name: pandoc
      version: '>= 2.0'
  r_packages:
    - testthat
    - devtools
    - roxygen2
    - pkgdown
  projects:
    - id: medfit
      type: code
      reason: Shares common mediation functions
    - id: quarto-mediation-guide
      type: docs
      reason: Documentation examples

# Workflows (common commands)
workflows:
  dev:
    load: 'devtools::load_all()'
    test: 'devtools::test()'
    check: 'devtools::check()'
    document: 'devtools::document()'
    build: 'devtools::build()'
    install: 'devtools::install()'

  ci:
    test: 'R CMD check --as-cran'
    coverage: 'covr::package_coverage()'

  docs:
    build: 'pkgdown::build_site()'
    preview: 'pkgdown::preview_site()'
    deploy: 'pkgdown::deploy_to_branch()'

  release:
    bump_version: 'usethis::use_version()'
    build_source: 'R CMD build .'
    submit_cran: 'devtools::release()'

# Documentation
documentation:
  readme: README.md
  changelog: NEWS.md
  contributing: CONTRIBUTING.md
  license: LICENSE
  citation: inst/CITATION

  external:
    website: https://user.github.io/rmediation
    pkgdown: https://user.github.io/rmediation
    cran: https://cran.r-project.org/package=rmediation
    paper: https://doi.org/10.xxxx/xxxxx

# Project-specific config
config:
  test_on_save: true
  auto_document: true
  check_on_commit: false
  notify_on_failure: true

# Milestones
milestones:
  - name: v2.0.0 Release
    target: 2025-03-01
    status: in-progress
    progress: 75
    items:
      - Bootstrap variance estimation
      - Bayesian extension
      - Performance optimization
      - Documentation update

# Health checks
health:
  required_files:
    - DESCRIPTION
    - NAMESPACE
    - R/
    - tests/
  quality_gates:
    test_coverage: 80
    check_warnings: 0
    check_errors: 0
  monitoring:
    check_ci_daily: true
    alert_on_failure: true
---
```

**Usage:**

- Optional for simple projects (use .STATUS only)
- Recommended for complex projects with teams
- Auto-generated from templates: `flow init-project --type r-package`

---

### 3. Roadmap File (ROADMAP.yml) - Optional

**Purpose:** Long-term planning and feature tracking

**Schema:**

```yaml
---
project: rmediation
version: 2.0

phases:
  - id: p1-core
    name: Core Features
    status: complete
    completed: 2024-06-15
    items:
      - Basic mediation estimation
      - Sobel test
      - Bootstrap CIs
      - Unit tests

  - id: p2-advanced
    name: Advanced Features
    status: in-progress
    progress: 75
    target: 2025-03-01
    items:
      - id: bootstrap-var
        name: Bootstrap variance estimation
        status: in-progress
        progress: 60
        assigned: DT
        effort: 2 weeks
      - id: bayesian
        name: Bayesian extension
        status: planned
        blocked_by: [methodology-decision]
      - id: performance
        name: Performance optimization
        status: completed

  - id: p3-ecosystem
    name: Ecosystem Integration
    status: planned
    target: 2025-06-01
    items:
      - Integration with mediationverse
      - Tidyverse compatibility
      - Pipe support

next_milestones:
  - name: v2.0.0 Alpha
    target: 2025-01-15
    blockers: [bootstrap-var]
    requirements:
      - All P2 features complete
      - Test coverage > 80%
      - No CRAN check warnings

  - name: v2.0.0 Release
    target: 2025-03-01
    blockers: [alpha-feedback]
    requirements:
      - Alpha tested for 6 weeks
      - All bug fixes applied
      - Documentation complete

backlog:
  - Multilevel mediation support
  - Moderated mediation
  - Multiple mediators
  - Visualization functions
  - Interactive Shiny app

archived:
  - Removed: Complex effect size calculations (scope creep)
  - Removed: SEM integration (separate package)
---
```

**Usage:**

- For projects with long-term vision
- Helps answer "what's next after current work?"
- Tracks decisions and removed features

---

## 🔍 Discovery & Scanning

### Auto-Discovery Algorithm

```javascript
// Daily scan workflow
async function scanEcosystem() {
  const categories = await loadCategories() // From registry

  const discovered = []

  for (const [name, config] of Object.entries(categories)) {
    const projects = await scanDirectory(config.path, config.scan_depth, config.type)

    discovered.push(...projects)
  }

  // Update registry
  await updateRegistry(discovered)

  // Detect changes
  const changes = await detectChanges(discovered)

  return { discovered, changes }
}

// Scan single directory
async function scanDirectory(basePath, maxDepth, defaultType) {
  const projects = []

  async function scan(dir, depth) {
    if (depth > maxDepth) return

    const entries = await readdir(dir, { withFileTypes: true })

    for (const entry of entries) {
      if (!entry.isDirectory()) continue

      const fullPath = join(dir, entry.name)

      // Skip hidden/node_modules/etc
      if (entry.name.startsWith('.') || entry.name === 'node_modules' || entry.name === 'venv') {
        continue
      }

      // Check if this is a project
      const isProject = await detectProject(fullPath)

      if (isProject) {
        const metadata = await extractMetadata(fullPath, defaultType)
        projects.push(metadata)
      } else {
        // Recurse
        await scan(fullPath, depth + 1)
      }
    }
  }

  await scan(basePath, 0)
  return projects
}

// Detect if directory is a project
async function detectProject(dir) {
  const indicators = [
    '.git',
    '.STATUS',
    'PROJECT.yml',
    'package.json',
    'DESCRIPTION',
    'pyproject.toml',
    'Cargo.toml',
    '_quarto.yml'
  ]

  for (const indicator of indicators) {
    if (existsSync(join(dir, indicator))) {
      return true
    }
  }

  return false
}
```

---

## 🔗 Dependency Management

### Dependency Graph

```javascript
// Build dependency graph
function buildDependencyGraph(projects) {
  const graph = {
    nodes: [],
    edges: []
  }

  // Add nodes
  for (const project of projects) {
    graph.nodes.push({
      id: project.id,
      name: project.name,
      type: project.type,
      status: project.status
    })
  }

  // Add edges
  for (const project of projects) {
    if (project.dependencies?.depends_on) {
      for (const dep of project.dependencies.depends_on) {
        graph.edges.push({
          from: project.id,
          to: dep,
          type: 'depends-on'
        })
      }
    }

    if (project.dependencies?.related_docs) {
      for (const doc of project.dependencies.related_docs) {
        graph.edges.push({
          from: project.id,
          to: doc,
          type: 'documented-by'
        })
      }
    }
  }

  return graph
}

// Visualize with Mermaid
function generateMermaidGraph(graph) {
  let mermaid = 'graph TD\n'

  // Define nodes
  for (const node of graph.nodes) {
    const shape = node.type === 'r-package' ? '([' : node.type === 'quarto' ? '{' : '['

    const endShape = node.type === 'r-package' ? '])' : node.type === 'quarto' ? '}' : ']'

    mermaid += `  ${node.id}${shape}${node.name}${endShape}\n`
  }

  // Define edges
  for (const edge of graph.edges) {
    const arrow = edge.type === 'depends-on' ? '==>' : '-->'
    mermaid += `  ${edge.from} ${arrow} ${edge.to}\n`
  }

  return mermaid
}
```

**CLI Command:**

```bash
flow graph
# Generates docs/PROJECT-GRAPH.md with Mermaid diagram

flow graph --format dot
# Generates Graphviz DOT file

flow graph --workspace research
# Shows only research workspace projects
```

---

## 🎯 Smart Recommendations

### Context-Aware Suggestions

```javascript
// Analyze current state and suggest next action
async function suggestNextAction(context) {
  const { activeSession, recentSessions, projects, time } = context

  const suggestions = []

  // 1. Active session suggestions
  if (activeSession) {
    const duration = activeSession.getDuration()

    if (duration > 90) {
      suggestions.push({
        type: 'break',
        priority: 'high',
        message: "You've been working for 90+ minutes. Take a 5-10 minute break?",
        action: 'flow pause'
      })
    }

    if (duration >= 15 && duration < 20) {
      suggestions.push({
        type: 'flow-state',
        priority: 'info',
        message: "You're in flow state! 🔥 Keep going.",
        action: null
      })
    }
  }

  // 2. No active session suggestions
  if (!activeSession) {
    // Check time of day
    const hour = time.getHours()

    if (hour >= 9 && hour <= 11) {
      // Morning - suggest high-priority work
      const urgent = projects.filter(p => p.priority === 'p0' && p.status === 'active')

      if (urgent.length > 0) {
        suggestions.push({
          type: 'project',
          priority: 'high',
          message: `Start your day with high-priority work on ${urgent[0].name}?`,
          action: `flow work ${urgent[0].id}`
        })
      }
    }

    // Check for stalled projects
    const stalled = projects.filter(p => {
      const daysSince = daysSinceLastSession(p)
      return daysSince > 3 && p.status === 'active'
    })

    if (stalled.length > 0) {
      suggestions.push({
        type: 'stalled',
        priority: 'medium',
        message: `${stalled[0].name} hasn't been touched in ${daysSince(stalled[0])} days`,
        action: `flow work ${stalled[0].id}`
      })
    }
  }

  // 3. Pattern-based suggestions
  const patterns = await analyzePatterns(recentSessions)

  if (patterns.bestHours.includes(time.getHours())) {
    suggestions.push({
      type: 'optimal-time',
      priority: 'info',
      message: "You're in your most productive hours!",
      action: null
    })
  }

  // 4. Dependency suggestions
  for (const project of projects) {
    if (project.dependencies?.depends_on) {
      for (const depId of project.dependencies.depends_on) {
        const dep = projects.find(p => p.id === depId)

        if (dep?.status === 'active' && hasUncommittedChanges(dep)) {
          suggestions.push({
            type: 'dependency',
            priority: 'low',
            message: `${dep.name} (dependency of ${project.name}) has uncommitted changes`,
            action: `cd ${dep.path} && git status`
          })
        }
      }
    }
  }

  return suggestions.sort((a, b) => {
    const priority = { high: 3, medium: 2, low: 1, info: 0 }
    return priority[b.priority] - priority[a.priority]
  })
}
```

---

## 📊 Ecosystem Health Monitoring

```bash
flow health

# Output:
┌─────────────────────────────────────────────────────────┐
│ 🏥 Ecosystem Health Report                              │
│ Generated: 2025-12-23 18:00                             │
└─────────────────────────────────────────────────────────┘

Overall Health: 82/100 ⭐ Good

Issues Found: 3
Warnings: 7
Projects Scanned: 32

┌─ Issues ────────────────────────────────────────────────┐
│ ❌ medfit: Failing tests (2 failures)                   │
│ ❌ quarto-guide: Build failing                          │
│ ❌ flow-cli: Uncommitted changes (5 files)              │
└─────────────────────────────────────────────────────────┘

┌─ Warnings ──────────────────────────────────────────────┐
│ ⚠️  rmediation: No commits in 3 days                    │
│ ⚠️  probmed: .STATUS file stale (7 days)                │
│ ⚠️  stat-440: Behind main by 5 commits                  │
│ ⚠️  collider: Test coverage below 80% (currently 65%)   │
│ ⚠️  causal-inference: No .STATUS file                   │
│ ⚠️  claude-mcp: Dependencies outdated                   │
│ ⚠️  zsh-workflow: Large uncommitted changes             │
└─────────────────────────────────────────────────────────┘

Quick Fixes Available:
  flow fix medfit        # Run tests and show failures
  flow fix quarto-guide  # Attempt build and diagnose
  flow fix flow-cli      # Show git status

Run 'flow health --verbose' for detailed breakdown
Run 'flow health --fix-all' to attempt automatic fixes
```

---

## 🚀 CLI Commands

### New Commands

```bash
# Project management
flow projects [options]        # List/search projects
flow graph [options]           # Visualize dependencies
flow health [options]          # Ecosystem health check
flow workspace <name>          # Switch workspace context

# Status file management
flow status-init [--type]      # Create .STATUS from template
flow status-validate           # Validate current .STATUS
flow status-migrate            # Migrate v1 → v2 format

# Cross-project operations
flow run-all <command>         # Run command in all projects
flow sync-all                  # Git sync all projects
flow find <query>              # Search across projects

# Scanning & discovery
flow scan [--force]            # Scan for new projects
flow register <path>           # Manually register project
flow unregister <id>           # Remove from registry
```

---

## 📅 Implementation Timeline

### Week 3: Foundation

- Design schemas (registry, PROJECT.yml, ROADMAP.yml)
- Implement scanning/discovery
- Build registry management
- Create validator

### Week 4: Coordination

- Dependency graph
- Health monitoring
- Cross-project commands
- Smart suggestions

### Week 5: Polish

- Documentation
- Migration tools
- Templates
- Testing

---

**Last Updated:** 2025-12-23
**Status:** Planning - Ready for implementation after Week 2

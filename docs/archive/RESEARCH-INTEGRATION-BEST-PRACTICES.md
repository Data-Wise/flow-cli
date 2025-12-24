# Integration Best Practices Research

**Created:** 2025-12-20
**Purpose:** Research how to design flow-cli for seamless integration with other tools
**Context:** Making the project integration-friendly while maintaining independence

---

## Executive Summary

To make flow-cli highly integratable with other tools, we should follow these principles:

1. **Programmatic API** - Expose Node.js modules that other tools can import
2. **Standard Interfaces** - Use common data formats (JSON, standard outputs)
3. **CLI Composability** - Follow Unix philosophy (small, focused, pipeable)
4. **Plugin Architecture** - Allow extensions without modifying core
5. **Event Hooks** - Emit events that other tools can listen to
6. **Configuration API** - Allow external tools to read/write our config
7. **Data Export** - Provide multiple export formats for data sharing

---

## 1. Programmatic API (JavaScript/Node.js)

### Best Practice: Export Modules for Direct Import

**Principle:** Other Node.js tools should be able to import and use our functions directly.

### Implementation

```javascript
// cli/api/index.js - Main public API
export { SessionManager } from './session-api.js'
export { DashboardGenerator } from './dashboard-api.js'
export { ProjectScanner } from './project-scanner-api.js'
export { DependencyTracker } from './dependency-api.js'

// Usage by other tools:
import { SessionManager, ProjectScanner } from 'flow-cli'

const scanner = new ProjectScanner()
const projects = await scanner.scanAll()
console.log(`Found ${projects.length} projects`)
```

### package.json Exports

```json
{
  "name": "flow-cli",
  "version": "1.0.0",
  "type": "module",
  "exports": {
    ".": "./cli/api/index.js",
    "./session": "./cli/api/session-api.js",
    "./dashboard": "./cli/api/dashboard-api.js",
    "./scanner": "./cli/api/project-scanner-api.js",
    "./deps": "./cli/api/dependency-api.js"
  },
  "main": "./cli/api/index.js"
}
```

### Real-World Example: chalk

```javascript
// chalk is designed for programmatic use
import chalk from 'chalk'
console.log(chalk.blue('Hello world!'))

// We should do the same
import { SessionManager } from 'flow-cli'
const session = new SessionManager()
await session.save({ projectName: 'foo', task: 'bar' })
```

---

## 2. Standard Interfaces & Data Formats

### Best Practice: Use Widely-Adopted Formats

**Principle:** Use JSON, YAML, TOML for config/data - not custom formats.

### Data Exchange Formats

```javascript
// ✅ GOOD: Standard JSON for session state
{
  "sessionId": "uuid-12345",
  "projectName": "rmediation",
  "projectPath": "/Users/dt/projects/r-packages/stable/rmediation",
  "projectType": "r-package",
  "startTime": "2025-12-20T10:30:00Z",
  "context": {
    "lastTask": "Fix failing test"
  }
}

// ❌ BAD: Custom binary format or proprietary structure
```

### Standard Output Formats

```javascript
// cli/api/dashboard-api.js

export class DashboardGenerator {
  // Return multiple formats
  async generate(format = 'json') {
    const data = await this.collectData()

    switch (format) {
      case 'json':
        return JSON.stringify(data, null, 2)
      case 'yaml':
        return toYAML(data)
      case 'csv':
        return toCSV(data)
      case 'markdown':
        return toMarkdown(data)
      default:
        return data // Return raw object
    }
  }
}

// Other tools can choose their preferred format
import { DashboardGenerator } from 'flow-cli'
const dash = new DashboardGenerator()
const markdown = await dash.generate('markdown')
```

### Real-World Example: ESLint

```javascript
// ESLint supports multiple output formats
eslint --format json
eslint --format stylish
eslint --format html

// We should do the same
zsh-config dashboard --format json
zsh-config dashboard --format markdown
zsh-config dashboard --format csv
```

---

## 3. CLI Composability (Unix Philosophy)

### Best Practice: Small, Focused, Pipeable Commands

**Principle:** Each command does one thing well, outputs to stdout, accepts stdin.

### Implementation

```bash
# ✅ GOOD: Pipeable, composable
zsh-config projects list --format json | jq '.[] | select(.priority == "P0")'
zsh-config projects scan | zsh-config deps analyze | jq '.impact'
zsh-config session current | grep "project"

# ❌ BAD: Monolithic, non-pipeable
zsh-config --show-all-projects-with-p0-priority
```

### Design Pattern: Output to stdout, Errors to stderr

```javascript
// cli/commands/projects-list.js

export async function listProjects(options) {
  try {
    const scanner = new ProjectScanner()
    const projects = await scanner.scanAll()

    // Output to stdout (can be piped)
    console.log(JSON.stringify(projects, null, 2))

    return 0 // Success exit code
  } catch (error) {
    // Errors to stderr
    console.error(`Error scanning projects: ${error.message}`)
    return 1 // Error exit code
  }
}
```

### Real-World Example: ripgrep

```bash
# ripgrep is highly composable
rg "TODO" --json | jq '.data.lines.text'
rg "FIXME" | wc -l
rg "pattern" --files-with-matches | xargs sed -i 's/old/new/g'

# We should enable similar workflows
zsh-config projects list --json | jq '.[] | .name'
zsh-config tasks list --quick-wins | wc -l
zsh-config projects find --type r-package | xargs zsh-config deps analyze
```

---

## 4. Plugin/Extension Architecture

### Best Practice: Allow Extensions Without Modifying Core

**Principle:** Provide plugin hooks so other tools can extend functionality.

### Plugin System Design

```javascript
// cli/core/plugin-manager.js

export class PluginManager {
  constructor() {
    this.plugins = new Map()
  }

  register(name, plugin) {
    // Validate plugin has required interface
    if (!plugin.init || !plugin.hooks) {
      throw new Error(`Invalid plugin: ${name}`)
    }

    this.plugins.set(name, plugin)
    plugin.init(this.getPluginAPI())
  }

  async runHook(hookName, ...args) {
    const results = []
    for (const [name, plugin] of this.plugins) {
      if (plugin.hooks[hookName]) {
        const result = await plugin.hooks[hookName](...args)
        results.push({ plugin: name, result })
      }
    }
    return results
  }

  getPluginAPI() {
    return {
      registerCommand: (name, fn) => {
        /* ... */
      },
      registerDetector: (type, fn) => {
        /* ... */
      },
      emitEvent: (event, data) => {
        /* ... */
      }
    }
  }
}
```

### Plugin Example

```javascript
// External plugin: zsh-config-plugin-git
export default {
  name: 'git-enhanced',
  version: '1.0.0',

  init(api) {
    // Register new project type detector
    api.registerDetector('git-repo', projectPath => {
      return fs.existsSync(path.join(projectPath, '.git'))
    })

    // Register new command
    api.registerCommand('git-status', async projectName => {
      const session = await api.getSession(projectName)
      const { stdout } = await exec('git status -sb', {
        cwd: session.projectPath
      })
      return stdout
    })

    // Listen to events
    api.onEvent('session:start', session => {
      console.log(`Git plugin: Session started for ${session.projectName}`)
    })
  },

  hooks: {
    'before:session:save': async session => {
      // Add git info to session
      session.git = await getGitInfo(session.projectPath)
      return session
    },

    'after:dashboard:generate': async dashboard => {
      // Enhance dashboard with git stats
      dashboard.gitStats = await collectGitStats()
      return dashboard
    }
  }
}
```

### Plugin Discovery

```javascript
// ~/.zsh-config/plugins/
// Auto-discover plugins in user directory

const pluginDir = path.join(os.homedir(), '.zsh-config/plugins')
const pluginFiles = fs.readdirSync(pluginDir).filter(f => f.endsWith('.js'))

for (const file of pluginFiles) {
  const plugin = await import(path.join(pluginDir, file))
  pluginManager.register(file.replace('.js', ''), plugin.default)
}
```

### Real-World Example: Babel, Webpack, ESLint

```javascript
// All use plugin systems
// .babelrc
{
  "plugins": ["@babel/plugin-transform-runtime"]
}

// webpack.config.js
plugins: [new HtmlWebpackPlugin()]

// .eslintrc
{
  "plugins": ["react", "import"]
}

// We should do the same
// ~/.zsh-config/config.json
{
  "plugins": [
    "git-enhanced",
    "jira-integration",
    "slack-notifier"
  ]
}
```

---

## 5. Event Hooks & Callbacks

### Best Practice: Emit Events for Integration Points

**Principle:** Other tools can listen to events without modifying our code.

### Event System

```javascript
// cli/core/event-emitter.js
import { EventEmitter } from 'events'

export class ZshConfigEvents extends EventEmitter {
  // Session events
  emitSessionStart(session) {
    this.emit('session:start', session)
    this.emit('session:change', { type: 'start', session })
  }

  emitSessionEnd(session) {
    this.emit('session:end', session)
    this.emit('session:change', { type: 'end', session })
  }

  // Project events
  emitProjectsScanned(projects) {
    this.emit('projects:scanned', projects)
  }

  emitProjectAdded(project) {
    this.emit('project:added', project)
  }

  // Dashboard events
  emitDashboardGenerated(dashboard) {
    this.emit('dashboard:generated', dashboard)
  }
}

export const events = new ZshConfigEvents()
```

### Integration Example: aiterm

```javascript
// In aiterm's integration with flow-cli
import { events } from 'flow-cli'

events.on('session:start', session => {
  // Switch terminal profile when session starts
  const profile = getProfileForProjectType(session.projectType)
  switchTerminalProfile(profile)
  setWindowTitle(`${session.projectName} (${session.projectType})`)
})

events.on('session:end', session => {
  // Reset terminal to default
  switchTerminalProfile('default')
  setWindowTitle('Terminal')
})
```

### Real-World Example: Webpack

```javascript
// Webpack emits events via hooks
compiler.hooks.compile.tap('MyPlugin', params => {
  console.log('The compiler is starting to compile...')
})

compiler.hooks.emit.tapAsync('MyPlugin', (compilation, callback) => {
  // Do something asynchronous...
  callback()
})

// We should provide similar hooks
import { hooks } from 'flow-cli'

hooks.session.start.tap('MyIntegration', session => {
  // Custom logic when session starts
})
```

---

## 6. Configuration API

### Best Practice: Allow External Tools to Read/Write Config

**Principle:** Configuration should be programmatically accessible.

### Configuration Manager

```javascript
// cli/core/config-manager.js

export class ConfigManager {
  constructor(configPath = '~/.zsh-config/config.json') {
    this.configPath = path.expanduser(configPath)
    this.config = this.load()
  }

  load() {
    if (!fs.existsSync(this.configPath)) {
      return this.getDefaults()
    }
    return JSON.parse(fs.readFileSync(this.configPath, 'utf8'))
  }

  save() {
    fs.writeFileSync(this.configPath, JSON.stringify(this.config, null, 2))
  }

  // Get configuration value
  get(key, defaultValue) {
    const keys = key.split('.')
    let value = this.config

    for (const k of keys) {
      if (value && typeof value === 'object' && k in value) {
        value = value[k]
      } else {
        return defaultValue
      }
    }

    return value
  }

  // Set configuration value
  set(key, value) {
    const keys = key.split('.')
    const lastKey = keys.pop()
    let target = this.config

    for (const k of keys) {
      if (!(k in target)) {
        target[k] = {}
      }
      target = target[k]
    }

    target[lastKey] = value
    this.save()
  }

  // Get all configuration
  getAll() {
    return { ...this.config }
  }

  // Update multiple values
  update(updates) {
    this.config = { ...this.config, ...updates }
    this.save()
  }
}

// Export singleton
export const config = new ConfigManager()
```

### External Tool Integration

```javascript
// Other tool accessing our configuration
import { config } from 'flow-cli'

// Read config
const sessionDir = config.get('session.directory', '~/.zsh-sessions')
const dashboardFormat = config.get('dashboard.defaultFormat', 'terminal')

// Modify config
config.set('integrations.aiterm.enabled', true)
config.set('integrations.aiterm.autoSwitch', true)

// Batch update
config.update({
  'integrations.jira.enabled': true,
  'integrations.jira.apiKey': process.env.JIRA_API_KEY
})
```

### Real-World Example: VS Code Settings

```javascript
// VS Code allows programmatic access to settings
const config = vscode.workspace.getConfiguration('editor')
const fontSize = config.get('fontSize', 14)
await config.update('fontSize', 16, vscode.ConfigurationTarget.Global)

// We should provide similar API
import { config } from 'flow-cli'
const sessionDir = config.get('session.directory')
await config.update('dashboard.format', 'json')
```

---

## 7. Data Export & Import

### Best Practice: Provide Multiple Export Formats

**Principle:** Allow data to be exported in formats other tools can consume.

### Export API

```javascript
// cli/api/export-api.js

export class DataExporter {
  constructor() {
    this.exporters = new Map([
      ['json', this.exportJSON],
      ['yaml', this.exportYAML],
      ['csv', this.exportCSV],
      ['markdown', this.exportMarkdown],
      ['html', this.exportHTML]
    ])
  }

  async export(data, format = 'json', options = {}) {
    const exporter = this.exporters.get(format)
    if (!exporter) {
      throw new Error(`Unknown export format: ${format}`)
    }
    return exporter.call(this, data, options)
  }

  exportJSON(data, options) {
    const indent = options.pretty ? 2 : 0
    return JSON.stringify(data, null, indent)
  }

  exportYAML(data, options) {
    // Use yaml library
    return yaml.dump(data, options)
  }

  exportCSV(data, options) {
    // Convert to CSV format
    if (Array.isArray(data)) {
      const headers = Object.keys(data[0])
      const rows = data.map(item => headers.map(h => item[h]).join(','))
      return [headers.join(','), ...rows].join('\n')
    }
    throw new Error('CSV export requires array of objects')
  }

  exportMarkdown(data, options) {
    // Convert to Markdown table
    if (Array.isArray(data)) {
      const headers = Object.keys(data[0])
      const headerRow = `| ${headers.join(' | ')} |`
      const separator = `| ${headers.map(() => '---').join(' | ')} |`
      const rows = data.map(item => `| ${headers.map(h => item[h]).join(' | ')} |`)
      return [headerRow, separator, ...rows].join('\n')
    }
  }

  exportHTML(data, options) {
    // Convert to HTML table
    // ...
  }

  // Register custom exporter
  registerExporter(format, exporterFn) {
    this.exporters.set(format, exporterFn)
  }
}
```

### CLI Export Commands

```bash
# Export to different formats
zsh-config projects list --export json > projects.json
zsh-config projects list --export csv > projects.csv
zsh-config projects list --export markdown > projects.md

# Export dashboard
zsh-config dashboard --export html > dashboard.html
zsh-config dashboard --export json | jq '.projects[] | .name'

# Export session history
zsh-config session history --export csv --since "1 week ago"
```

### Real-World Example: Prettier, TypeScript

```javascript
// Prettier supports multiple formats
prettier --parser typescript
prettier --parser markdown
prettier --parser json

// TypeScript emits multiple outputs
tsc --declaration  // .d.ts files
tsc --sourceMap    // .map files

// We should provide similar flexibility
zsh-config export --format json
zsh-config export --format yaml
zsh-config export --format markdown
```

---

## 8. Standard CLI Conventions

### Best Practice: Follow Established CLI Patterns

**Principle:** Use conventions other tools expect.

### Exit Codes

```javascript
// Standard exit codes
const EXIT_SUCCESS = 0
const EXIT_GENERAL_ERROR = 1
const EXIT_USAGE_ERROR = 2
const EXIT_NOT_FOUND = 3

process.exit(EXIT_SUCCESS)
```

### Help & Version Flags

```bash
# Standard flags that MUST work
zsh-config --help
zsh-config -h
zsh-config --version
zsh-config -v

# Per-command help
zsh-config projects --help
zsh-config session --help
```

### Configuration File Locations

```javascript
// Follow XDG Base Directory Specification
const XDG_CONFIG_HOME = process.env.XDG_CONFIG_HOME || path.join(os.homedir(), '.config')
const XDG_DATA_HOME = process.env.XDG_DATA_HOME || path.join(os.homedir(), '.local/share')
const XDG_CACHE_HOME = process.env.XDG_CACHE_HOME || path.join(os.homedir(), '.cache')

// Our directories
const CONFIG_DIR = path.join(XDG_CONFIG_HOME, 'flow-cli')
const DATA_DIR = path.join(XDG_DATA_HOME, 'flow-cli')
const CACHE_DIR = path.join(XDG_CACHE_HOME, 'flow-cli')
```

### Environment Variables

```bash
# Respect standard environment variables
export ZSH_CONFIG_HOME="$HOME/.config/flow-cli"
export ZSH_CONFIG_DATA="$HOME/.local/share/flow-cli"
export ZSH_CONFIG_DEBUG=1
export ZSH_CONFIG_LOG_LEVEL=debug
```

---

## 9. API Versioning & Stability

### Best Practice: Version Your APIs

**Principle:** Breaking changes should be obvious, semver compliant.

### Versioned Exports

```javascript
// package.json
{
  "version": "1.0.0",
  "exports": {
    ".": "./cli/api/index.js",
    "./v1": "./cli/api/v1/index.js",
    "./v2": "./cli/api/v2/index.js"
  }
}

// Future: Breaking changes go in v2
import { SessionManager } from 'flow-cli/v1';  // Old API
import { SessionManager } from 'flow-cli/v2';  // New API
```

### Deprecation Warnings

```javascript
// cli/api/session-api.js

export class SessionManager {
  /**
   * @deprecated Use getCurrentSession() instead
   * Will be removed in v2.0.0
   */
  getCurrent() {
    console.warn(
      'DEPRECATED: SessionManager.getCurrent() is deprecated. ' +
        'Use getCurrentSession() instead. ' +
        'This will be removed in v2.0.0'
    )
    return this.getCurrentSession()
  }

  getCurrentSession() {
    // New method
  }
}
```

### Real-World Example: Node.js, AWS SDK

```javascript
// Node.js deprecates APIs gracefully
fs.exists() // [DEP0001] DeprecationWarning

// AWS SDK versions APIs
import AWS from 'aws-sdk' // v2
import { S3Client } from '@aws-sdk/client-s3' // v3

// We should do the same
import { SessionManager } from 'flow-cli/v1'
```

---

## 10. Documentation for Integrators

### Best Practice: Provide Integration Guides

**Principle:** Make it easy for others to integrate.

### Documentation Structure

```
docs/
├── integration/
│   ├── README.md                    # Integration overview
│   ├── programmatic-api.md          # Node.js API docs
│   ├── cli-integration.md           # CLI composability
│   ├── plugin-development.md        # Creating plugins
│   ├── event-system.md              # Event hooks
│   └── examples/
│       ├── aiterm-integration.md    # Real example
│       ├── jira-integration.md      # Real example
│       └── slack-notifier.md        # Real example
├── api/
│   ├── session-api.md
│   ├── dashboard-api.md
│   └── scanner-api.md
└── guides/
    ├── embedding.md                 # Using as library
    ├── extending.md                 # Creating extensions
    └── contributing.md              # Contributing back
```

### API Documentation Example

```markdown
# Session API

## SessionManager

Manages workflow session state.

### Constructor

\`\`\`javascript
import { SessionManager } from 'flow-cli';

const manager = new SessionManager(options);
\`\`\`

**Options:**

- `dataDir` (string): Directory for session data. Default: `~/.local/share/flow-cli/sessions`
- `autoSave` (boolean): Auto-save on changes. Default: `true`

### Methods

#### `getCurrentSession()`

Returns the current active session.

\`\`\`javascript
const session = await manager.getCurrentSession();
// Returns: { sessionId, projectName, projectPath, ... }
\`\`\`

**Returns:** `Promise<Session | null>`

#### `save(session)`

Saves session state to disk.

\`\`\`javascript
await manager.save({
projectName: 'rmediation',
projectPath: '/Users/dt/projects/r-packages/stable/rmediation',
projectType: 'r-package',
startTime: new Date().toISOString()
});
\`\`\`

**Parameters:**

- `session` (object): Session data to save

**Returns:** `Promise<void>`

### Events

The SessionManager emits the following events:

\`\`\`javascript
manager.on('session:start', (session) => {
console.log(\`Started session for \${session.projectName}\`);
});

manager.on('session:end', (session) => {
console.log(\`Ended session for \${session.projectName}\`);
});
\`\`\`
```

---

## 11. Real-World Integration Examples

### Example 1: aiterm Integration

```javascript
// In aiterm's code
import { SessionManager, events } from 'flow-cli'

const sessionManager = new SessionManager()

// Listen to session changes
events.on('session:start', async session => {
  // Determine terminal profile based on project type
  const profileMap = {
    'r-package': 'R-Dev',
    quarto: 'Research',
    node: 'Node-Dev',
    python: 'Python-Dev'
  }

  const profile = profileMap[session.projectType] || 'Default'

  // Switch iTerm2 profile
  await switchProfile(profile)

  // Update window title
  await setWindowTitle(`${session.projectName} (${session.projectType})`)

  // Set custom user variables
  await setUserVariable('PROJECT_NAME', session.projectName)
  await setUserVariable('PROJECT_TYPE', session.projectType)
})

events.on('session:end', async () => {
  await switchProfile('Default')
  await setWindowTitle('Terminal')
})
```

### Example 2: JIRA Integration Plugin

```javascript
// ~/.zsh-config/plugins/jira-integration.js

import fetch from 'node-fetch'

export default {
  name: 'jira-integration',
  version: '1.0.0',

  init(api) {
    // Add JIRA task tracking to sessions
    api.onEvent('session:start', async session => {
      const jiraIssue = await this.findJiraIssue(session.projectName)
      if (jiraIssue) {
        session.jira = {
          issueKey: jiraIssue.key,
          summary: jiraIssue.fields.summary,
          status: jiraIssue.fields.status.name
        }
        await api.updateSession(session)
      }
    })

    // Register command to create JIRA task
    api.registerCommand('jira-create', async (summary, projectKey) => {
      const issue = await this.createJiraIssue(summary, projectKey)
      console.log(`Created JIRA issue: ${issue.key}`)
      return issue
    })
  },

  async findJiraIssue(projectName) {
    const response = await fetch(
      `https://jira.example.com/rest/api/2/search?jql=project=${projectName}`,
      {
        headers: {
          Authorization: `Bearer ${process.env.JIRA_API_TOKEN}`
        }
      }
    )
    const data = await response.json()
    return data.issues[0]
  },

  async createJiraIssue(summary, projectKey) {
    // Implementation...
  }
}
```

### Example 3: Slack Notifier

```javascript
// ~/.zsh-config/plugins/slack-notifier.js

export default {
  name: 'slack-notifier',
  version: '1.0.0',

  init(api) {
    // Notify when session ends with summary
    api.onEvent('session:end', async session => {
      const duration = Date.now() - new Date(session.startTime)
      const hours = (duration / (1000 * 60 * 60)).toFixed(1)

      await this.sendSlackMessage({
        text: `Session completed: ${session.projectName}`,
        attachments: [
          {
            color: 'good',
            fields: [
              { title: 'Project', value: session.projectName, short: true },
              { title: 'Type', value: session.projectType, short: true },
              { title: 'Duration', value: `${hours}h`, short: true },
              { title: 'Task', value: session.context.lastTask, short: false }
            ]
          }
        ]
      })
    })

    // Notify on quick wins completion
    api.onEvent('task:completed', async task => {
      if (task.duration < 30 * 60 * 1000) {
        // 30 minutes
        await this.sendSlackMessage({
          text: `:tada: Quick win completed: ${task.description}`,
          channel: '#productivity'
        })
      }
    })
  },

  async sendSlackMessage(message) {
    await fetch(process.env.SLACK_WEBHOOK_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(message)
    })
  }
}
```

---

## 12. Testing for Integrations

### Best Practice: Provide Test Utilities

**Principle:** Make it easy for integrators to test their code.

### Test Helpers

```javascript
// cli/testing/index.js

export class TestSessionManager extends SessionManager {
  constructor() {
    super({ dataDir: '/tmp/zsh-config-test' })
  }

  async cleanup() {
    await fs.rm(this.dataDir, { recursive: true, force: true })
  }
}

export async function createTestSession(overrides = {}) {
  return {
    sessionId: 'test-session-id',
    projectName: 'test-project',
    projectPath: '/tmp/test-project',
    projectType: 'generic',
    startTime: new Date().toISOString(),
    ...overrides
  }
}

export async function createTestProjects(count = 5) {
  const projects = []
  for (let i = 0; i < count; i++) {
    projects.push({
      name: `test-project-${i}`,
      path: `/tmp/test-project-${i}`,
      type: ['r-package', 'node', 'python'][i % 3]
    })
  }
  return projects
}
```

### Usage by Integrators

```javascript
// In aiterm's tests
import { TestSessionManager, createTestSession } from 'flow-cli/testing'

describe('aiterm integration', () => {
  let sessionManager

  beforeEach(() => {
    sessionManager = new TestSessionManager()
  })

  afterEach(async () => {
    await sessionManager.cleanup()
  })

  it('should switch profile on session start', async () => {
    const session = await createTestSession({
      projectType: 'r-package'
    })

    await sessionManager.save(session)

    // Test that profile switched correctly
    expect(getCurrentProfile()).toBe('R-Dev')
  })
})
```

---

## 13. Security Best Practices

### Best Practice: Safe by Default

**Principle:** Don't expose sensitive data, validate inputs.

### Input Validation

```javascript
// cli/core/validator.js

export function validateProjectPath(projectPath) {
  // Prevent directory traversal
  const normalized = path.normalize(projectPath)
  if (normalized.includes('..')) {
    throw new Error('Invalid project path: directory traversal detected')
  }

  // Ensure absolute path
  if (!path.isAbsolute(normalized)) {
    throw new Error('Project path must be absolute')
  }

  return normalized
}

export function validateProjectName(name) {
  // Only allow safe characters
  if (!/^[a-zA-Z0-9_-]+$/.test(name)) {
    throw new Error('Project name contains invalid characters')
  }

  return name
}
```

### Sensitive Data Handling

```javascript
// Don't expose sensitive data in exports
export class SessionManager {
  async getCurrentSession() {
    const session = await this.load()

    // Remove sensitive fields before returning
    const { apiKeys, passwords, secrets, ...safe } = session

    return safe
  }

  async export(format = 'json') {
    const session = await this.getCurrentSession()

    // Explicitly mark fields that should never be exported
    const sanitized = this.sanitize(session, ['apiKeys', 'passwords', 'tokens', 'secrets'])

    return this.format(sanitized, format)
  }
}
```

---

## Summary: Integration Checklist

### ✅ Must Have

- [ ] **Programmatic API** - Export Node.js modules
- [ ] **Standard Data Formats** - JSON, YAML, CSV output
- [ ] **CLI Composability** - Pipeable, stdout/stderr separation
- [ ] **Clear Documentation** - API docs, examples, guides
- [ ] **Semantic Versioning** - Clear version policy
- [ ] **Exit Codes** - Standard exit codes
- [ ] **Help & Version** - --help, --version flags

### ⭐ Should Have

- [ ] **Event System** - Emit events for integration points
- [ ] **Plugin Architecture** - Allow extensions
- [ ] **Configuration API** - Programmatic config access
- [ ] **Multiple Export Formats** - JSON, YAML, CSV, Markdown
- [ ] **Test Utilities** - Helpers for integrators
- [ ] **XDG Compliance** - Standard config/data/cache locations

### 🎁 Nice to Have

- [ ] **Webhooks** - HTTP callbacks for events
- [ ] **REST API** - Optional HTTP server
- [ ] **Language Bindings** - Python, Ruby wrappers
- [ ] **GraphQL API** - Query interface
- [ ] **Real-time Updates** - WebSocket support

---

## Recommended Implementation Priority

### Phase 1: Foundation (Week 1-2)

1. **Programmatic API** - Export core modules
2. **Standard Outputs** - JSON format for all data
3. **CLI Composability** - Pipeable commands
4. **Basic Documentation** - API reference

### Phase 2: Events & Plugins (Week 3-4)

5. **Event System** - Basic event emitter
6. **Configuration API** - Read/write config
7. **Plugin Hooks** - Before/after hooks
8. **Integration Examples** - aiterm integration

### Phase 3: Advanced (Month 2-3)

9. **Plugin Architecture** - Full plugin system
10. **Multiple Export Formats** - YAML, CSV, Markdown
11. **Test Utilities** - Test helpers
12. **Comprehensive Docs** - Integration guides

---

**Status:** ✅ Research complete
**Recommendation:** Implement Phase 1 features in Week 1-2
**Key Insight:** Focus on programmatic API and standard outputs first
**Next Action:** Add to PROJECT-SCOPE.md as integration requirements

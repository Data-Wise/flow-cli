# CLI Integration Layer

This directory contains the integration layer between the desktop app and the ZSH CLI tools.

## Purpose

The ZSH functions live in `~/.config/zsh/`, but the desktop app (Electron) needs a Node.js-friendly API to interact with them. This layer provides:

1. **Adapters**: Wrappers around ZSH functions that can be called from Node.js
2. **API**: JavaScript/Node.js API endpoints for the desktop app

## Directory Structure

```
cli/
├── adapters/          # ZSH function adapters
│   ├── workflow.js    # Workflow commands (work, finish, etc.)
│   ├── session.js     # Session management
│   └── status.js      # Status queries
│
├── api/               # Node.js API layer
│   ├── workflow-api.js
│   ├── status-api.js
│   └── config-api.js
│
└── README.md
```

## How It Works

### 1. Adapters (`adapters/`)

Adapters execute ZSH commands via `child_process.exec()` and return structured data:

```javascript
// Example: adapters/workflow.js
const { exec } = require('child_process');

async function startWork(project) {
  return new Promise((resolve, reject) => {
    exec(`zsh -c 'source ~/.zshrc && work ${project}'`, (error, stdout, stderr) => {
      if (error) reject(error);
      resolve({ success: true, output: stdout });
    });
  });
}

module.exports = { startWork };
```

### 2. API Layer (`api/`)

The API layer provides higher-level functions that the desktop app calls:

```javascript
// Example: api/workflow-api.js
const { startWork } = require('../adapters/workflow');

class WorkflowAPI {
  async startSession(projectName) {
    const result = await startWork(projectName);
    // Parse result, update state, emit events
    return {
      sessionId: Date.now(),
      project: projectName,
      startTime: new Date()
    };
  }
}

module.exports = new WorkflowAPI();
```

### 3. Desktop App Usage

The Electron main process imports these APIs:

```javascript
// In app/src/main/index.js
const { WorkflowAPI } = require('../../cli/api/workflow-api');

ipcMain.handle('start-session', async (event, project) => {
  return await WorkflowAPI.startSession(project);
});
```

## Data Flow

```
Desktop App (Renderer)
    ↓ IPC
Electron Main Process
    ↓ require()
CLI API Layer
    ↓ function call
Adapters
    ↓ exec()
ZSH Shell
    ↓ source ~/.zshrc
ZSH Functions (~/.config/zsh/)
```

## Development Guidelines

1. **Keep adapters thin**: Just execute commands and return raw output
2. **API layer handles logic**: Parsing, validation, state management
3. **Error handling**: Always catch and format errors properly
4. **Async/await**: Use promises for all shell commands
5. **Testing**: Write tests that mock shell execution

## State Management

- **Read-only**: Adapters only READ from ~/.config/zsh/ files
- **No modification**: Never modify ZSH config from the app
- **Worklog**: Read `~/.config/zsh/.worklog` for current session
- **Status**: Parse `.STATUS` files from projects

## Next Steps

1. Implement `adapters/status.js` (read worklog, parse status)
2. Create `api/status-api.js` (dashboard data provider)
3. Test with simple Node.js script before integrating with app
4. Add error handling and logging

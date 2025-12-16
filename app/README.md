# ZSH Workflow Manager - Desktop App

A desktop application for managing and monitoring ADHD-optimized ZSH workflows.

## Architecture

This is an Electron-based desktop application that provides a graphical interface for:
- Monitoring workflow status
- Managing sessions (work/teaching/research)
- Viewing alias/function reference
- Quick workflow commands
- Dashboard visualization

### Structure

```
app/
├── src/
│   ├── main/          # Electron main process (Node.js)
│   ├── renderer/      # UI layer (HTML/CSS/JS or React)
│   ├── preload/       # Bridge between main and renderer
│   └── shared/        # Shared types and utilities
├── assets/            # Icons, images
└── package.json       # App dependencies
```

## Development Setup

```bash
# Install dependencies
cd app
npm install

# Run in development mode
npm run dev

# Build for production
npm run build
```

## Connection to CLI

The app communicates with the ZSH CLI tools through the `/cli` integration layer:

- **Adapters** (`/cli/adapters`): Wrap ZSH functions for programmatic access
- **API** (`/cli/api`): Node.js API that the Electron main process calls
- **Config**: Reads from `~/.config/zsh/` for current state

## Key Features (Planned)

### Phase 1: Core UI
- [ ] Dashboard view (session status, quota, recent commands)
- [ ] Alias reference viewer
- [ ] Session management (start/end work sessions)

### Phase 2: Advanced Features
- [ ] Workflow automation
- [ ] Project switcher
- [ ] Command palette (fuzzy search aliases)

### Phase 3: ADHD Optimizations
- [ ] Focus mode integration
- [ ] Dopamine tracking (wins/celebrations)
- [ ] Context-aware suggestions

## Technology Stack

- **Framework**: Electron 28+
- **UI**: Plain JavaScript (or React - TBD)
- **State**: electron-store for persistence
- **CLI Bridge**: Node.js child_process to exec ZSH commands

## Next Steps

1. Implement basic Electron main process
2. Create simple renderer with dashboard view
3. Build first CLI adapter (workflow status)
4. Test integration with ~/.config/zsh/ functions

# Installation Guide

Quick guide to install Flow CLI and make the `flow` command available globally.

## Prerequisites

- Node.js >= 18.0.0
- npm >= 9.0.0

Check your versions:
```bash
node --version
npm --version
```

## Quick Install (Recommended)

From the flow-cli directory:

```bash
# 1. Install dependencies
npm install

# 2. Link the CLI globally
npm run install:cli
```

That's it! The `flow` command is now available globally.

## Verify Installation

```bash
flow --version
flow help
flow status
```

## Usage Examples

### CLI Mode (Default - Fast & Scriptable)

```bash
# Show current status
flow status

# Verbose output with all metrics
flow status -v

# Last 14 days of history
flow status -d 14

# Skip worklog integration
flow status --no-worklog
```

### Web Dashboard Mode (Rich Visualizations)

```bash
# Launch web dashboard (opens browser)
flow status --web

# Custom port
flow status --web -p 8080
```

The web dashboard includes:
- Real-time session monitoring
- Chart.js visualizations
- Session history trends
- Project statistics
- Dark theme (ADHD-friendly)

## Uninstall

```bash
npm run uninstall:cli
```

## Reinstall

If you make changes to the CLI code:

```bash
npm run reinstall:cli
```

## Manual Installation

If the npm scripts don't work, you can install manually:

```bash
cd cli
npm link
```

To uninstall manually:

```bash
cd cli
npm unlink
```

## Development Mode

If you're developing and don't want to install globally:

```bash
# Run commands directly with node
node cli/commands/status.js
node cli/commands/status.js --web
```

## Troubleshooting

### "command not found: flow"

The global link might not be in your PATH. Try:

```bash
npm run reinstall:cli
```

Or check where npm installs global packages:

```bash
npm config get prefix
```

Make sure that directory is in your PATH.

### Permission errors

If you get EACCES errors, you may need to fix npm permissions:

```bash
# Fix npm global permissions
mkdir -p ~/.npm-global
npm config set prefix ~/.npm-global

# Add to PATH (add this to ~/.zshrc)
export PATH=~/.npm-global/bin:$PATH

# Then reinstall
npm run reinstall:cli
```

### Already installed but not working

```bash
# Uninstall and reinstall
npm run reinstall:cli

# Verify
which flow
flow --version
```

## Next Steps

After installation:

1. **Start a session** (when implemented):
   ```bash
   flow work my-project "Implement feature"
   ```

2. **Check status**:
   ```bash
   flow status
   ```

3. **Launch web dashboard**:
   ```bash
   flow status --web
   ```

See the [documentation](https://Data-Wise.github.io/flow-cli/) for more details.

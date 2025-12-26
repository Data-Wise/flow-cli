# Tutorial 5: AI-Powered Commands

> **Time:** 10 minutes
> **Prerequisites:** flow-cli installed, Claude CLI (`claude`) available
> **Goal:** Use AI to accelerate your workflow

---

## Overview

flow-cli v3.2.0 introduces AI-powered commands that use Claude to help you:

- Ask questions with project context (`flow ai`)
- Translate natural language to shell commands (`flow do`)
- Get unstuck with AI assistance (`stuck --ai`)
- Get smart task suggestions (`next --ai`)

---

## Step 1: Check Prerequisites

First, verify Claude CLI is installed:

```bash
command -v claude && echo "✅ Claude CLI found" || echo "❌ Install: npm i -g @anthropic-ai/claude-code"
```

---

## Step 2: Ask AI Questions

### Basic Query

Ask AI anything about your project:

```bash
flow ai "what testing framework should I use for this project?"
```

The AI receives context about:

- Your current directory
- Project type (ZSH plugin, R package, etc.)
- Git branch and status
- Active flow session

### Explain Mode

Get explanations of code or concepts:

```bash
flow ai --explain "what does this regex do: ^##\s*Focus:"
```

### Fix Mode

Get help fixing problems:

```bash
flow ai --fix "my tests are failing with 'command not found'"
```

### Suggest Mode

Get improvement suggestions:

```bash
flow ai --suggest "make this function more efficient"
```

### Create Mode

Generate code from descriptions:

```bash
flow ai --create "a function that validates email addresses"
```

---

## Step 3: Natural Language Commands

The `flow do` command translates plain English into shell commands.

### Try These Examples

```bash
# Show recent git activity
flow do "show commits from last week"

# Find files
flow do "find all markdown files modified today"

# Count code
flow do "count lines of code in zsh files"

# Check disk usage
flow do "show largest files in current directory"
```

### Dry Run Mode

See what command would run without executing:

```bash
flow do --dry-run "delete all .bak files"
```

Output:

```
🔍 Translating: "delete all .bak files"
📝 Command: find . -name "*.bak" -delete

⚠️  DRY RUN - command not executed
```

### Safety Features

Dangerous commands require confirmation:

```bash
flow do "remove all files"
```

Output:

```
⚠️  DANGEROUS COMMAND DETECTED
📝 Command: rm -rf *

This command could cause data loss.
Execute anyway? [y/N]:
```

---

## Step 4: ADHD Helpers with AI

### When You're Stuck

```bash
# Get general unstuck tips
stuck

# Get AI-powered help
stuck --ai

# Describe your specific problem
stuck --ai "can't figure out why the tests pass locally but fail in CI"
```

The AI will:

1. Break down the problem into tiny steps
2. Suggest ONE specific action to start
3. Offer to capture the problem for later

### What to Work on Next

```bash
# See your active projects
next

# Get AI-powered suggestion
next --ai
```

The AI considers:

- Your active projects and their focus
- Inbox items waiting
- Energy management for ADHD

---

## Step 5: Advanced Usage

### Include Extra Context

Force context inclusion even for simple queries:

```bash
flow ai --context "should I use async here?"
```

### Verbose Mode

See what context is being sent to AI:

```bash
flow ai --verbose "how do I add a new command?"
```

Output:

```
📋 Context being sent:
Directory: /Users/dt/projects/dev-tools/flow-cli
Project type: zsh-plugin
Git branch: main
Changed files: 3
...

🤖 Asking AI...
```

### Combine Modes

```bash
# Explain with context
flow ai --explain --context "the _flow_detect_type function"

# Fix with verbose output
flow ai --fix --verbose "completion not working"
```

---

## Quick Reference

| Command             | Purpose                   |
| ------------------- | ------------------------- |
| `flow ai "query"`   | Ask AI anything           |
| `flow ai --explain` | Explain code/concepts     |
| `flow ai --fix`     | Get fix suggestions       |
| `flow ai --suggest` | Get improvements          |
| `flow ai --create`  | Generate code             |
| `flow do "..."`     | Natural language → shell  |
| `flow do --dry-run` | Preview without executing |
| `stuck --ai`        | AI help when blocked      |
| `next --ai`         | AI task suggestion        |

---

## Tips for ADHD Brains

1. **Use `flow do` for commands you can't remember**
   - Don't waste mental energy on syntax
   - Just describe what you want

2. **`stuck --ai` is your rubber duck**
   - Describing the problem often reveals the solution
   - AI breaks it into manageable pieces

3. **`next --ai` helps with decision paralysis**
   - When everything feels equally important
   - Get ONE clear recommendation

4. **Dry run everything dangerous**
   - `flow do --dry-run` before destructive operations
   - Builds confidence before executing

---

## Troubleshooting

### "Claude CLI not found"

Install with:

```bash
npm install -g @anthropic-ai/claude-code
```

### AI responses are slow

- Claude CLI makes API calls - expect 1-3 seconds
- Use `--verbose` to see progress

### Commands not translating correctly

- Be more specific in your description
- Use `--dry-run` to see what it would do
- Adjust and try again

---

## What's Next?

- **Tutorial 6:** Custom workflows (coming soon)
- **Reference:** [COMMAND-QUICK-REFERENCE.md](../reference/COMMAND-QUICK-REFERENCE.md)
- **Help:** `flow ai --help`, `flow do --help`

---

_Tutorial created: 2025-12-26 (v3.2.0)_

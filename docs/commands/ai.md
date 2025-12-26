# flow ai

> AI-powered assistant with project context

## Synopsis

```bash
flow ai [options] <query>
```

## Description

`flow ai` sends queries to Claude with automatic project context. The AI receives information about your current directory, project type, git status, and active flow session.

## Options

| Option          | Description                                         |
| --------------- | --------------------------------------------------- |
| `-e, --explain` | Explain mode - get explanations of code or concepts |
| `-f, --fix`     | Fix mode - get suggestions to fix problems          |
| `-s, --suggest` | Suggest mode - get improvement suggestions          |
| `--create`      | Create mode - generate code from descriptions       |
| `-c, --context` | Force include project context                       |
| `-v, --verbose` | Show context being sent to AI                       |
| `-h, --help`    | Show help message                                   |

## Modes

### Default Mode

Ask any question with project awareness:

```bash
flow ai "what's the best way to handle errors in this project?"
```

### Explain Mode (`--explain`)

Get explanations of code, patterns, or concepts:

```bash
flow ai --explain "the dispatcher pattern used here"
flow ai -e "what does this regex do?"
```

### Fix Mode (`--fix`)

Get help fixing problems:

```bash
flow ai --fix "tests are timing out"
flow ai -f "completion not working for new command"
```

### Suggest Mode (`--suggest`)

Get improvement suggestions:

```bash
flow ai --suggest "make this function faster"
flow ai -s "better error messages"
```

### Create Mode (`--create`)

Generate code from descriptions:

```bash
flow ai --create "a function that parses .STATUS files"
flow ai --create "completion for the new 'sync' command"
```

## Context

The AI automatically receives:

- Current working directory
- Detected project type (zsh-plugin, r-package, quarto, etc.)
- Git branch name
- Number of changed files
- flow-cli version
- Shell and OS information
- Active flow session (if any)

Use `--verbose` to see what context is sent:

```bash
flow ai --verbose "how do I add a test?"
```

## Examples

```bash
# General questions
flow ai "should I use associative arrays here?"

# Explain existing code
flow ai --explain "the _flow_detect_type function"

# Get fix suggestions
flow ai --fix "zsh: command not found: r"

# Request improvements
flow ai --suggest "better progress bar implementation"

# Generate new code
flow ai --create "a health check for brew packages"
```

## Requirements

- Claude CLI (`claude`) must be installed
- Install: `npm install -g @anthropic-ai/claude-code`

## See Also

- [`flow do`](do.md) - Natural language command execution
- [Tutorial: AI-Powered Commands](../tutorials/05-ai-commands.md)

---

_Added in v3.2.0_

# flow ai

> AI-powered assistant with project context

## Synopsis

```bash
flow ai [options] <query>
flow ai recipe <name> [input]
flow ai chat [options]
flow ai usage [action]
flow ai model [action]
```

## Description

`flow ai` sends queries to Claude with automatic project context. The AI receives information about your current directory, project type, git status, and active flow session.

## Subcommands

### recipe

Run reusable AI prompts with variable substitution.

```bash
flow ai recipe list              # List all recipes
flow ai recipe show <name>       # View recipe content
flow ai recipe <name> <input>    # Run a recipe
flow ai recipe create <name>     # Create custom recipe
flow ai recipe edit <name>       # Edit user recipe
flow ai recipe delete <name>     # Delete user recipe
```

**Built-in Recipes:**

| Recipe         | Description                          |
| -------------- | ------------------------------------ |
| `review`       | Code review with actionable feedback |
| `commit`       | Generate conventional commit message |
| `explain-code` | Step-by-step code explanation        |
| `debug`        | Help diagnose issues                 |
| `refactor`     | Suggest code improvements            |
| `test`         | Generate tests for code              |
| `document`     | Generate documentation               |
| `eli5`         | Explain like I'm 5                   |
| `shell`        | Generate shell commands              |
| `fix`          | Fix a problem                        |

**Variables Available:**

- `{{input}}` - User-provided input
- `{{project_type}}` - Detected project type
- `{{pwd}}` - Current directory
- `{{date}}` - Today's date
- `{{branch}}` - Current git branch
- `{{project}}` - Project name

### chat

Interactive conversation mode with persistent history.

```bash
flow ai chat                     # Start chat session
flow ai chat --context           # Enable project context
flow ai chat --clear             # Clear conversation history
flow ai chat --history           # Show conversation history
```

**In-Chat Commands:**

| Command    | Description                |
| ---------- | -------------------------- |
| `/clear`   | Clear conversation history |
| `/history` | Show conversation history  |
| `/context` | Toggle project context     |
| `/help`    | Show help                  |
| `/exit`    | Exit chat (or Ctrl+D)      |

### usage

Track AI command usage and get personalized suggestions.

```bash
flow ai usage                    # Show statistics (default)
flow ai usage stats              # Show usage statistics
flow ai usage suggest            # Get personalized suggestions
flow ai usage recent [n]         # Show last n commands
flow ai usage clear              # Clear usage history
```

**Statistics Tracked:**

- Total calls and success rate
- Usage by command and mode
- Recipe usage frequency
- Current streak (daily usage)
- Project-type patterns

### model

Manage AI model selection.

```bash
flow ai model                    # Show current model
flow ai model list               # List available models
flow ai model set <name>         # Set default model
```

**Available Models:**

| Model    | Description                             |
| -------- | --------------------------------------- |
| `opus`   | Most capable, deep reasoning            |
| `sonnet` | Balanced speed and capability (default) |
| `haiku`  | Fast, lightweight responses             |

## Options

| Option          | Description                                         |
| --------------- | --------------------------------------------------- |
| `-e, --explain` | Explain mode - get explanations of code or concepts |
| `-f, --fix`     | Fix mode - get suggestions to fix problems          |
| `-s, --suggest` | Suggest mode - get improvement suggestions          |
| `--create`      | Create mode - generate code from descriptions       |
| `-m, --model`   | Select model for this query (opus, sonnet, haiku)   |
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

# Get fix suggestions with specific model
flow ai --model opus --fix "complex architectural issue"

# Use recipes
flow ai recipe review "function parse_status() { ... }"
flow ai recipe commit "$(git diff --staged)"

# Interactive chat
flow ai chat --context

# Check usage patterns
flow ai usage suggest

# Switch to faster model for quick queries
flow ai model set haiku
flow ai "quick question"
```

## Requirements

- Claude CLI (`claude`) must be installed
- Install: `npm install -g @anthropic-ai/claude-code`

## See Also

- [`flow do`](do.md) - Natural language command execution
- [Tutorial: AI-Powered Commands](../tutorials/05-ai-commands.md)

---

_Added in v3.2.0, enhanced in v3.4.0 (recipes, chat, usage, model)_

# flow do

> Natural language to shell command translation

## Synopsis

```bash
flow do [options] "<natural language description>"
```

## Description

`flow do` translates plain English descriptions into shell commands using AI. It understands your project context and generates appropriate commands for your environment.

## Options

| Option          | Description                    |
| --------------- | ------------------------------ |
| `-n, --dry-run` | Show command without executing |
| `-v, --verbose` | Show AI reasoning              |
| `-h, --help`    | Show help message              |

## Safety Features

### Dangerous Command Detection

Commands that could cause data loss are flagged:

```bash
flow do "delete all files"
```

Output:

```text
⚠️  DANGEROUS COMMAND DETECTED
📝 Command: rm -rf *

This command could cause data loss.
Execute anyway? [y/N]:
```

Dangerous patterns detected:

- `rm -rf`
- `rm -r`
- `> /dev/`
- `mkfs`
- `dd if=`
- `:(){:|:&};:`

### Dry Run Mode

Always preview before executing uncertain commands:

```bash
flow do --dry-run "remove all backup files"
```

Output:

```text
🔍 Translating: "remove all backup files"
📝 Command: find . -name "*.bak" -delete

⚠️  DRY RUN - command not executed
```

## Examples

### File Operations

```bash
flow do "find large files over 100MB"
# → find . -size +100M -type f

flow do "show files modified in the last hour"
# → find . -mmin -60 -type f

flow do "count lines in all zsh files"
# → find . -name "*.zsh" -exec wc -l {} +
```

### Git Operations

```bash
flow do "show commits from last week"
# → git log --since='1 week ago' --oneline

flow do "find who last modified this file"
# → git log -1 --format='%an' -- <file>

flow do "show branches merged into main"
# → git branch --merged main
```

### System Information

```bash
flow do "check disk usage"
# → df -h

flow do "show running node processes"
# → pgrep -fl node

flow do "what's using port 3000"
# → lsof -i :3000
```

### Project-Specific

The AI considers your project type:

```bash
# In an R package directory:
flow do "run the tests"
# → Rscript -e "devtools::test()"

# In a Node.js project:
flow do "run the tests"
# → npm test

# In a Quarto project:
flow do "build the document"
# → quarto render
```

## Workflow Tips

### ADHD-Friendly Usage

1. **Don't memorize syntax** - Just describe what you want
2. **Always use `--dry-run` first** - Build confidence before executing
3. **Be specific** - "show git log" vs "show commits by me this week"

### Chaining with Other Commands

```bash
# Preview first, then run
flow do --dry-run "find duplicate files" && flow do "find duplicate files"

# Use output in pipes (careful!)
flow do "list all TODO comments" | head -20
```

## Limitations

- Requires Claude CLI (`claude`)
- Response time: 1-3 seconds for API call
- Complex multi-step operations may need refinement
- Always verify generated commands before execution

## Requirements

- Claude CLI (`claude`) must be installed
- Install: `npm install -g @anthropic-ai/claude-code`

## See Also

- [`flow ai`](ai.md) - General AI assistant
- [Tutorial: AI-Powered Commands](../tutorials/05-ai-commands.md)

---

**Last Updated:** 2026-01-07
**Command Version:** v4.8.0 (do v3.2.0)
**Status:** ✅ Production ready with dangerous command detection

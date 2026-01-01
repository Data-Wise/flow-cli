# Claude Code Container Mode - Brainstorm

**Generated:** 2026-01-01
**Context:** flow-cli integration with Claude Code
**Research Question:** Does Claude Code CLI have container mode? What's its use for workflow? Can it be used for "acceptEdits" with extensive permissions?

---

## Overview

**Yes, Claude Code CLI has extensive container support** through multiple approaches:

1. **DevContainers** (VS Code Dev Containers extension)
2. **Docker Sandbox** (Official Docker image: `docker/sandbox-templates:claude-code`)
3. **CLI-only containers** (devcontainer CLI or custom Docker setups)

**Primary Use Case:** Safe isolation for `--dangerously-skip-permissions` flag (true YOLO mode)

---

## Key Findings

### What is Container Mode?

Container mode allows Claude Code to run in an isolated Docker/DevContainer environment where:

- ✅ Claude can execute **all commands without prompts** (`--dangerously-skip-permissions`)
- ✅ File system access is **restricted to container**
- ✅ Network access can be **firewall-controlled** (whitelist Anthropic API, npm, GitHub)
- ✅ Mistakes only affect the **container, not host machine**
- ✅ Credentials persist across container restarts via Docker volumes

### vs VS Code Extension "Auto-Accept Edits"

| Feature                 | VS Code Shift+Tab     | Container + CLI YOLO |
| ----------------------- | --------------------- | -------------------- |
| **Auto-accept edits**   | ✅ Yes                | ✅ Yes               |
| **Auto-accept reads**   | ❌ No (still prompts) | ✅ Yes (no prompts)  |
| **Auto-accept writes**  | ❌ No (still prompts) | ✅ Yes (no prompts)  |
| **Auto-accept execute** | ❌ No (still prompts) | ✅ Yes (no prompts)  |
| **Isolation**           | ❌ Full host access   | ✅ Container only    |
| **Network control**     | ❌ Full internet      | ✅ Firewall rules    |
| **Safety**              | ⚠️ Relies on prompts  | ✅ Container sandbox |

**Answer:** Container mode gives you **true extensive permissions** that VS Code extension cannot provide.

---

## Container Approaches (2025/2026)

### 1. Official Docker Sandbox (Easiest)

**Image:** `docker/sandbox-templates:claude-code`

**Features:**

- Pre-installed Claude Code CLI
- Automatic credential management (persisted in `docker-claude-sandbox-data` volume)
- Development tools: Docker CLI, GitHub CLI, Node.js, Go, Python 3, Git, ripgrep, jq
- Official Docker support

**Usage:**

```bash
# Run Claude Code in sandbox
docker sandbox run docker/sandbox-templates:claude-code

# With YOLO mode
docker sandbox run docker/sandbox-templates:claude-code \
  -- claude --dangerously-skip-permissions

# Continue conversation
docker sandbox run docker/sandbox-templates:claude-code \
  -- claude --continue
```

**Credentials:** Stored in persistent Docker volume, automatically reused across sessions

---

### 2. DevContainers (VS Code Integration)

**Best for:** Projects you're actively developing in VS Code

**Setup:**

1. Create `.devcontainer/` folder in project root
2. Add `devcontainer.json` with Claude Code feature
3. Reopen project in container (VS Code command palette)

**Example `.devcontainer/devcontainer.json`:**

```json
{
  "name": "Claude Code Dev Environment",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/anthropics/devcontainer-features/claude-code:latest": {}
  },
  "postCreateCommand": "echo 'Container ready'",
  "customizations": {
    "vscode": {
      "extensions": ["claude.claude-code"]
    }
  }
}
```

**Security Enhancement (Firewall):**

```json
{
  "postCreateCommand": "bash .devcontainer/setup-firewall.sh"
}
```

**`.devcontainer/setup-firewall.sh`:**

```bash
#!/bin/bash
# Whitelist Anthropic API, npm, GitHub
iptables -A OUTPUT -d api.anthropic.com -j ACCEPT
iptables -A OUTPUT -d registry.npmjs.org -j ACCEPT
iptables -A OUTPUT -d github.com -j ACCEPT
iptables -A OUTPUT -j DROP  # Block all other outbound
```

**Usage in Container:**

```bash
# Inside devcontainer terminal
claude --dangerously-skip-permissions
```

**Benefits:**

- Integrated with VS Code Dev Containers extension
- Firewall rules restrict network access
- Container-only file access
- Can use `--dangerously-skip-permissions` safely

---

### 3. CLI-Only DevContainer (No VS Code)

**Best for:** Automation, CI/CD, server environments

**Install devcontainer CLI:**

```bash
npm install -g @devcontainers/cli
```

**Usage:**

```bash
# Start container
devcontainer up --workspace-folder .

# Run Claude Code inside
devcontainer exec --workspace-folder . \
  claude --dangerously-skip-permissions

# Stop container
devcontainer down --workspace-folder .
```

**Benefits:**

- No VS Code required
- Can be scripted for automation
- Same security as VS Code devcontainers

---

### 4. Custom Docker Setup

**Community projects** (GitHub examples from 2025):

#### ClaudeBox

- Fully containerized environment
- Pre-configured development profiles
- [GitHub: RchGrav/claudebox](https://github.com/RchGrav/claudebox)

#### claude-container

- Complete isolation from host
- Optional logging proxy (captures API requests to SQLite)
- Persistent credentials and workspace
- [GitHub: nezhar/claude-container](https://github.com/nezhar/claude-container)

#### claude-docker

- Full permissions by default
- Twilio notifications (when tasks complete)
- Pre-configured MCP servers
- Host GPU access
- [GitHub: VishalJ99/claude-docker](https://github.com/VishalJ99/claude-docker)

---

## Use Cases for Your Workflow

### Scenario 1: Safe YOLO Mode for Refactoring

**Problem:** Want Claude to refactor multiple files without constant prompts, but don't want to risk host machine

**Solution:** DevContainer + `--dangerously-skip-permissions`

```bash
# flow-cli integration idea
cc yolo container "refactor commands/ directory"

# What it does:
# 1. Launches devcontainer (or creates if missing)
# 2. Runs: claude --dangerously-skip-permissions
# 3. Passes prompt: "refactor commands/ directory"
# 4. Monitors with: watch -n 2 'git diff --stat'
# 5. When done, shows diff and asks to commit or discard
```

**Safety:** All changes happen in container, can `git reset --hard` if needed

---

### Scenario 2: Automated Workflow Execution

**Problem:** Want to run repetitive Claude Code tasks unattended (e.g., nightly lint fixes, doc generation)

**Solution:** Docker Sandbox + scripted prompts

```bash
# Docker sandbox with stored prompt
docker sandbox run docker/sandbox-templates:claude-code \
  -- claude --dangerously-skip-permissions \
  --prompt "$(cat .claude/commands/lint-fix.md)"

# Or with devcontainer CLI
devcontainer exec --workspace-folder . \
  claude --dangerously-skip-permissions \
  --prompt "Fix all ESLint errors in src/"
```

**Benefits:**

- No user interaction needed
- Runs in CI/CD pipeline
- Results isolated to container

---

### Scenario 3: Parallel Development Environments

**Problem:** Working on multiple experiments simultaneously without polluting main environment

**Solution:** Multiple devcontainers (worktree-style)

```bash
# flow-cli integration idea
cc container create experiment-auth    # New container
cc container create experiment-cache   # Another container

# Each has own Claude Code instance
# Each isolated from others
# Each can use --dangerously-skip-permissions
```

**Use Case:** Like worktrees, but for entire development environments

---

## Integration with flow-cli

### Proposed CC Dispatcher Enhancement

```bash
# Current
cc                # VS Code (Shift+Tab for auto-accept edits)
cc yolo           # VS Code (manual Shift+Tab required)

# Proposed New
cc container      # Launch Claude in devcontainer (YOLO mode)
cc container pick # Pick project → devcontainer YOLO
cc sandbox        # Launch Docker sandbox YOLO
cc sandbox pick   # Pick project → sandbox YOLO
```

### Implementation Ideas

#### Option A: DevContainer Integration

```bash
# cc-dispatcher.zsh enhancement
_cc_container() {
    local project_dir="${1:-$PWD}"

    # Check if .devcontainer exists
    if [[ ! -d "$project_dir/.devcontainer" ]]; then
        echo "📦 No .devcontainer found. Create one?"
        read -q "REPLY?Create devcontainer? [y/N] "
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            _cc_create_devcontainer "$project_dir"
        else
            return 1
        fi
    fi

    # Launch devcontainer with Claude Code
    echo "🚀 Launching Claude Code in devcontainer..."
    devcontainer exec --workspace-folder "$project_dir" \
        claude --dangerously-skip-permissions
}

_cc_create_devcontainer() {
    local project_dir="$1"
    mkdir -p "$project_dir/.devcontainer"

    cat > "$project_dir/.devcontainer/devcontainer.json" <<'EOF'
{
  "name": "Claude Code Container",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/anthropics/devcontainer-features/claude-code:latest": {}
  }
}
EOF

    echo "✅ Created .devcontainer/devcontainer.json"
}
```

#### Option B: Docker Sandbox Integration

```bash
# cc-dispatcher.zsh enhancement
_cc_sandbox() {
    local prompt="${1:-}"

    if [[ -z "$prompt" ]]; then
        echo "🐳 Launching Claude Code sandbox..."
        docker sandbox run docker/sandbox-templates:claude-code \
            -- claude --dangerously-skip-permissions
    else
        echo "🐳 Running prompt in sandbox: $prompt"
        docker sandbox run docker/sandbox-templates:claude-code \
            -- claude --dangerously-skip-permissions \
            --prompt "$prompt"
    fi
}

# With project picker
_cc_sandbox_pick() {
    local project=$(pick)  # Uses existing pick command
    cd "$project" || return 1
    _cc_sandbox
}
```

---

## Comparison Matrix

| Approach                   | Setup Effort         | Safety                | Speed           | Best For                      |
| -------------------------- | -------------------- | --------------------- | --------------- | ----------------------------- |
| **VS Code Shift+Tab**      | ⚡ None              | ⚠️ Prompts still      | ⚡ Instant      | Interactive editing           |
| **CLI --dangerously-skip** | ⚡ None              | ❌ Full host access   | ⚡ Instant      | **NOT RECOMMENDED** (unsafe)  |
| **DevContainer + YOLO**    | 🔧 Medium (one-time) | ✅ Container isolated | 🐢 Slow startup | Development projects          |
| **Docker Sandbox**         | ⚡ Low (docker only) | ✅ Container isolated | 🚀 Fast startup | Quick experiments, automation |
| **Custom Docker**          | 🔧🔧 High            | ✅ Full control       | 🚀 Fast         | Advanced workflows, CI/CD     |

---

## Recommended Path

### Phase 1: Quick Wins (< 30 min each)

1. ⚡ **Try Docker Sandbox** - Easiest way to experience true YOLO mode

   ```bash
   docker sandbox run docker/sandbox-templates:claude-code \
     -- claude --dangerously-skip-permissions
   ```

2. ⚡ **Update YOLO-MODE-WORKFLOW.md** - Add Container section (Method 3)

3. ⚡ **Test with flow-cli project** - Safe environment to experiment

### Phase 2: Medium Effort (1-2 hours)

1. 🔧 **Create flow-cli devcontainer** - Add `.devcontainer/` folder
2. 🔧 **Add `cc container` to CC dispatcher** - New command for devcontainer launch
3. 🔧 **Document in CC-DISPATCHER-REFERENCE.md** - Update reference docs

### Phase 3: Long-term (Future sessions)

1. 🏗️ **MCP integration in containers** - Run statistical-research MCP inside container
2. 🏗️ **Parallel container workflows** - Multiple Claude instances for different tasks
3. 🏗️ **CI/CD automation** - Scheduled Claude Code tasks in containers
4. 🏗️ **Team devcontainer templates** - Shareable devcontainer configs for R packages

---

## Open Questions

1. **Credential management:** How to handle Claude API key in containers?
   - Docker Sandbox: Automatic (uses persistent volume)
   - DevContainer: Need to mount `~/.anthropic/` or use environment variable

2. **File sync:** How to get container changes back to host?
   - DevContainer: Automatic (workspace mounted)
   - Docker Sandbox: May need volume mounts

3. **MCP servers:** Can MCP servers run inside containers?
   - Yes, but need network access to Zotero, R, etc.
   - May need to expose ports or use host network mode

4. **Performance:** Is container overhead acceptable for interactive use?
   - Docker Sandbox: Fast startup (~5s)
   - DevContainer: Slower startup (~30s first time, ~5s cached)

---

## Next Steps

**Recommended Action:** Start with Docker Sandbox to experience container-based YOLO mode

```bash
# Try it now
docker sandbox run docker/sandbox-templates:claude-code

# Then inside the sandbox
claude --dangerously-skip-permissions

# Give it a test prompt
> Analyze the structure of /workspace and suggest improvements
```

**Follow-up:**

1. If Docker Sandbox works well → Add `cc sandbox` to flow-cli
2. If need VS Code integration → Create devcontainer for flow-cli
3. Update YOLO-MODE-WORKFLOW.md with Container section (Method 3)

---

## Sources

- [Claude Code DevContainer Docs](https://code.claude.com/docs/en/devcontainer)
- [How to Safely Run AI Agents Like Cursor and Claude Code Inside a DevContainer](https://codewithandrea.com/articles/run-ai-agents-inside-devcontainer/)
- [Configure Claude Code | Docker Docs](https://docs.docker.com/ai/sandboxes/claude-code/)
- [Switching to Claude Code + VSCode inside Docker](https://timsh.org/claude-inside-docker/)
- [Using Claude Code Safely with Dev Containers](https://nakamasato.medium.com/using-claude-code-safely-with-dev-containers-b46b8fedbca9)
- [Running Claude Code Safely in Devcontainers - Jökull Sólberg](https://www.solberg.is/claude-devcontainer/)
- [Building a Secure AI Development Environment](https://medium.com/@brett_4870/building-a-secure-ai-development-environment-containerized-claude-code-mcp-integration-e2129fe3af5a)
- [GitHub: anthropics/devcontainer-features](https://github.com/anthropics/devcontainer-features)
- [Claude Code in Devcontainers · Mitja Martini](https://mitjamartini.com/posts/claude-code-in-devcontainer/)
- [Running Claude Code inside your dev containers - DEV Community](https://dev.to/sbotto/running-claude-code-inside-your-dev-containers-36e7)
- [Claude Code dangerously-skip-permissions: Safe Usage Guide](https://www.ksred.com/claude-code-dangerously-skip-permissions-when-to-use-it-and-when-you-absolutely-shouldnt/)
- [Claude --dangerously-skip-permissions - AI Wiki](https://aiwiki.ai/wiki/Claude_--dangerously-skip-permissions)
- [Dangerous Skip Permissions | ClaudeLog](https://claudelog.com/mechanics/dangerous-skip-permissions/)
- [GitHub Issue #1498: --dangerously-skip-permissions sometimes still asks](https://github.com/anthropics/claude-code/issues/1498)
- [claude --dangerously-skip-permissions](https://blog.promptlayer.com/claude-dangerously-skip-permissions/)
- [GitHub: tintinweb/claude-code-container](https://github.com/tintinweb/claude-code-container)
- [Claude Code: Best practices for agentic coding](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Living dangerously with Claude](https://simonwillison.net/2025/Oct/22/living-dangerously-with-claude/)
- [Running Claude Code Agents in Docker Containers](https://medium.com/@dan.avila7/running-claude-code-agents-in-docker-containers-for-complete-isolation-63036a2ef6f4)
- [GitHub: RchGrav/claudebox](https://github.com/RchGrav/claudebox)
- [GitHub: nezhar/claude-container](https://github.com/nezhar/claude-container)
- [GitHub: VishalJ99/claude-docker](https://github.com/VishalJ99/claude-docker)
- [Shipyard: Building an App with Claude Code and Docker Compose](https://shipyard.build/blog/building-an-app-claude-code-docker-compose/)
- [Add MCP Servers to Claude Code with MCP Toolkit | Docker](https://www.docker.com/blog/add-mcp-servers-to-claude-code-with-mcp-toolkit/)
- [Run Claude Code in Docker: A Secure Developer's Guide](https://www.arsturn.com/blog/how-to-run-claude-code-securely-in-a-docker-container)

---

**Last Updated:** 2026-01-01
**Status:** Research complete - Ready for implementation planning

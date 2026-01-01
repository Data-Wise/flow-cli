# CC Sand (Sandbox) - Brainstorm + Docker Education

**Generated:** 2026-01-01
**Context:** flow-cli CC dispatcher enhancement
**Goal:** Design `cc sand` command + Docker education for beginners

---

## Part 1: Docker Education for Beginners

### What is Docker? (5-Minute Explanation)

**Docker** is a tool that packages your code and everything it needs to run (libraries, tools, system files) into a **container**.

Think of a container like a **shipping container**:

- Standard size/shape (works anywhere)
- Self-contained (everything inside)
- Isolated (doesn't interfere with other containers)
- Portable (works on any ship/truck/train)

### Key Concepts

#### 1. Container vs Virtual Machine

```
┌─────────────────────────────────────────────────────────────┐
│ VIRTUAL MACHINE (Heavy)                                     │
├─────────────────────────────────────────────────────────────┤
│ Your App + Full OS (Windows/Linux)                          │
│ Takes: 1-2 GB RAM, boots in ~1 min                          │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ CONTAINER (Lightweight)                                     │
├─────────────────────────────────────────────────────────────┤
│ Your App + Only what it needs                               │
│ Takes: 100-500 MB RAM, boots in ~5 sec                      │
└─────────────────────────────────────────────────────────────┘
```

**Why containers are better for development:**

- ⚡ **Faster** - Start in seconds, not minutes
- 💾 **Lighter** - Use less disk space and RAM
- 🔁 **Disposable** - Delete and recreate instantly
- 📦 **Portable** - Works same on Mac, Linux, Windows

#### 2. Docker Image vs Container

```
┌─────────────────────────────────────────────────────────────┐
│ IMAGE = Blueprint (Template)                                │
├─────────────────────────────────────────────────────────────┤
│ Like: A recipe in a cookbook                                │
│ Contains: Instructions to build a container                 │
│ Stored: Docker Hub (like GitHub for containers)             │
│ Example: docker/sandbox-templates:claude-code               │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ CONTAINER = Running Instance                                │
├─────────────────────────────────────────────────────────────┤
│ Like: The actual meal you cooked from the recipe            │
│ Contains: Running processes, files, network                 │
│ Lifecycle: Created → Running → Stopped → Deleted            │
│ Example: Your Claude Code session in a sandbox              │
└─────────────────────────────────────────────────────────────┘
```

**Analogy:**

- **Image** = Cookie cutter (shape/template)
- **Container** = The actual cookie (you can eat it!)

#### 3. Key Docker Commands (Cheat Sheet)

| Command                  | What It Does                 | Analogy                           |
| ------------------------ | ---------------------------- | --------------------------------- |
| `docker pull <image>`    | Download an image            | Download recipe book              |
| `docker run <image>`     | Create + start container     | Bake the cookie                   |
| `docker ps`              | List running containers      | See which cookies are fresh       |
| `docker ps -a`           | List all containers          | See all cookies (even eaten ones) |
| `docker stop <id>`       | Stop a container             | Put cookie back in jar            |
| `docker rm <id>`         | Delete a container           | Throw cookie away                 |
| `docker images`          | List downloaded images       | List recipe books                 |
| `docker exec <id> <cmd>` | Run command inside container | Add sprinkles to cookie           |

#### 4. Docker for Claude Code (Why It's Useful)

**Problem:** Claude Code with `--dangerously-skip-permissions` can:

- ❌ Delete files on your computer
- ❌ Install malicious packages
- ❌ Send data to external servers
- ❌ Corrupt your git history

**Solution:** Run Claude Code in a Docker container:

- ✅ Only accesses files **inside container**
- ✅ Can delete container files → **just recreate container**
- ✅ Network access **controlled by firewall rules**
- ✅ Mistakes don't affect your **host machine**

**Real-World Example:**

```
Without Docker (Dangerous):
┌─────────────────────────────────────────────────────────────┐
│ Your Mac                                                    │
├─────────────────────────────────────────────────────────────┤
│ ~/projects/ ← Claude can modify ANYTHING here               │
│ ~/.ssh/     ← Including your SSH keys!                      │
│ /System/    ← Even system files!                            │
└─────────────────────────────────────────────────────────────┘
Risk: High - Claude has full access to your entire computer

With Docker (Safe):
┌─────────────────────────────────────────────────────────────┐
│ Your Mac (Host)                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Docker Container (Isolated)                             │ │
│ │ /workspace/ ← Claude can only see THIS                  │ │
│ │ (mapped to ~/projects/flow-cli on host)                 │ │
│ └─────────────────────────────────────────────────────────┘ │
│ ~/.ssh/ ← Claude CANNOT access this                        │
└─────────────────────────────────────────────────────────────┘
Risk: Low - Claude limited to /workspace in container
```

#### 5. Docker Volumes (How Files Get In/Out)

**Volume** = Shared folder between host and container

```
Host Machine                    Container
~/projects/flow-cli    ←→      /workspace
    ↑                              ↑
    │                              │
Changes sync in real-time!
```

**Example:**

```bash
# Run container with volume mount
docker run -v ~/projects/flow-cli:/workspace claude-image

# Inside container:
cd /workspace     # Same files as ~/projects/flow-cli on host
ls               # You see: flow.plugin.zsh, lib/, commands/, etc.
# Edit a file → changes appear on host immediately
```

**Benefits:**

- ✅ Work on **real project files** (not copies)
- ✅ Changes **persist** after container stops
- ✅ Can use **host tools** (Git, VS Code) alongside container

#### 6. Docker Networks (How Containers Talk)

**Network** = How containers access the internet or each other

```
Three network modes:

1. bridge (default) - Container gets own IP
   ┌─────────────┐     ┌─────────────┐
   │ Container   │────▶│ Docker      │────▶ Internet
   │ 172.17.0.2  │     │ 172.17.0.1  │
   └─────────────┘     └─────────────┘

2. host - Container shares host's network
   ┌─────────────┐
   │ Container   │────▶ Internet (directly)
   │ (no IP)     │
   └─────────────┘
   Faster, but less isolated

3. none - No network access
   ┌─────────────┐
   │ Container   │  ✗  No internet
   └─────────────┘
   Most secure for YOLO mode!
```

**For Claude Code:**

- Use **bridge** with firewall → Only allow api.anthropic.com
- Or use **none** → No internet at all (air-gapped)

#### 7. Installing Docker (Mac)

**Option 1: Docker Desktop (Easiest)**

```bash
# Install via Homebrew
brew install --cask docker

# Or download from: https://www.docker.com/products/docker-desktop/
```

**What you get:**

- ✅ GUI app with whale icon in menu bar
- ✅ `docker` command in terminal
- ✅ Visual container management
- ✅ Resource limits (CPU/RAM) control

**Option 2: Colima (Lightweight alternative)**

```bash
# For users who want CLI-only (no GUI)
brew install colima docker

# Start Docker
colima start
```

**Test installation:**

```bash
docker --version
# Output: Docker version 24.0.7, build afdd53b

docker run hello-world
# Downloads and runs test container
```

#### 8. Docker Compose (Advanced - For Later)

**Docker Compose** = Run multiple containers together with one command

**Example:** Claude Code + PostgreSQL + Redis

```yaml
# docker-compose.yml
services:
  claude:
    image: docker/sandbox-templates:claude-code
    volumes:
      - ./project:/workspace

  database:
    image: postgres:15

  cache:
    image: redis:7
```

```bash
# Start all containers
docker compose up

# Stop all containers
docker compose down
```

**Not needed for basic Claude Code usage**, but useful for complex projects.

---

## Part 2: CC Sand Command Design

### Overview

**Name:** `cc sand` (or `cc sandbox`)
**Purpose:** Launch Claude Code in isolated Docker sandbox for safe YOLO mode
**Philosophy:** Make containers **as easy as** `cc yolo` but **safer**

### Command Structure

```bash
# Basic usage
cc sand              # Launch HERE in sandbox
cc sand pick         # Pick project → sandbox
cc sand <project>    # Direct jump → sandbox

# With modes (same as existing cc dispatcher)
cc sand yolo         # Sandbox + skip permissions (safest YOLO)
cc sand plan         # Sandbox + plan mode
cc sand opus         # Sandbox + Opus model

# Quick variants
cc s                 # Short alias for cc sand
cc sy                # cc sand yolo (ultra-short)
ccs                  # Global alias (like ccw, ccwy)
ccsy                 # Global alias for sand yolo
```

### How It Fits with Current CC Dispatcher

#### Current Structure (From Analysis)

```
cc dispatcher has:
├── Default (no args) → claude --permission-mode acceptEdits
├── pick → Project picker + Claude
├── <project> → Direct jump + Claude
├── Modes:
│   ├── yolo → --dangerously-skip-permissions
│   ├── plan → --permission-mode plan
│   ├── opus → --model opus
│   └── haiku → --model haiku
├── Session:
│   ├── resume → claude -r
│   └── continue → claude -c
├── Quick actions:
│   ├── ask → claude -p
│   ├── file → analyze file
│   └── diff → review changes
└── Worktree:
    └── wt → Worktree integration
```

#### Proposed Addition: Sandbox (sand)

```
cc dispatcher will have:
├── ... (all existing commands) ...
└── Sandbox (NEW):
    ├── sand → Launch in Docker sandbox
    ├── sand pick → Picker + sandbox
    ├── sand <project> → Direct jump + sandbox
    ├── sand yolo → Sandbox + YOLO mode
    ├── sand plan → Sandbox + plan mode
    ├── sand opus → Sandbox + Opus model
    └── sand status → Show running sandboxes
```

**Design Principle:** Mirror existing `yolo`, `plan`, `opus` patterns but in sandbox

### Implementation Design

#### Option A: Docker Sandbox (Official Image)

**Pros:**

- ✅ Official Anthropic support
- ✅ Auto credential management (persisted volume)
- ✅ Pre-installed tools (Git, Node.js, Python, etc.)
- ✅ Simple command: `docker sandbox run`

**Cons:**

- ⚠️ Requires Docker Desktop or Colima
- ⚠️ Less control over environment

**Implementation:**

```bash
_cc_sandbox() {
    local project_dir="${1:-$PWD}"
    local mode_args=""
    local docker_cmd="docker sandbox run"

    # Build Docker command
    local full_cmd="$docker_cmd docker/sandbox-templates:claude-code"

    # Add volume mount
    full_cmd="$full_cmd -v $project_dir:/workspace"

    # Add mode args
    case "$mode" in
        yolo)
            mode_args="--dangerously-skip-permissions"
            ;;
        plan)
            mode_args="--permission-mode plan"
            ;;
        opus)
            mode_args="--model opus --permission-mode acceptEdits"
            ;;
    esac

    # Run
    echo "🐳 Launching Claude Code sandbox..."
    eval "$full_cmd -- claude $mode_args"
}
```

#### Option B: DevContainer CLI

**Pros:**

- ✅ Integrates with VS Code Dev Containers
- ✅ Supports `.devcontainer/devcontainer.json` config
- ✅ More customizable (firewall rules, etc.)

**Cons:**

- ⚠️ Slower startup (builds container first time)
- ⚠️ Requires devcontainer CLI install

**Implementation:**

```bash
_cc_sandbox_devcontainer() {
    local project_dir="${1:-$PWD}"

    # Check for .devcontainer
    if [[ ! -d "$project_dir/.devcontainer" ]]; then
        echo "📦 No .devcontainer found. Create one?"
        # ... create default devcontainer.json
    fi

    # Start devcontainer
    devcontainer up --workspace-folder "$project_dir"

    # Run Claude inside
    devcontainer exec --workspace-folder "$project_dir" \
        claude --dangerously-skip-permissions
}
```

#### Option C: Custom Docker Run

**Pros:**

- ✅ Full control over everything
- ✅ Lightweight (no extra tools)
- ✅ Can customize image, network, volumes

**Cons:**

- ⚠️ More complex setup
- ⚠️ Manual credential management

**Implementation:**

```bash
_cc_sandbox_custom() {
    local project_dir="${1:-$PWD}"

    # Run custom Docker container
    docker run --rm -it \
        -v "$project_dir:/workspace" \
        -v ~/.anthropic:/root/.anthropic \
        --network none \
        my-claude-image \
        claude --dangerously-skip-permissions
}
```

### Recommended Approach: Hybrid (A + C)

**Default:** Use Docker Sandbox (Option A) for ease of use
**Advanced:** Support custom config via `.cc-sandbox.json` (Option C)

**Why hybrid?**

- ✅ **Beginners** get instant setup (Docker Sandbox)
- ✅ **Advanced users** get customization (custom config)
- ✅ **Flow-cli stays simple** (no complex setup required)

### Full Command Spec

#### Basic Commands

```bash
# Launch sandbox
cc sand                         # Current dir
cc sand pick                    # Project picker
cc sand flow                    # Direct jump to flow-cli

# With modes
cc sand yolo                    # YOLO mode (safe in sandbox)
cc sand yolo pick               # Picker + YOLO
cc sand plan                    # Plan mode
cc sand opus                    # Opus model
cc sand haiku                   # Haiku model

# Chaining (like cc wt)
cc sand yolo <project>          # Direct jump + YOLO
cc sand plan pick               # Picker + plan
cc sand opus flow               # flow-cli + Opus
```

#### Management Commands

```bash
# Status
cc sand status                  # List running sandboxes
cc sand ps                      # Alias for status

# Cleanup
cc sand stop <id>               # Stop a sandbox
cc sand clean                   # Remove all stopped sandboxes

# Config
cc sand init                    # Create .cc-sandbox.json
cc sand config                  # Edit config
```

#### Advanced Commands

```bash
# Custom image
cc sand --image my-image        # Use custom Docker image

# Network modes
cc sand --network none          # No internet (air-gapped)
cc sand --network host          # Host network (faster)

# Resource limits
cc sand --memory 4g             # Limit RAM
cc sand --cpus 2                # Limit CPU cores
```

### Configuration File: `.cc-sandbox.json`

**Location:** Project root (optional)

```json
{
  "image": "docker/sandbox-templates:claude-code",
  "network": "bridge",
  "volumes": ["./:/workspace"],
  "environment": {
    "FLOW_DEBUG": "1"
  },
  "ports": [],
  "limits": {
    "memory": "4g",
    "cpus": 2
  },
  "firewall": {
    "allow": ["api.anthropic.com", "github.com", "registry.npmjs.org"],
    "block": ["*"]
  }
}
```

**Benefits:**

- ✅ **Per-project config** (different settings for different projects)
- ✅ **Team sharing** (check into git for consistent environment)
- ✅ **Advanced users** (firewall rules, custom images)
- ✅ **Beginners** (works without config file)

### Integration with Existing CC Dispatcher

#### Code Location

Add to `lib/dispatchers/cc-dispatcher.zsh` after `wt|worktree|w)` case:

```bash
# Around line 246 (after worktree integration)

# Sandbox integration
sand|sandbox|s)
    shift
    _cc_sandbox "$@"
    ;;
```

#### Implementation File Structure

```
lib/dispatchers/
├── cc-dispatcher.zsh           # Main dispatcher (add sand case)
└── cc-sandbox-helpers.zsh      # New file for sandbox functions
```

**cc-sandbox-helpers.zsh:**

```bash
# Sandbox detection
_cc_sandbox_detect() { ... }

# Docker Sandbox launcher
_cc_sandbox_docker() { ... }

# DevContainer launcher
_cc_sandbox_devcontainer() { ... }

# Status/management
_cc_sandbox_status() { ... }
_cc_sandbox_clean() { ... }

# Help
_cc_sandbox_help() { ... }
```

#### Help Text Update

Add to `_cc_help()` function:

```bash
${_C_BLUE}🐳 SANDBOX${_C_NC}:
  ${_C_CYAN}cc sand${_C_NC}            Launch HERE in Docker sandbox
  ${_C_CYAN}cc sand pick${_C_NC}       Pick project → sandbox
  ${_C_CYAN}cc sand yolo${_C_NC}       Sandbox + YOLO mode (safest!)
  ${_C_CYAN}cc sand status${_C_NC}     Show running sandboxes
  ${_C_CYAN}cc sand clean${_C_NC}      Remove stopped sandboxes
```

### User Experience Flow

#### Scenario 1: First-Time User

```bash
User: cc sand

Claude: 🐳 Docker not detected. Install?
[y] Yes - Install Docker Desktop (recommended)
[c] Yes - Install Colima (lightweight CLI)
[n] No - Learn more about Docker

User: y

Claude: Opening Docker Desktop download page...
        After installing, run: cc sand

User: [installs Docker, then...]
      cc sand

Claude: 🐳 Pulling docker/sandbox-templates:claude-code...
        ████████████████████████████████ 100%
        ✅ Image downloaded
        🚀 Launching Claude Code in sandbox...
        📂 Workspace: /Users/dt/projects/dev-tools/flow-cli

[Claude Code starts in sandbox]
```

#### Scenario 2: Regular Use

```bash
User: cc sand yolo pick

Claude: [Shows project picker]

User: [Selects "flow-cli"]

Claude: 🐳 Launching sandbox for flow-cli...
        🚀 Mode: YOLO (skip permissions)
        📂 Workspace: /workspace
        ⚡ Ready in 3s

[Claude Code starts with YOLO mode in sandbox]
```

#### Scenario 3: Advanced User

```bash
User: [Creates .cc-sandbox.json with custom config]

User: cc sand yolo

Claude: 🐳 Using config: .cc-sandbox.json
        📋 Image: my-custom-claude-image
        🔒 Network: none (air-gapped)
        🔥 Firewall: Allowing api.anthropic.com only
        🚀 Launching...

[Claude Code starts with custom config]
```

---

## Part 3: Comparison Matrix

### Current vs Proposed

| Feature         | `cc yolo`             | `cc sand yolo`             |
| --------------- | --------------------- | -------------------------- |
| **Speed**       | ⚡ Instant            | 🐢 5s startup              |
| **Safety**      | ❌ Full host access   | ✅ Container isolated      |
| **Permissions** | All bypassed          | All bypassed (safe!)       |
| **Network**     | Full internet         | Configurable/blocked       |
| **File access** | Entire computer       | Workspace only             |
| **Cleanup**     | ⚠️ Manual (git reset) | ✅ Auto (delete container) |
| **Best for**    | Trusted tasks         | Experiments, automation    |

### All CC Modes Comparison

| Mode           | Permission Model      | Safety    | Speed      | Use Case            |
| -------------- | --------------------- | --------- | ---------- | ------------------- |
| `cc`           | acceptEdits           | 🟡 Medium | ⚡ Instant | Interactive editing |
| `cc yolo`      | Skip all              | 🔴 Low    | ⚡ Instant | Trusted refactoring |
| `cc plan`      | Plan mode             | 🟢 High   | ⚡ Instant | Planning sessions   |
| `cc sand`      | acceptEdits (sandbox) | 🟢 High   | 🐢 5s      | Safe experiments    |
| `cc sand yolo` | Skip all (sandbox)    | 🟢 High   | 🐢 5s      | **Safest YOLO**     |

### vs Other Tools

| Tool                     | What It Does               | vs cc sand                       |
| ------------------------ | -------------------------- | -------------------------------- |
| **VS Code DevContainer** | Opens project in container | `cc sand` = CLI equivalent       |
| **Docker Desktop**       | GUI for containers         | `cc sand` = Terminal shortcut    |
| **devcontainer CLI**     | Command-line DevContainer  | `cc sand` = Simpler wrapper      |
| **docker run**           | Raw Docker command         | `cc sand` = ADHD-friendly preset |

---

## Part 4: Quick Wins

### Phase 1: Minimal Viable Sandbox (< 2 hours)

1. ⚡ **Add `sand` case** to cc-dispatcher.zsh
   - Copy `yolo` case, wrap in Docker command
   - Test: `cc sand` launches Docker Sandbox

2. ⚡ **Add help text** to `_cc_help()`
   - Add "🐳 SANDBOX" section
   - Document basic commands

3. ⚡ **Create global alias**
   - Add `alias ccs='cc sand'`
   - Add `alias ccsy='cc sand yolo'`

**Result:** Working `cc sand` with Docker Sandbox in 2 hours

### Phase 2: Polish (< 1 hour)

1. 🔧 **Add `cc sand status`** - List running sandboxes
2. 🔧 **Add `cc sand clean`** - Remove stopped containers
3. 🔧 **Add `cc sand pick`** - Project picker integration
4. 🔧 **Add mode chaining** - `cc sand yolo pick`, etc.

**Result:** Full-featured sandbox dispatcher

### Phase 3: Advanced (Future)

1. 🏗️ **Add `.cc-sandbox.json`** support - Custom configs
2. 🏗️ **Add firewall rules** - Network isolation
3. 🏗️ **Add MCP integration** - Run MCP servers in sandbox
4. 🏗️ **Add resource limits** - Memory/CPU controls

---

## Part 5: Docker Education Resources

### Recommended Learning Path

#### Week 1: Basics (1 hour total)

- [ ] Install Docker Desktop
- [ ] Run `docker run hello-world`
- [ ] Try `docker run -it ubuntu bash` (interactive container)
- [ ] Read: [Docker 101 Tutorial](https://www.docker.com/101-tutorial)

#### Week 2: Images & Containers (2 hours total)

- [ ] Pull an image: `docker pull nginx`
- [ ] Run a web server: `docker run -p 8080:80 nginx`
- [ ] Visit http://localhost:8080 in browser
- [ ] Read: [Docker Getting Started](https://docs.docker.com/get-started/)

#### Week 3: Volumes & Networks (2 hours total)

- [ ] Mount a volume: `docker run -v ~/test:/data ubuntu ls /data`
- [ ] Try different network modes
- [ ] Read: [Docker Volumes](https://docs.docker.com/storage/volumes/)

#### Week 4: Real Usage (Ongoing)

- [ ] Use `cc sand` for Claude Code experiments
- [ ] Try DevContainers in VS Code
- [ ] Explore Docker Compose

### Key Resources

| Resource                                                                  | What It Is       | When to Use                 |
| ------------------------------------------------------------------------- | ---------------- | --------------------------- |
| [Docker Docs](https://docs.docker.com/)                                   | Official docs    | Reference                   |
| [Docker Hub](https://hub.docker.com/)                                     | Image repository | Find images                 |
| [Play with Docker](https://labs.play-with-docker.com/)                    | Browser sandbox  | Practice without installing |
| [Docker Cheat Sheet](https://dockerlabs.collabnix.com/docker/cheatsheet/) | Quick reference  | Daily use                   |

### Common Docker Pitfalls (ADHD-Friendly Warnings)

| Mistake                           | What Happens                       | Fix                              |
| --------------------------------- | ---------------------------------- | -------------------------------- |
| **Forgetting to stop containers** | Uses RAM even when idle            | `docker stop $(docker ps -q)`    |
| **Not removing old containers**   | Fills disk space                   | `docker system prune`            |
| **Using `:latest` tag**           | Unpredictable updates              | Use specific version (`:v1.2.3`) |
| **No volume mounts**              | Lose all work when container stops | Always use `-v` flag             |
| **Exposing all ports**            | Security risk                      | Only `-p` ports you need         |

---

## Part 6: Recommended Path

### For You (DT)

**Immediate (Today):**

1. ⚡ **Install Docker Desktop** (if not already)

   ```bash
   brew install --cask docker
   ```

2. ⚡ **Test Docker Sandbox** (5 min)

   ```bash
   docker sandbox run docker/sandbox-templates:claude-code
   ```

3. ⚡ **Try with flow-cli** (10 min)
   ```bash
   cd ~/projects/dev-tools/flow-cli
   docker sandbox run docker/sandbox-templates:claude-code \
     -v $PWD:/workspace \
     -- claude --dangerously-skip-permissions
   ```

**This Week:**

1. 🔧 **Implement `cc sand` basic** (Phase 1 - 2 hours)
2. 🔧 **Test with real refactoring task** (safe YOLO mode)
3. 🔧 **Document in YOLO-MODE-WORKFLOW.md** (add Container section)

**Next Week:**

1. 🏗️ **Add `cc sand pick`** and mode chaining
2. 🏗️ **Create `.devcontainer/` for flow-cli** (optional)
3. 🏗️ **Update CC-DISPATCHER-REFERENCE.md** docs

### For Flow-CLI Users

**Beginner Track:**

1. Install Docker Desktop
2. Run `cc sand` (auto-setup)
3. Try safe YOLO mode experiments

**Advanced Track:**

1. Create custom `.cc-sandbox.json`
2. Configure firewall rules
3. Run MCP servers in sandbox

---

## Part 7: Open Questions

1. **Default network mode?**
   - Option A: `bridge` (internet access) - More flexible
   - Option B: `none` (no internet) - More secure
   - **Recommendation:** `bridge` with firewall (best of both)

2. **Credential management?**
   - Option A: Auto-mount `~/.anthropic/` - Convenient
   - Option B: Docker volume (like Docker Sandbox) - More isolated
   - **Recommendation:** Docker volume (Docker Sandbox approach)

3. **Project detection?**
   - Mount entire project or just workspace?
   - **Recommendation:** Mount project root (same as current dir)

4. **Cleanup strategy?**
   - Auto-remove containers on exit (`--rm` flag)?
   - Keep for debugging?
   - **Recommendation:** `--rm` by default, `--keep` flag for debugging

5. **Error handling?**
   - What if Docker not installed?
   - What if image pull fails?
   - **Recommendation:** Friendly error with install instructions

---

## Part 8: Implementation Checklist

### Phase 1: Minimal Viable Sandbox (2 hours)

- [ ] Add `sand|sandbox|s)` case to cc-dispatcher.zsh
- [ ] Implement `_cc_sandbox()` function (basic)
- [ ] Add Docker detection + error message
- [ ] Test: `cc sand` launches Docker Sandbox
- [ ] Add help text to `_cc_help()`
- [ ] Create aliases: `ccs`, `ccsy`
- [ ] Test with flow-cli project

### Phase 2: Mode Integration (1 hour)

- [ ] Add `cc sand yolo` support
- [ ] Add `cc sand plan` support
- [ ] Add `cc sand opus` support
- [ ] Add `cc sand pick` support
- [ ] Test all mode combinations

### Phase 3: Management Commands (1 hour)

- [ ] Implement `cc sand status` (list containers)
- [ ] Implement `cc sand clean` (remove stopped)
- [ ] Implement `cc sand stop <id>` (stop container)
- [ ] Add to help text

### Phase 4: Documentation (1 hour)

- [ ] Update YOLO-MODE-WORKFLOW.md (Method 3: Container)
- [ ] Update CC-DISPATCHER-REFERENCE.md (Sandbox section)
- [ ] Create docs/guides/DOCKER-BASICS.md (Docker education)
- [ ] Add to README.md feature list

### Phase 5: Advanced Features (Future)

- [ ] Support `.cc-sandbox.json` config
- [ ] Add firewall rule configuration
- [ ] Add resource limits (memory/CPU)
- [ ] Add custom image support
- [ ] MCP server integration in sandbox

---

## Summary

**Docker in 3 Sentences:**

1. Docker packages your code + dependencies into a **container** (like a shipping container)
2. Containers are **isolated** (can't access your computer) and **disposable** (delete and recreate instantly)
3. Use Docker for **safe experiments** with Claude Code YOLO mode - mistakes only affect the container

**CC Sand in 3 Sentences:**

1. `cc sand` launches Claude Code in a **Docker sandbox** for safe YOLO mode
2. Works **exactly like** existing `cc` commands (`cc sand pick`, `cc sand yolo`, etc.)
3. **Safest way** to use `--dangerously-skip-permissions` - all changes isolated to container

**Recommended First Steps:**

1. ⚡ Install Docker Desktop (5 min)
2. ⚡ Test Docker Sandbox with flow-cli (10 min)
3. ⚡ Implement basic `cc sand` (2 hours)

---

**Last Updated:** 2026-01-01
**Status:** Ready for implementation
**Estimated Time:** Phase 1 (2h) + Phase 2 (1h) = 3 hours total

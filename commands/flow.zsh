# commands/flow.zsh - Unified flow CLI namespace
# Single entry point for all flow-cli commands

# ============================================================================
# FLOW - Main Command Dispatcher
# ============================================================================

flow() {
  local cmd="${1:-}"
  shift 2>/dev/null || true

  case "$cmd" in
    # ── Help & Learning ─────────────────────────────────────────────────────
    help|--help|-h|"")
      _flow_help "$@"
      ;;
    learn|tutorial)
      _flow_learn "$@"
      ;;
    version|--version|-v)
      echo "flow-cli v${FLOW_VERSION:-3.0.0}"
      ;;

    # ── Core Workflow ───────────────────────────────────────────────────────
    work)
      work "$@"
      ;;
    pick|pp)
      pick "$@"
      ;;
    dash|dashboard)
      dash "$@"
      ;;
    finish|fin|done)
      finish "$@"
      ;;
    hop)
      hop "$@"
      ;;
    why)
      why "$@"
      ;;

    # ── ADHD Helpers ────────────────────────────────────────────────────────
    start|js)
      js "$@"
      ;;
    stuck)
      stuck "$@"
      ;;
    focus)
      focus "$@"
      ;;
    next)
      next "$@"
      ;;
    break|brk)
      brk "$@"
      ;;

    # ── Capture & Track ─────────────────────────────────────────────────────
    catch)
      catch "$@"
      ;;
    crumb)
      crumb "$@"
      ;;
    inbox)
      inbox "$@"
      ;;
    win)
      win "$@"
      ;;
    status)
      status "$@"
      ;;

    # ── Timer ───────────────────────────────────────────────────────────────
    timer)
      timer "$@"
      ;;
    morning)
      morning "$@"
      ;;

    # ── Context-Aware Actions ───────────────────────────────────────────────
    test|t)
      _flow_action_test "$@"
      ;;
    build|b)
      _flow_action_build "$@"
      ;;
    preview|view|pv)
      _flow_action_preview "$@"
      ;;
    sync)
      _flow_action_sync "$@"
      ;;
    check)
      _flow_action_check "$@"
      ;;
    plan)
      _flow_action_plan "$@"
      ;;
    log)
      _flow_action_log "$@"
      ;;

    # ── Setup & Diagnostics ────────────────────────────────────────────────
    doctor|health)
      doctor "$@"
      ;;

    # ── Unknown ─────────────────────────────────────────────────────────────
    *)
      echo "Unknown command: $cmd"
      echo "Run 'flow help' for available commands"
      return 1
      ;;
  esac
}

# ============================================================================
# HELP SYSTEM
# ============================================================================

_flow_help() {
  local topic="${1:-}"

  if [[ -n "$topic" ]]; then
    # Specific command help
    case "$topic" in
      work|pick|dash|finish|status|timer|tutorial|morning)
        $topic help
        ;;
      test|build|sync|check|plan)
        _flow_action_${topic} --help
        ;;
      doctor|health)
        doctor --help
        ;;
      *)
        echo "No help available for: $topic"
        echo "Try: flow help"
        ;;
    esac
    return
  fi

  cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║  🌊 FLOW - ADHD-Friendly Workflow CLI                                      ║
╚════════════════════════════════════════════════════════════════════════════╝

USAGE: flow <command> [args]

┌─ CORE WORKFLOW ────────────────────────────────────────────────────────────┐
│  work <project>     Start a focused work session                           │
│  pick [category]    Interactive project picker (fzf)                       │
│  dash [scope]       Show project dashboard                                 │
│  finish [note]      End session, optionally commit                         │
│  hop <project>      Quick switch (tmux)                                    │
│  why                Show current context                                   │
└────────────────────────────────────────────────────────────────────────────┘

┌─ ADHD HELPERS ─────────────────────────────────────────────────────────────┐
│  start              Just start - picks a project for you (alias: js)       │
│  stuck              When you're blocked - get unstuck                      │
│  focus <text>       Set your current focus                                 │
│  next               What should I work on?                                 │
│  break [mins]       Take a proper break (default: 5 min)                   │
└────────────────────────────────────────────────────────────────────────────┘

┌─ CAPTURE & TRACK ──────────────────────────────────────────────────────────┐
│  catch <idea>       Quick capture to inbox                                 │
│  crumb <note>       Leave breadcrumb in project                            │
│  inbox              View your inbox                                        │
│  win <text>         Log a win (dopamine boost!)                            │
│  status [action]    View/update .STATUS file                               │
└────────────────────────────────────────────────────────────────────────────┘

┌─ ACTIONS (Context-Aware) ──────────────────────────────────────────────────┐
│  test [args]        Run tests (detects R/Node/Python)                      │
│  build [args]       Build project (Quarto/npm/R CMD)                       │
│  preview            Preview output (opens browser)                         │
│  sync               Smart git sync (pull, push, conflicts)                 │
│  check              Health check (lint, types, etc.)                       │
│  plan               Sprint/project planning                                │
└────────────────────────────────────────────────────────────────────────────┘

┌─ TIMER & ROUTINE ──────────────────────────────────────────────────────────┐
│  timer [mins]       Start focus timer (default: 25)                        │
│  timer status       Check remaining time                                   │
│  timer stop         Cancel timer                                           │
│  morning            Morning startup routine                                │
└────────────────────────────────────────────────────────────────────────────┘

┌─ LEARNING ─────────────────────────────────────────────────────────────────┐
│  learn              Start/resume interactive tutorial                      │
│  learn beginner     Core workflow lessons                                  │
│  learn medium       Productivity tools                                     │
│  learn advanced     Power features                                         │
│  help [command]     Show help (this screen or specific command)            │
└────────────────────────────────────────────────────────────────────────────┘

┌─ SETUP & DIAGNOSTICS ──────────────────────────────────────────────────────┐
│  doctor             Check dependencies & health                            │
│  doctor --fix       Interactive install missing tools                      │
│  doctor --fix -y    Auto-install all missing (no prompts)                  │
│  doctor --ai        AI-assisted troubleshooting (Claude CLI)               │
└────────────────────────────────────────────────────────────────────────────┘

EXAMPLES:
  flow pick dev           # Pick from dev-tools projects
  flow work flow-cli      # Start working on flow-cli
  flow test               # Run tests for current project
  flow sync               # Git pull, push, handle conflicts
  flow finish "done"      # Commit and end session
  flow learn              # Start tutorial

SHORTCUTS: Most commands work directly too:
  pick dev    =  flow pick dev
  work foo    =  flow work foo
  js          =  flow start

VERSION: flow-cli v${FLOW_VERSION:-3.0.0}
EOF
}

# ============================================================================
# LEARNING (Tutorial Integration)
# ============================================================================

_flow_learn() {
  local level="${1:-}"

  case "$level" in
    run)
      # flow learn run <name> - for future named tutorials
      local name="${2:-getting-started}"
      case "$name" in
        getting-started|gs)
          tutorial beginner
          ;;
        productivity|prod)
          tutorial medium
          ;;
        power|advanced)
          tutorial advanced
          ;;
        *)
          echo "Unknown tutorial: $name"
          echo "Available: getting-started, productivity, power"
          ;;
      esac
      ;;
    *)
      # Pass through to tutorial command
      tutorial "$level" "$@"
      ;;
  esac
}

# ============================================================================
# CONTEXT-AWARE ACTIONS
# ============================================================================

# Detect project type
_flow_detect_type() {
  local dir="${1:-$(pwd)}"

  if [[ -f "$dir/DESCRIPTION" ]]; then
    echo "r-package"
  elif [[ -f "$dir/package.json" ]]; then
    echo "node"
  elif [[ -f "$dir/_quarto.yml" ]] || [[ -f "$dir/index.qmd" ]]; then
    echo "quarto"
  elif [[ -f "$dir/pyproject.toml" ]] || [[ -f "$dir/setup.py" ]]; then
    echo "python"
  elif [[ -f "$dir/Cargo.toml" ]]; then
    echo "rust"
  elif [[ -f "$dir/go.mod" ]]; then
    echo "go"
  elif [[ -f "$dir/Makefile" ]]; then
    echo "make"
  else
    echo "unknown"
  fi
}

# ── TEST ────────────────────────────────────────────────────────────────────

_flow_action_test() {
  if [[ "$1" == "--help" || "$1" == "help" ]]; then
    cat << 'EOF'
flow test - Run tests (context-aware)

USAGE: flow test [options]

OPTIONS:
  --watch, -w    Watch mode (rerun on changes)
  --coverage     Run with coverage
  --verbose      Verbose output

Detected test runners by project type:
  R package   → R CMD check / testthat
  Node.js     → npm test
  Python      → pytest
  Rust        → cargo test
  Go          → go test
EOF
    return
  fi

  local type=$(_flow_detect_type)
  local watch=0

  [[ "$1" == "--watch" || "$1" == "-w" ]] && watch=1

  echo "🧪 Running tests (detected: $type)"
  echo ""

  case "$type" in
    r-package)
      if (( watch )); then
        echo "Watch mode not available for R. Running once..."
      fi
      if [[ -d "tests/testthat" ]]; then
        Rscript -e "devtools::test()"
      else
        R CMD check . --no-manual
      fi
      ;;
    node)
      if (( watch )); then
        npm test -- --watch
      else
        npm test
      fi
      ;;
    python)
      if (( watch )); then
        pytest-watch
      else
        pytest
      fi
      ;;
    rust)
      if (( watch )); then
        cargo watch -x test
      else
        cargo test
      fi
      ;;
    go)
      if (( watch )); then
        echo "Watch mode: install 'gow' for Go watch"
        go test ./...
      else
        go test ./...
      fi
      ;;
    quarto)
      echo "Quarto projects: use 'flow check' for validation"
      ;;
    *)
      echo "❌ Unknown project type. No test runner detected."
      echo "   Looked for: package.json, DESCRIPTION, pyproject.toml, Cargo.toml, go.mod"
      return 1
      ;;
  esac
}

# ── BUILD ───────────────────────────────────────────────────────────────────

_flow_action_build() {
  if [[ "$1" == "--help" || "$1" == "help" ]]; then
    cat << 'EOF'
flow build - Build project (context-aware)

USAGE: flow build [options]

Detected build systems:
  Quarto      → quarto render
  R package   → R CMD build / devtools::document
  Node.js     → npm run build
  Python      → python -m build
  Rust        → cargo build
  Go          → go build
EOF
    return
  fi

  local type=$(_flow_detect_type)

  echo "🔨 Building (detected: $type)"
  echo ""

  case "$type" in
    quarto)
      quarto render
      ;;
    r-package)
      Rscript -e "devtools::document(); devtools::build()"
      ;;
    node)
      npm run build
      ;;
    python)
      python -m build
      ;;
    rust)
      cargo build --release
      ;;
    go)
      go build ./...
      ;;
    make)
      make
      ;;
    *)
      echo "❌ Unknown project type. No build system detected."
      return 1
      ;;
  esac
}

# ── PREVIEW ─────────────────────────────────────────────────────────────────

_flow_action_preview() {
  if [[ "$1" == "--help" || "$1" == "help" ]]; then
    cat << 'EOF'
flow preview - Preview project output

USAGE: flow preview

Actions by project type:
  Quarto      → quarto preview (opens browser)
  Node.js     → npm run dev / npm start
  R package   → Opens pkgdown site if available
EOF
    return
  fi

  local type=$(_flow_detect_type)

  echo "👁️ Preview (detected: $type)"
  echo ""

  case "$type" in
    quarto)
      quarto preview
      ;;
    node)
      if grep -q '"dev"' package.json 2>/dev/null; then
        npm run dev
      elif grep -q '"start"' package.json 2>/dev/null; then
        npm start
      else
        echo "No dev or start script found in package.json"
      fi
      ;;
    r-package)
      if [[ -d "docs" ]]; then
        open docs/index.html
      elif [[ -f "_pkgdown.yml" ]]; then
        Rscript -e "pkgdown::build_site(preview = TRUE)"
      else
        echo "No docs/ or _pkgdown.yml found"
      fi
      ;;
    *)
      echo "❌ No preview available for: $type"
      return 1
      ;;
  esac
}

# ── SYNC ────────────────────────────────────────────────────────────────────

_flow_action_sync() {
  if [[ "$1" == "--help" || "$1" == "help" ]]; then
    cat << 'EOF'
flow sync - Smart git sync

USAGE: flow sync [options]

Actions:
  1. Stash any uncommitted changes
  2. Pull with rebase
  3. Push
  4. Pop stash if needed

OPTIONS:
  --force    Force push (use carefully!)
  --dry-run  Show what would happen
EOF
    return
  fi

  echo "🔄 Syncing with remote..."
  echo ""

  # Check if we're in a git repo
  if ! git rev-parse --git-dir &>/dev/null; then
    echo "❌ Not in a git repository"
    return 1
  fi

  local branch=$(git branch --show-current)
  local has_changes=0

  # Check for uncommitted changes
  if ! git diff --quiet || ! git diff --cached --quiet; then
    has_changes=1
    echo "📦 Stashing uncommitted changes..."
    git stash push -m "flow sync auto-stash"
  fi

  # Pull
  echo "⬇️ Pulling from origin/$branch..."
  if ! git pull --rebase origin "$branch"; then
    echo "❌ Pull failed. Resolve conflicts and try again."
    if (( has_changes )); then
      echo "   Your changes are in the stash. Run: git stash pop"
    fi
    return 1
  fi

  # Push
  echo "⬆️ Pushing to origin/$branch..."
  if ! git push origin "$branch"; then
    echo "❌ Push failed."
    return 1
  fi

  # Restore stash
  if (( has_changes )); then
    echo "📦 Restoring stashed changes..."
    git stash pop
  fi

  echo ""
  echo "✅ Sync complete!"
}

# ── CHECK ───────────────────────────────────────────────────────────────────

_flow_action_check() {
  if [[ "$1" == "--help" || "$1" == "help" ]]; then
    cat << 'EOF'
flow check - Project health check

USAGE: flow check

Runs appropriate linting/checking:
  R package   → R CMD check
  Node.js     → npm run lint / eslint
  Python      → ruff / flake8 / mypy
  Quarto      → quarto check
  Rust        → cargo clippy
  Go          → go vet
EOF
    return
  fi

  local type=$(_flow_detect_type)

  echo "🔍 Health check (detected: $type)"
  echo ""

  case "$type" in
    r-package)
      R CMD check . --no-manual --no-examples
      ;;
    node)
      if grep -q '"lint"' package.json 2>/dev/null; then
        npm run lint
      elif command -v eslint &>/dev/null; then
        eslint .
      else
        echo "No linter configured"
      fi
      ;;
    python)
      if command -v ruff &>/dev/null; then
        ruff check .
      elif command -v flake8 &>/dev/null; then
        flake8
      fi
      if command -v mypy &>/dev/null; then
        mypy .
      fi
      ;;
    quarto)
      quarto check
      ;;
    rust)
      cargo clippy
      ;;
    go)
      go vet ./...
      ;;
    *)
      echo "❌ No check available for: $type"
      return 1
      ;;
  esac
}

# ── PLAN ────────────────────────────────────────────────────────────────────

_flow_action_plan() {
  if [[ "$1" == "--help" || "$1" == "help" ]]; then
    cat << 'EOF'
flow plan - Sprint/project planning

USAGE: flow plan [action]

ACTIONS:
  (none)      Show current plan/TODO
  sprint      Sprint planning view
  roadmap     Show roadmap
  edit        Edit TODO.md or .STATUS
EOF
    return
  fi

  local action="${1:-show}"

  case "$action" in
    show|"")
      # Show TODO or .STATUS
      if [[ -f "TODO.md" ]]; then
        echo "📋 TODO.md:"
        echo ""
        cat TODO.md
      elif [[ -f ".STATUS" ]]; then
        echo "📋 .STATUS:"
        echo ""
        cat .STATUS
      else
        echo "No TODO.md or .STATUS found"
      fi
      ;;
    sprint)
      echo "🏃 Sprint Planning"
      echo ""
      # Show active items from .STATUS files
      dash
      ;;
    edit)
      if [[ -f "TODO.md" ]]; then
        ${EDITOR:-vim} TODO.md
      elif [[ -f ".STATUS" ]]; then
        ${EDITOR:-vim} .STATUS
      else
        echo "Creating TODO.md..."
        echo "# TODO\n\n## Current Sprint\n\n- [ ] " > TODO.md
        ${EDITOR:-vim} TODO.md
      fi
      ;;
    *)
      echo "Unknown plan action: $action"
      ;;
  esac
}

# ── LOG ─────────────────────────────────────────────────────────────────────

_flow_action_log() {
  if [[ "$1" == "--help" || "$1" == "help" ]]; then
    cat << 'EOF'
flow log - Activity log

USAGE: flow log [action]

ACTIONS:
  (none)      Show recent activity
  today       Today's activity
  week        This week's activity
EOF
    return
  fi

  local period="${1:-recent}"

  echo "📜 Activity Log ($period)"
  echo ""

  case "$period" in
    today)
      git log --oneline --since="midnight" --author="$(git config user.email)"
      ;;
    week)
      git log --oneline --since="1 week ago" --author="$(git config user.email)"
      ;;
    recent|*)
      git log --oneline -20
      ;;
  esac
}

# ============================================================================
# SHORT ALIAS
# ============================================================================

# Removed 'f' alias - use full 'flow' command (single-letter aliases removed per user preference)

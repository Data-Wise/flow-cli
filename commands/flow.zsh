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

  # Colors (use flow-cli colors if available)
  local _C_BOLD="${_C_BOLD:-\033[1m}"
  local _C_NC="${_C_NC:-\033[0m}"
  local _C_GREEN="${_C_GREEN:-\033[0;32m}"
  local _C_CYAN="${_C_CYAN:-\033[0;36m}"
  local _C_BLUE="${_C_BLUE:-\033[0;34m}"
  local _C_YELLOW="${_C_YELLOW:-\033[0;33m}"
  local _C_DIM="${_C_DIM:-\033[2m}"

  echo -e "
${_C_BOLD}╭─────────────────────────────────────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ 🌊 FLOW - ADHD-Friendly Workflow CLI                                        │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────────────────────────────────────╯${_C_NC}

${_C_BOLD}Usage:${_C_NC} flow <command> [args]

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}work <project>${_C_NC}     Start focused work session
  ${_C_CYAN}pick [category]${_C_NC}    Interactive project picker (fzf)
  ${_C_CYAN}js${_C_NC}                 Just start - picks a project for you
  ${_C_CYAN}dash${_C_NC}               Show project dashboard
  ${_C_CYAN}doctor${_C_NC}             Check dependencies & health

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} flow work flow-cli        ${_C_DIM}# Start working on project${_C_NC}
  ${_C_DIM}\$${_C_NC} flow pick dev             ${_C_DIM}# Pick from dev-tools${_C_NC}
  ${_C_DIM}\$${_C_NC} flow test                 ${_C_DIM}# Run tests (auto-detects type)${_C_NC}
  ${_C_DIM}\$${_C_NC} flow finish \"done\"        ${_C_DIM}# Commit and end session${_C_NC}
  ${_C_DIM}\$${_C_NC} flow doctor --fix         ${_C_DIM}# Install missing tools${_C_NC}

${_C_BLUE}📋 CORE WORKFLOW${_C_NC}:
  ${_C_CYAN}work${_C_NC} <project>     Start a focused work session
  ${_C_CYAN}pick${_C_NC} [category]    Interactive project picker (fzf)
  ${_C_CYAN}dash${_C_NC} [scope]       Show project dashboard
  ${_C_CYAN}finish${_C_NC} [note]      End session, optionally commit
  ${_C_CYAN}hop${_C_NC} <project>      Quick switch (tmux)
  ${_C_CYAN}why${_C_NC}                Show current context

${_C_BLUE}🧠 ADHD HELPERS${_C_NC}:
  ${_C_CYAN}start${_C_NC}, ${_C_CYAN}js${_C_NC}         Just start - picks a project for you
  ${_C_CYAN}stuck${_C_NC}              When you're blocked - get unstuck
  ${_C_CYAN}focus${_C_NC} <text>       Set your current focus
  ${_C_CYAN}next${_C_NC}               What should I work on?
  ${_C_CYAN}break${_C_NC} [mins]       Take a proper break (default: 5 min)

${_C_BLUE}📝 CAPTURE & TRACK${_C_NC}:
  ${_C_CYAN}catch${_C_NC} <idea>       Quick capture to inbox
  ${_C_CYAN}crumb${_C_NC} <note>       Leave breadcrumb in project
  ${_C_CYAN}inbox${_C_NC}              View your inbox
  ${_C_CYAN}win${_C_NC} <text>         Log a win (dopamine boost!)
  ${_C_CYAN}status${_C_NC} [action]    View/update .STATUS file

${_C_BLUE}⚡ ACTIONS${_C_NC} ${_C_DIM}(Context-Aware)${_C_NC}:
  ${_C_CYAN}test${_C_NC} [args]        Run tests (detects R/Node/Python)
  ${_C_CYAN}build${_C_NC} [args]       Build project (Quarto/npm/R CMD)
  ${_C_CYAN}preview${_C_NC}            Preview output (opens browser)
  ${_C_CYAN}sync${_C_NC}               Smart git sync (pull, push, conflicts)
  ${_C_CYAN}check${_C_NC}              Health check (lint, types, etc.)
  ${_C_CYAN}plan${_C_NC}               Sprint/project planning

${_C_BLUE}⏱️ TIMER & ROUTINE${_C_NC}:
  ${_C_CYAN}timer${_C_NC} [mins]       Start focus timer (default: 25)
  ${_C_CYAN}timer status${_C_NC}       Check remaining time
  ${_C_CYAN}timer stop${_C_NC}         Cancel timer
  ${_C_CYAN}morning${_C_NC}            Morning startup routine

${_C_BLUE}📚 LEARNING${_C_NC}:
  ${_C_CYAN}learn${_C_NC}              Start/resume interactive tutorial
  ${_C_CYAN}learn beginner${_C_NC}     Core workflow lessons
  ${_C_CYAN}learn medium${_C_NC}       Productivity tools
  ${_C_CYAN}learn advanced${_C_NC}     Power features
  ${_C_CYAN}help${_C_NC} [command]     Show help (this or specific command)

${_C_BLUE}🔧 SETUP & DIAGNOSTICS${_C_NC}:
  ${_C_CYAN}doctor${_C_NC}             Check dependencies & health
  ${_C_CYAN}doctor --fix${_C_NC}       Interactive install missing tools
  ${_C_CYAN}doctor --fix -y${_C_NC}    Auto-install all (no prompts)
  ${_C_CYAN}doctor --ai${_C_NC}        AI-assisted troubleshooting (Claude CLI)

${_C_DIM}SHORTCUTS: Most commands work directly too:${_C_NC}
  pick dev    =  flow pick dev
  work foo    =  flow work foo
  js          =  flow start

${_C_DIM}See also:${_C_NC} man flow, r help, g help, qu help, mcp help, obs help

${_C_BOLD}Version:${_C_NC} flow-cli v\${FLOW_VERSION:-3.1.0}
"
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

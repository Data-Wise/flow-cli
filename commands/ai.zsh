# commands/ai.zsh - AI-powered assistance via Claude CLI
# Uses claude -p for one-shot AI responses

# ============================================================================
# FLOW AI COMMAND
# ============================================================================

flow_ai() {
  local mode="default"
  local context_enabled=false
  local verbose=false
  local query=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --context|-c)    context_enabled=true; shift ;;
      --explain|-e)    mode="explain"; shift ;;
      --fix|-f)        mode="fix"; shift ;;
      --suggest|-s)    mode="suggest"; shift ;;
      --create)        mode="create"; shift ;;
      --verbose|-v)    verbose=true; shift ;;
      --help|-h)       _flow_ai_help; return 0 ;;
      -*)              echo "Unknown option: $1"; return 1 ;;
      *)               query="$query $1"; shift ;;
    esac
  done

  # Trim leading space
  query="${query# }"

  # Check if Claude CLI is available
  if ! command -v claude >/dev/null 2>&1; then
    echo ""
    echo "${FLOW_COLORS[error]}Claude CLI not found${FLOW_COLORS[reset]}"
    echo ""
    echo "Install it with:"
    echo "  ${FLOW_COLORS[accent]}npm install -g @anthropic-ai/claude-code${FLOW_COLORS[reset]}"
    echo ""
    return 1
  fi

  # If no query, show help
  if [[ -z "$query" ]]; then
    _flow_ai_help
    return 0
  fi

  # Build the prompt based on mode
  local full_prompt=""
  local system_context=""

  # Add context if enabled
  if $context_enabled; then
    system_context=$(_flow_ai_build_context)
  fi

  case "$mode" in
    explain)
      full_prompt="Explain this clearly and concisely for a developer: $query"
      ;;
    fix)
      full_prompt="I'm having this problem: $query

Please provide:
1. What's likely causing this
2. Step-by-step fix
3. How to prevent it in the future

Be concise and practical."
      ;;
    suggest)
      full_prompt="Suggest the best approach for: $query

Consider:
- Simplicity and maintainability
- ADHD-friendly (low friction, clear steps)
- macOS/ZSH environment

Provide 2-3 options with pros/cons, then recommend one."
      ;;
    create)
      full_prompt="Create this for me: $query

Requirements:
- Follow ZSH best practices
- Include helpful comments
- Make it ADHD-friendly (clear, simple)
- Include usage examples

Provide complete, working code."
      ;;
    *)
      full_prompt="$query"
      ;;
  esac

  # Add context to prompt if available
  if [[ -n "$system_context" ]]; then
    full_prompt="CONTEXT:
$system_context

QUESTION:
$full_prompt"
  fi

  # Show what we're asking (if verbose)
  if $verbose; then
    echo "${FLOW_COLORS[muted]}─────────────────────────────────────────────${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[muted]}Mode: $mode${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[muted]}Context: $context_enabled${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[muted]}─────────────────────────────────────────────${FLOW_COLORS[reset]}"
    echo ""
  fi

  # Execute Claude CLI
  echo "${FLOW_COLORS[accent]}🤖 Thinking...${FLOW_COLORS[reset]}"
  echo ""

  # Use claude -p for print mode (one-shot, no conversation)
  claude -p "$full_prompt" 2>/dev/null

  local exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    echo ""
    echo "${FLOW_COLORS[error]}Claude CLI returned an error${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[muted]}Try: claude --help${FLOW_COLORS[reset]}"
    return $exit_code
  fi

  echo ""
}

# ============================================================================
# CONTEXT BUILDER
# ============================================================================

_flow_ai_build_context() {
  local ctx=""

  # Current directory
  ctx+="Current directory: $PWD\n"

  # Project type
  local proj_type=$(_flow_detect_type 2>/dev/null || echo "unknown")
  ctx+="Project type: $proj_type\n"

  # Git info
  if git rev-parse --git-dir &>/dev/null; then
    local branch=$(git branch --show-current 2>/dev/null)
    local changed_count=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
    ctx+="Git branch: $branch ($changed_count changed files)\n"
  fi

  # flow-cli version
  ctx+="flow-cli: v${FLOW_VERSION:-unknown}\n"

  # Shell
  ctx+="Shell: $SHELL\n"

  # OS
  ctx+="OS: $(uname -s) $(uname -r)\n"

  # Recent error (if any)
  if [[ -n "$_FLOW_LAST_ERROR" ]]; then
    ctx+="Recent error: $_FLOW_LAST_ERROR\n"
  fi

  # Active session
  if [[ -n "$FLOW_SESSION_PROJECT" ]]; then
    ctx+="Active session: $FLOW_SESSION_PROJECT\n"
  fi

  # Key files present
  local files=""
  [[ -f "DESCRIPTION" ]] && files+="DESCRIPTION "
  [[ -f "package.json" ]] && files+="package.json "
  [[ -f "_quarto.yml" ]] && files+="_quarto.yml "
  [[ -f "pyproject.toml" ]] && files+="pyproject.toml "
  [[ -f "Cargo.toml" ]] && files+="Cargo.toml "
  [[ -f "go.mod" ]] && files+="go.mod "
  [[ -f ".STATUS" ]] && files+=".STATUS "
  [[ -n "$files" ]] && ctx+="Key files: $files\n"

  echo -e "$ctx"
}

# ============================================================================
# SPECIALIZED AI COMMANDS
# ============================================================================

# Quick explain
ai_explain() {
  flow_ai --explain "$@"
}

# Quick fix
ai_fix() {
  flow_ai --fix --context "$@"
}

# Quick suggest
ai_suggest() {
  flow_ai --suggest --context "$@"
}

# ============================================================================
# HELP
# ============================================================================

_flow_ai_help() {
  echo ""
  echo "${FLOW_COLORS[header]}╭─────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🤖 flow ai${FLOW_COLORS[reset]} - AI-Powered Assistant            ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰─────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
  echo "${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
  echo "  flow ai [options] <query>"
  echo ""
  echo "${FLOW_COLORS[bold]}MODES${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[accent]}(default)${FLOW_COLORS[reset]}       Free-form question"
  echo "  ${FLOW_COLORS[accent]}-e, --explain${FLOW_COLORS[reset]}   Explain a concept or tool"
  echo "  ${FLOW_COLORS[accent]}-f, --fix${FLOW_COLORS[reset]}       Help fix a problem"
  echo "  ${FLOW_COLORS[accent]}-s, --suggest${FLOW_COLORS[reset]}   Get recommendations"
  echo "  ${FLOW_COLORS[accent]}--create${FLOW_COLORS[reset]}        Generate code/config"
  echo ""
  echo "${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}"
  echo "  -c, --context  Include project context automatically"
  echo "  -v, --verbose  Show debug info"
  echo "  -h, --help     Show this help"
  echo ""
  echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow ai \"what does fzf do?\""
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow ai --explain \"git rebase vs merge\""
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow ai --fix --context \"tests are failing\""
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow ai --suggest \"tools for R development\""
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow ai --create \"a git pre-commit hook\""
  echo ""
  echo "${FLOW_COLORS[bold]}SHORTCUTS${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[accent]}ai_explain${FLOW_COLORS[reset]} <topic>   Quick explain"
  echo "  ${FLOW_COLORS[accent]}ai_fix${FLOW_COLORS[reset]} <problem>     Quick fix (with context)"
  echo "  ${FLOW_COLORS[accent]}ai_suggest${FLOW_COLORS[reset]} <topic>   Quick suggestion"
  echo ""
  echo "${FLOW_COLORS[muted]}Requires: Claude CLI (npm install -g @anthropic-ai/claude-code)${FLOW_COLORS[reset]}"
  echo ""
}

# ============================================================================
# FLOW DO - Natural Language Command Execution
# ============================================================================

flow_do() {
  local dry_run=false
  local verbose=false
  local request=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run|-n)   dry_run=true; shift ;;
      --verbose|-v)   verbose=true; shift ;;
      --help|-h)      _flow_do_help; return 0 ;;
      -*)             echo "Unknown option: $1"; return 1 ;;
      *)              request="$request $1"; shift ;;
    esac
  done

  request="${request# }"  # Trim leading space

  # Check if Claude CLI is available
  if ! command -v claude >/dev/null 2>&1; then
    echo ""
    echo "${FLOW_COLORS[error]}Claude CLI not found${FLOW_COLORS[reset]}"
    echo ""
    echo "Install it with:"
    echo "  ${FLOW_COLORS[accent]}npm install -g @anthropic-ai/claude-code${FLOW_COLORS[reset]}"
    echo ""
    return 1
  fi

  # If no request, show help
  if [[ -z "$request" ]]; then
    _flow_do_help
    return 0
  fi

  echo ""
  echo "${FLOW_COLORS[header]}╭─────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🪄 flow do${FLOW_COLORS[reset]}                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰─────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
  echo "${FLOW_COLORS[muted]}Request: $request${FLOW_COLORS[reset]}"
  echo ""

  # Build context
  local context=$(_flow_ai_build_context)

  # Build the prompt for Claude to generate commands
  local prompt="You are a shell command translator for flow-cli (a ZSH workflow tool).

USER REQUEST: \"$request\"

CURRENT CONTEXT:
$context

AVAILABLE FLOW-CLI COMMANDS:
- work <project>: Start working on a project
- pick [category]: Interactive project picker (dev, research, teaching, quarto)
- dash: Show project dashboard
- finish [message]: End session, optionally commit
- flow install [--profile <name>]: Install tools (profiles: minimal, developer, researcher)
- flow install <tool>: Install specific tool
- flow upgrade: Update flow-cli
- doctor: Health check
- setup: Interactive setup wizard
- stuck: Get unstuck (--ai for AI help)
- next: What to work on next (--ai for AI suggestion)
- catch <text>: Quick capture to inbox
- focus <text>: Set current focus
- timer [mins]: Start focus timer
- g <cmd>: Git dispatcher (status, push, commit, etc.)
- r <cmd>: R package dispatcher (test, check, doc, etc.)
- qu <cmd>: Quarto dispatcher (preview, render, etc.)

SYSTEM COMMANDS: git, brew, npm, code, open, cd, mkdir, etc.

TASK: Translate the user's request into the appropriate shell command(s).

OUTPUT FORMAT (strict):
1. First line: The exact command(s) to run (can be multiple with &&)
2. Second line: Brief explanation (max 10 words)

RULES:
- Prefer flow-cli commands over raw shell commands when applicable
- Use flow install for installing dev tools
- Keep commands simple and safe
- Never include destructive commands without warning
- If request is ambiguous, ask for clarification

Example output:
flow install --profile developer
Installs all developer tools via Homebrew"

  # Get AI response
  echo "${FLOW_COLORS[accent]}🤖 Translating...${FLOW_COLORS[reset]}"
  echo ""

  local response=$(claude -p "$prompt" 2>/dev/null)

  if [[ -z "$response" ]]; then
    echo "${FLOW_COLORS[error]}No response from Claude${FLOW_COLORS[reset]}"
    return 1
  fi

  # Parse response - first line is command, rest is explanation
  local command=$(echo "$response" | head -1)
  local explanation=$(echo "$response" | tail -n +2 | head -1)

  # Clean up command (remove markdown code blocks if present)
  command=$(echo "$command" | sed 's/^```[a-z]*$//' | sed 's/^```$//' | sed 's/`//g' | tr -d '\n')

  # Safety check
  local dangerous=false
  if [[ "$command" == *"rm -rf"* ]] || \
     [[ "$command" == *"sudo"* ]] || \
     [[ "$command" == *">"* && "$command" == *"/"* ]] || \
     [[ "$command" == *"dd "* ]]; then
    dangerous=true
  fi

  echo "${FLOW_COLORS[bold]}Command:${FLOW_COLORS[reset]}"
  if $dangerous; then
    echo "  ${FLOW_COLORS[error]}⚠️  $command${FLOW_COLORS[reset]}"
    echo ""
    echo "${FLOW_COLORS[warning]}Warning: This command may be destructive${FLOW_COLORS[reset]}"
  else
    echo "  ${FLOW_COLORS[success]}$command${FLOW_COLORS[reset]}"
  fi

  if [[ -n "$explanation" ]]; then
    echo ""
    echo "${FLOW_COLORS[muted]}$explanation${FLOW_COLORS[reset]}"
  fi

  echo ""

  # Dry run mode
  if $dry_run; then
    echo "${FLOW_COLORS[warning]}Dry run - command not executed${FLOW_COLORS[reset]}"
    echo ""
    return 0
  fi

  # Confirm execution
  local confirm_msg="Execute this command?"
  $dangerous && confirm_msg="⚠️  Execute this POTENTIALLY DANGEROUS command?"

  echo -n "${FLOW_COLORS[info]}$confirm_msg${FLOW_COLORS[reset]} [y/N] "
  read -r response
  echo ""

  case "$response" in
    [yY]|[yY][eE][sS])
      echo "${FLOW_COLORS[info]}Running...${FLOW_COLORS[reset]}"
      echo ""
      eval "$command"
      local exit_code=$?
      echo ""
      if [[ $exit_code -eq 0 ]]; then
        echo "${FLOW_COLORS[success]}✓ Done${FLOW_COLORS[reset]}"
      else
        echo "${FLOW_COLORS[error]}✗ Command failed (exit code: $exit_code)${FLOW_COLORS[reset]}"
      fi
      return $exit_code
      ;;
    *)
      echo "${FLOW_COLORS[muted]}Cancelled${FLOW_COLORS[reset]}"
      return 0
      ;;
  esac
}

_flow_do_help() {
  echo ""
  echo "${FLOW_COLORS[header]}╭─────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🪄 flow do${FLOW_COLORS[reset]} - Natural Language Commands       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰─────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
  echo "${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
  echo "  flow do [options] \"<request>\""
  echo ""
  echo "${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}"
  echo "  -n, --dry-run    Show command without executing"
  echo "  -v, --verbose    Show detailed output"
  echo "  -h, --help       Show this help"
  echo ""
  echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow do \"install all the git tools\""
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow do \"set up my R development environment\""
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow do \"start working on flow-cli\""
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow do \"commit my changes with a good message\""
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow do \"show me what needs to be done\""
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow do --dry-run \"update everything\""
  echo ""
  echo "${FLOW_COLORS[bold]}HOW IT WORKS${FLOW_COLORS[reset]}"
  echo "  1. Describe what you want in plain English"
  echo "  2. AI translates to appropriate shell command(s)"
  echo "  3. Review the command before it runs"
  echo "  4. Confirm to execute"
  echo ""
  echo "${FLOW_COLORS[muted]}Requires: Claude CLI (npm install -g @anthropic-ai/claude-code)${FLOW_COLORS[reset]}"
  echo ""
}

# ============================================================================
# ALIASES
# ============================================================================

# Main command alias
alias ai='flow_ai'

# commands/ai.zsh - AI-powered assistance via Claude CLI
# Uses claude -p for one-shot AI responses

# ============================================================================
# FLOW AI COMMAND
# ============================================================================

flow_ai() {
  # Handle subcommands first
  case "$1" in
    recipe)
      shift
      flow_ai_recipe "$@"
      return $?
      ;;
    chat)
      shift
      flow_ai_chat "$@"
      return $?
      ;;
    usage|stats)
      shift
      flow_ai_usage "$@"
      return $?
      ;;
    model)
      shift
      flow_ai_model "$@"
      return $?
      ;;
  esac

  local mode="default"
  local context_enabled=false
  local verbose=false
  local model=""
  local query=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --context|-c)    context_enabled=true; shift ;;
      --explain|-e)    mode="explain"; shift ;;
      --fix|-f)        mode="fix"; shift ;;
      --suggest|-s)    mode="suggest"; shift ;;
      --create)        mode="create"; shift ;;
      --model|-m)      shift; model="$1"; shift ;;
      --verbose|-v)    verbose=true; shift ;;
      --help|-h)       _flow_ai_help; return 0 ;;
      -*)              echo "Unknown option: $1"; return 1 ;;
      *)               query="$query $1"; shift ;;
    esac
  done

  # Get model from config if not specified
  if [[ -z "$model" ]]; then
    model="${FLOW_CONFIG[ai_model]:-sonnet}"
  fi

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
    echo "${FLOW_COLORS[muted]}Model: $model${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[muted]}Context: $context_enabled${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[muted]}─────────────────────────────────────────────${FLOW_COLORS[reset]}"
    echo ""
  fi

  # Execute Claude CLI with timing
  echo "${FLOW_COLORS[accent]}🤖 Thinking ($model)...${FLOW_COLORS[reset]}"
  echo ""

  local start_time=$SECONDS

  # Map short model names to full model identifiers
  local model_flag=""
  case "$model" in
    opus|opus4)     model_flag="--model claude-opus-4-20250514" ;;
    sonnet|sonnet4) model_flag="--model claude-sonnet-4-20250514" ;;
    haiku)          model_flag="--model claude-3-5-haiku-latest" ;;
    *)              model_flag="" ;;  # Use default
  esac

  # Use claude -p for print mode (one-shot, no conversation)
  claude -p "$full_prompt" $model_flag 2>/dev/null

  local exit_code=$?
  local duration=$(( (SECONDS - start_time) * 1000 ))

  # Log usage
  if [[ $exit_code -eq 0 ]]; then
    _flow_ai_log_usage "ai" "$mode" "true" "$duration" 2>/dev/null
  else
    _flow_ai_log_usage "ai" "$mode" "false" "$duration" 2>/dev/null
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
  echo "  flow ai recipe <name> <input>"
  echo "  flow ai chat"
  echo ""
  echo "${FLOW_COLORS[bold]}SUBCOMMANDS${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[accent]}recipe${FLOW_COLORS[reset]}          Reusable AI prompts (10 built-in)"
  echo "  ${FLOW_COLORS[accent]}chat${FLOW_COLORS[reset]}            Interactive conversation mode"
  echo "  ${FLOW_COLORS[accent]}usage${FLOW_COLORS[reset]}           Usage statistics and suggestions"
  echo "  ${FLOW_COLORS[accent]}model${FLOW_COLORS[reset]}           Manage AI models"
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
  echo "  -m, --model    Select model (opus, sonnet, haiku)"
  echo "  -v, --verbose  Show debug info"
  echo "  -h, --help     Show this help"
  echo ""
  echo "${FLOW_COLORS[bold]}RECIPES${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}(flow ai recipe <name> <input>)${FLOW_COLORS[reset]}"
  echo "  review, commit, explain-code, debug, refactor,"
  echo "  test, document, eli5, shell, fix"
  echo ""
  echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow ai \"what does fzf do?\""
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow ai --fix --context \"tests are failing\""
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow ai --model opus \"complex question\""
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow ai recipe review \"my code here\""
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow ai chat --context"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow ai model set haiku"
  echo ""
  echo "${FLOW_COLORS[muted]}Requires: Claude CLI (npm install -g @anthropic-ai/claude-code)${FLOW_COLORS[reset]}"
  echo ""
}

# ============================================================================
# MODEL MANAGEMENT
# ============================================================================

# Available models
typeset -gA FLOW_AI_MODELS=(
  [opus]="claude-opus-4-20250514"
  [opus4]="claude-opus-4-20250514"
  [sonnet]="claude-sonnet-4-20250514"
  [sonnet4]="claude-sonnet-4-20250514"
  [haiku]="claude-3-5-haiku-latest"
)

# Model command handler
flow_ai_model() {
  local action="${1:-show}"
  shift 2>/dev/null

  case "$action" in
    show|current)
      _flow_ai_model_show
      ;;
    list|ls)
      _flow_ai_model_list
      ;;
    set|use)
      _flow_ai_model_set "$@"
      ;;
    help|--help|-h)
      _flow_ai_model_help
      ;;
    *)
      # Assume it's a model name to set
      _flow_ai_model_set "$action"
      ;;
  esac
}

# Show current model
_flow_ai_model_show() {
  local current="${FLOW_CONFIG[ai_model]:-sonnet}"
  echo ""
  echo "${FLOW_COLORS[bold]}Current AI Model:${FLOW_COLORS[reset]} ${FLOW_COLORS[accent]}$current${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[muted]}Full ID: ${FLOW_AI_MODELS[$current]:-unknown}${FLOW_COLORS[reset]}"
  echo ""
}

# List available models
_flow_ai_model_list() {
  local current="${FLOW_CONFIG[ai_model]:-sonnet}"

  echo ""
  echo "${FLOW_COLORS[header]}AVAILABLE MODELS${FLOW_COLORS[reset]}"
  echo ""

  echo "  ${FLOW_COLORS[bold]}Name       Description                          ${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"

  # Opus
  local marker=""
  [[ "$current" == "opus" || "$current" == "opus4" ]] && marker=" ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[accent]}opus${FLOW_COLORS[reset]}       Most capable, deep reasoning$marker"

  # Sonnet
  marker=""
  [[ "$current" == "sonnet" || "$current" == "sonnet4" ]] && marker=" ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[accent]}sonnet${FLOW_COLORS[reset]}     Balanced speed and capability$marker"

  # Haiku
  marker=""
  [[ "$current" == "haiku" ]] && marker=" ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[accent]}haiku${FLOW_COLORS[reset]}      Fast, lightweight responses$marker"

  echo ""
  echo "${FLOW_COLORS[muted]}Set with: flow ai model set <name>${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[muted]}One-off:  flow ai --model <name> \"query\"${FLOW_COLORS[reset]}"
  echo ""
}

# Set model
_flow_ai_model_set() {
  local model="$1"

  if [[ -z "$model" ]]; then
    echo "Usage: flow ai model set <name>"
    echo ""
    echo "Available: opus, sonnet, haiku"
    return 1
  fi

  # Validate model
  if [[ -z "${FLOW_AI_MODELS[$model]+isset}" ]]; then
    _flow_log_error "Unknown model: $model"
    echo ""
    echo "Available models: opus, sonnet, haiku"
    return 1
  fi

  # Update config
  FLOW_CONFIG[ai_model]="$model"
  _flow_config_save

  _flow_log_success "Model set to: $model"
  echo "${FLOW_COLORS[muted]}Full ID: ${FLOW_AI_MODELS[$model]}${FLOW_COLORS[reset]}"
  echo ""
}

# Model help
_flow_ai_model_help() {
  echo ""
  echo "${FLOW_COLORS[header]}╭─────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🤖 flow ai model${FLOW_COLORS[reset]} - Model Management       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰─────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
  echo "${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
  echo "  flow ai model [action]"
  echo ""
  echo "${FLOW_COLORS[bold]}ACTIONS${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[accent]}show${FLOW_COLORS[reset]}          Show current model (default)"
  echo "  ${FLOW_COLORS[accent]}list${FLOW_COLORS[reset]}          List available models"
  echo "  ${FLOW_COLORS[accent]}set <name>${FLOW_COLORS[reset]}    Set default model"
  echo ""
  echo "${FLOW_COLORS[bold]}MODELS${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[accent]}opus${FLOW_COLORS[reset]}          Most capable, deep reasoning"
  echo "  ${FLOW_COLORS[accent]}sonnet${FLOW_COLORS[reset]}        Balanced (default)"
  echo "  ${FLOW_COLORS[accent]}haiku${FLOW_COLORS[reset]}         Fast, lightweight"
  echo ""
  echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow ai model list"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow ai model set opus"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow ai --model haiku \"quick question\""
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

# ============================================================================
# FLOW AI CHAT - Interactive Conversation Mode
# ============================================================================

# Chat session file
FLOW_CHAT_FILE="${FLOW_DATA_DIR}/chat-session.md"

flow_ai_chat() {
  local context_enabled=false
  local verbose=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --context|-c)    context_enabled=true; shift ;;
      --verbose|-v)    verbose=true; shift ;;
      --clear)         _flow_chat_clear; return 0 ;;
      --history)       _flow_chat_history; return 0 ;;
      --help|-h)       _flow_chat_help; return 0 ;;
      -*)              echo "Unknown option: $1"; return 1 ;;
      *)               shift ;;
    esac
  done

  # Check if Claude CLI is available
  if ! command -v claude >/dev/null 2>&1; then
    echo ""
    _flow_log_error "Claude CLI not found"
    echo ""
    echo "Install it with:"
    echo "  ${FLOW_COLORS[accent]}npm install -g @anthropic-ai/claude-code${FLOW_COLORS[reset]}"
    echo ""
    return 1
  fi

  echo ""
  echo "${FLOW_COLORS[header]}╭─────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}💬 flow ai chat${FLOW_COLORS[reset]} - Interactive Session       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰─────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
  echo "${FLOW_COLORS[muted]}Type your message and press Enter. Commands:${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[muted]}  /clear    Clear conversation history${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[muted]}  /history  Show conversation history${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[muted]}  /context  Toggle project context${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[muted]}  /help     Show help${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[muted]}  /exit     Exit chat (or Ctrl+D)${FLOW_COLORS[reset]}"
  echo ""

  if $context_enabled; then
    echo "${FLOW_COLORS[info]}📁 Project context enabled${FLOW_COLORS[reset]}"
    echo ""
  fi

  # Initialize chat session file
  [[ ! -d "${FLOW_DATA_DIR}" ]] && mkdir -p "${FLOW_DATA_DIR}"

  # Load existing conversation or start fresh
  local conversation=""
  if [[ -f "$FLOW_CHAT_FILE" ]]; then
    conversation=$(cat "$FLOW_CHAT_FILE")
    local msg_count=$(grep -c "^## " "$FLOW_CHAT_FILE" 2>/dev/null || echo "0")
    if [[ $msg_count -gt 0 ]]; then
      echo "${FLOW_COLORS[muted]}(Resuming session with $msg_count messages. /clear to start fresh)${FLOW_COLORS[reset]}"
      echo ""
    fi
  fi

  # Chat loop
  while true; do
    # Prompt
    echo -n "${FLOW_COLORS[accent]}You:${FLOW_COLORS[reset]} "
    local user_input
    read -r user_input || { echo ""; break; }  # Handle Ctrl+D

    # Handle commands
    case "$user_input" in
      /exit|/quit|/q)
        echo ""
        echo "${FLOW_COLORS[muted]}Chat session saved. Goodbye!${FLOW_COLORS[reset]}"
        break
        ;;
      /clear)
        _flow_chat_clear
        conversation=""
        echo "${FLOW_COLORS[success]}✓ Conversation cleared${FLOW_COLORS[reset]}"
        echo ""
        continue
        ;;
      /history)
        _flow_chat_history
        continue
        ;;
      /context)
        context_enabled=$(! $context_enabled && echo true || echo false)
        if $context_enabled; then
          echo "${FLOW_COLORS[info]}📁 Project context enabled${FLOW_COLORS[reset]}"
        else
          echo "${FLOW_COLORS[muted]}📁 Project context disabled${FLOW_COLORS[reset]}"
        fi
        echo ""
        continue
        ;;
      /help)
        _flow_chat_help
        continue
        ;;
      "")
        continue
        ;;
    esac

    # Build prompt with conversation history
    local full_prompt=""

    # Add context if enabled
    if $context_enabled; then
      local ctx=$(_flow_ai_build_context)
      full_prompt+="PROJECT CONTEXT:\n$ctx\n\n"
    fi

    # Add conversation history (last 10 exchanges for context window)
    if [[ -n "$conversation" ]]; then
      # Get last 10 exchanges
      local recent=$(echo "$conversation" | tail -40)
      full_prompt+="CONVERSATION HISTORY:\n$recent\n\n"
    fi

    # Add current message
    full_prompt+="USER: $user_input\n\nProvide a helpful, concise response."

    # Save user message to history
    echo "## User" >> "$FLOW_CHAT_FILE"
    echo "$user_input" >> "$FLOW_CHAT_FILE"
    echo "" >> "$FLOW_CHAT_FILE"

    # Get response
    echo ""
    echo "${FLOW_COLORS[accent]}Claude:${FLOW_COLORS[reset]}"

    local response
    response=$(claude -p "$full_prompt" 2>/dev/null)
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
      echo "${FLOW_COLORS[error]}Error getting response${FLOW_COLORS[reset]}"
    else
      echo "$response"

      # Save response to history
      echo "## Claude" >> "$FLOW_CHAT_FILE"
      echo "$response" >> "$FLOW_CHAT_FILE"
      echo "" >> "$FLOW_CHAT_FILE"

      # Update conversation variable
      conversation+="User: $user_input\n\nClaude: $response\n\n"
    fi

    echo ""
  done
}

# Clear chat history
_flow_chat_clear() {
  if [[ -f "$FLOW_CHAT_FILE" ]]; then
    rm "$FLOW_CHAT_FILE"
  fi
}

# Show chat history
_flow_chat_history() {
  echo ""
  if [[ -f "$FLOW_CHAT_FILE" && -s "$FLOW_CHAT_FILE" ]]; then
    echo "${FLOW_COLORS[header]}CHAT HISTORY${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[muted]}─────────────────────────────────────────────${FLOW_COLORS[reset]}"
    cat "$FLOW_CHAT_FILE"
    echo "${FLOW_COLORS[muted]}─────────────────────────────────────────────${FLOW_COLORS[reset]}"
    local msg_count=$(grep -c "^## " "$FLOW_CHAT_FILE" 2>/dev/null || echo "0")
    echo "${FLOW_COLORS[muted]}Total messages: $msg_count${FLOW_COLORS[reset]}"
  else
    echo "${FLOW_COLORS[muted]}No chat history. Start a conversation with: flow ai chat${FLOW_COLORS[reset]}"
  fi
  echo ""
}

# Chat help
_flow_chat_help() {
  echo ""
  echo "${FLOW_COLORS[header]}╭─────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}💬 flow ai chat${FLOW_COLORS[reset]} - Interactive Session       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰─────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
  echo "${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
  echo "  flow ai chat [options]"
  echo ""
  echo "${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}"
  echo "  -c, --context   Enable project context"
  echo "  --clear         Clear conversation history"
  echo "  --history       Show conversation history"
  echo "  -h, --help      Show this help"
  echo ""
  echo "${FLOW_COLORS[bold]}IN-CHAT COMMANDS${FLOW_COLORS[reset]}"
  echo "  /clear          Clear conversation history"
  echo "  /history        Show conversation history"
  echo "  /context        Toggle project context"
  echo "  /help           Show help"
  echo "  /exit           Exit chat (or Ctrl+D)"
  echo ""
  echo "${FLOW_COLORS[bold]}FEATURES${FLOW_COLORS[reset]}"
  echo "  • Persistent conversation history"
  echo "  • Context-aware responses (optional)"
  echo "  • Resume previous conversations"
  echo ""
  echo "${FLOW_COLORS[muted]}History saved to: $FLOW_CHAT_FILE${FLOW_COLORS[reset]}"
  echo ""
}

# lib/ai-recipes.zsh - AI recipe system for flow-cli
# Reusable prompt templates with variables

# ============================================================================
# RECIPE STORAGE
# ============================================================================

# Directory for recipes
FLOW_RECIPE_DIR="${FLOW_CONFIG_DIR}/recipes"

# Built-in recipes (name -> content)
typeset -gA FLOW_BUILTIN_RECIPES=(
  # Code review recipe
  [review]='Review this code for:
1. Potential bugs or issues
2. Performance improvements
3. Code style and best practices
4. Security concerns

Be concise. Prioritize actionable feedback.

CODE:
{{input}}'

  # Commit message recipe
  [commit]='Generate a concise git commit message for these changes:

{{input}}

Requirements:
- Follow conventional commits format (feat:, fix:, docs:, etc.)
- Keep first line under 72 characters
- Be specific about what changed
- Add body if needed for complex changes

Just output the commit message, nothing else.'

  # Explain code recipe
  [explain-code]='Explain this code step by step:

{{input}}

For each section:
1. What it does
2. Why it works
3. Any potential issues

Keep explanations clear and concise.'

  # Debug recipe
  [debug]='Help me debug this issue:

Error/Problem:
{{input}}

Context:
- Project type: {{project_type}}
- Shell: zsh on macOS

Provide:
1. Likely causes
2. Diagnostic steps
3. Potential fixes

Be practical and specific.'

  # Refactor recipe
  [refactor]='Suggest how to refactor this code:

{{input}}

Goals:
- Improve readability
- Reduce complexity
- Follow best practices
- Maintain functionality

Show before/after with explanations.'

  # Test generation recipe
  [test]='Generate tests for this code:

{{input}}

Requirements:
- Cover happy path and edge cases
- Include error scenarios
- Use appropriate testing framework for {{project_type}}
- Keep tests focused and readable'

  # Documentation recipe
  [document]='Generate documentation for this code:

{{input}}

Include:
- Purpose and description
- Parameters/arguments
- Return values
- Usage examples
- Any important notes

Format appropriately for {{project_type}}.'

  # Quick explain recipe
  [eli5]='Explain like I am 5 years old:

{{input}}

Use simple analogies. No jargon.'

  # Shell command recipe
  [shell]='I need a shell command to:

{{input}}

Requirements:
- Use standard Unix/macOS tools
- zsh compatible
- Include brief explanation

Output just the command(s), then explanation.'

  # Fix this recipe
  [fix]='Fix this problem:

{{input}}

Provide the corrected version with explanation.'
)

# ============================================================================
# RECIPE MANAGEMENT
# ============================================================================

# Initialize recipes directory
_flow_recipe_init() {
  [[ ! -d "$FLOW_RECIPE_DIR" ]] && mkdir -p "$FLOW_RECIPE_DIR"
}

# List all available recipes
_flow_recipe_list() {
  echo ""
  echo "${FLOW_COLORS[header]}AVAILABLE AI RECIPES${FLOW_COLORS[reset]}"
  echo ""

  # Built-in recipes
  echo "  ${FLOW_COLORS[bold]}Built-in:${FLOW_COLORS[reset]}"
  local name
  for name in "${(@ko)FLOW_BUILTIN_RECIPES}"; do
    # Get first line as description
    local first_line="${FLOW_BUILTIN_RECIPES[$name]%%$'\n'*}"
    first_line="${first_line:0:50}..."
    printf "    ${FLOW_COLORS[accent]}%-12s${FLOW_COLORS[reset]} %s\n" "$name" "$first_line"
  done
  echo ""

  # User recipes
  if [[ -d "$FLOW_RECIPE_DIR" ]] && [[ -n "$(ls -A "$FLOW_RECIPE_DIR" 2>/dev/null)" ]]; then
    echo "  ${FLOW_COLORS[bold]}User Recipes:${FLOW_COLORS[reset]}"
    for recipe_file in "$FLOW_RECIPE_DIR"/*.recipe(N); do
      local name="${${recipe_file:t}%.recipe}"
      local desc=$(head -1 "$recipe_file" 2>/dev/null | sed 's/^#\s*//')
      printf "    ${FLOW_COLORS[accent]}%-12s${FLOW_COLORS[reset]} %s\n" "$name" "${desc:0:50}"
    done
  else
    echo "  ${FLOW_COLORS[muted]}No user recipes. Create with: flow ai recipe create <name>${FLOW_COLORS[reset]}"
  fi
  echo ""

  echo "  ${FLOW_COLORS[bold]}Usage:${FLOW_COLORS[reset]}"
  echo "    flow ai recipe <name> <input>"
  echo "    flow ai recipe review \"my code here\""
  echo "    flow ai recipe commit \"\$(git diff --staged)\""
  echo ""
}

# Get a recipe by name
# Returns: recipe content or empty string
_flow_recipe_get() {
  local name="$1"

  # Check built-in first
  if [[ -n "${FLOW_BUILTIN_RECIPES[$name]+isset}" ]]; then
    echo "${FLOW_BUILTIN_RECIPES[$name]}"
    return 0
  fi

  # Check user recipes
  local recipe_file="$FLOW_RECIPE_DIR/${name}.recipe"
  if [[ -f "$recipe_file" ]]; then
    cat "$recipe_file"
    return 0
  fi

  return 1
}

# Apply variables to recipe
_flow_recipe_apply() {
  local recipe="$1"
  local input="$2"

  # Replace {{input}} with the provided input
  recipe="${recipe//\{\{input\}\}/$input}"

  # Replace {{project_type}}
  local proj_type=$(_flow_detect_type 2>/dev/null || echo "unknown")
  recipe="${recipe//\{\{project_type\}\}/$proj_type}"

  # Replace {{pwd}}
  recipe="${recipe//\{\{pwd\}\}/$PWD}"

  # Replace {{date}}
  recipe="${recipe//\{\{date\}\}/$(date +%Y-%m-%d)}"

  # Replace {{branch}}
  local branch=$(git branch --show-current 2>/dev/null || echo "none")
  recipe="${recipe//\{\{branch\}\}/$branch}"

  # Replace {{project}}
  local project="${FLOW_SESSION_PROJECT:-${PWD:t}}"
  recipe="${recipe//\{\{project\}\}/$project}"

  echo "$recipe"
}

# Create a new user recipe
_flow_recipe_create() {
  local name="$1"

  if [[ -z "$name" ]]; then
    echo "Usage: flow ai recipe create <name>"
    return 1
  fi

  # Validate name
  if [[ ! "$name" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
    _flow_log_error "Invalid recipe name. Use letters, numbers, hyphens, underscores."
    return 1
  fi

  # Check if built-in
  if [[ -n "${FLOW_BUILTIN_RECIPES[$name]+isset}" ]]; then
    _flow_log_error "Cannot overwrite built-in recipe: $name"
    return 1
  fi

  _flow_recipe_init

  local recipe_file="$FLOW_RECIPE_DIR/${name}.recipe"

  # Create template
  cat > "$recipe_file" <<'EOF'
# My custom recipe - describe what it does
# Variables: {{input}}, {{project_type}}, {{pwd}}, {{date}}, {{branch}}, {{project}}

Your prompt template here.

Use {{input}} where the user's input should go.

Example:
---
Help me with {{input}} for my {{project_type}} project.
---
EOF

  local editor="${EDITOR:-${VISUAL:-vim}}"
  echo "Opening recipe in $editor..."
  "$editor" "$recipe_file"

  if [[ -f "$recipe_file" ]]; then
    _flow_log_success "Created recipe: $name"
    echo "  Location: $recipe_file"
    echo ""
    echo "Usage: flow ai recipe $name <input>"
  fi
}

# Edit an existing recipe
_flow_recipe_edit() {
  local name="$1"

  if [[ -z "$name" ]]; then
    echo "Usage: flow ai recipe edit <name>"
    return 1
  fi

  # Check if built-in
  if [[ -n "${FLOW_BUILTIN_RECIPES[$name]+isset}" ]]; then
    _flow_log_error "Cannot edit built-in recipe: $name"
    echo "To customize, create a user recipe with same name:"
    echo "  flow ai recipe create $name"
    return 1
  fi

  local recipe_file="$FLOW_RECIPE_DIR/${name}.recipe"

  if [[ ! -f "$recipe_file" ]]; then
    _flow_log_error "Recipe not found: $name"
    return 1
  fi

  local editor="${EDITOR:-${VISUAL:-vim}}"
  "$editor" "$recipe_file"
}

# Delete a user recipe
_flow_recipe_delete() {
  local name="$1"

  if [[ -z "$name" ]]; then
    echo "Usage: flow ai recipe delete <name>"
    return 1
  fi

  # Check if built-in
  if [[ -n "${FLOW_BUILTIN_RECIPES[$name]+isset}" ]]; then
    _flow_log_error "Cannot delete built-in recipe: $name"
    return 1
  fi

  local recipe_file="$FLOW_RECIPE_DIR/${name}.recipe"

  if [[ ! -f "$recipe_file" ]]; then
    _flow_log_error "Recipe not found: $name"
    return 1
  fi

  if _flow_confirm "Delete recipe '$name'?"; then
    rm "$recipe_file"
    _flow_log_success "Deleted recipe: $name"
  fi
}

# Show recipe content
_flow_recipe_show() {
  local name="$1"

  if [[ -z "$name" ]]; then
    echo "Usage: flow ai recipe show <name>"
    return 1
  fi

  local recipe=$(_flow_recipe_get "$name")

  if [[ -z "$recipe" ]]; then
    _flow_log_error "Recipe not found: $name"
    return 1
  fi

  echo ""
  echo "${FLOW_COLORS[header]}Recipe: $name${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[muted]}─────────────────────────────────────────────${FLOW_COLORS[reset]}"
  echo "$recipe"
  echo "${FLOW_COLORS[muted]}─────────────────────────────────────────────${FLOW_COLORS[reset]}"
  echo ""
}

# Run a recipe
_flow_recipe_run() {
  local name="$1"
  shift
  local input="$*"

  if [[ -z "$name" ]]; then
    _flow_recipe_list
    return 0
  fi

  # Get recipe
  local recipe=$(_flow_recipe_get "$name")

  if [[ -z "$recipe" ]]; then
    _flow_log_error "Recipe not found: $name"
    echo ""
    echo "Available recipes:"
    echo "  Built-in: ${(k)FLOW_BUILTIN_RECIPES}"
    echo ""
    return 1
  fi

  # If no input provided and not a simple recipe, prompt for it
  if [[ -z "$input" && "$recipe" == *"{{input}}"* ]]; then
    echo -n "Input: "
    read -r input
    if [[ -z "$input" ]]; then
      _flow_log_error "Input required for this recipe"
      return 1
    fi
  fi

  # Apply variables
  local prompt=$(_flow_recipe_apply "$recipe" "$input")

  echo ""
  echo "${FLOW_COLORS[accent]}🧪 Running recipe: $name${FLOW_COLORS[reset]}"
  echo ""

  # Execute via Claude
  if ! command -v claude >/dev/null 2>&1; then
    _flow_log_error "Claude CLI not found"
    echo "Install with: npm install -g @anthropic-ai/claude-code"
    return 1
  fi

  local start_time=$SECONDS
  claude -p "$prompt" 2>/dev/null
  local exit_code=$?
  local duration=$(( (SECONDS - start_time) * 1000 ))

  # Log usage
  if [[ $exit_code -eq 0 ]]; then
    _flow_ai_log_usage "recipe" "recipe:$name" "true" "$duration" 2>/dev/null
  else
    _flow_ai_log_usage "recipe" "recipe:$name" "false" "$duration" 2>/dev/null
  fi

  echo ""
  return $exit_code
}

# ============================================================================
# RECIPE COMMAND HANDLER
# ============================================================================

# Main recipe command handler
flow_ai_recipe() {
  local action="${1:-list}"
  shift 2>/dev/null

  case "$action" in
    list|ls)
      _flow_recipe_list
      ;;
    show|view)
      _flow_recipe_show "$@"
      ;;
    create|new)
      _flow_recipe_create "$@"
      ;;
    edit)
      _flow_recipe_edit "$@"
      ;;
    delete|rm)
      _flow_recipe_delete "$@"
      ;;
    help|--help|-h)
      _flow_recipe_help
      ;;
    *)
      # Assume it's a recipe name
      _flow_recipe_run "$action" "$@"
      ;;
  esac
}

# Help for recipe command
_flow_recipe_help() {
  echo ""
  echo "${FLOW_COLORS[header]}╭─────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🧪 flow ai recipe${FLOW_COLORS[reset]} - Reusable AI Prompts    ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰─────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
  echo "${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
  echo "  flow ai recipe <name> <input>"
  echo "  flow ai recipe <action>"
  echo ""
  echo "${FLOW_COLORS[bold]}ACTIONS${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[accent]}list${FLOW_COLORS[reset]}           Show all available recipes"
  echo "  ${FLOW_COLORS[accent]}show <name>${FLOW_COLORS[reset]}    View recipe content"
  echo "  ${FLOW_COLORS[accent]}create <name>${FLOW_COLORS[reset]}  Create a new recipe"
  echo "  ${FLOW_COLORS[accent]}edit <name>${FLOW_COLORS[reset]}    Edit user recipe"
  echo "  ${FLOW_COLORS[accent]}delete <name>${FLOW_COLORS[reset]}  Delete user recipe"
  echo ""
  echo "${FLOW_COLORS[bold]}BUILT-IN RECIPES${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[accent]}review${FLOW_COLORS[reset]}         Code review"
  echo "  ${FLOW_COLORS[accent]}commit${FLOW_COLORS[reset]}         Generate commit message"
  echo "  ${FLOW_COLORS[accent]}explain-code${FLOW_COLORS[reset]}   Explain code step by step"
  echo "  ${FLOW_COLORS[accent]}debug${FLOW_COLORS[reset]}          Help debug an issue"
  echo "  ${FLOW_COLORS[accent]}refactor${FLOW_COLORS[reset]}       Suggest refactoring"
  echo "  ${FLOW_COLORS[accent]}test${FLOW_COLORS[reset]}           Generate tests"
  echo "  ${FLOW_COLORS[accent]}document${FLOW_COLORS[reset]}       Generate documentation"
  echo "  ${FLOW_COLORS[accent]}eli5${FLOW_COLORS[reset]}           Explain simply"
  echo "  ${FLOW_COLORS[accent]}shell${FLOW_COLORS[reset]}          Generate shell commands"
  echo "  ${FLOW_COLORS[accent]}fix${FLOW_COLORS[reset]}            Fix a problem"
  echo ""
  echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow ai recipe review \"function foo() { ... }\""
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow ai recipe commit \"\$(git diff --staged)\""
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow ai recipe eli5 \"what is a monad\""
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow ai recipe shell \"find large files over 100MB\""
  echo ""
  echo "${FLOW_COLORS[bold]}VARIABLES${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}{{input}}${FLOW_COLORS[reset]}        User-provided input"
  echo "  ${FLOW_COLORS[muted]}{{project_type}}${FLOW_COLORS[reset]} Detected project type"
  echo "  ${FLOW_COLORS[muted]}{{pwd}}${FLOW_COLORS[reset]}          Current directory"
  echo "  ${FLOW_COLORS[muted]}{{date}}${FLOW_COLORS[reset]}         Today's date"
  echo "  ${FLOW_COLORS[muted]}{{branch}}${FLOW_COLORS[reset]}       Current git branch"
  echo "  ${FLOW_COLORS[muted]}{{project}}${FLOW_COLORS[reset]}      Project name"
  echo ""
}

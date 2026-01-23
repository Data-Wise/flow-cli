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

# =============================================================================
# Function: _flow_recipe_init
# Purpose: Initialize the user recipes directory if it doesn't exist
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   None (silent operation)
#
# Example:
#   _flow_recipe_init
#
# Notes:
#   - Creates FLOW_RECIPE_DIR (~/.config/flow/recipes) if missing
#   - Called automatically before recipe operations that need the directory
#   - Safe to call multiple times (idempotent)
# =============================================================================
_flow_recipe_init() {
  [[ ! -d "$FLOW_RECIPE_DIR" ]] && mkdir -p "$FLOW_RECIPE_DIR"
}

# =============================================================================
# Function: _flow_recipe_list
# Purpose: Display all available AI recipes (built-in and user-created)
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Formatted list of recipes with names and descriptions
#            Includes built-in recipes, user recipes, and usage examples
#
# Example:
#   _flow_recipe_list
#
# Notes:
#   - Built-in recipes are defined in FLOW_BUILTIN_RECIPES associative array
#   - User recipes are stored as .recipe files in FLOW_RECIPE_DIR
#   - Descriptions are truncated to 50 characters for display
#   - Called when running "flow ai recipe" or "flow ai recipe list"
# =============================================================================
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

# =============================================================================
# Function: _flow_recipe_get
# Purpose: Retrieve a recipe's content by name from built-in or user storage
# =============================================================================
# Arguments:
#   $1 - (required) Recipe name to retrieve
#
# Returns:
#   0 - Recipe found and output
#   1 - Recipe not found
#
# Output:
#   stdout - Recipe content (prompt template with variables)
#
# Example:
#   local recipe=$(_flow_recipe_get "review")
#   local recipe=$(_flow_recipe_get "my-custom-recipe")
#
# Notes:
#   - Checks built-in recipes first (FLOW_BUILTIN_RECIPES)
#   - Falls back to user recipes in FLOW_RECIPE_DIR/*.recipe
#   - User recipes can override built-in names by creating same-named file
# =============================================================================
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

# =============================================================================
# Function: _flow_recipe_apply
# Purpose: Replace template variables in a recipe with actual values
# =============================================================================
# Arguments:
#   $1 - (required) Recipe content with {{variable}} placeholders
#   $2 - (required) User input to substitute for {{input}}
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Recipe with all variables replaced
#
# Example:
#   local prompt=$(_flow_recipe_apply "$recipe" "my code here")
#
# Notes:
#   - Supported variables:
#     {{input}}        - User-provided input
#     {{project_type}} - Detected project type (r-package, node, etc.)
#     {{pwd}}          - Current working directory
#     {{date}}         - Today's date (YYYY-MM-DD format)
#     {{branch}}       - Current git branch name
#     {{project}}      - Project name from session or directory
#   - Uses ZSH parameter expansion for string replacement
#   - Falls back gracefully if git or project detection fails
# =============================================================================
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

# =============================================================================
# Function: _flow_recipe_create
# Purpose: Create a new user recipe from template and open in editor
# =============================================================================
# Arguments:
#   $1 - (required) Name for the new recipe (alphanumeric, hyphens, underscores)
#
# Returns:
#   0 - Recipe created successfully
#   1 - Invalid name, missing argument, or would overwrite built-in
#
# Output:
#   stdout - Success message with file location and usage instructions
#   stderr - Error messages for invalid input
#
# Example:
#   _flow_recipe_create "my-review"
#   _flow_recipe_create "project-setup"
#
# Notes:
#   - Recipe names must start with a letter and contain only [a-zA-Z0-9_-]
#   - Cannot overwrite built-in recipes (use user recipe to shadow instead)
#   - Opens template in $EDITOR, $VISUAL, or vim as fallback
#   - Template includes documentation of available variables
#   - Recipe saved to FLOW_RECIPE_DIR/<name>.recipe
# =============================================================================
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

# =============================================================================
# Function: _flow_recipe_edit
# Purpose: Open an existing user recipe in the default editor
# =============================================================================
# Arguments:
#   $1 - (required) Name of the user recipe to edit
#
# Returns:
#   0 - Editor opened successfully
#   1 - Recipe not found, is built-in, or missing argument
#
# Output:
#   stderr - Error message if recipe cannot be edited
#
# Example:
#   _flow_recipe_edit "my-review"
#
# Notes:
#   - Cannot edit built-in recipes directly (suggests creating user recipe)
#   - Opens recipe file in $EDITOR, $VISUAL, or vim as fallback
#   - Changes take effect immediately on next recipe use
#   - File location: FLOW_RECIPE_DIR/<name>.recipe
# =============================================================================
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

# =============================================================================
# Function: _flow_recipe_delete
# Purpose: Delete a user-created recipe after confirmation
# =============================================================================
# Arguments:
#   $1 - (required) Name of the user recipe to delete
#
# Returns:
#   0 - Recipe deleted successfully or user declined
#   1 - Recipe not found, is built-in, or missing argument
#
# Output:
#   stdout - Success message on deletion
#   stderr - Error message if recipe cannot be deleted
#
# Example:
#   _flow_recipe_delete "old-recipe"
#
# Notes:
#   - Cannot delete built-in recipes
#   - Prompts for confirmation before deletion
#   - Deletion is permanent (no undo)
#   - Uses _flow_confirm for user interaction
# =============================================================================
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

# =============================================================================
# Function: _flow_recipe_show
# Purpose: Display the full content of a recipe (built-in or user)
# =============================================================================
# Arguments:
#   $1 - (required) Name of the recipe to display
#
# Returns:
#   0 - Recipe displayed successfully
#   1 - Recipe not found or missing argument
#
# Output:
#   stdout - Formatted display of recipe content with header and dividers
#
# Example:
#   _flow_recipe_show "review"
#   _flow_recipe_show "my-custom"
#
# Notes:
#   - Works with both built-in and user recipes
#   - Useful for inspecting recipe content before running
#   - Shows raw template with {{variable}} placeholders visible
#   - Uses FLOW_COLORS for formatted output
# =============================================================================
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

# =============================================================================
# Function: _flow_recipe_run
# Purpose: Execute a recipe by applying variables and sending to Claude CLI
# =============================================================================
# Arguments:
#   $1 - (required) Recipe name to run
#   $@ - (optional) Input text to substitute into {{input}} placeholder
#
# Returns:
#   0 - Recipe executed successfully
#   1 - Recipe not found, Claude CLI missing, or execution failed
#
# Output:
#   stdout - Claude's response to the processed prompt
#   stderr - Error messages for missing dependencies or failed execution
#
# Example:
#   _flow_recipe_run "review" "function foo() { return 42; }"
#   _flow_recipe_run "commit" "$(git diff --staged)"
#   _flow_recipe_run "eli5" "what is a monad"
#
# Notes:
#   - If no name provided, displays recipe list
#   - If recipe requires {{input}} and none provided, prompts interactively
#   - Applies all template variables via _flow_recipe_apply
#   - Requires Claude CLI to be installed (npm install -g @anthropic-ai/claude-code)
#   - Logs usage statistics via _flow_ai_log_usage
#   - Tracks execution duration for performance monitoring
# =============================================================================
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

# =============================================================================
# Function: flow_ai_recipe
# Purpose: Main entry point for recipe command routing and execution
# =============================================================================
# Arguments:
#   $1 - (optional) Action or recipe name [default: list]
#        Actions: list, show, create, edit, delete, help
#        Otherwise treated as recipe name to run
#   $@ - Additional arguments passed to subcommand
#
# Returns:
#   0 - Command executed successfully
#   1 - Error in subcommand execution
#
# Output:
#   Varies by action (see individual function documentation)
#
# Example:
#   flow_ai_recipe                      # List recipes
#   flow_ai_recipe list                 # List recipes
#   flow_ai_recipe show review          # Show review recipe content
#   flow_ai_recipe create my-prompt     # Create new recipe
#   flow_ai_recipe review "my code"     # Run review recipe
#
# Notes:
#   - Aliases: ls (list), view (show), new (create), rm (delete)
#   - Unknown actions are treated as recipe names to run
#   - Primary interface: "flow ai recipe <action|name>"
# =============================================================================
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

# =============================================================================
# Function: _flow_recipe_help
# Purpose: Display comprehensive help for the recipe command system
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Formatted help text including:
#            - Usage syntax
#            - Available actions (list, show, create, edit, delete)
#            - All 10 built-in recipes with descriptions
#            - Usage examples
#            - Available template variables
#
# Example:
#   _flow_recipe_help
#   flow ai recipe help
#   flow ai recipe --help
#
# Notes:
#   - Uses FLOW_COLORS for consistent styling
#   - Triggered by: help, --help, -h arguments
#   - Documents all template variables available in recipes
# =============================================================================
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

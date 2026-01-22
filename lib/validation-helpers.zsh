# lib/validation-helpers.zsh - Shared validation functions for Quarto workflow
# Provides granular validation layers (YAML → Syntax → Render)
# Used by: teach-validate command, pre-commit hooks
# v4.6.0 - Week 2-3: Validation Commands

# Source core utilities if not already loaded
if [[ -z "$_FLOW_CORE_LOADED" ]]; then
    local core_path="${0:A:h}/core.zsh"
    [[ -f "$core_path" ]] && source "$core_path"
    typeset -g _FLOW_CORE_LOADED=1
fi

typeset -g _FLOW_VALIDATION_HELPERS_LOADED=1

# ============================================================================
# LAYER 1: YAML FRONTMATTER VALIDATION
# ============================================================================

# =============================================================================
# Function: _validate_yaml
# Purpose: Validate YAML frontmatter in a Quarto (.qmd) file
# =============================================================================
# Arguments:
#   $1 - (required) Path to the Quarto file to validate
#   $2 - (optional) Quiet mode: "1" to suppress output [default: "0"]
#
# Returns:
#   0 - YAML frontmatter is valid
#   1 - File not found, no frontmatter, empty frontmatter, or invalid YAML
#
# Output:
#   stdout - Success/error messages (unless quiet mode)
#
# Example:
#   _validate_yaml "lectures/week-01.qmd"
#   _validate_yaml "lectures/week-01.qmd" 1  # Quiet mode
#
# Dependencies:
#   - yq (optional, skips validation if not installed)
#   - _flow_log_error, _flow_log_warning, _flow_log_success (from core.zsh)
#
# Notes:
#   - Fast validation (~100ms per file)
#   - Extracts YAML between first two --- markers
#   - Gracefully skips if yq not installed
# =============================================================================
_validate_yaml() {
    local file="$1"
    local quiet="${2:-0}"  # 1 = suppress output

    # Check file exists
    if [[ ! -f "$file" ]]; then
        [[ "$quiet" -eq 0 ]] && _flow_log_error "File not found: $file"
        return 1
    fi

    # Check for YAML frontmatter delimiters
    if ! grep -qE '^---' "$file"; then
        [[ "$quiet" -eq 0 ]] && _flow_log_error "No YAML frontmatter found in: $file"
        return 1
    fi

    # Extract YAML frontmatter (between first two --- markers)
    local yaml_content
    yaml_content=$(awk '/^---$/{if(++c==2){exit}; next} c==1' "$file")

    if [[ -z "$yaml_content" ]]; then
        [[ "$quiet" -eq 0 ]] && _flow_log_error "Empty YAML frontmatter in: $file"
        return 1
    fi

    # Use yq to validate YAML syntax
    if ! command -v yq &>/dev/null; then
        [[ "$quiet" -eq 0 ]] && _flow_log_warning "yq not found - skipping YAML validation"
        return 0  # Don't fail if yq not installed
    fi

    if ! echo "$yaml_content" | yq eval . - &>/dev/null; then
        [[ "$quiet" -eq 0 ]] && _flow_log_error "Invalid YAML syntax in: $file"
        return 1
    fi

    [[ "$quiet" -eq 0 ]] && _flow_log_success "YAML valid: $file"
    return 0
}

# =============================================================================
# Function: _validate_yaml_batch
# Purpose: Validate YAML frontmatter for multiple Quarto files
# =============================================================================
# Arguments:
#   $@ - (required) List of file paths to validate
#
# Returns:
#   0 - All files have valid YAML
#   1 - One or more files failed validation
#
# Output:
#   stdout - Progress messages and summary
#
# Example:
#   _validate_yaml_batch lectures/*.qmd
#   files=($(find . -name "*.qmd")); _validate_yaml_batch "${files[@]}"
#
# Dependencies:
#   - _validate_yaml (internal)
#   - _flow_log_info, _flow_log_error, _flow_log_success (from core.zsh)
#
# Notes:
#   - Validates files sequentially (parallel optimization planned)
#   - Reports total pass/fail count
# =============================================================================
_validate_yaml_batch() {
    local files=("$@")
    local failed=0
    local total=${#files[@]}

    _flow_log_info "Validating YAML for $total files..."

    for file in "${files[@]}"; do
        if ! _validate_yaml "$file" 1; then
            _flow_log_error "YAML validation failed: $file"
            ((failed++))
        fi
    done

    if [[ $failed -eq 0 ]]; then
        _flow_log_success "All $total files have valid YAML"
        return 0
    else
        _flow_log_error "$failed/$total files failed YAML validation"
        return 1
    fi
}

# ============================================================================
# LAYER 2: QUARTO SYNTAX VALIDATION
# ============================================================================

# =============================================================================
# Function: _validate_syntax
# Purpose: Validate Quarto document syntax using quarto inspect
# =============================================================================
# Arguments:
#   $1 - (required) Path to the Quarto file to validate
#   $2 - (optional) Quiet mode: "1" to suppress output [default: "0"]
#
# Returns:
#   0 - Syntax is valid
#   1 - File not found or syntax errors detected
#
# Output:
#   stdout - Success/error messages (unless quiet mode)
#   stderr - First few error lines from quarto inspect
#
# Example:
#   _validate_syntax "lectures/week-01.qmd"
#   if _validate_syntax "$file" 1; then echo "Valid"; fi
#
# Dependencies:
#   - quarto (optional, skips if not installed)
#   - _flow_log_error, _flow_log_warning, _flow_log_success (from core.zsh)
#
# Notes:
#   - Medium speed validation (~500ms per file)
#   - Uses quarto inspect which catches more errors than YAML-only
# =============================================================================
_validate_syntax() {
    local file="$1"
    local quiet="${2:-0}"

    # Check file exists
    if [[ ! -f "$file" ]]; then
        [[ "$quiet" -eq 0 ]] && _flow_log_error "File not found: $file"
        return 1
    fi

    # Check if quarto is installed
    if ! command -v quarto &>/dev/null; then
        [[ "$quiet" -eq 0 ]] && _flow_log_warning "Quarto not found - skipping syntax validation"
        return 0
    fi

    # Run quarto inspect (captures syntax errors)
    local output
    if ! output=$(quarto inspect "$file" 2>&1); then
        [[ "$quiet" -eq 0 ]] && _flow_log_error "Syntax error in: $file"
        [[ "$quiet" -eq 0 ]] && echo "$output" | grep -i error
        return 1
    fi

    [[ "$quiet" -eq 0 ]] && _flow_log_success "Syntax valid: $file"
    return 0
}

# =============================================================================
# Function: _validate_syntax_batch
# Purpose: Validate Quarto syntax for multiple files
# =============================================================================
# Arguments:
#   $@ - (required) List of file paths to validate
#
# Returns:
#   0 - All files have valid syntax
#   1 - One or more files failed validation
#
# Output:
#   stdout - Progress messages and summary
#
# Example:
#   _validate_syntax_batch lectures/*.qmd
#
# Dependencies:
#   - _validate_syntax (internal)
# =============================================================================
_validate_syntax_batch() {
    local files=("$@")
    local failed=0
    local total=${#files[@]}

    _flow_log_info "Validating syntax for $total files..."

    for file in "${files[@]}"; do
        if ! _validate_syntax "$file" 1; then
            _flow_log_error "Syntax validation failed: $file"
            ((failed++))
        fi
    done

    if [[ $failed -eq 0 ]]; then
        _flow_log_success "All $total files have valid syntax"
        return 0
    else
        _flow_log_error "$failed/$total files failed syntax validation"
        return 1
    fi
}

# ============================================================================
# LAYER 3: FULL RENDER VALIDATION
# ============================================================================

# =============================================================================
# Function: _validate_render
# Purpose: Validate Quarto file by performing a full render
# =============================================================================
# Arguments:
#   $1 - (required) Path to the Quarto file to validate
#   $2 - (optional) Quiet mode: "1" to suppress output [default: "0"]
#
# Returns:
#   0 - File renders successfully
#   1 - File not found or render failed
#
# Output:
#   stdout - Success message with render duration (unless quiet mode)
#   stderr - First 5 error lines from quarto render
#
# Example:
#   _validate_render "lectures/week-01.qmd"
#   time _validate_render "$file"  # Check render duration
#
# Dependencies:
#   - quarto (optional, skips if not installed)
#   - _flow_log_error, _flow_log_warning, _flow_log_success (from core.zsh)
#
# Notes:
#   - Slow validation (3-15s per file depending on complexity)
#   - Uses quarto render --quiet for actual compilation
#   - Most thorough validation layer
# =============================================================================
_validate_render() {
    local file="$1"
    local quiet="${2:-0}"

    # Check file exists
    if [[ ! -f "$file" ]]; then
        [[ "$quiet" -eq 0 ]] && _flow_log_error "File not found: $file"
        return 1
    fi

    # Check if quarto is installed
    if ! command -v quarto &>/dev/null; then
        [[ "$quiet" -eq 0 ]] && _flow_log_warning "Quarto not found - skipping render validation"
        return 0
    fi

    # Render with --quiet flag
    local output
    local start_time=$(date +%s)

    if ! output=$(quarto render "$file" --quiet 2>&1); then
        [[ "$quiet" -eq 0 ]] && _flow_log_error "Render failed: $file"
        [[ "$quiet" -eq 0 ]] && echo "$output" | grep -i error | head -5
        return 1
    fi

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    [[ "$quiet" -eq 0 ]] && _flow_log_success "Render valid: $file (${duration}s)"
    return 0
}

# =============================================================================
# Function: _validate_render_batch
# Purpose: Validate multiple Quarto files by rendering them
# =============================================================================
# Arguments:
#   $@ - (required) List of file paths to validate
#
# Returns:
#   0 - All files render successfully
#   1 - One or more files failed to render
#
# Output:
#   stdout - Progress messages and summary
#
# Environment:
#   FLOW_MAX_PARALLEL - Maximum parallel workers [default: 4]
#
# Example:
#   _validate_render_batch lectures/*.qmd
#   FLOW_MAX_PARALLEL=8 _validate_render_batch "${files[@]}"
#
# Dependencies:
#   - _validate_render (internal)
#
# Notes:
#   - Currently sequential; parallel optimization planned for Week 10-11
# =============================================================================
_validate_render_batch() {
    local files=("$@")
    local failed=0
    local total=${#files[@]}
    local max_parallel=${FLOW_MAX_PARALLEL:-4}  # Default 4 cores

    _flow_log_info "Validating renders for $total files (using $max_parallel workers)..."

    # Simple sequential for now (parallel optimization in Week 10-11)
    for file in "${files[@]}"; do
        if ! _validate_render "$file" 1; then
            _flow_log_error "Render validation failed: $file"
            ((failed++))
        fi
    done

    if [[ $failed -eq 0 ]]; then
        _flow_log_success "All $total files rendered successfully"
        return 0
    else
        _flow_log_error "$failed/$total files failed render validation"
        return 1
    fi
}

# ============================================================================
# LAYER 4: EMPTY CODE CHUNK DETECTION (WARNING)
# ============================================================================

# =============================================================================
# Function: _check_empty_chunks
# Purpose: Detect empty R code chunks in Quarto files (warning only)
# =============================================================================
# Arguments:
#   $1 - (required) Path to the Quarto file to check
#   $2 - (optional) Quiet mode: "1" to suppress output [default: "0"]
#
# Returns:
#   0 - No empty code chunks found
#   1 - Empty code chunks detected (or file not found)
#
# Output:
#   stdout - Warning message for each empty chunk found (unless quiet mode)
#
# Example:
#   _check_empty_chunks "lectures/week-01.qmd"
#   if ! _check_empty_chunks "$file"; then echo "Has empty chunks"; fi
#
# Dependencies:
#   - _flow_log_warning (from core.zsh)
#
# Notes:
#   - Fast check (~50ms per file)
#   - Only checks R chunks (```{r ...})
#   - Chunks with only whitespace are considered empty
#   - macOS compatible (no Perl regex)
# =============================================================================
_check_empty_chunks() {
    local file="$1"
    local quiet="${2:-0}"
    local found=0

    # Check file exists
    if [[ ! -f "$file" ]]; then
        return 1
    fi

    # Look for empty R chunks using basic pattern matching
    # (Perl regex not available on macOS, use line-by-line approach)

    # Also check for chunks with only whitespace
    local lines
    local in_chunk=0
    local chunk_empty=1

    while IFS= read -r line; do
        if [[ "$line" =~ ^\`\`\`\{r ]]; then
            in_chunk=1
            chunk_empty=1
        elif [[ "$line" =~ ^\`\`\`$ ]] && [[ $in_chunk -eq 1 ]]; then
            if [[ $chunk_empty -eq 1 ]]; then
                [[ "$quiet" -eq 0 ]] && _flow_log_warning "Empty code chunk detected in: $file"
                found=1
            fi
            in_chunk=0
        elif [[ $in_chunk -eq 1 ]] && [[ -n "${line// /}" ]]; then
            chunk_empty=0
        fi
    done < "$file"

    # Return 0 if no empty chunks found, 1 if found
    [[ $found -eq 0 ]]
}

# ============================================================================
# LAYER 5: IMAGE REFERENCE VALIDATION (WARNING)
# ============================================================================

# =============================================================================
# Function: _check_images
# Purpose: Check for missing image references in Quarto files
# =============================================================================
# Arguments:
#   $1 - (required) Path to the Quarto file to check
#   $2 - (optional) Quiet mode: "1" to suppress output [default: "0"]
#
# Returns:
#   0 - All referenced images exist
#   1 - One or more images are missing (or file not found)
#
# Output:
#   stdout - Warning message for each missing image (unless quiet mode)
#
# Example:
#   _check_images "lectures/week-01.qmd"
#   _check_images "$file" 1  # Quiet mode
#
# Dependencies:
#   - _flow_log_warning (from core.zsh)
#
# Notes:
#   - Fast check (~100ms per file)
#   - Extracts image refs from ![alt](path) markdown syntax
#   - Skips URL references (http://, https://)
#   - Resolves relative paths from file's directory
# =============================================================================
_check_images() {
    local file="$1"
    local quiet="${2:-0}"
    local missing=0
    local file_dir
    file_dir=$(dirname "$file")

    # Check file exists
    if [[ ! -f "$file" ]]; then
        return 1
    fi

    # Extract image references: ![alt](path)
    # Using sed instead of grep -P for macOS compatibility
    local images
    images=$(sed -n 's/.*!\[.*\](\([^)]*\)).*/\1/p' "$file" 2>/dev/null || true)

    if [[ -z "$images" ]]; then
        return 0  # No images to check
    fi

    while IFS= read -r img; do
        # Skip URLs (http://, https://)
        if [[ "$img" =~ ^https?:// ]]; then
            continue
        fi

        # Resolve relative path
        local img_path
        if [[ "$img" =~ ^/ ]]; then
            img_path="$img"  # Absolute path
        else
            img_path="$file_dir/$img"  # Relative to file
        fi

        # Check if image exists
        if [[ ! -f "$img_path" ]]; then
            [[ "$quiet" -eq 0 ]] && _flow_log_warning "Missing image: $img (referenced in: $file)"
            ((missing++))
        fi
    done <<< "$images"

    # Return 0 if all images found, 1 if any missing
    [[ $missing -eq 0 ]]
}

# ============================================================================
# SPECIAL: _freeze/ COMMIT PREVENTION
# ============================================================================

# =============================================================================
# Function: _check_freeze_staged
# Purpose: Check if _freeze/ directory is staged for git commit
# =============================================================================
# Arguments:
#   $1 - (optional) Quiet mode: "1" to suppress output [default: "0"]
#
# Returns:
#   0 - No _freeze/ files staged (or not in git repo)
#   1 - _freeze/ files are staged
#
# Output:
#   stdout - Error message and fix instructions (unless quiet mode)
#
# Example:
#   if ! _check_freeze_staged; then
#       echo "Remove _freeze/ from staging before committing"
#   fi
#
# Dependencies:
#   - git
#   - _flow_log_error, _flow_log_info (from core.zsh)
#
# Notes:
#   - Used in pre-commit hooks to prevent accidental _freeze/ commits
#   - _freeze/ contains rendered cache that shouldn't be versioned
# =============================================================================
_check_freeze_staged() {
    local quiet="${1:-0}"

    # Check if in git repo
    if ! git rev-parse --git-dir &>/dev/null; then
        return 0
    fi

    # Check for staged _freeze/ files
    if git diff --cached --name-only | grep -q '^_freeze/'; then
        [[ "$quiet" -eq 0 ]] && _flow_log_error "Cannot commit _freeze/ directory"
        [[ "$quiet" -eq 0 ]] && _flow_log_info "Run: git restore --staged _freeze/"
        return 1
    fi

    return 0
}

# ============================================================================
# WATCH MODE HELPERS
# ============================================================================

# =============================================================================
# Function: _is_quarto_preview_running
# Purpose: Detect if quarto preview is currently running
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Quarto preview is running
#   1 - Quarto preview is not running
#
# Example:
#   if _is_quarto_preview_running; then
#       echo "Preview already running - skipping validation to avoid conflict"
#   fi
#
# Notes:
#   - Checks .quarto-preview.pid file first
#   - Falls back to pgrep for "quarto preview" process
#   - Cleans up stale PID files automatically
# =============================================================================
_is_quarto_preview_running() {
    local project_root
    project_root=$(pwd)

    # Check for .quarto-preview.pid file
    if [[ -f "$project_root/.quarto-preview.pid" ]]; then
        local pid
        pid=$(cat "$project_root/.quarto-preview.pid")

        # Check if process is actually running
        if ps -p "$pid" &>/dev/null; then
            return 0
        else
            # Stale PID file, remove it
            rm -f "$project_root/.quarto-preview.pid"
            return 1
        fi
    fi

    # Alternative: check for quarto preview process
    if pgrep -f "quarto preview" &>/dev/null; then
        return 0
    fi

    return 1
}

# =============================================================================
# Function: _get_validation_status
# Purpose: Get cached validation status for a file from JSON status file
# =============================================================================
# Arguments:
#   $1 - (required) Path to the file to check
#
# Returns:
#   0 - Always (outputs status string)
#
# Output:
#   stdout - Status string: "pass", "fail", "pending", or "unknown"
#
# Example:
#   status=$(_get_validation_status "lectures/week-01.qmd")
#   if [[ "$status" == "pass" ]]; then echo "Previously validated"; fi
#
# Dependencies:
#   - jq (optional, returns "unknown" if not installed)
#
# Notes:
#   - Reads from .teach/validation-status.json
#   - Returns "unknown" if file not in status cache
# =============================================================================
_get_validation_status() {
    local file="$1"
    local status_file=".teach/validation-status.json"

    if [[ ! -f "$status_file" ]]; then
        echo "unknown"
        return
    fi

    # Extract status for this file using jq if available
    if command -v jq &>/dev/null; then
        jq -r --arg file "$file" '.files[$file].status // "unknown"' "$status_file" 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

# =============================================================================
# Function: _update_validation_status
# Purpose: Update validation status for a file in JSON status file
# =============================================================================
# Arguments:
#   $1 - (required) Path to the file being validated
#   $2 - (required) Status: "pass", "fail", or "pending"
#   $3 - (optional) Error message if status is "fail"
#
# Returns:
#   0 - Always
#
# Example:
#   _update_validation_status "lectures/week-01.qmd" "pass"
#   _update_validation_status "lectures/week-02.qmd" "fail" "Invalid YAML"
#
# Dependencies:
#   - jq (optional, no-op if not installed)
#
# Notes:
#   - Creates .teach directory if needed
#   - Initializes status file if it doesn't exist
#   - Adds ISO 8601 timestamp to each entry
# =============================================================================
_update_validation_status() {
    local file="$1"
    local validation_status="$2"  # pass|fail|pending
    local error="${3:-}"
    local status_file=".teach/validation-status.json"

    # Create .teach directory if it doesn't exist
    mkdir -p .teach

    # Initialize status file if it doesn't exist
    if [[ ! -f "$status_file" ]]; then
        echo '{"files":{}}' > "$status_file"
    fi

    # Update status using jq if available
    if command -v jq &>/dev/null; then
        local timestamp
        timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

        local temp_file
        temp_file=$(mktemp)

        jq --arg file "$file" \
           --arg vstatus "$validation_status" \
           --arg error "$error" \
           --arg timestamp "$timestamp" \
           '.files[$file] = {status: $vstatus, error: $error, timestamp: $timestamp}' \
           "$status_file" > "$temp_file"

        mv "$temp_file" "$status_file"
    fi
}

# =============================================================================
# Function: _debounce_validation
# Purpose: Debounce file changes to prevent rapid re-validation
# =============================================================================
# Arguments:
#   $1 - (required) Path to the file being changed
#   $2 - (optional) Debounce window in milliseconds [default: 500]
#
# Returns:
#   0 - Should validate (debounce window expired)
#   1 - Should wait (still within debounce window)
#
# Example:
#   if _debounce_validation "lectures/week-01.qmd"; then
#       _validate_yaml "$file"
#   fi
#   # With custom debounce window
#   _debounce_validation "$file" 1000  # 1 second
#
# Notes:
#   - Stores timestamps in .teach/last-change-*.timestamp files
#   - macOS compatible (uses gdate if available)
#   - Prevents validation storms during rapid file changes
# =============================================================================
_debounce_validation() {
    local file="$1"
    local debounce_ms="${2:-500}"
    local last_change_file=".teach/last-change-${file//\//_}.timestamp"

    mkdir -p .teach

    # macOS date doesn't support %3N, use seconds with nanoseconds
    local now
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: use gdate if available, otherwise use seconds * 1000
        if command -v gdate &>/dev/null; then
            now=$(gdate +%s%3N)
        else
            now=$(($(date +%s) * 1000))
        fi
    else
        now=$(date +%s%3N)
    fi

    # Check if file exists and read last change time
    if [[ -f "$last_change_file" ]]; then
        local last_change
        last_change=$(cat "$last_change_file")
        local elapsed=$((now - last_change))

        if [[ $elapsed -lt $debounce_ms ]]; then
            # Still in debounce window
            echo "$now" > "$last_change_file"
            return 1
        fi
    fi

    # Update timestamp and allow validation
    echo "$now" > "$last_change_file"
    return 0
}

# ============================================================================
# COMBINED VALIDATION
# ============================================================================

# =============================================================================
# Function: _validate_file_full
# Purpose: Run all validation layers for a Quarto file
# =============================================================================
# Arguments:
#   $1 - (required) Path to the Quarto file to validate
#   $2 - (optional) Quiet mode: "1" to suppress output [default: "0"]
#   $3 - (optional) Layers to run, comma-separated [default: "yaml,syntax,render"]
#
# Returns:
#   0 - All requested layers pass
#   1+ - Number of failed layers
#
# Layer Options:
#   yaml   - YAML frontmatter validation (Layer 1)
#   syntax - Quarto syntax validation (Layer 2)
#   render - Full render validation (Layer 3)
#   chunks - Empty code chunk detection (Layer 4, warning only)
#   images - Missing image detection (Layer 5, warning only)
#
# Example:
#   _validate_file_full "lectures/week-01.qmd"
#   _validate_file_full "$file" 0 "yaml,syntax"  # Skip render
#   _validate_file_full "$file" 1 "yaml,syntax,render,chunks,images"  # All layers
#
# Notes:
#   - Layers run in order; later layers skip if earlier ones fail
#   - Layers 4-5 (chunks, images) are warnings and don't affect return code
# =============================================================================
_validate_file_full() {
    local file="$1"
    local quiet="${2:-0}"
    local layers="${3:-yaml,syntax,render}"  # Comma-separated layers

    local failed=0

    # Layer 1: YAML
    if [[ "$layers" == *"yaml"* ]]; then
        if ! _validate_yaml "$file" "$quiet"; then
            ((failed++))
        fi
    fi

    # Layer 2: Syntax (only if YAML passed)
    if [[ "$layers" == *"syntax"* ]] && [[ $failed -eq 0 ]]; then
        if ! _validate_syntax "$file" "$quiet"; then
            ((failed++))
        fi
    fi

    # Layer 3: Render (only if syntax passed)
    if [[ "$layers" == *"render"* ]] && [[ $failed -eq 0 ]]; then
        if ! _validate_render "$file" "$quiet"; then
            ((failed++))
        fi
    fi

    # Layer 4: Empty chunks (warning only)
    if [[ "$layers" == *"chunks"* ]]; then
        _check_empty_chunks "$file" "$quiet"
    fi

    # Layer 5: Images (warning only)
    if [[ "$layers" == *"images"* ]]; then
        _check_images "$file" "$quiet"
    fi

    return $failed
}

# =============================================================================
# Function: _find_quarto_files
# Purpose: Find all Quarto (.qmd) files in a directory recursively
# =============================================================================
# Arguments:
#   $1 - (optional) Directory to search [default: current directory]
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - One file path per line, sorted alphabetically
#
# Example:
#   files=$(_find_quarto_files)
#   files=$(_find_quarto_files "lectures")
#   _find_quarto_files | while read -r file; do echo "$file"; done
#
# Notes:
#   - Uses find command with -name "*.qmd"
#   - Output is sorted for consistent ordering
# =============================================================================
_find_quarto_files() {
    local dir="${1:-.}"
    find "$dir" -name "*.qmd" -type f | sort
}

# =============================================================================
# Function: _get_staged_quarto_files
# Purpose: Get list of staged Quarto files for pre-commit validation
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Success (or empty list)
#   1 - Not in a git repository
#
# Output:
#   stdout - One staged .qmd file path per line
#
# Example:
#   staged=$(_get_staged_quarto_files)
#   if [[ -n "$staged" ]]; then
#       echo "Staged Quarto files: $staged"
#   fi
#
# Notes:
#   - Filters for Added, Copied, Modified files only (ACM)
#   - Returns empty string if no .qmd files staged
#   - Used in pre-commit hooks for targeted validation
# =============================================================================
_get_staged_quarto_files() {
    if ! git rev-parse --git-dir &>/dev/null; then
        return 1
    fi

    git diff --cached --name-only --diff-filter=ACM | grep '\.qmd$' || true
}

# ============================================================================
# PERFORMANCE TRACKING
# ============================================================================

# Track validation performance
typeset -gA VALIDATION_STATS

# =============================================================================
# Function: _track_validation_start
# Purpose: Record start time for validation performance tracking
# =============================================================================
# Arguments:
#   $1 - (required) File path being validated
#
# Returns:
#   0 - Always
#
# Example:
#   _track_validation_start "lectures/week-01.qmd"
#   # ... perform validation ...
#   duration=$(_track_validation_end "lectures/week-01.qmd")
#
# Notes:
#   - Stores timestamp in VALIDATION_STATS associative array
#   - macOS compatible (uses gdate if available, falls back to seconds)
# =============================================================================
_track_validation_start() {
    local file="$1"
    # Use cross-platform timestamp
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v gdate &>/dev/null; then
            VALIDATION_STATS["${file}_start"]=$(gdate +%s%3N)
        else
            VALIDATION_STATS["${file}_start"]=$(($(date +%s) * 1000))
        fi
    else
        VALIDATION_STATS["${file}_start"]=$(date +%s%3N)
    fi
}

# =============================================================================
# Function: _track_validation_end
# Purpose: Record end time and calculate validation duration
# =============================================================================
# Arguments:
#   $1 - (required) File path that was validated
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Duration in milliseconds
#
# Example:
#   _track_validation_start "$file"
#   _validate_yaml "$file"
#   duration=$(_track_validation_end "$file")
#   echo "Validation took ${duration}ms"
#
# Notes:
#   - Must call _track_validation_start first
#   - Duration stored in VALIDATION_STATS for later analysis
# =============================================================================
_track_validation_end() {
    local file="$1"
    local start="${VALIDATION_STATS[${file}_start]}"
    local end

    # Use cross-platform timestamp
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v gdate &>/dev/null; then
            end=$(gdate +%s%3N)
        else
            end=$(($(date +%s) * 1000))
        fi
    else
        end=$(date +%s%3N)
    fi

    local duration=$((end - start))
    VALIDATION_STATS["${file}_duration"]=$duration
    echo "$duration"
}

# =============================================================================
# Function: _show_validation_stats
# Purpose: Display summary of validation performance statistics
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Total time, file count, and average time per file
#
# Example:
#   # After validating multiple files
#   _show_validation_stats
#   # Output: Total: 1250ms | Files: 5 | Avg: 250ms/file
#
# Dependencies:
#   - _flow_log_info (from core.zsh)
#
# Notes:
#   - Reads from VALIDATION_STATS array populated by _track_validation_*
#   - Only shows stats if files were tracked
# =============================================================================
_show_validation_stats() {
    local total_time=0
    local file_count=0

    for key in "${(@k)VALIDATION_STATS}"; do
        if [[ "$key" == *"_duration" ]]; then
            local duration="${VALIDATION_STATS[$key]}"
            ((total_time += duration))
            ((file_count++))
        fi
    done

    if [[ $file_count -gt 0 ]]; then
        local avg_time=$((total_time / file_count))
        _flow_log_info "Total: ${total_time}ms | Files: $file_count | Avg: ${avg_time}ms/file"
    fi
}

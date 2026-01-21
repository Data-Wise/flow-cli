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

# Validate YAML frontmatter in Quarto file
# Fast validation (~100ms per file)
# Returns: 0 if valid, 1 if invalid
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

# Batch validate YAML for multiple files
# Uses parallel processing if available
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

# Validate Quarto syntax using `quarto inspect`
# Medium speed validation (~500ms per file)
# Returns: 0 if valid, 1 if invalid
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

# Batch validate syntax for multiple files
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

# Validate by performing full render
# Slow validation (3-15s per file depending on complexity)
# Returns: 0 if renders successfully, 1 if render fails
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

# Batch render validation with parallel processing
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

# Check for empty code chunks (warning, not error)
# Fast check (~50ms per file)
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

# Check for missing image references
# Fast check (~100ms per file)
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

# Check if _freeze/ directory is staged for commit
# Used in pre-commit hook
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

# Detect if quarto preview is running
# Returns: 0 if running, 1 if not
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

# Get validation status from .teach/validation-status.json
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

# Update validation status in .teach/validation-status.json
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

# Debounce file changes (wait 500ms for more changes)
# Returns: 0 if should validate, 1 if should wait
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

# Run all validation layers for a file
# Returns: 0 if all pass, 1 if any fail
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

# Find Quarto files in directory (recursive)
_find_quarto_files() {
    local dir="${1:-.}"
    find "$dir" -name "*.qmd" -type f | sort
}

# Get list of staged Quarto files (for pre-commit)
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

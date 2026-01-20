# commands/teach-validate.zsh - Standalone validation command for Quarto workflow
# Granular validation with watch mode
# v4.6.0 - Week 2-3: Validation Commands

# Source core utilities
if [[ -z "$_FLOW_CORE_LOADED" ]]; then
    local core_path="${0:A:h:h}/lib/core.zsh"
    [[ -f "$core_path" ]] && source "$core_path"
    typeset -g _FLOW_CORE_LOADED=1
fi

# Source validation helpers
if [[ -z "$_FLOW_VALIDATION_HELPERS_LOADED" ]]; then
    local validation_path="${0:A:h:h}/lib/validation-helpers.zsh"
    [[ -f "$validation_path" ]] && source "$validation_path"
    typeset -g _FLOW_VALIDATION_HELPERS_LOADED=1
fi

# ============================================================================
# TEACH VALIDATE COMMAND
# ============================================================================

teach-validate() {
    local mode="full"        # full|yaml|syntax|render|watch
    local files=()
    local watch_mode=0
    local stats_mode=0
    local quiet=0

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --yaml)
                mode="yaml"
                shift
                ;;
            --syntax)
                mode="syntax"
                shift
                ;;
            --render)
                mode="render"
                shift
                ;;
            --watch)
                watch_mode=1
                shift
                ;;
            --stats)
                stats_mode=1
                shift
                ;;
            --quiet|-q)
                quiet=1
                shift
                ;;
            --help|-h)
                _teach_validate_help
                return 0
                ;;
            *.qmd)
                files+=("$1")
                shift
                ;;
            *)
                _flow_log_error "Unknown option: $1"
                _teach_validate_help
                return 1
                ;;
        esac
    done

    # If no files specified, find all .qmd files
    if [[ ${#files[@]} -eq 0 ]]; then
        local found_files
        found_files=($(_find_quarto_files .))

        if [[ ${#found_files[@]} -eq 0 ]]; then
            _flow_log_error "No .qmd files found in current directory"
            return 1
        fi

        files=("${found_files[@]}")
    fi

    # Execute based on mode
    if [[ $watch_mode -eq 1 ]]; then
        _teach_validate_watch "${files[@]}"
    else
        _teach_validate_run "$mode" "$quiet" "$stats_mode" "${files[@]}"
    fi
}

# ============================================================================
# VALIDATION EXECUTION
# ============================================================================

_teach_validate_run() {
    local mode="$1"
    local quiet="$2"
    local stats="$3"
    shift 3
    local files=("$@")

    [[ $quiet -eq 0 ]] && _flow_log_info "Running $mode validation for ${#files[@]} file(s)..."

    local failed=0
    local passed=0

    # Track performance (cross-platform)
    local start_time
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v gdate &>/dev/null; then
            start_time=$(gdate +%s%3N)
        else
            start_time=$(($(date +%s) * 1000))
        fi
    else
        start_time=$(date +%s%3N)
    fi

    for file in "${files[@]}"; do
        [[ $quiet -eq 0 ]] && echo ""
        [[ $quiet -eq 0 ]] && _flow_log_info "Validating: $file"

        _track_validation_start "$file"

        local result=0
        case "$mode" in
            yaml)
                _validate_yaml "$file" "$quiet" || result=$?
                ;;
            syntax)
                _validate_yaml "$file" "$quiet" || result=$?
                if [[ $result -eq 0 ]]; then
                    _validate_syntax "$file" "$quiet" || result=$?
                fi
                ;;
            render)
                _validate_yaml "$file" "$quiet" || result=$?
                if [[ $result -eq 0 ]]; then
                    _validate_syntax "$file" "$quiet" || result=$?
                fi
                if [[ $result -eq 0 ]]; then
                    _validate_render "$file" "$quiet" || result=$?
                fi
                ;;
            full)
                _validate_file_full "$file" "$quiet" "yaml,syntax,render,chunks,images" || result=$?
                ;;
        esac

        local duration
        duration=$(_track_validation_end "$file")

        if [[ $result -eq 0 ]]; then
            ((passed++))
            _update_validation_status "$file" "pass" ""
            [[ $quiet -eq 0 ]] && _flow_log_success "✓ $file (${duration}ms)"
        else
            ((failed++))
            _update_validation_status "$file" "fail" "Validation failed"
            [[ $quiet -eq 0 ]] && _flow_log_error "✗ $file (${duration}ms)"
        fi
    done

    local end_time
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v gdate &>/dev/null; then
            end_time=$(gdate +%s%3N)
        else
            end_time=$(($(date +%s) * 1000))
        fi
    else
        end_time=$(date +%s%3N)
    fi
    local total_time=$((end_time - start_time))

    # Summary
    echo ""
    if [[ $failed -eq 0 ]]; then
        _flow_log_success "All ${#files[@]} files passed validation (${total_time}ms)"
    else
        _flow_log_error "$failed/${#files[@]} files failed validation (${total_time}ms)"
    fi

    # Show stats if requested
    if [[ $stats -eq 1 ]]; then
        echo ""
        _show_validation_stats
    fi

    return $failed
}

# ============================================================================
# WATCH MODE
# ============================================================================

_teach_validate_watch() {
    local files=("$@")

    _flow_log_info "Starting watch mode for ${#files[@]} file(s)..."
    _flow_log_info "Press Ctrl+C to stop"

    # Check if quarto preview is running
    if _is_quarto_preview_running; then
        _flow_log_warning "Quarto preview is running - validation may conflict"
        _flow_log_info "Consider using separate terminal for validation"
        echo ""
        read "?Continue anyway? [y/N] " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            _flow_log_info "Aborted"
            return 1
        fi
    fi

    # Determine file watcher command
    local watcher=""
    if command -v fswatch &>/dev/null; then
        watcher="fswatch"
    elif command -v inotifywait &>/dev/null; then
        watcher="inotifywait"
    else
        _flow_log_error "No file watcher found (fswatch or inotifywait required)"
        _flow_log_info "Install with: brew install fswatch (macOS) or apt-get install inotify-tools (Linux)"
        return 1
    fi

    # Initial validation
    _flow_log_info "Running initial validation..."
    _teach_validate_run "full" 0 0 "${files[@]}"

    echo ""
    _flow_log_info "Watching for changes..."
    echo ""

    # Watch loop
    if [[ "$watcher" == "fswatch" ]]; then
        _watch_with_fswatch "${files[@]}"
    else
        _watch_with_inotifywait "${files[@]}"
    fi
}

# Watch using fswatch (macOS)
_watch_with_fswatch() {
    local files=("$@")

    # Create temp file for tracking last validation
    local last_validated
    last_validated=$(mktemp)
    echo "0" > "$last_validated"

    fswatch -0 -l 0.5 "${files[@]}" | while read -d "" event; do
        # Check if quarto preview is running
        if _is_quarto_preview_running; then
            _flow_log_warning "Skipping validation - Quarto preview is active"
            continue
        fi

        # Debounce (wait 500ms)
        if ! _debounce_validation "$event" 500; then
            continue
        fi

        # Run validation in background
        (
            echo ""
            _flow_log_info "File changed: $event"
            _flow_log_info "Validating..."

            _track_validation_start "$event"
            _update_validation_status "$event" "pending" ""

            local result=0
            _validate_file_full "$event" 0 "yaml,syntax,chunks,images" || result=$?

            local duration
            duration=$(_track_validation_end "$event")

            if [[ $result -eq 0 ]]; then
                _update_validation_status "$event" "pass" ""
                _flow_log_success "✓ Validation passed (${duration}ms)"
            else
                _update_validation_status "$event" "fail" "Validation failed"
                _flow_log_error "✗ Validation failed (${duration}ms)"
            fi

            echo ""
            _flow_log_info "Watching for changes..."
        ) &
    done

    rm -f "$last_validated"
}

# Watch using inotifywait (Linux)
_watch_with_inotifywait() {
    local files=("$@")

    while true; do
        # Wait for file modification
        local changed_file
        changed_file=$(inotifywait -q -e modify -e close_write --format '%w' "${files[@]}" 2>/dev/null)

        if [[ -z "$changed_file" ]]; then
            continue
        fi

        # Check if quarto preview is running
        if _is_quarto_preview_running; then
            _flow_log_warning "Skipping validation - Quarto preview is active"
            continue
        fi

        # Debounce (wait 500ms)
        if ! _debounce_validation "$changed_file" 500; then
            continue
        fi

        # Run validation
        echo ""
        _flow_log_info "File changed: $changed_file"
        _flow_log_info "Validating..."

        _track_validation_start "$changed_file"
        _update_validation_status "$changed_file" "pending" ""

        local result=0
        _validate_file_full "$changed_file" 0 "yaml,syntax,chunks,images" || result=$?

        local duration
        duration=$(_track_validation_end "$changed_file")

        if [[ $result -eq 0 ]]; then
            _update_validation_status "$changed_file" "pass" ""
            _flow_log_success "✓ Validation passed (${duration}ms)"
        else
            _update_validation_status "$changed_file" "fail" "Validation failed"
            _flow_log_error "✗ Validation failed (${duration}ms)"
        fi

        echo ""
        _flow_log_info "Watching for changes..."
    done
}

# ============================================================================
# HELP
# ============================================================================

_teach_validate_help() {
    cat <<'EOF'
teach validate - Validate Quarto files with granular control

USAGE:
  teach validate [OPTIONS] [FILES...]

OPTIONS:
  --yaml          YAML frontmatter validation only (fast, ~1s)
  --syntax        YAML + Quarto syntax validation (~2s)
  --render        Full render validation (slow, 3-15s per file)
  --watch         Continuous validation on file changes
  --stats         Show performance statistics
  --quiet, -q     Minimal output
  --help, -h      Show this help

VALIDATION LAYERS:
  1. YAML        - Validate YAML frontmatter syntax
  2. Syntax      - Check Quarto document structure
  3. Render      - Attempt full document render
  4. Chunks      - Warn about empty code chunks
  5. Images      - Check for missing image references

EXAMPLES:
  # Full validation (all layers)
  teach validate

  # Fast YAML-only validation
  teach validate --yaml

  # Validate specific files
  teach validate lectures/week-01.qmd lectures/week-02.qmd

  # Watch mode (auto-validate on save)
  teach validate --watch

  # Syntax check with stats
  teach validate --syntax --stats

WATCH MODE:
  - Monitors file changes in real-time
  - Auto-validates on save (debounced 500ms)
  - Detects conflicts with 'quarto preview'
  - Updates .teach/validation-status.json
  - Press Ctrl+C to stop

PERFORMANCE:
  YAML validation:     <1s per file
  Syntax validation:   ~2s per file
  Render validation:   3-15s per file
  Watch mode overhead: ~50ms per change

RACE CONDITION PREVENTION:
  - Detects .quarto-preview.pid
  - Skips validation if preview is running
  - Warns about potential conflicts

OUTPUT:
  Validation status saved to:
    .teach/validation-status.json

  JSON format:
    {
      "files": {
        "lectures/week-01.qmd": {
          "status": "pass",
          "error": "",
          "timestamp": "2026-01-20T12:00:00Z"
        }
      }
    }

SEE ALSO:
  teach doctor       - Check project health
  teach hooks        - Install pre-commit validation hooks
EOF
}

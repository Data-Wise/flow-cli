#!/usr/bin/env zsh
# lib/custom-validators.zsh - Custom Validator Plugin Framework
# Extensible validation system for Quarto teaching workflows
# v4.6.0 - Wave 3: Custom Validators Framework
#
# ARCHITECTURE:
#   - Discover validators in .teach/validators/*.zsh
#   - Load and validate plugin API compliance
#   - Execute validators in isolated environment
#   - Aggregate results with clear formatting
#
# PLUGIN API:
#   Required:
#     - VALIDATOR_NAME (string)
#     - VALIDATOR_VERSION (string)
#     - VALIDATOR_DESCRIPTION (string)
#     - _validate() function
#   Optional:
#     - _validator_init() function
#     - _validator_cleanup() function
#
# USAGE:
#   teach validate --custom [files...]
#   teach validate --custom --validators check-citations,check-links [files...]

# Source core utilities if not already loaded
if [[ -z "$_FLOW_CORE_LOADED" ]]; then
    local core_path="${0:A:h}/core.zsh"
    [[ -f "$core_path" ]] && source "$core_path"
    typeset -g _FLOW_CORE_LOADED=1
fi

typeset -g _FLOW_CUSTOM_VALIDATORS_LOADED=1

# ============================================================================
# VALIDATOR DISCOVERY
# ============================================================================

# Discover all validators in .teach/validators/
# Returns: Array of validator script paths
# Usage: validators=($(_discover_validators))
_discover_validators() {
    local project_root="${1:-.}"
    local validators_dir="$project_root/.teach/validators"

    # Check if validators directory exists
    if [[ ! -d "$validators_dir" ]]; then
        return 0  # No validators, not an error
    fi

    # Find all .zsh files in validators directory
    local validator_scripts=()
    for script in "$validators_dir"/*.zsh(N); do
        [[ -f "$script" ]] && validator_scripts+=("$script")
    done

    # Return script paths (one per line for easy array capture)
    printf '%s\n' "${validator_scripts[@]}"
}

# Get validator name from script path
# Extracts clean name from filename (check-citations.zsh → check-citations)
_get_validator_name_from_path() {
    local script_path="$1"
    basename "$script_path" .zsh
}

# ============================================================================
# VALIDATOR API VALIDATION
# ============================================================================

# Validate that a validator implements the required API
# Returns: 0 if valid, 1 if invalid
# Prints: Error messages for missing/invalid components
_validate_validator_api() {
    local script_path="$1"
    local errors=()

    # Source validator in subshell to check API
    local api_check
    api_check=$(
        source "$script_path" 2>&1

        # Check required variables
        [[ -z "$VALIDATOR_NAME" ]] && echo "ERROR:Missing VALIDATOR_NAME"
        [[ -z "$VALIDATOR_VERSION" ]] && echo "ERROR:Missing VALIDATOR_VERSION"
        [[ -z "$VALIDATOR_DESCRIPTION" ]] && echo "ERROR:Missing VALIDATOR_DESCRIPTION"

        # Check required function
        if ! declare -f _validate &>/dev/null; then
            echo "ERROR:Missing _validate() function"
        fi

        # Note: We don't validate function signature deeply
        # The function should accept a file argument, but we trust the plugin author
    )

    # Parse errors from API check
    while IFS= read -r line; do
        if [[ "$line" == ERROR:* ]]; then
            errors+=("${line#ERROR:}")
        elif [[ "$line" == WARNING:* ]]; then
            errors+=("${line#WARNING:}")
        fi
    done <<< "$api_check"

    # Return status
    if [[ ${#errors[@]} -gt 0 ]]; then
        printf '%s\n' "${errors[@]}"
        return 1
    fi

    return 0
}

# ============================================================================
# VALIDATOR LOADING
# ============================================================================

# Load validator metadata without executing it
# Returns: JSON object with metadata
# Format: {"name": "...", "version": "...", "description": "..."}
_load_validator_metadata() {
    local script_path="$1"

    # Extract metadata in subshell
    local metadata
    metadata=$(
        source "$script_path" 2>/dev/null

        # Output JSON
        echo "{"
        echo "  \"name\": \"$VALIDATOR_NAME\","
        echo "  \"version\": \"$VALIDATOR_VERSION\","
        echo "  \"description\": \"$VALIDATOR_DESCRIPTION\","
        echo "  \"script\": \"$script_path\""
        echo "}"
    )

    echo "$metadata"
}

# ============================================================================
# VALIDATOR EXECUTION
# ============================================================================

# Execute a single validator on a file
# Returns: 0 if validation passed, 1 if errors found
# Prints: Error messages to stdout (one per line)
_execute_validator() {
    local script_path="$1"
    local file="$2"
    local validator_name
    validator_name=$(_get_validator_name_from_path "$script_path")

    # Execute validator in subshell for isolation
    local result
    local exit_code
    result=$(
        # Source the validator
        source "$script_path" 2>/dev/null || {
            echo "ERROR: Failed to source validator"
            exit 2
        }

        # Run optional init
        if declare -f _validator_init &>/dev/null; then
            _validator_init 2>&1 || {
                echo "ERROR: Validator initialization failed"
                exit 2
            }
        fi

        # Run validation with error handling
        local validation_output
        validation_output=$(_validate "$file" 2>&1)
        local validate_exit=$?

        # Check if validation crashed
        if [[ $validate_exit -gt 1 ]]; then
            echo "ERROR: Validator crashed during execution"
            exit 2
        fi

        # Print validation output
        echo "$validation_output"

        # Run optional cleanup
        if declare -f _validator_cleanup &>/dev/null; then
            _validator_cleanup 2>/dev/null
        fi

        # Exit with validation status
        exit $validate_exit
    ) 2>&1
    exit_code=$?

    # Handle validator crash (exit code 2)
    if [[ $exit_code -eq 2 ]]; then
        echo "FATAL: Validator crashed or failed to initialize"
        return 2
    fi

    # Print validation results
    echo "$result"

    # Return validation status
    return $exit_code
}

# ============================================================================
# RESULT AGGREGATION
# ============================================================================

# Aggregate results from multiple validators
# Displays grouped results with clear formatting
# Returns: 0 if all passed, 1 if any failed
_aggregate_validator_results() {
    local -A file_errors  # file -> error_count
    local -A validator_errors  # validator -> error_count
    local total_errors=0
    local total_validators=0
    local files_checked=0

    # Read results from stdin (format: validator|file|error_message)
    while IFS='|' read -r validator file error; do
        ((total_errors++))

        # Track errors per file
        file_errors[$file]=$((${file_errors[$file]:-0} + 1))

        # Track errors per validator
        validator_errors[$validator]=$((${validator_errors[$validator]:-0} + 1))
    done

    # Display summary
    if [[ $total_errors -eq 0 ]]; then
        return 0
    fi

    # Display grouped errors
    local unique_files=(${(k)file_errors})
    files_checked=${#unique_files[@]}

    echo
    _flow_log_error "Validation Summary:"
    echo "  ✗ ${total_errors} errors found"
    echo "  Files with errors: ${files_checked}"
    echo "  Validators run: ${#validator_errors[@]}"

    return 1
}

# ============================================================================
# MAIN ORCHESTRATOR
# ============================================================================

# Run custom validators on files
# Arguments:
#   --validators <list>  : Comma-separated list of validators to run
#   --skip-external      : Skip external URL checks (for link validator)
#   files...             : Files to validate
# Returns: 0 if all passed, 1 if any failed
_run_custom_validators() {
    local selected_validators=()
    local files=()
    local skip_external=0
    local project_root="."

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --validators)
                shift
                IFS=',' read -rA selected_validators <<< "$1"
                ;;
            --skip-external)
                skip_external=1
                ;;
            --project-root)
                shift
                project_root="$1"
                ;;
            -*)
                _flow_log_error "Unknown flag: $1"
                return 1
                ;;
            *)
                files+=("$1")
                ;;
        esac
        shift
    done

    # Validate inputs
    if [[ ${#files[@]} -eq 0 ]]; then
        _flow_log_error "No files specified for validation"
        return 1
    fi

    # Discover validators
    local available_validators
    available_validators=($(_discover_validators "$project_root"))

    if [[ ${#available_validators[@]} -eq 0 ]]; then
        _flow_log_warning "No custom validators found in $project_root/.teach/validators/"
        return 0
    fi

    # Filter validators if --validators specified
    local validators_to_run=()
    if [[ ${#selected_validators[@]} -gt 0 ]]; then
        # Map selected names to script paths
        for selected in "${selected_validators[@]}"; do
            local found=0
            for script in "${available_validators[@]}"; do
                local script_name
                script_name=$(_get_validator_name_from_path "$script")
                if [[ "$script_name" == "$selected" ]]; then
                    validators_to_run+=("$script")
                    found=1
                    break
                fi
            done
            if [[ $found -eq 0 ]]; then
                _flow_log_warning "Validator not found: $selected"
            fi
        done
    else
        validators_to_run=("${available_validators[@]}")
    fi

    if [[ ${#validators_to_run[@]} -eq 0 ]]; then
        _flow_log_error "No validators to run"
        return 1
    fi

    # Display header
    echo
    _flow_log_info "Running custom validators..."
    if [[ ${#selected_validators[@]} -gt 0 ]]; then
        echo "  Selected: ${(j:, :)selected_validators}"
    else
        echo "  Found: ${#validators_to_run[@]} validators"
    fi
    echo

    # Validate and run each validator
    local total_errors=0
    local start_time=$(date +%s)
    local -A all_results  # validator|file -> errors

    for script in "${validators_to_run[@]}"; do
        local validator_name
        validator_name=$(_get_validator_name_from_path "$script")

        # Validate API compliance
        local api_errors
        api_errors=$(_validate_validator_api "$script")
        if [[ $? -ne 0 ]]; then
            _flow_log_error "→ $validator_name: INVALID PLUGIN API"
            echo "$api_errors" | while IFS= read -r error; do
                echo "    $error"
            done
            ((total_errors++))
            continue
        fi

        # Load metadata
        local metadata
        metadata=$(_load_validator_metadata "$script")
        local version
        version=$(echo "$metadata" | grep -o '"version": "[^"]*"' | cut -d'"' -f4)

        # Display validator header
        echo "→ $validator_name (v$version)"

        # Run validator on each file
        local validator_file_errors=0
        for file in "${files[@]}"; do
            # Skip if file doesn't exist
            if [[ ! -f "$file" ]]; then
                echo "  $file:"
                echo "    File not found (skipped)"
                continue
            fi

            # Execute validator
            local errors
            local exit_code

            # Pass --skip-external flag to validator if needed
            if [[ $skip_external -eq 1 ]]; then
                export VALIDATOR_SKIP_EXTERNAL=1
            fi

            errors=$(_execute_validator "$script" "$file")
            exit_code=$?

            unset VALIDATOR_SKIP_EXTERNAL

            # Handle validator crash
            if [[ $exit_code -eq 2 ]]; then
                echo "  $file:"
                echo "    ✗ VALIDATOR CRASHED"
                ((total_errors++))
                ((validator_file_errors++))
                continue
            fi

            # Display errors if any
            if [[ $exit_code -ne 0 && -n "$errors" ]]; then
                echo "  $file:"
                echo "$errors" | while IFS= read -r error; do
                    [[ -n "$error" ]] && echo "    ✗ $error"
                    ((total_errors++))
                    ((validator_file_errors++))
                done
            fi
        done

        # Display validator summary
        if [[ $validator_file_errors -eq 0 ]]; then
            echo "  ✓ All files passed"
        else
            echo "  ✗ $validator_file_errors errors found"
        fi
        echo
    done

    # Calculate duration
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    # Display final summary
    echo "────────────────────────────────────────────────────"
    if [[ $total_errors -eq 0 ]]; then
        _flow_log_success "Summary: All validators passed"
        echo "  Files checked: ${#files[@]}"
        echo "  Validators run: ${#validators_to_run[@]}"
        echo "  Time: ${duration}s"
        return 0
    else
        _flow_log_error "Summary: $total_errors errors found"
        echo "  Files checked: ${#files[@]}"
        echo "  Validators run: ${#validators_to_run[@]}"
        echo "  Time: ${duration}s"
        return 1
    fi
}

# ============================================================================
# VALIDATOR MANAGEMENT
# ============================================================================

# List available validators with metadata
_list_custom_validators() {
    local project_root="${1:-.}"

    local validators
    validators=($(_discover_validators "$project_root"))

    if [[ ${#validators[@]} -eq 0 ]]; then
        _flow_log_info "No custom validators found in $project_root/.teach/validators/"
        return 0
    fi

    echo
    _flow_log_info "Available Custom Validators:"
    echo

    for script in "${validators[@]}"; do
        local name
        name=$(_get_validator_name_from_path "$script")

        # Validate API
        local api_errors
        api_errors=$(_validate_validator_api "$script" 2>&1)
        if [[ $? -ne 0 ]]; then
            echo "  ✗ $name (INVALID API)"
            continue
        fi

        # Load metadata
        local metadata
        metadata=$(_load_validator_metadata "$script")

        local version
        local description
        version=$(echo "$metadata" | grep -o '"version": "[^"]*"' | cut -d'"' -f4)
        description=$(echo "$metadata" | grep -o '"description": "[^"]*"' | cut -d'"' -f4)

        echo "  ✓ $name (v$version)"
        echo "    $description"
        echo
    done
}

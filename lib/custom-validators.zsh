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

# =============================================================================
# Function: _discover_validators
# Purpose: Find all custom validator scripts in .teach/validators/ directory
# =============================================================================
# Arguments:
#   $1 - (optional) Project root directory [default: "."]
#
# Returns:
#   0 - Always succeeds (empty result is valid - no validators configured)
#
# Output:
#   stdout - Validator script paths, one per line (can be captured as array)
#
# Example:
#   validators=($(_discover_validators))
#   validators=($(_discover_validators "/path/to/project"))
#   for v in $(_discover_validators); do echo "Found: $v"; done
#
# Notes:
#   - Looks for *.zsh files in $project_root/.teach/validators/
#   - Returns empty (exit 0) if validators directory doesn't exist
#   - Does not validate API compliance - use _validate_validator_api for that
#   - Uses ZSH glob qualifier (N) to handle no-match gracefully
# =============================================================================
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

# =============================================================================
# Function: _get_validator_name_from_path
# Purpose: Extract clean validator name from script file path
# =============================================================================
# Arguments:
#   $1 - (required) Full path to validator script file
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Validator name without path or .zsh extension
#
# Example:
#   name=$(_get_validator_name_from_path "/path/.teach/validators/check-citations.zsh")
#   # Returns: "check-citations"
#   name=$(_get_validator_name_from_path "validators/check-links.zsh")
#   # Returns: "check-links"
#
# Notes:
#   - Uses basename to strip directory path
#   - Removes .zsh extension from filename
#   - Used for display purposes and validator selection matching
# =============================================================================
_get_validator_name_from_path() {
    local script_path="$1"
    basename "$script_path" .zsh
}

# ============================================================================
# VALIDATOR API VALIDATION
# ============================================================================

# =============================================================================
# Function: _validate_validator_api
# Purpose: Check if a validator script implements the required plugin API
# =============================================================================
# Arguments:
#   $1 - (required) Path to validator script file
#
# Returns:
#   0 - Validator implements all required API components
#   1 - Validator missing required components
#
# Output:
#   stdout - Error messages for missing/invalid components (one per line)
#
# Example:
#   if _validate_validator_api "validators/check-citations.zsh"; then
#       echo "Valid validator"
#   else
#       echo "Invalid validator"
#   fi
#   errors=$(_validate_validator_api "$script") || echo "API errors: $errors"
#
# Notes:
#   - Required API components:
#     * VALIDATOR_NAME (string variable)
#     * VALIDATOR_VERSION (string variable)
#     * VALIDATOR_DESCRIPTION (string variable)
#     * _validate() function
#   - Optional API components:
#     * _validator_init() function - called before validation
#     * _validator_cleanup() function - called after validation
#   - Sources validator in subshell to avoid polluting current environment
# =============================================================================
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

# =============================================================================
# Function: _load_validator_metadata
# Purpose: Extract metadata from validator script without running validation
# =============================================================================
# Arguments:
#   $1 - (required) Path to validator script file
#
# Returns:
#   0 - Always succeeds (may return incomplete JSON if variables missing)
#
# Output:
#   stdout - JSON object with validator metadata:
#            {"name": "...", "version": "...", "description": "...", "script": "..."}
#
# Example:
#   metadata=$(_load_validator_metadata "validators/check-citations.zsh")
#   version=$(echo "$metadata" | jq -r '.version')
#   name=$(echo "$metadata" | grep -o '"name": "[^"]*"' | cut -d'"' -f4)
#
# Notes:
#   - Sources validator in subshell to extract VALIDATOR_* variables
#   - Does not execute _validate() function
#   - Includes full script path in output for reference
#   - Use _validate_validator_api first to ensure required fields exist
# =============================================================================
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

# =============================================================================
# Function: _execute_validator
# Purpose: Run a single validator script on a specified file
# =============================================================================
# Arguments:
#   $1 - (required) Path to validator script file
#   $2 - (required) Path to file to validate
#
# Returns:
#   0 - Validation passed (no errors found)
#   1 - Validation failed (errors found in file)
#   2 - Validator crashed or failed to initialize
#
# Output:
#   stdout - Error messages from validator (one per line)
#   stdout - "FATAL: Validator crashed..." on exit code 2
#
# Example:
#   errors=$(_execute_validator "validators/check-citations.zsh" "lecture.qmd")
#   exit_code=$?
#   if [[ $exit_code -eq 0 ]]; then echo "Passed"; fi
#
# Notes:
#   - Executes validator in isolated subshell for safety
#   - Calls _validator_init() if defined (optional API)
#   - Calls _validate($file) with target file path
#   - Calls _validator_cleanup() if defined (optional API)
#   - Environment variable VALIDATOR_SKIP_EXTERNAL can be set before calling
#   - Exit code 2 indicates internal validator failure (not validation error)
# =============================================================================
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

# =============================================================================
# Function: _aggregate_validator_results
# Purpose: Collect and summarize validation results from multiple validators
# =============================================================================
# Arguments:
#   None - reads from stdin
#
# Input:
#   stdin - Pipe-delimited results: "validator|file|error_message" per line
#
# Returns:
#   0 - All validations passed (no errors in input)
#   1 - One or more validation errors found
#
# Output:
#   stdout - Summary report with error counts per file and validator
#
# Example:
#   echo "check-links|doc.qmd|Broken link on line 42" | _aggregate_validator_results
#   {
#       echo "check-citations|lecture.qmd|Missing citation"
#       echo "check-links|lecture.qmd|Dead link"
#   } | _aggregate_validator_results
#
# Notes:
#   - Expects specific input format: validator|file|error_message
#   - Tracks errors per file and per validator using associative arrays
#   - Displays summary only (individual errors should be shown before aggregation)
#   - Used internally by _run_custom_validators for final summary
# =============================================================================
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

# =============================================================================
# Function: _run_custom_validators
# Purpose: Main orchestrator to run custom validators on specified files
# =============================================================================
# Arguments:
#   --validators <list>  - (optional) Comma-separated validator names to run
#   --skip-external      - (optional) Skip external URL checks (link validator)
#   --project-root <dir> - (optional) Project root directory [default: "."]
#   files...             - (required) One or more files to validate
#
# Returns:
#   0 - All validators passed on all files
#   1 - One or more validation errors found, or no files specified
#
# Output:
#   stdout - Detailed validation progress and results:
#            - Validator headers with version
#            - Per-file error messages
#            - Per-validator pass/fail summary
#            - Final summary with totals and timing
#
# Example:
#   _run_custom_validators lecture.qmd assignment.qmd
#   _run_custom_validators --validators check-citations,check-links *.qmd
#   _run_custom_validators --skip-external --project-root /path/to/course docs/*.qmd
#
# Notes:
#   - Discovers validators from $project_root/.teach/validators/
#   - Validates each validator's API compliance before running
#   - Runs all validators (or selected subset) on each file
#   - Sets VALIDATOR_SKIP_EXTERNAL=1 env var when --skip-external used
#   - Displays timing information in final summary
#   - Returns early with warning if no validators found (exit 0)
# =============================================================================
_run_custom_validators() {
    local selected_validators=()
    local files=()
    local skip_external=0
    local quiet=0
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
            --quiet|-q)
                quiet=1
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
                local script_name=$(_get_validator_name_from_path "$script")
                if [[ "$script_name" == "$selected" ]]; then
                    validators_to_run+=("$script")
                    found=1
                    break
                fi
            done
            if [[ $found -eq 0 && $quiet -eq 0 ]]; then
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
    if [[ $quiet -eq 0 ]]; then
        echo
        _flow_log_info "Running custom validators..."
        if [[ ${#selected_validators[@]} -gt 0 ]]; then
            echo "  Selected: ${(j:, :)selected_validators}"
        else
            echo "  Found: ${#validators_to_run[@]} validators"
        fi
        echo
    fi

    # Validate and run each validator
    local total_errors=0
    local start_time=$(date +%s)
    local -A all_results  # validator|file -> errors

    local validator_name api_errors metadata version validator_file_errors errors exit_code

    for script in "${validators_to_run[@]}"; do
        validator_name=$(_get_validator_name_from_path "$script")

        # Validate API compliance
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
        metadata=$(_load_validator_metadata "$script")
        version=$(echo "$metadata" | grep -o '"version": "[^"]*"' | cut -d'"' -f4)

        # Display validator header
        [[ $quiet -eq 0 ]] && echo "→ $validator_name (v$version)"

        # Run validator on each file
        validator_file_errors=0
        for file in "${files[@]}"; do
            # Skip if file doesn't exist
            if [[ ! -f "$file" ]]; then
                [[ $quiet -eq 0 ]] && echo "  $file:"
                [[ $quiet -eq 0 ]] && echo "    File not found (skipped)"
                continue
            fi

            # Execute validator

            # Pass --skip-external flag to validator if needed
            if [[ $skip_external -eq 1 ]]; then
                export VALIDATOR_SKIP_EXTERNAL=1
            fi

            errors=$(_execute_validator "$script" "$file")
            exit_code=$?

            unset VALIDATOR_SKIP_EXTERNAL

            # Handle validator crash
            if [[ $exit_code -eq 2 ]]; then
                [[ $quiet -eq 0 ]] && echo "  $file:"
                [[ $quiet -eq 0 ]] && echo "    ✗ VALIDATOR CRASHED"
                ((total_errors++))
                ((validator_file_errors++))
                continue
            fi

            # Display errors if any
            if [[ $exit_code -ne 0 && -n "$errors" ]]; then
                [[ $quiet -eq 0 ]] && echo "  $file:"
                echo "$errors" | while IFS= read -r error; do
                    if [[ -n "$error" ]]; then
                        [[ $quiet -eq 0 ]] && echo "    ✗ $error"
                        ((total_errors++))
                        ((validator_file_errors++))
                    fi
                done
            fi
        done

        # Display validator summary
        if [[ $quiet -eq 0 ]]; then
            if [[ $validator_file_errors -eq 0 ]]; then
                echo "  ✓ All files passed"
            else
                echo "  ✗ $validator_file_errors errors found"
            fi
            echo
        fi
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

# =============================================================================
# Function: _list_custom_validators
# Purpose: Display all available custom validators with their metadata
# =============================================================================
# Arguments:
#   $1 - (optional) Project root directory [default: "."]
#
# Returns:
#   0 - Always succeeds (empty list is valid)
#
# Output:
#   stdout - Formatted list of validators showing:
#            - Validator name and version
#            - Description
#            - API validity status (INVALID API if missing required components)
#
# Example:
#   _list_custom_validators
#   _list_custom_validators "/path/to/project"
#
# Notes:
#   - Looks for validators in $project_root/.teach/validators/
#   - Validates API compliance for each validator found
#   - Displays INVALID API warning for non-compliant validators
#   - Uses _discover_validators, _validate_validator_api, _load_validator_metadata
#   - Useful for checking available validators before running validation
# =============================================================================
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

    local name api_errors metadata version description

    for script in "${validators[@]}"; do
        name=$(_get_validator_name_from_path "$script")

        # Validate API
        api_errors=$(_validate_validator_api "$script" 2>&1)
        if [[ $? -ne 0 ]]; then
            echo "  ✗ $name (INVALID API)"
            continue
        fi

        # Load metadata
        metadata=$(_load_validator_metadata "$script")

        version=$(echo "$metadata" | grep -o '"version": "[^"]*"' | cut -d'"' -f4)
        description=$(echo "$metadata" | grep -o '"description": "[^"]*"' | cut -d'"' -f4)

        echo "  ✓ $name (v$version)"
        echo "    $description"
        echo
    done
}

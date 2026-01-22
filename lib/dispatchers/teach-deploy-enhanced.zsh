#!/usr/bin/env zsh
#
# Enhanced Deploy Implementation (v5.14.0 - Quarto Workflow Week 5-7)
# Purpose: Partial deployment with dependency tracking and index management
#
# Features:
# - Partial deploys: teach deploy lectures/week-05.qmd
# - Dependency tracking
# - Index management (ADD/UPDATE/REMOVE)
# - Auto-commit + Auto-tag
# - Cross-reference validation
#

# ============================================================================
# ENHANCED TEACH DEPLOY - WITH PARTIAL DEPLOYMENT SUPPORT
# ============================================================================

_teach_deploy_enhanced() {
    local direct_push=false
    local partial_deploy=false
    local deploy_files=()
    local auto_commit=false
    local auto_tag=false
    local skip_index=false
    local check_prereqs=false

    # Parse flags and files
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --direct-push)
                direct_push=true
                shift
                ;;
            --auto-commit)
                auto_commit=true
                shift
                ;;
            --auto-tag)
                auto_tag=true
                shift
                ;;
            --skip-index)
                skip_index=true
                shift
                ;;
            --check-prereqs|--check-prerequisites)
                check_prereqs=true
                shift
                ;;
            --help|-h|help)
                _teach_deploy_enhanced_help
                return 0
                ;;
            -*)
                _teach_error "Unknown flag: $1" "Run 'teach deploy --help' for usage"
                return 1
                ;;
            *)
                # File argument - enable partial deploy mode
                if [[ -f "$1" ]]; then
                    partial_deploy=true
                    deploy_files+=("$1")
                elif [[ -d "$1" ]]; then
                    # Directory - add all .qmd files in it
                    partial_deploy=true
                    for file in "$1"/**/*.qmd; do
                        [[ -f "$file" ]] && deploy_files+=("$file")
                    done
                else
                    _teach_error "File or directory not found: $1"
                    return 1
                fi
                shift
                ;;
        esac
    done

    # ============================================
    # PRE-FLIGHT CHECKS
    # ============================================

    # Check if in git repo
    if ! _git_in_repo; then
        _teach_error "Not in a git repository" \
            "Initialize git first with: git init"
        return 1
    fi

    # Check if config file exists
    local config_file=".flow/teach-config.yml"
    if [[ ! -f "$config_file" ]]; then
        _teach_error ".flow/teach-config.yml not found" \
            "Run 'teach init' to create the configuration"
        return 1
    fi

    # Read git configuration from teach-config.yml
    local draft_branch prod_branch auto_pr require_clean
    draft_branch=$(yq '.git.draft_branch // .branches.draft // "draft"' "$config_file" 2>/dev/null) || draft_branch="draft"
    prod_branch=$(yq '.git.production_branch // .branches.production // "main"' "$config_file" 2>/dev/null) || prod_branch="main"
    auto_pr=$(yq '.git.auto_pr // true' "$config_file" 2>/dev/null) || auto_pr="true"
    require_clean=$(yq '.git.require_clean // true' "$config_file" 2>/dev/null) || require_clean="true"

    # Read course info
    local course_name
    course_name=$(yq '.course.name // "Teaching Project"' "$config_file" 2>/dev/null) || course_name="Teaching Project"

    echo ""
    echo "${FLOW_COLORS[info]}🔍 Pre-flight Checks${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"

    # Check 1: Verify we're on draft branch
    local current_branch=$(_git_current_branch)
    if [[ "$current_branch" != "$draft_branch" ]]; then
        echo "${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} Not on $draft_branch branch (currently on: $current_branch)"
        echo ""
        echo -n "${FLOW_COLORS[prompt]}Switch to $draft_branch branch? [Y/n]:${FLOW_COLORS[reset]} "
        read -r switch_confirm

        case "$switch_confirm" in
            n|N|no|No|NO)
                return 1
                ;;
            *)
                git checkout "$draft_branch" || {
                    _teach_error "Failed to switch to $draft_branch"
                    return 1
                }
                echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Switched to $draft_branch"
                ;;
        esac
    else
        echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} On $draft_branch branch"
    fi

    # ============================================
    # PREREQUISITE CHECK (if --check-prereqs flag)
    # ============================================
    if [[ "$check_prereqs" == "true" ]]; then
        echo ""
        echo "${FLOW_COLORS[info]}🔍 Prerequisite Validation${FLOW_COLORS[reset]}"
        echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"

        if ! _check_prerequisites_for_deploy; then
            echo ""
            _teach_error "Deploy blocked: Prerequisite validation failed" \
                "Fix missing prerequisites before deploying"
            echo ""
            echo "${FLOW_COLORS[dim]}Tip: Run 'teach validate --deep' to see full details${FLOW_COLORS[reset]}"
            return 1
        fi

        echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} All prerequisites satisfied"
    fi

    # ============================================
    # PARTIAL DEPLOY MODE
    # ============================================

    if [[ "$partial_deploy" == "true" ]]; then
        echo ""
        echo "${FLOW_COLORS[info]}📦 Partial Deploy Mode${FLOW_COLORS[reset]}"
        echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"
        echo ""
        echo "${FLOW_COLORS[bold]}Files to deploy:${FLOW_COLORS[reset]}"
        for file in "${deploy_files[@]}"; do
            echo "  • $file"
        done

        # Validate cross-references
        echo ""
        echo "${FLOW_COLORS[info]}🔗 Validating cross-references...${FLOW_COLORS[reset]}"
        if _validate_cross_references "${deploy_files[@]}"; then
            echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} All cross-references valid"
        else
            echo ""
            echo -n "${FLOW_COLORS[prompt]}Continue with broken references? [y/N]:${FLOW_COLORS[reset]} "
            read -r continue_confirm
            case "$continue_confirm" in
                y|Y|yes|Yes|YES) ;;
                *) return 1 ;;
            esac
        fi

        # Find dependencies
        echo ""
        echo "${FLOW_COLORS[info]}🔍 Finding dependencies...${FLOW_COLORS[reset]}"
        local all_files=()
        local dep_count=0

        for file in "${deploy_files[@]}"; do
            all_files+=("$file")

            # Find dependencies for this file
            local deps=($(_find_dependencies "$file"))

            if [[ ${#deps[@]} -gt 0 ]]; then
                echo "${FLOW_COLORS[dim]}  Dependencies for $file:${FLOW_COLORS[reset]}"
                for dep in "${deps[@]}"; do
                    # Check if dependency is already in deploy list
                    if [[ ! " ${all_files[@]} " =~ " $dep " ]]; then
                        all_files+=("$dep")
                        echo "    • $dep"
                        ((dep_count++))
                    fi
                done
            fi
        done

        if [[ $dep_count -gt 0 ]]; then
            echo ""
            echo "${FLOW_COLORS[info]}Found $dep_count additional dependencies${FLOW_COLORS[reset]}"
            echo -n "${FLOW_COLORS[prompt]}Include dependencies in deployment? [Y/n]:${FLOW_COLORS[reset]} "
            read -r include_deps
            case "$include_deps" in
                n|N|no|No|NO)
                    # Keep only original files
                    all_files=("${deploy_files[@]}")
                    ;;
                *)
                    # Use all files including dependencies
                    deploy_files=("${all_files[@]}")
                    ;;
            esac
        fi

        # Check for uncommitted changes in deploy files
        local uncommitted_files=()
        for file in "${deploy_files[@]}"; do
            if ! git diff --quiet HEAD -- "$file" 2>/dev/null; then
                uncommitted_files+=("$file")
            fi
        done

        # Auto-commit if requested or if there are uncommitted changes
        if [[ ${#uncommitted_files[@]} -gt 0 ]]; then
            echo ""
            echo "${FLOW_COLORS[warn]}⚠️  Uncommitted changes detected${FLOW_COLORS[reset]}"
            echo ""
            for file in "${uncommitted_files[@]}"; do
                echo "  • $file"
            done
            echo ""

            if [[ "$auto_commit" == "true" ]]; then
                # Auto-commit mode
                echo "${FLOW_COLORS[info]}Auto-commit mode enabled${FLOW_COLORS[reset]}"
                local commit_msg="Update: $(date +%Y-%m-%d)"

                git add "${uncommitted_files[@]}"
                git commit -m "$commit_msg"

                echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Auto-committed changes"
            else
                # Prompt for commit
                echo -n "${FLOW_COLORS[prompt]}Commit message (or Enter for auto): ${FLOW_COLORS[reset]}"
                read -r commit_msg

                if [[ -z "$commit_msg" ]]; then
                    commit_msg="Update: $(date +%Y-%m-%d)"
                fi

                git add "${uncommitted_files[@]}"
                git commit -m "$commit_msg"

                echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Committed changes"
            fi
        fi

        # Index management (if not skipped)
        if [[ "$skip_index" == "false" ]]; then
            _process_index_changes "${deploy_files[@]}"

            # Check if index files were modified
            local index_modified=false
            for idx_file in home_lectures.qmd home_labs.qmd home_exams.qmd; do
                if [[ -f "$idx_file" ]] && ! git diff --quiet HEAD -- "$idx_file" 2>/dev/null; then
                    index_modified=true
                    break
                fi
            done

            if [[ "$index_modified" == "true" ]]; then
                echo ""
                echo "${FLOW_COLORS[info]}📝 Committing index changes...${FLOW_COLORS[reset]}"
                git add home_*.qmd
                git commit -m "Update index files"
                echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Index changes committed"
            fi
        fi

        # Push to remote
        echo ""
        echo -n "${FLOW_COLORS[prompt]}Push to origin/$draft_branch? [Y/n]:${FLOW_COLORS[reset]} "
        read -r push_confirm

        case "$push_confirm" in
            n|N|no|No|NO)
                echo "Deployment cancelled"
                return 1
                ;;
            *)
                if _git_push_current_branch; then
                    echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Pushed to origin/$draft_branch"
                else
                    return 1
                fi
                ;;
        esac

        # Auto-tag if requested
        if [[ "$auto_tag" == "true" ]]; then
            local tag="deploy-$(date +%Y-%m-%d-%H%M)"
            git tag "$tag"
            git push origin "$tag"
            echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Tagged as $tag"
        fi

        # Create PR
        if [[ "$auto_pr" == "true" ]]; then
            local pr_title="Deploy: Partial Update"
            local pr_body="Deployed files:\n\n"
            for file in "${deploy_files[@]}"; do
                pr_body+="- $file\n"
            done

            echo ""
            echo -n "${FLOW_COLORS[prompt]}Create pull request? [Y/n]:${FLOW_COLORS[reset]} "
            read -r pr_confirm

            case "$pr_confirm" in
                n|N|no|No|NO)
                    echo "PR creation skipped"
                    ;;
                *)
                    if _git_create_deploy_pr "$draft_branch" "$prod_branch" "$pr_title" "$pr_body"; then
                        echo ""
                        echo "${FLOW_COLORS[success]}✅ Pull Request Created${FLOW_COLORS[reset]}"
                    else
                        return 1
                    fi
                    ;;
            esac
        fi

        echo ""
        echo "${FLOW_COLORS[success]}✅ Partial deployment complete${FLOW_COLORS[reset]}"
        return 0
    fi

    # ============================================
    # FULL SITE DEPLOY MODE (existing behavior)
    # ============================================

    # Fall back to original _teach_deploy implementation
    # This preserves the existing full-site deployment workflow

    # Check 2: Verify no uncommitted changes (if required)
    if [[ "$require_clean" == "true" ]]; then
        if ! _git_is_clean; then
            echo "${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} Uncommitted changes detected"
            echo ""
            echo "  ${FLOW_COLORS[dim]}Commit or stash changes before deploying${FLOW_COLORS[reset]}"
            echo "  ${FLOW_COLORS[dim]}Or disable with: git.require_clean: false${FLOW_COLORS[reset]}"
            return 1
        else
            echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} No uncommitted changes"
        fi
    fi

    # Check 3: Check for unpushed commits
    if _git_has_unpushed_commits; then
        echo "${FLOW_COLORS[warn]}⚠️  ${FLOW_COLORS[reset]} Unpushed commits detected"
        echo ""
        echo -n "${FLOW_COLORS[prompt]}Push to origin/$draft_branch first? [Y/n]:${FLOW_COLORS[reset]} "
        read -r push_confirm

        case "$push_confirm" in
            n|N|no|No|NO)
                echo "${FLOW_COLORS[warn]}Continuing without push...${FLOW_COLORS[reset]}"
                ;;
            *)
                if _git_push_current_branch; then
                    echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Pushed to origin/$draft_branch"
                else
                    return 1
                fi
                ;;
        esac
    else
        echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Remote is up-to-date"
    fi

    # Check 4: Conflict detection
    if _git_detect_production_conflicts "$draft_branch" "$prod_branch"; then
        echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} No conflicts with production"
    else
        echo "${FLOW_COLORS[warn]}⚠️  ${FLOW_COLORS[reset]} Production ($prod_branch) has new commits"
        echo ""
        echo "${FLOW_COLORS[prompt]}Production branch has updates. Rebase first?${FLOW_COLORS[reset]}"
        echo ""
        echo "  ${FLOW_COLORS[dim]}[1]${FLOW_COLORS[reset]} Yes - Rebase $draft_branch onto $prod_branch (Recommended)"
        echo "  ${FLOW_COLORS[dim]}[2]${FLOW_COLORS[reset]} No - Continue anyway (may have merge conflicts in PR)"
        echo "  ${FLOW_COLORS[dim]}[3]${FLOW_COLORS[reset]} Cancel deployment"
        echo ""
        echo -n "${FLOW_COLORS[prompt]}Your choice [1-3]:${FLOW_COLORS[reset]} "
        read -r rebase_choice

        case "$rebase_choice" in
            1)
                if _git_rebase_onto_production "$draft_branch" "$prod_branch"; then
                    echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Rebase successful"
                else
                    return 1
                fi
                ;;
            2)
                echo "${FLOW_COLORS[warn]}Continuing without rebase...${FLOW_COLORS[reset]}"
                ;;
            3|*)
                echo "Deployment cancelled"
                return 1
                ;;
        esac
    fi

    echo ""

    # Generate PR details
    local commit_count=$(_git_get_commit_count "$draft_branch" "$prod_branch")
    local pr_title="Deploy: $course_name Updates"
    local pr_body=$(_git_generate_pr_body "$draft_branch" "$prod_branch")

    # Show PR preview
    echo "${FLOW_COLORS[info]}📋 Pull Request Preview${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"
    echo ""
    echo "${FLOW_COLORS[bold]}Title:${FLOW_COLORS[reset]} $pr_title"
    echo "${FLOW_COLORS[bold]}From:${FLOW_COLORS[reset]} $draft_branch → $prod_branch"
    echo "${FLOW_COLORS[bold]}Commits:${FLOW_COLORS[reset]} $commit_count"
    echo ""

    # Show changes preview
    echo ""
    echo "${FLOW_COLORS[info]}📋 Changes Preview${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"

    local files_changed=$(git diff --name-status "$prod_branch"..."$draft_branch" 2>/dev/null)
    if [[ -n "$files_changed" ]]; then
        echo ""
        echo "${FLOW_COLORS[dim]}Files Changed:${FLOW_COLORS[reset]}"
        while IFS=$'\t' read -r file_status file; do
            case "$file_status" in
                M)  echo "  ${FLOW_COLORS[warn]}M${FLOW_COLORS[reset]}  $file" ;;
                A)  echo "  ${FLOW_COLORS[success]}A${FLOW_COLORS[reset]}  $file" ;;
                D)  echo "  ${FLOW_COLORS[error]}D${FLOW_COLORS[reset]}  $file" ;;
                R*) echo "  ${FLOW_COLORS[info]}R${FLOW_COLORS[reset]}  $file" ;;
                *)  echo "  ${FLOW_COLORS[muted]}$file_status${FLOW_COLORS[reset]}  $file" ;;
            esac
        done <<< "$files_changed"

        local modified=$(echo "$files_changed" | grep -c "^M" || echo 0)
        local added=$(echo "$files_changed" | grep -c "^A" || echo 0)
        local deleted=$(echo "$files_changed" | grep -c "^D" || echo 0)
        local total=$(echo "$files_changed" | wc -l | tr -d ' ')

        echo ""
        echo "${FLOW_COLORS[dim]}Summary: $total files ($added added, $modified modified, $deleted deleted)${FLOW_COLORS[reset]}"
    else
        echo "${FLOW_COLORS[muted]}No changes detected${FLOW_COLORS[reset]}"
    fi

    # Create PR
    echo ""
    if [[ "$auto_pr" == "true" ]]; then
        echo "${FLOW_COLORS[prompt]}Create pull request?${FLOW_COLORS[reset]}"
        echo ""
        echo "  ${FLOW_COLORS[dim]}[1]${FLOW_COLORS[reset]} Yes - Create PR (Recommended)"
        echo "  ${FLOW_COLORS[dim]}[2]${FLOW_COLORS[reset]} Push to $draft_branch only (no PR)"
        echo "  ${FLOW_COLORS[dim]}[3]${FLOW_COLORS[reset]} Cancel"
        echo ""
        echo -n "${FLOW_COLORS[prompt]}Your choice [1-3]:${FLOW_COLORS[reset]} "
        read -r pr_choice

        case "$pr_choice" in
            1)
                echo ""
                if _git_create_deploy_pr "$draft_branch" "$prod_branch" "$pr_title" "$pr_body"; then
                    echo ""
                    echo "${FLOW_COLORS[success]}✅ Pull Request Created${FLOW_COLORS[reset]}"
                else
                    return 1
                fi
                ;;
            2)
                if _git_push_current_branch; then
                    echo ""
                    echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Pushed to origin/$draft_branch"
                else
                    return 1
                fi
                ;;
            3|*)
                echo "Deployment cancelled"
                return 1
                ;;
        esac
    else
        if _git_push_current_branch; then
            echo ""
            echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Pushed to origin/$draft_branch"
        else
            return 1
        fi
    fi
}

# Help for enhanced teach deploy
_teach_deploy_enhanced_help() {
    echo "teach deploy - Deploy teaching content via PR workflow"
    echo ""
    echo "Usage:"
    echo "  teach deploy [files...] [options]"
    echo ""
    echo "Arguments:"
    echo "  files            Files or directories to deploy (partial deploy mode)"
    echo ""
    echo "Options:"
    echo "  --auto-commit       Auto-commit uncommitted changes"
    echo "  --auto-tag          Auto-tag deployment with timestamp"
    echo "  --skip-index        Skip index management prompts"
    echo "  --check-prereqs     Run prerequisite validation before deploy (blocks on errors)"
    echo "  --direct-push       Bypass PR and push directly to production (advanced)"
    echo "  --help, -h          Show this help message"
    echo ""
    echo "Deployment Modes:"
    echo "  Full Site (default):"
    echo "    teach deploy                    # Deploy all changes"
    echo ""
    echo "  Partial Deploy:"
    echo "    teach deploy lectures/week-05.qmd    # Deploy single file"
    echo "    teach deploy lectures/               # Deploy entire directory"
    echo "    teach deploy file1.qmd file2.qmd     # Deploy multiple files"
    echo ""
    echo "Features:"
    echo "  • Dependency tracking (sourced files, cross-references)"
    echo "  • Index management (ADD/UPDATE/REMOVE links)"
    echo "  • Cross-reference validation"
    echo "  • Auto-commit with custom message"
    echo "  • Auto-tag with timestamp"
    echo ""
    echo "Examples:"
    echo "  # Partial deploy with auto features"
    echo "  teach deploy lectures/week-05.qmd --auto-commit --auto-tag"
    echo ""
    echo "  # Deploy directory with index updates"
    echo "  teach deploy lectures/"
    echo ""
    echo "  # Full site deploy (traditional workflow)"
    echo "  teach deploy"
    echo ""
    echo "  # Deploy with prerequisite validation"
    echo "  teach deploy --check-prereqs"
}

# ============================================================================
# PREREQUISITE VALIDATION FOR DEPLOY
# ============================================================================

# Check prerequisites before deploy
# Returns 0 if no errors, 1 if missing prerequisites (errors) found
# Warnings (future prerequisites) do NOT block deploy
_check_prerequisites_for_deploy() {
    local course_dir="$PWD"

    # Source concept extraction if not loaded
    if ! typeset -f _build_concept_graph >/dev/null 2>&1; then
        local concept_path="${0:A:h:h}/concept-extraction.zsh"
        [[ -f "$concept_path" ]] && source "$concept_path"
    fi

    # Source prerequisite checker if not loaded
    if ! typeset -f _check_prerequisites >/dev/null 2>&1; then
        local prereq_path="${0:A:h:h}/prerequisite-checker.zsh"
        [[ -f "$prereq_path" ]] && source "$prereq_path"
    fi

    # Source analysis cache if not loaded (for cache support)
    if ! typeset -f _cache_read >/dev/null 2>&1; then
        local cache_path="${0:A:h:h}/analysis-cache.zsh"
        [[ -f "$cache_path" ]] && source "$cache_path"
    fi

    # Try to use cached concept graph first
    local graph_json=""
    local use_cache=0

    if typeset -f _cache_read >/dev/null 2>&1; then
        local cached_graph
        cached_graph=$(_cache_read "concepts-graph" "$course_dir" 2>/dev/null)
        if [[ -n "$cached_graph" && "$cached_graph" != "null" ]]; then
            graph_json="$cached_graph"
            use_cache=1
            echo "${FLOW_COLORS[dim]}  Using cached concept graph${FLOW_COLORS[reset]}"
        fi
    fi

    if [[ $use_cache -eq 0 ]]; then
        # Build concept graph fresh
        echo "${FLOW_COLORS[dim]}  Building concept graph...${FLOW_COLORS[reset]}"

        local graph_file
        graph_file=$(_build_concept_graph "$course_dir" 2>/dev/null)

        if [[ -z "$graph_file" || ! -f "$graph_file" ]]; then
            # No concepts found - not an error, just no validation needed
            echo "${FLOW_COLORS[dim]}  No concept metadata found - skipping validation${FLOW_COLORS[reset]}"
            return 0
        fi

        graph_json=$(cat "$graph_file")
        rm -f "$graph_file"

        # Cache for future use
        if typeset -f _cache_write >/dev/null 2>&1; then
            _cache_write "concepts-graph" "$graph_json" "$course_dir" 2>/dev/null
        fi
    fi

    # Check concept count
    local concept_count
    concept_count=$(echo "$graph_json" | jq '.metadata.total_concepts // 0' 2>/dev/null)

    if [[ "$concept_count" -eq 0 ]]; then
        echo "${FLOW_COLORS[dim]}  No concepts defined - skipping validation${FLOW_COLORS[reset]}"
        return 0
    fi

    echo "${FLOW_COLORS[dim]}  Checking $concept_count concepts...${FLOW_COLORS[reset]}"

    # Convert graph to course_data format
    local course_data
    course_data=$(echo "$graph_json" | jq '
        .concepts | to_entries |
        group_by(.value.introduced_in.week) |
        map({
            week_num: .[0].value.introduced_in.week,
            concepts: map({
                id: .key,
                prerequisites: .value.prerequisites
            })
        }) |
        {weeks: sort_by(.week_num)}
    ' 2>/dev/null)

    # Check prerequisites
    local violations_json raw_output
    raw_output=$(_check_prerequisites "$course_data" 2>/dev/null)
    violations_json=$(echo "$raw_output" | awk '/^\[/,/^\]/' | jq -c '.' 2>/dev/null)
    [[ -z "$violations_json" || "$violations_json" == "null" ]] && violations_json="[]"

    # Count errors (missing prerequisites) - these block deploy
    local error_count=0
    local warning_count=0

    if [[ -n "$violations_json" && "$violations_json" != "[]" ]]; then
        error_count=$(echo "$violations_json" | jq '[.[] | select(.type == "missing")] | length' 2>/dev/null || echo "0")
        warning_count=$(echo "$violations_json" | jq '[.[] | select(.type == "future")] | length' 2>/dev/null || echo "0")
    fi

    # Report results
    if [[ "$error_count" -gt 0 ]]; then
        echo ""
        echo "${FLOW_COLORS[error]}✗ Found $error_count missing prerequisite(s)${FLOW_COLORS[reset]}"

        # Show violations
        echo "$violations_json" | jq -r '.[] | select(.type == "missing") | "  • \(.concept_id) requires \(.prerequisite_id) (not defined)"' 2>/dev/null
        return 1
    fi

    if [[ "$warning_count" -gt 0 ]]; then
        echo "${FLOW_COLORS[warn]}⚠ Found $warning_count future prerequisite(s) (warnings only)${FLOW_COLORS[reset]}"
        # Warnings do not block deploy
    fi

    return 0
}

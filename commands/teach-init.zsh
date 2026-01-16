# commands/teach-init.zsh - Teaching workflow initialization
# Scaffolds teaching workflow in existing or new course repository

# ============================================================================
# TEACH-INIT COMMAND
# ============================================================================

teach-init() {
  local course_name=""
  local dry_run=false
  local interactive=true
  local skip_git=false  # Phase 5 - v5.11.0

  # Parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help|help)
        _teach_init_help
        return 0
        ;;
      --dry-run)
        dry_run=true
        shift
        ;;
      -y|--yes)
        interactive=false
        shift
        ;;
      --no-git)  # Phase 5 - v5.11.0
        skip_git=true
        shift
        ;;
      *)
        course_name="$1"
        shift
        ;;
    esac
  done

  # Export for child functions
  export TEACH_INTERACTIVE="$interactive"
  export TEACH_SKIP_GIT="$skip_git"  # Phase 5 - v5.11.0

  if [[ -z "$course_name" ]]; then
    _flow_log_error "Usage: teach-init [OPTIONS] <course-name>"
    echo ""
    echo "Options:"
    echo "  --dry-run    Preview migration plan without making changes"
    echo "  -y, --yes    Non-interactive mode (accept safe defaults)"
    echo "  --no-git     Skip git initialization (Phase 5 - v5.11.0)"
    echo ""
    echo "Examples:"
    echo "  teach-init \"STAT 545\"              # Interactive (default)"
    echo "  teach-init -y \"STAT 545\"           # Non-interactive, safe defaults"
    echo "  teach-init --dry-run \"STAT 545\"    # Preview migration plan"
    echo "  teach-init --no-git \"STAT 545\"     # Skip git setup"
    return 1
  fi

  # Show mode indicator for non-interactive
  if [[ "$interactive" == "false" ]]; then
    echo "🤖 Non-interactive mode: using safe defaults"
    echo ""
  fi

  # Dry-run mode: show plan and exit
  if [[ "$dry_run" == "true" ]]; then
    echo "🔍 DRY RUN MODE - No changes will be made"
    echo ""
    # Check if already initialized
    if _teach_is_already_initialized; then
      echo "┌────────────────────────────────────────────────────────────┐"
      echo "│ ✅ Teaching workflow already initialized!"
      echo "├────────────────────────────────────────────────────────────┤"
      echo "│"
      echo "│ Status:"
      echo "│   ✅ .flow/teach-config.yml exists"
      echo "│   ✅ draft branch exists"
      echo "│   ✅ production branch exists"
      echo "│"
      echo "│ No migration needed. To start working:"
      echo "│   work $(basename "$PWD" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"
      echo "│"
      echo "└────────────────────────────────────────────────────────────┘"
      return 0
    fi
    _teach_show_migration_plan "$course_name"
    return 0
  fi

  echo "🎓 Initializing teaching workflow for: $course_name"
  echo ""

  # Check if already initialized
  if _teach_is_already_initialized; then
    _flow_log_warning "Teaching workflow already initialized!"
    echo ""
    echo "  ✅ .flow/teach-config.yml exists"
    echo "  ✅ draft and production branches exist"
    echo ""
    echo "To reconfigure, manually edit:"
    echo "  \$EDITOR .flow/teach-config.yml"
    echo ""
    echo "To start working:"
    echo "  work $(basename "$PWD" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"
    return 0
  fi

  # Check dependencies
  if ! command -v yq &>/dev/null; then
    _flow_log_error "yq is required"
    echo "Install: brew install yq"
    return 1
  fi

  # Detect git state
  if [[ -d .git ]]; then
    _teach_migrate_existing_repo "$course_name"
  else
    _teach_create_fresh_repo "$course_name"
  fi
}

# Help function for teach-init
_teach_init_help() {
  echo "${FLOW_COLORS[bold]}teach-init${FLOW_COLORS[reset]} - Initialize teaching workflow for course websites"
  echo ""
  echo "${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
  echo "  teach-init [OPTIONS] <course-name>"
  echo ""
  echo "${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}"
  echo "  -h, --help     Show this help message"
  echo "  --dry-run      Preview migration plan without making changes"
  echo "  -y, --yes      Non-interactive mode (accept safe defaults)"
  echo "  --no-git       Skip git initialization (Phase 5 - v5.11.0)"
  echo ""
  echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
  echo "  teach-init \"STAT 545\"              # Interactive (default)"
  echo "  teach-init -y \"STAT 545\"           # Non-interactive, safe defaults"
  echo "  teach-init --dry-run \"STAT 545\"    # Preview migration plan"
  echo "  teach-init --no-git \"STAT 545\"     # Skip git setup"
  echo ""
  echo "${FLOW_COLORS[bold]}SAFE DEFAULTS (non-interactive)${FLOW_COLORS[reset]}"
  echo "  • Strategy 1: In-place conversion (preserves history)"
  echo "  • Auto-exclude renv/ from git"
  echo "  • Skip GitHub push (push manually later)"
  echo "  • Use auto-suggested semester start date"
  echo "  • Skip break configuration"
  echo ""
  echo "${FLOW_COLORS[bold]}DOCUMENTATION${FLOW_COLORS[reset]}"
  echo "  https://data-wise.github.io/flow-cli/commands/teach-init/"
}

# ============================================================================
# PHASE 1: DETECTION AND VALIDATION (v5.4.0)
# ============================================================================

# Check if teaching workflow is already initialized
# Returns 0 if already initialized, 1 otherwise
_teach_is_already_initialized() {
  # Check for config file
  [[ ! -f ".flow/teach-config.yml" ]] && return 1

  # Check for both branches (only if in git repo)
  if [[ -d .git ]]; then
    local has_draft=$(git branch --list draft 2>/dev/null)
    local has_production=$(git branch --list production 2>/dev/null)
    [[ -z "$has_draft" || -z "$has_production" ]] && return 1
  fi

  return 0
}

# Detect project type based on presence of config files
_teach_detect_project_type() {
  if [[ -f "_quarto.yml" ]]; then
    echo "quarto"
  elif [[ -f "mkdocs.yml" ]]; then
    echo "mkdocs"
  else
    echo "unknown"
  fi
}

# Validate Quarto project structure
# Returns 0 on success, 1 on failure
_teach_validate_quarto_project() {
  local errors=()

  # Check required files
  [[ ! -f "_quarto.yml" ]] && errors+=("Missing _quarto.yml")
  [[ ! -f "index.qmd" ]] && errors+=("Missing index.qmd (homepage)")

  # Report errors if any
  if (( ${#errors[@]} > 0 )); then
    _flow_log_error "Project validation failed:"
    printf '  %s\n' "${errors[@]}"
    return 1
  fi

  return 0
}

# Handle renv/ directories interactively
# Prompts user to exclude from git if detected (auto-excludes in non-interactive mode)
_teach_handle_renv() {
  if [[ -d "renv" ]]; then
    echo ""
    echo "  ${FLOW_COLORS[warning]}⚠️  Detected renv/ directory${FLOW_COLORS[reset]}"
    echo "  R package management with symlinks (not suitable for git)"

    local exclude_renv="y"
    if [[ "$TEACH_INTERACTIVE" != "false" ]]; then
      echo ""
      read "?  Exclude renv/ from git? [Y/n]: " exclude_renv
    else
      echo "  → Auto-excluding renv/ (non-interactive mode)"
    fi

    if [[ "$exclude_renv" != "n" ]]; then
      # Check if already in .gitignore
      if [[ -f ".gitignore" ]] && grep -q "^renv/$" .gitignore; then
        echo "  ℹ️  renv/ already in .gitignore"
      else
        echo "renv/" >> .gitignore
        echo "  ✅ Added renv/ to .gitignore"
      fi
    else
      echo "  ⚠️  Warning: renv/ will be included in git (may cause backup issues)"
    fi
  fi
}

# Rollback failed migration to pre-migration tag
# Usage: _teach_rollback_migration <tag_name>
_teach_rollback_migration() {
  local tag="$1"

  if [[ -z "$tag" ]]; then
    _flow_log_error "Rollback failed: no tag specified"
    return 1
  fi

  _flow_log_error "Migration failed - rolling back to $tag"
  echo ""

  # Reset to tag
  if git reset --hard "$tag" 2>/dev/null; then
    echo "  ✅ Reset to tag: $tag"
  else
    _flow_log_error "Failed to reset to tag: $tag"
    return 1
  fi

  # Remove created files
  if [[ -d ".flow" ]]; then
    rm -rf .flow
    echo "  ✅ Removed .flow/ directory"
  fi

  if [[ -d "scripts" ]]; then
    rm -rf scripts
    echo "  ✅ Removed scripts/ directory"
  fi

  if [[ -f ".github/workflows/deploy.yml" ]]; then
    rm -f .github/workflows/deploy.yml
    echo "  ✅ Removed .github/workflows/deploy.yml"
  fi

  # Delete rollback tag
  if git tag -d "$tag" &>/dev/null; then
    echo "  ✅ Deleted rollback tag"
  fi

  echo ""
  echo "Your repository is back to its original state."
  return 0
}

# Show migration plan for dry-run mode
_teach_show_migration_plan() {
  local course_name="$1"

  echo "┌────────────────────────────────────────────────────────────┐"
  echo "│ Migration Plan for: $course_name"
  echo "├────────────────────────────────────────────────────────────┤"
  echo "│"

  # Detection
  echo "│ Detection:"
  if [[ -d .git ]]; then
    echo "│   ✅ Git repository found"
    local current_branch=$(git branch --show-current 2>/dev/null)
    echo "│   ✅ Current branch: $current_branch"

    local project_type=$(_teach_detect_project_type)
    case "$project_type" in
      quarto)
        echo "│   ✅ Project type: Quarto website"
        ;;
      mkdocs)
        echo "│   ✅ Project type: MkDocs website"
        ;;
      *)
        echo "│   ℹ️  Project type: Generic git repository"
        ;;
    esac
  else
    echo "│   ❌ No git repository - would initialize"
  fi

  # Validation (if Quarto)
  echo "│"
  echo "│ Validation:"
  local project_type=$(_teach_detect_project_type)
  if [[ "$project_type" == "quarto" ]]; then
    [[ -f "_quarto.yml" ]] && echo "│   ✅ _quarto.yml found" || echo "│   ❌ _quarto.yml missing"
    [[ -f "index.qmd" ]] && echo "│   ✅ index.qmd found" || echo "│   ❌ index.qmd missing"
    [[ -d "renv" ]] && echo "│   ⚠️  renv/ detected (will prompt to exclude)"
  else
    echo "│   ℹ️  Standard migration (not Quarto-specific)"
  fi

  # Actions
  echo "│"
  echo "│ Actions that would be taken:"
  echo "│   1. Create rollback tag: $(date +'%B' | tr '[:upper:]' '[:lower:]')-$(date +'%Y')-pre-migration"

  if [[ -d .git ]]; then
    local current_branch=$(git branch --show-current 2>/dev/null)
    echo "│   2. Rename $current_branch → production"
  else
    echo "│   2. Initialize git repository"
  fi

  echo "│   3. Create draft branch from production"
  echo "│   4. Add .flow/teach-config.yml"
  echo "│   5. Add scripts/quick-deploy.sh"
  echo "│   6. Add scripts/semester-archive.sh"
  echo "│   7. Add .github/workflows/deploy.yml"
  echo "│   8. Prompt for semester dates"
  echo "│   9. Prompt for GitHub push (optional)"
  echo "│  10. Generate MIGRATION-COMPLETE.md"
  echo "│"
  echo "│ Estimated time: ~3 minutes"
  echo "│"
  echo "│ To execute for real:"
  echo "│   teach-init \"$course_name\""
  echo "│"
  echo "└────────────────────────────────────────────────────────────┘"
}

# ============================================================================
# MIGRATION STRATEGIES
# ============================================================================

_teach_migrate_existing_repo() {
  local course_name="$1"

  echo "📋 Detected existing git repository"
  echo ""

  # Check current branch
  local current_branch=$(git branch --show-current)
  echo "Current branch: $current_branch"
  echo ""

  # Detect project type
  local project_type=$(_teach_detect_project_type)

  case "$project_type" in
    quarto)
      echo "📚 Detected: Quarto website"
      echo ""
      _teach_migrate_quarto_project "$course_name"
      ;;
    mkdocs)
      echo "📚 Detected: MkDocs website"
      echo ""
      _flow_log_warning "MkDocs support coming soon - using generic migration"
      _teach_migrate_generic_repo "$course_name"
      ;;
    *)
      echo "📚 Detected: Generic git repository"
      echo ""
      _teach_migrate_generic_repo "$course_name"
      ;;
  esac
}

# Quarto-specific migration with validation and safety
_teach_migrate_quarto_project() {
  local course_name="$1"

  # Step 1: Validate Quarto project structure
  echo "Validating Quarto project..."
  if ! _teach_validate_quarto_project; then
    echo ""
    _flow_log_error "Migration cannot proceed - fix validation errors first"
    return 1
  fi
  echo "✅ Validation passed"
  echo ""

  # Step 2: Handle renv/ directories
  _teach_handle_renv

  # Step 3: Show migration strategy options
  local current_branch=$(git branch --show-current)
  local choice=""

  if [[ "$TEACH_INTERACTIVE" == "false" ]]; then
    # Non-interactive: auto-select strategy 1 (safest - preserves history)
    echo ""
    echo "→ Auto-selecting strategy 1: Convert existing → production (non-interactive mode)"
    choice="1"
  else
    echo ""
    echo "Choose migration strategy:"
    echo "  ${FLOW_COLORS[bold]}1.${FLOW_COLORS[reset]} Convert existing branch → production (preserve history)"
    echo "     Renames $current_branch → production, creates draft"
    echo ""
    echo "  ${FLOW_COLORS[bold]}2.${FLOW_COLORS[reset]} Create parallel branches (keep existing + add draft/production)"
    echo "     Keeps $current_branch, adds new draft + production branches"
    echo ""
    echo "  ${FLOW_COLORS[bold]}3.${FLOW_COLORS[reset]} Fresh start (tag current, start new structure)"
    echo "     Tags current state, creates clean draft + production"
    echo ""

    read "choice?Choice [1/2/3]: "
  fi

  case "$choice" in
    1) _teach_quarto_inplace_conversion "$course_name" ;;
    2) _teach_quarto_parallel_branches "$course_name" ;;
    3) _teach_quarto_fresh_start "$course_name" ;;
    *)
      echo "Invalid choice"
      return 1
      ;;
  esac
}

# Strategy 1: Convert existing branch → production
_teach_quarto_inplace_conversion() {
  local course_name="$1"
  local current_branch=$(git branch --show-current)

  echo ""
  echo "⚠️  This will:"
  echo "  1. Create rollback tag (safe recovery point)"
  echo "  2. Rename $current_branch → production"
  echo "  3. Create new draft branch from production"
  echo "  4. Add .flow/teach-config.yml and scripts/"
  echo ""

  if [[ "$TEACH_INTERACTIVE" != "false" ]]; then
    read "confirm?Continue? [y/N] "
    if [[ "$confirm" != "y" ]]; then
      echo "Cancelled"
      return 1
    fi
  else
    echo "→ Proceeding automatically (non-interactive mode)"
  fi

  # Create rollback tag
  local semester=$(date +"%B" | sed 's/January\|February\|March\|April\|May/spring/; s/June\|July/summer/; s/August\|September\|October\|November\|December/fall/')
  local year=$(date +%Y)
  local rollback_tag="$semester-$year-pre-migration"

  echo ""
  echo "Creating rollback tag: $rollback_tag"
  if ! git tag -a "$rollback_tag" -m "Pre-migration snapshot (Quarto)" 2>&1; then
    _flow_log_error "Failed to create rollback tag"
    return 1
  fi

  # Execute migration with error trapping
  (
    echo "Renaming $current_branch → production..."
    git branch -m "$current_branch" production || exit 1

    echo "Creating draft branch..."
    git checkout -b draft production || exit 1

    echo "Installing templates..."
    _teach_install_templates "$course_name" || exit 1

    echo "Offering GitHub push..."
    _teach_offer_github_push || exit 1

    echo "Generating documentation..."
    _teach_generate_migration_docs "$course_name" || exit 1
  ) || {
    # ROLLBACK on any error
    echo ""
    _flow_log_error "Migration failed at step above"
    _teach_rollback_migration "$rollback_tag"
    return 1
  }

  echo ""
  echo "✅ Migration complete"
  _teach_show_completion_summary "$course_name" "$rollback_tag" "$current_branch"
}

# Strategy 2: Create parallel branches
_teach_quarto_parallel_branches() {
  local course_name="$1"
  local current_branch=$(git branch --show-current)

  echo ""
  echo "⚠️  This will:"
  echo "  1. Create rollback tag"
  echo "  2. Keep $current_branch as-is"
  echo "  3. Create new production branch"
  echo "  4. Create new draft branch"
  echo "  5. Add teaching workflow files"
  echo ""

  if [[ "$TEACH_INTERACTIVE" != "false" ]]; then
    read "confirm?Continue? [y/N] "
    if [[ "$confirm" != "y" ]]; then
      echo "Cancelled"
      return 1
    fi
  else
    echo "→ Proceeding automatically (non-interactive mode)"
  fi

  # Create rollback tag
  local semester=$(date +"%B" | sed 's/January\|February\|March\|April\|May/spring/; s/June\|July/summer/; s/August\|September\|October\|November\|December/fall/')
  local year=$(date +%Y)
  local rollback_tag="$semester-$year-pre-migration"

  echo ""
  echo "Creating rollback tag: $rollback_tag"
  if ! git tag -a "$rollback_tag" -m "Pre-migration snapshot (Quarto)" 2>&1; then
    _flow_log_error "Failed to create rollback tag"
    return 1
  fi

  # Execute migration with error trapping
  (
    echo "Creating production branch..."
    git checkout -b production || exit 1

    echo "Creating draft branch..."
    git checkout -b draft || exit 1

    echo "Installing templates..."
    _teach_install_templates "$course_name" || exit 1

    echo "Offering GitHub push..."
    _teach_offer_github_push || exit 1

    echo "Generating documentation..."
    _teach_generate_migration_docs "$course_name" || exit 1
  ) || {
    # ROLLBACK on any error
    echo ""
    _flow_log_error "Migration failed at step above"
    _teach_rollback_migration "$rollback_tag"
    return 1
  }

  echo ""
  echo "✅ Migration complete"
  _teach_show_completion_summary "$course_name" "$rollback_tag" "$current_branch"
}

# Strategy 3: Fresh start
_teach_quarto_fresh_start() {
  local course_name="$1"
  local current_branch=$(git branch --show-current)

  echo ""
  echo "⚠️  This will:"
  echo "  1. Tag current state as archive"
  echo "  2. Create orphan 'production' branch (clean history)"
  echo "  3. Create draft branch from production"
  echo "  4. Add teaching workflow files"
  echo ""

  if [[ "$TEACH_INTERACTIVE" != "false" ]]; then
    read "confirm?Continue? [y/N] "
    if [[ "$confirm" != "y" ]]; then
      echo "Cancelled"
      return 1
    fi
  else
    echo "→ Proceeding automatically (non-interactive mode)"
  fi

  # Create archive tag
  local semester=$(date +"%B" | sed 's/January\|February\|March\|April\|May/spring/; s/June\|July/summer/; s/August\|September\|October\|November\|December/fall/')
  local year=$(date +%Y)
  local archive_tag="$semester-$year-archive"

  echo ""
  echo "Creating archive tag: $archive_tag"
  if ! git tag -a "$archive_tag" -m "Pre-fresh-start archive" 2>&1; then
    _flow_log_error "Failed to create archive tag"
    return 1
  fi

  # Execute migration with error trapping
  (
    echo "Creating orphan production branch..."
    git checkout --orphan production || exit 1

    echo "Creating draft branch..."
    git checkout -b draft production || exit 1

    echo "Installing templates..."
    _teach_install_templates "$course_name" || exit 1

    echo "Offering GitHub push..."
    _teach_offer_github_push || exit 1

    echo "Generating documentation..."
    _teach_generate_migration_docs "$course_name" || exit 1
  ) || {
    # ROLLBACK on any error
    echo ""
    _flow_log_error "Migration failed at step above"
    _flow_log_warning "Returning to original branch"
    git checkout "$current_branch"
    git tag -d "$archive_tag" &>/dev/null
    return 1
  }

  echo ""
  echo "✅ Migration complete (fresh start)"
  echo "💡 Original history preserved in tag: $archive_tag"
  _teach_show_completion_summary "$course_name" "$archive_tag" "$current_branch"
}

# Generic migration for non-Quarto projects
_teach_migrate_generic_repo() {
  local course_name="$1"
  local current_branch=$(git branch --show-current)
  local choice=""

  if [[ "$TEACH_INTERACTIVE" == "false" ]]; then
    # Non-interactive: auto-select strategy 1 (in-place conversion)
    echo "→ Auto-selecting strategy 1: In-place conversion (non-interactive mode)"
    choice="1"
  else
    # Strategy menu (original behavior)
    echo "Choose migration strategy:"
    echo "  ${FLOW_COLORS[bold]}1.${FLOW_COLORS[reset]} In-place conversion (rename $current_branch → production, create draft)"
    echo "  ${FLOW_COLORS[bold]}2.${FLOW_COLORS[reset]} Two-branch setup (keep $current_branch, create draft + production)"
    echo ""

    read "choice?Choice [1/2]: "
  fi

  case "$choice" in
    1) _teach_inplace_conversion "$course_name" ;;
    2) _teach_two_branch_setup "$course_name" ;;
    *) echo "Invalid choice"; return 1 ;;
  esac
}

_teach_inplace_conversion() {
  local course_name="$1"
  local current_branch=$(git branch --show-current)

  echo ""
  echo "⚠️  This will:"
  echo "  1. Rename $current_branch → production"
  echo "  2. Create new draft branch from production"
  echo "  3. Add .flow/teach-config.yml and scripts/"
  echo ""

  if [[ "$TEACH_INTERACTIVE" != "false" ]]; then
    read "confirm?Continue? [y/N] "
    if [[ "$confirm" != "y" ]]; then
      echo "Cancelled"
      return 1
    fi
  else
    echo "→ Proceeding automatically (non-interactive mode)"
  fi

  # Tag current state
  local semester=$(date +"%B" | sed 's/January\|February\|March\|April\|May/spring/; s/June\|July/summer/; s/August\|September\|October\|November\|December/fall/')
  local year=$(date +%Y)
  local rollback_tag="$semester-$year-pre-migration"
  git tag -a "$rollback_tag" -m "Pre-migration snapshot"

  # Rename to production
  git branch -m "$current_branch" production
  git push -u origin production

  # Create draft from production
  git checkout -b draft production
  git push -u origin draft

  # Install templates
  _teach_install_templates "$course_name"

  echo ""
  echo "✅ Migration complete"
  _teach_show_completion_summary "$course_name" "$rollback_tag" "$current_branch"
}

_teach_two_branch_setup() {
  local course_name="$1"
  local current_branch=$(git branch --show-current)

  # Create production and draft branches
  git checkout -b production
  git push -u origin production

  git checkout -b draft
  git push -u origin draft

  # Install templates
  _teach_install_templates "$course_name"

  echo ""
  echo "✅ Two-branch setup complete"
  # No rollback tag for two-branch setup (existing branch preserved)
  _teach_show_completion_summary "$course_name" "" "$current_branch"
}

# ============================================================================
# TEMPLATE INSTALLATION
# ============================================================================

_teach_install_templates() {
  local course_name="$1"

  # Create directory structure
  mkdir -p .flow scripts .github/workflows || {
    _flow_log_error "Failed to create directory structure"
    return 1
  }

  # Get template directory from flow-cli
  local template_dir="${FLOW_PLUGIN_DIR}/lib/templates/teaching"

  # Verify template directory exists
  if [[ ! -d "$template_dir" ]]; then
    _flow_log_error "Template directory not found: $template_dir"
    return 1
  fi

  # Copy script templates with error checking
  cp "$template_dir/quick-deploy.sh" scripts/ || {
    _flow_log_error "Failed to copy quick-deploy.sh"
    return 1
  }

  cp "$template_dir/semester-archive.sh" scripts/ || {
    _flow_log_error "Failed to copy semester-archive.sh"
    return 1
  }

  cp "$template_dir/exam-to-qti.sh" scripts/ || {
    _flow_log_error "Failed to copy exam-to-qti.sh"
    return 1
  }

  chmod +x scripts/*.sh || {
    _flow_log_error "Failed to set script permissions"
    return 1
  }

  # Copy GitHub Actions workflow
  cp "$template_dir/deploy.yml.template" .github/workflows/deploy.yml || {
    _flow_log_error "Failed to copy deploy.yml template"
    return 1
  }

  # Generate config (Increment 2: Course Context)
  local course_slug=$(echo "$course_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
  local semester=$(date +"%B" | sed 's/January\|February\|March\|April\|May/spring/; s/June\|July/summer/; s/August\|September\|October\|November\|December/fall/')
  local year=$(date +%Y)
  local generated_date=$(date +"%Y-%m-%d")

  # Prompt for semester dates (Increment 2)
  echo ""
  echo "${FLOW_COLORS[bold]}Semester Schedule${FLOW_COLORS[reset]}"
  echo "  Configure semester start/end dates for week calculation"

  # Suggest start date based on current month
  local suggested_start=$(_suggest_semester_start)
  local start_date=""
  local add_break=""

  if [[ "$TEACH_INTERACTIVE" == "false" ]]; then
    # Non-interactive: use suggested defaults
    echo "  → Using default start date: $suggested_start (non-interactive mode)"
    start_date="$suggested_start"
  else
    echo ""
    read "start_date?  Start date (YYYY-MM-DD) [$suggested_start]: "
    start_date="${start_date:-$suggested_start}"

    # Validate date format
    if ! _validate_date_format "$start_date"; then
      _flow_log_error "Invalid date format. Please use YYYY-MM-DD"
      return 1
    fi
  fi

  # Calculate semester end (16 weeks from start)
  local end_date=$(_calculate_semester_end "$start_date")

  echo "  ${FLOW_COLORS[info]}Calculated end date: $end_date (16 weeks)${FLOW_COLORS[reset]}"

  # Ask about breaks (skip in non-interactive mode)
  local breaks_config=""
  if [[ "$TEACH_INTERACTIVE" != "false" ]]; then
    echo ""
    read "?  Add spring/fall break? [y/N]: " add_break

    if [[ "$add_break" == "y" ]]; then
      echo ""
      read "break_name?  Break name [Spring Break]: "
      break_name="${break_name:-Spring Break}"

      # Calculate week 8 as suggested break time
      local start_epoch=$(date -j -f "%Y-%m-%d" "$start_date" "+%s")
      local break_start_epoch=$((start_epoch + (7 * 7 * 86400)))
      local break_end_epoch=$((break_start_epoch + (7 * 86400)))
      local suggested_break_start=$(date -j -f "%s" "$break_start_epoch" "+%Y-%m-%d")
      local suggested_break_end=$(date -j -f "%s" "$break_end_epoch" "+%Y-%m-%d")

      read "break_start?  Break start [$suggested_break_start]: "
      break_start="${break_start:-$suggested_break_start}"

      read "break_end?  Break end [$suggested_break_end]: "
      break_end="${break_end:-$suggested_break_end}"
    fi
  else
    echo "  → Skipping break configuration (non-interactive mode)"
    add_break="n"
  fi

  # Read template and substitute variables
  local config_template=$(cat "$template_dir/teach-config.yml.template" 2>/dev/null) || {
    _flow_log_error "Failed to read config template"
    return 1
  }

  # Perform substitutions
  echo "$config_template" | \
    sed "s/{{COURSE_NAME}}/$course_name/g" | \
    sed "s/{{COURSE_FULL_NAME}}/$course_name/g" | \
    sed "s/{{COURSE_SLUG}}/$course_slug/g" | \
    sed "s/{{SEMESTER}}/$semester/g" | \
    sed "s/{{YEAR}}/$year/g" | \
    sed "s/{{INSTRUCTOR}}/$USER/g" | \
    sed "s/{{GENERATED_DATE}}/$generated_date/g" | \
    sed "s/{{START_DATE}}/$start_date/g" | \
    sed "s/{{END_DATE}}/$end_date/g" \
    > .flow/teach-config.yml || {
    _flow_log_error "Failed to generate config file"
    return 1
  }

  # Handle breaks config (multiline replacement)
  # Fix for macOS sed: use backslash-escaped newlines instead of literal newlines
  if [[ "$add_break" == "y" ]]; then
    # Replace placeholder with actual breaks config (escaped newlines for macOS sed)
    sed -i '' "s|{{BREAKS_CONFIG}}|  breaks:\\
    - name: \"$break_name\"\\
      start: \"$break_start\"\\
      end: \"$break_end\"|" .flow/teach-config.yml || {
      _flow_log_error "Failed to add breaks config"
      return 1
    }
  else
    # Remove the breaks placeholder line if no breaks
    sed -i '' '/{{BREAKS_CONFIG}}/d' .flow/teach-config.yml || {
      _flow_log_error "Failed to remove breaks placeholder"
      return 1
    }
  fi

  # Commit setup
  git add .flow scripts .github || {
    _flow_log_error "Failed to stage files"
    return 1
  }

  git commit -m "chore: Initialize teaching workflow

- Add .flow/teach-config.yml (Increment 2)
- Add deployment automation scripts
- Add GitHub Actions workflow
- Branch structure: draft + production
- Semester schedule: $start_date to $end_date
- Week calculation configured

Generated by flow-cli teach-init" || {
    _flow_log_error "Failed to commit workflow files"
    return 1
  }

  echo ""
  echo "✅ Templates installed"
  return 0
}

# ============================================================================
# PHASE 2: GITHUB & DOCUMENTATION (v5.4.0)
# ============================================================================

# Offer optional GitHub remote push
_teach_offer_github_push() {
  echo ""
  echo "GitHub Integration (Optional)"

  # Non-interactive mode: skip GitHub push (safe default)
  if [[ "$TEACH_INTERACTIVE" == "false" ]]; then
    echo "  → Skipped in non-interactive mode"
    echo "  ℹ️  Push manually later:"
    echo "     git push -u origin draft production"
    return 0
  fi

  read "?  Push to GitHub remote? [y/N]: " push_github

  if [[ "$push_github" != "y" ]]; then
    echo "  ℹ️  Skipped - push manually later:"
    echo "     git remote add origin <url>"
    echo "     git push -u origin draft production"
    return 0
  fi

  read "remote_url?  GitHub remote URL: " remote_url

  if [[ -z "$remote_url" ]]; then
    _flow_log_warning "No URL provided - skipping push"
    return 0
  fi

  # Check if remote already exists
  if git remote get-url origin &>/dev/null; then
    local current_url=$(git remote get-url origin)

    if [[ "$current_url" == "$remote_url" ]]; then
      # Same URL, just push
      echo "  ℹ️  Remote origin already configured"
      git push -u origin draft production 2>&1 | grep -E "branch|up-to-date|->|Writing"
    else
      # Different URL, ask to update
      echo "  ⚠️  Remote origin exists: $current_url"
      read "?  Update to $remote_url? [y/N]: " update

      if [[ "$update" == "y" ]]; then
        git remote set-url origin "$remote_url"
        git push -u origin draft production 2>&1 | grep -E "branch|up-to-date|->|Writing"
      else
        echo "  ℹ️  Keeping existing remote"
      fi
    fi
  else
    # No remote, add it
    git remote add origin "$remote_url"
    echo "  ✅ Added remote: origin"
    git push -u origin draft production 2>&1 | grep -E "branch|up-to-date|->|Writing"
  fi

  echo "  ✅ Pushed to GitHub"
}

# Generate migration documentation
_teach_generate_migration_docs() {
  local course_name="$1"

  # Get config values if available
  local start_date=""
  local end_date=""
  local semester=""
  local year=""

  if [[ -f ".flow/teach-config.yml" ]] && command -v yq &>/dev/null; then
    start_date=$(yq -r '.semester_info.start_date' .flow/teach-config.yml 2>/dev/null || echo "")
    end_date=$(yq -r '.semester_info.end_date' .flow/teach-config.yml 2>/dev/null || echo "")
    semester=$(yq -r '.course.semester' .flow/teach-config.yml 2>/dev/null || echo "")
    year=$(yq -r '.course.year' .flow/teach-config.yml 2>/dev/null || echo "")
  fi

  # Generate MIGRATION-COMPLETE.md
  cat > MIGRATION-COMPLETE.md << EOF
# $course_name Teaching Workflow Migration - COMPLETE ✅

**Date:** $(date +%Y-%m-%d)
**Status:** Successfully migrated to flow-cli teaching workflow v2.0
**Branch:** $(git branch --show-current) (ready for editing)

---

## Migration Summary

### What Was Done

1. **Git Repository** ✅
   - Pre-migration tag: $(git tag -l "*pre-migration" | tail -1)
   - Branch structure: draft + production

2. **Teaching Workflow Configured** ✅
   - Config: .flow/teach-config.yml
   - Course: $course_name
EOF

  # Add semester info if available
  if [[ -n "$semester" ]] && [[ -n "$year" ]]; then
    echo "   - Semester: $semester $year" >> MIGRATION-COMPLETE.md
  fi

  if [[ -n "$start_date" ]] && [[ -n "$end_date" ]]; then
    echo "   - Dates: $start_date to $end_date" >> MIGRATION-COMPLETE.md
  fi

  cat >> MIGRATION-COMPLETE.md << 'EOF'

3. **Deployment Tools Created** ✅
   - scripts/quick-deploy.sh - Fast deployment (< 2 min)
   - scripts/semester-archive.sh - End-of-semester archival
   - .github/workflows/deploy.yml - GitHub Actions (optional)

4. **Validation Passed** ✅
   - Project type: Quarto website
   - Required files: _quarto.yml, index.qmd
   - Structure: Valid

---

## Daily Workflow

```bash
# Start work session (safe on draft branch)
work COURSE_NAME

# Edit course materials
# Commit changes

# Deploy to production (when ready)
./scripts/quick-deploy.sh
```

---

## Branch Safety

The workflow uses two branches:
- **draft**: Safe for editing (current)
- **production**: What students see (deployed)

**Automatic warning when editing production branch.**

---

## Next Steps

1. Test workflow: `work COURSE_NAME`
2. Make edit, commit, deploy: `./scripts/quick-deploy.sh`
3. Set up GitHub Pages (optional)

---

## Documentation

- **Migration Guide:** Created by flow-cli teach-init
- **flow-cli docs:** https://Data-Wise.github.io/flow-cli/

---

## Success! 🎉

Your course is now using the teaching workflow. The safety features will protect your production branch while giving you freedom to experiment on draft.

**Start working:**
```bash
work COURSE_NAME
```
EOF

  # Replace COURSE_NAME placeholder with actual name
  sed -i '' "s/COURSE_NAME/$course_name/g" MIGRATION-COMPLETE.md

  echo "  ✅ Generated MIGRATION-COMPLETE.md"
}

# ============================================================================
# COMPLETION SUMMARY (ADHD-Friendly)
# ============================================================================

# Show comprehensive completion summary with rollback instructions
# Usage: _teach_show_completion_summary <course_name> [rollback_tag] [original_branch]
_teach_show_completion_summary() {
  local course_name="$1"
  local rollback_tag="${2:-}"
  local original_branch="${3:-main}"

  # Auto-detect rollback tag if not provided
  if [[ -z "$rollback_tag" ]]; then
    rollback_tag=$(git tag -l "*pre-migration" 2>/dev/null | tail -1)
  fi

  # Get course slug for work command
  local course_slug=$(echo "$course_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
  local current_branch=$(git branch --show-current 2>/dev/null)

  echo ""
  echo "┌─────────────────────────────────────────────────────────────┐"
  echo "│ 🎉 TEACHING WORKFLOW INITIALIZED!                           │"
  echo "├─────────────────────────────────────────────────────────────┤"
  echo "│                                                             │"
  echo "│ ${FLOW_COLORS[bold]}📋 What Just Happened:${FLOW_COLORS[reset]}                                      │"
  echo "│                                                             │"

  # Show rollback tag info
  if [[ -n "$rollback_tag" ]]; then
    echo "│   ✅ Created rollback tag: ${FLOW_COLORS[info]}$rollback_tag${FLOW_COLORS[reset]}"
    echo "│      └─ Your safety net! See \"How to Rollback\" below        │"
    echo "│                                                             │"
  fi

  # Show branch changes
  if [[ "$original_branch" != "production" ]]; then
    echo "│   ✅ Renamed $original_branch → production                  │"
    echo "│      └─ This is what students see (deployed site)           │"
    echo "│                                                             │"
  fi

  echo "│   ✅ Created draft branch (you're on it now)                │"
  echo "│      └─ Safe to edit - students won't see until you deploy  │"
  echo "│                                                             │"

  # Show created files
  echo "│   ✅ Created files:                                         │"
  [[ -f ".flow/teach-config.yml" ]] && \
    echo "│      • .flow/teach-config.yml    (course settings)          │"
  [[ -f "scripts/quick-deploy.sh" ]] && \
    echo "│      • scripts/quick-deploy.sh   (deploy draft→production)  │"
  [[ -f "scripts/semester-archive.sh" ]] && \
    echo "│      • scripts/semester-archive.sh (end-of-semester)        │"
  [[ -f ".github/workflows/deploy.yml" ]] && \
    echo "│      • .github/workflows/deploy.yml (GitHub Actions)        │"
  [[ -f "MIGRATION-COMPLETE.md" ]] && \
    echo "│      • MIGRATION-COMPLETE.md     (this summary)             │"

  echo "│                                                             │"

  # Rollback instructions section
  if [[ -n "$rollback_tag" ]]; then
    echo "├─────────────────────────────────────────────────────────────┤"
    echo "│ ${FLOW_COLORS[bold]}🏷️  HOW TO ROLLBACK${FLOW_COLORS[reset]} (if anything goes wrong):              │"
    echo "│                                                             │"
    echo "│   The tag '$rollback_tag' is your safety net.   │"
    echo "│   If migration caused issues:                               │"
    echo "│                                                             │"
    echo "│   ${FLOW_COLORS[dim]}# See what the tag contains:${FLOW_COLORS[reset]}                              │"
    echo "│   ${FLOW_COLORS[cmd]}git log $rollback_tag --oneline -5${FLOW_COLORS[reset]}"
    echo "│                                                             │"
    echo "│   ${FLOW_COLORS[dim]}# Completely undo migration:${FLOW_COLORS[reset]}                              │"
    echo "│   ${FLOW_COLORS[cmd]}git checkout $rollback_tag${FLOW_COLORS[reset]}"
    echo "│   ${FLOW_COLORS[cmd]}git checkout -b $original_branch${FLOW_COLORS[reset]}"
    echo "│   ${FLOW_COLORS[cmd]}rm -rf .flow scripts MIGRATION-COMPLETE.md${FLOW_COLORS[reset]}"
    echo "│                                                             │"
  fi

  # Next steps section
  echo "├─────────────────────────────────────────────────────────────┤"
  echo "│ ${FLOW_COLORS[bold]}🚀 NEXT STEPS:${FLOW_COLORS[reset]}                                              │"
  echo "│                                                             │"
  echo "│   1. Start working (safe on draft branch):                  │"
  echo "│      ${FLOW_COLORS[cmd]}work $course_slug${FLOW_COLORS[reset]}"
  echo "│                                                             │"
  echo "│   2. Make edits, commit as usual                            │"
  echo "│                                                             │"
  echo "│   3. Deploy when ready:                                     │"
  echo "│      ${FLOW_COLORS[cmd]}./scripts/quick-deploy.sh${FLOW_COLORS[reset]}"
  echo "│                                                             │"

  # Optional exam workflow
  echo "│   ${FLOW_COLORS[dim]}(Optional) Enable exam workflow:${FLOW_COLORS[reset]}                          │"
  echo "│      ${FLOW_COLORS[cmd]}npm install -g examark${FLOW_COLORS[reset]}"
  echo "│      ${FLOW_COLORS[cmd]}teach-exam \"Midterm 1\"${FLOW_COLORS[reset]}"
  echo "│                                                             │"

  # Documentation link
  echo "├─────────────────────────────────────────────────────────────┤"
  echo "│ 📚 Learn more: https://data-wise.github.io/flow-cli/        │"
  echo "│                guides/teaching-workflow/                    │"
  echo "└─────────────────────────────────────────────────────────────┘"
  echo ""
}

# Legacy wrapper for backward compatibility
_teach_show_next_steps() {
  local course_name="$1"
  _teach_show_completion_summary "$course_name"
}

# Phase 5 (v5.11.0): Git Initialization for Fresh Repos
# Creates git repo, draft/production branches, and initial commit
_teach_create_fresh_repo() {
  local course_name="$1"

  echo "📋 No git repository detected"
  echo ""

  # Check if --no-git flag was used
  if [[ "$TEACH_SKIP_GIT" == "true" ]]; then
    echo "${FLOW_COLORS[info]}--no-git flag detected: Skipping git initialization${FLOW_COLORS[reset]}"
    echo ""

    # Still install teaching templates (config, scripts, etc.)
    echo "${FLOW_COLORS[info]}Installing teaching workflow...${FLOW_COLORS[reset]}"
    if ! _teach_install_templates "$course_name"; then
      _flow_log_error "Failed to install teaching templates"
      return 1
    fi
    echo "✅ Teaching workflow installed"
    echo ""

    echo "To initialize git later:"
    echo "  git init"
    echo "  git add ."
    echo "  git commit -m 'Initial commit'"
    echo ""
    echo "Then run teach-init again to set up branches"
    return 0
  fi

  # Offer to initialize git
  local should_init_git="y"
  if [[ "$TEACH_INTERACTIVE" != "false" ]]; then
    echo "${FLOW_COLORS[prompt]}Initialize git repository for teaching workflow?${FLOW_COLORS[reset]}"
    echo ""
    echo "  This will:"
    echo "    • Create git repository (git init)"
    echo "    • Add teaching .gitignore"
    echo "    • Create draft and production branches"
    echo "    • Make initial commit with teach-config.yml"
    echo ""
    read "should_init_git?Initialize git? [Y/n]: "
    echo ""
  else
    echo "${FLOW_COLORS[info]}Auto-initializing git repository (non-interactive mode)${FLOW_COLORS[reset]}"
    echo ""
  fi

  case "$should_init_git" in
    n|N|no|No|NO)
      echo "Git initialization skipped"
      echo ""
      echo "To initialize git manually:"
      echo "  git init"
      echo "  git add ."
      echo "  git commit -m 'Initial commit'"
      echo ""
      echo "Then run teach-init again"
      return 0
      ;;
  esac

  # Initialize git
  echo "${FLOW_COLORS[info]}Initializing git repository...${FLOW_COLORS[reset]}"
  if ! git init 2>&1; then
    _flow_log_error "Failed to initialize git repository"
    return 1
  fi
  echo "✅ Git repository initialized"
  echo ""

  # Configure git user if not already set (only in interactive mode)
  if [[ "$TEACH_INTERACTIVE" != "false" ]]; then
    local git_user_name=$(git config user.name 2>/dev/null)
    local git_user_email=$(git config user.email 2>/dev/null)

    if [[ -z "$git_user_name" || -z "$git_user_email" ]]; then
      echo "${FLOW_COLORS[warning]}⚠️  Git user not configured${FLOW_COLORS[reset]}"
      echo ""
      echo "Configure git user (required for commits):"
      read "git_user_name?  Name: "
      read "git_user_email?  Email: "

      git config user.name "$git_user_name"
      git config user.email "$git_user_email"
      echo ""
      echo "✅ Git user configured"
      echo ""
    fi
  fi

  # Copy .gitignore template
  echo "${FLOW_COLORS[info]}Creating .gitignore...${FLOW_COLORS[reset]}"
  local gitignore_template="${0:A:h}/../lib/templates/teaching/teaching.gitignore"
  if [[ -f "$gitignore_template" ]]; then
    cp "$gitignore_template" .gitignore
    echo "✅ .gitignore created from template"
  else
    # Fallback: create minimal .gitignore
    cat > .gitignore <<'EOF'
# Teaching Project .gitignore
/.quarto/
/_site/
.DS_Store
.Rhistory
__pycache__/
EOF
    echo "✅ .gitignore created (minimal)"
  fi
  echo ""

  # Install teaching workflow templates
  echo "${FLOW_COLORS[info]}Installing teaching workflow...${FLOW_COLORS[reset]}"
  if ! _teach_install_templates "$course_name"; then
    _flow_log_error "Failed to install teaching templates"
    return 1
  fi
  echo "✅ Teaching workflow installed"
  echo ""

  # Make initial commit (on main/master branch)
  echo "${FLOW_COLORS[info]}Creating initial commit...${FLOW_COLORS[reset]}"
  git add .
  if ! git commit -m "$(cat <<EOF
feat: initialize teaching workflow for $course_name

Generated via: teach init "$course_name"

Initial setup includes:
- .flow/teach-config.yml (course configuration)
- .gitignore (teaching-specific patterns)
- scripts/ (automation helpers)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)" 2>&1; then
    _flow_log_error "Failed to create initial commit"
    return 1
  fi
  echo "✅ Initial commit created"
  echo ""

  # Create production branch from current branch (use "main" per schema default)
  local default_branch=$(git branch --show-current)
  echo "${FLOW_COLORS[info]}Creating branch structure...${FLOW_COLORS[reset]}"

  # Rename current branch to main (production branch)
  if ! git branch -m "$default_branch" main 2>&1; then
    _flow_log_error "Failed to rename branch to main"
    return 1
  fi
  echo "✅ Renamed $default_branch → main"

  # Create draft branch from main
  if ! git checkout -b draft main 2>&1; then
    _flow_log_error "Failed to create draft branch"
    return 1
  fi
  echo "✅ Created draft branch"
  echo ""

  # Switch back to draft for working
  git checkout draft 2>/dev/null

  # Offer to create GitHub repository
  if command -v gh &>/dev/null; then
    local create_github="n"
    if [[ "$TEACH_INTERACTIVE" != "false" ]]; then
      echo "${FLOW_COLORS[prompt]}Create GitHub repository?${FLOW_COLORS[reset]}"
      echo ""
      echo "  This will:"
      echo "    • Create a new repository on GitHub"
      echo "    • Set up origin remote"
      echo "    • Push draft and production branches"
      echo ""
      read "create_github?Create GitHub repo? [y/N]: "
      echo ""
    fi

    case "$create_github" in
      y|Y|yes|Yes|YES)
        _teach_create_github_repo "$course_name"
        ;;
      *)
        echo "${FLOW_COLORS[dim]}Skipped GitHub repository creation${FLOW_COLORS[reset]}"
        echo ""
        echo "To create GitHub repo later:"
        echo "  gh repo create --source=. --public"
        echo "  git push -u origin draft main"
        ;;
    esac
  else
    echo "${FLOW_COLORS[dim]}gh CLI not found - skipping GitHub setup${FLOW_COLORS[reset]}"
    echo ""
    echo "Install gh CLI to create GitHub repos:"
    echo "  brew install gh && gh auth login"
  fi

  echo ""
  echo "✅ ${FLOW_COLORS[success]}Git initialization complete!${FLOW_COLORS[reset]}"
  echo ""
  _teach_show_git_setup_summary "$course_name"
}

# Helper: Create GitHub repository (Phase 5 - v5.11.0)
_teach_create_github_repo() {
  local course_name="$1"

  echo "${FLOW_COLORS[info]}Creating GitHub repository...${FLOW_COLORS[reset]}"
  echo ""

  # Generate repo name from course name (e.g., "STAT 545" -> "stat-545")
  local repo_name=$(echo "$course_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

  # Check if gh is authenticated
  if ! gh auth status &>/dev/null; then
    _flow_log_error "gh CLI not authenticated"
    echo ""
    echo "Authenticate with: gh auth login"
    return 1
  fi

  # Create repository
  if gh repo create "$repo_name" --source=. --public --description "Course website for $course_name" 2>&1; then
    echo "✅ GitHub repository created"
    echo ""

    # Push both branches
    echo "${FLOW_COLORS[info]}Pushing branches to GitHub...${FLOW_COLORS[reset]}"
    if git push -u origin draft main 2>&1; then
      echo "✅ Branches pushed to GitHub"
      echo ""
      echo "Repository URL: $(gh repo view --json url -q .url)"
    else
      _flow_log_error "Failed to push branches"
      return 1
    fi
  else
    _flow_log_error "Failed to create GitHub repository"
    echo ""
    echo "Create manually with:"
    echo "  gh repo create --source=. --public"
    return 1
  fi
}

# Helper: Show git setup summary (Phase 5 - v5.11.0)
_teach_show_git_setup_summary() {
  local course_name="$1"

  echo "┌────────────────────────────────────────────────────────────┐"
  echo "│ ${FLOW_COLORS[bold]}Git Setup Summary${FLOW_COLORS[reset]}"
  echo "├────────────────────────────────────────────────────────────┤"
  echo "│"
  echo "│ ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Repository initialized"
  echo "│ ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} .gitignore created (teaching patterns)"
  echo "│ ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Initial commit: feat: initialize teaching workflow"
  echo "│ ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Branch structure:"
  echo "│     ${FLOW_COLORS[dim]}•${FLOW_COLORS[reset]} main (production/deployment branch)"
  echo "│     ${FLOW_COLORS[dim]}•${FLOW_COLORS[reset]} draft (working branch) ${FLOW_COLORS[dim]}← current${FLOW_COLORS[reset]}"
  echo "│"
  echo "│ ${FLOW_COLORS[bold]}Next Steps:${FLOW_COLORS[reset]}"
  echo "│"
  echo "│ 1. Start creating content:"
  echo "│    ${FLOW_COLORS[dim]}teach exam \"Midterm Exam\"${FLOW_COLORS[reset]}"
  echo "│    ${FLOW_COLORS[dim]}teach quiz \"Week 3 Quiz\"${FLOW_COLORS[reset]}"
  echo "│    ${FLOW_COLORS[dim]}teach slides \"Lecture 1\"${FLOW_COLORS[reset]}"
  echo "│"
  echo "│ 2. Deploy to production (creates PR):"
  echo "│    ${FLOW_COLORS[dim]}teach deploy${FLOW_COLORS[reset]}"
  echo "│"
  echo "│ 3. Check status:"
  echo "│    ${FLOW_COLORS[dim]}teach status${FLOW_COLORS[reset]}"
  echo "│"
  echo "└────────────────────────────────────────────────────────────┘"
  echo ""
}

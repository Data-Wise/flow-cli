# commands/teach-init.zsh - Teaching workflow initialization
# Scaffolds teaching workflow in existing or new course repository

# ============================================================================
# TEACH-INIT COMMAND
# ============================================================================

teach-init() {
  local course_name=""
  local dry_run=false

  # Parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        dry_run=true
        shift
        ;;
      *)
        course_name="$1"
        shift
        ;;
    esac
  done

  if [[ -z "$course_name" ]]; then
    _flow_log_error "Usage: teach-init [--dry-run] <course-name>"
    echo ""
    echo "Examples:"
    echo "  teach-init \"STAT 545\""
    echo "  teach-init \"STAT 440\""
    echo "  teach-init --dry-run \"STAT 545\"  # Preview migration plan"
    return 1
  fi

  # Dry-run mode: show plan and exit
  if [[ "$dry_run" == "true" ]]; then
    echo "🔍 DRY RUN MODE - No changes will be made"
    echo ""
    _teach_show_migration_plan "$course_name"
    return 0
  fi

  echo "🎓 Initializing teaching workflow for: $course_name"
  echo ""

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

# ============================================================================
# PHASE 1: DETECTION AND VALIDATION (v5.4.0)
# ============================================================================

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
# Prompts user to exclude from git if detected
_teach_handle_renv() {
  if [[ -d "renv" ]]; then
    echo ""
    echo "  ${FLOW_COLORS[warning]}⚠️  Detected renv/ directory${FLOW_COLORS[reset]}"
    echo "  R package management with symlinks (not suitable for git)"
    echo ""
    read "?  Exclude renv/ from git? [Y/n]: " exclude_renv

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

  # Strategy menu
  echo "Choose migration strategy:"
  echo "  ${FLOW_COLORS[bold]}1.${FLOW_COLORS[reset]} In-place conversion (rename $current_branch → production, create draft)"
  echo "  ${FLOW_COLORS[bold]}2.${FLOW_COLORS[reset]} Two-branch setup (keep $current_branch, create draft + production)"
  echo ""

  read "choice?Choice [1/2]: "

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

  read "confirm?Continue? [y/N] "
  if [[ "$confirm" != "y" ]]; then
    echo "Cancelled"
    return 1
  fi

  # Tag current state
  local semester=$(date +"%B" | sed 's/January\|February\|March\|April\|May/spring/; s/June\|July/summer/; s/August\|September\|October\|November\|December/fall/')
  local year=$(date +%Y)
  git tag -a "$semester-$year-pre-migration" -m "Pre-migration snapshot"

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
  _teach_show_next_steps "$course_name"
}

_teach_two_branch_setup() {
  local course_name="$1"

  # Create production and draft branches
  git checkout -b production
  git push -u origin production

  git checkout -b draft
  git push -u origin draft

  # Install templates
  _teach_install_templates "$course_name"

  echo ""
  echo "✅ Two-branch setup complete"
  _teach_show_next_steps "$course_name"
}

# ============================================================================
# TEMPLATE INSTALLATION
# ============================================================================

_teach_install_templates() {
  local course_name="$1"

  # Create directory structure
  mkdir -p .flow scripts .github/workflows

  # Get template directory from flow-cli
  local template_dir="${FLOW_PLUGIN_DIR}/lib/templates/teaching"

  # Copy script templates
  cp "$template_dir/quick-deploy.sh" scripts/
  cp "$template_dir/semester-archive.sh" scripts/
  chmod +x scripts/*.sh

  # Copy GitHub Actions workflow
  cp "$template_dir/deploy.yml.template" .github/workflows/deploy.yml

  # Generate config (Increment 2: Course Context)
  local course_slug=$(echo "$course_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
  local semester=$(date +"%B" | sed 's/January\|February\|March\|April\|May/spring/; s/June\|July/summer/; s/August\|September\|October\|November\|December/fall/')
  local year=$(date +%Y)
  local generated_date=$(date +"%Y-%m-%d")

  # Prompt for semester dates (Increment 2)
  echo ""
  echo "${FLOW_COLORS[bold]}Semester Schedule${FLOW_COLORS[reset]}"
  echo "  Configure semester start/end dates for week calculation"
  echo ""

  # Suggest start date based on current month
  local suggested_start=$(_suggest_semester_start)

  read "start_date?  Start date (YYYY-MM-DD) [$suggested_start]: "
  start_date="${start_date:-$suggested_start}"

  # Validate date format
  if ! _validate_date_format "$start_date"; then
    _flow_log_error "Invalid date format. Please use YYYY-MM-DD"
    return 1
  fi

  # Calculate semester end (16 weeks from start)
  local end_date=$(_calculate_semester_end "$start_date")

  echo "  ${FLOW_COLORS[info]}Calculated end date: $end_date (16 weeks)${FLOW_COLORS[reset]}"

  # Ask about breaks
  echo ""
  read "?  Add spring/fall break? [y/N]: " add_break

  local breaks_config=""
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

    # Build breaks config section
    breaks_config="  breaks:
    - name: \"$break_name\"
      start: \"$break_start\"
      end: \"$break_end\""
  fi

  # Read template and substitute variables
  local config_template=$(cat "$template_dir/teach-config.yml.template")

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
    > .flow/teach-config.yml

  # Handle breaks config (multiline replacement)
  if [[ -n "$breaks_config" ]]; then
    # Replace placeholder with actual breaks config
    sed -i '' "s|{{BREAKS_CONFIG}}|$breaks_config|" .flow/teach-config.yml
  else
    # Remove the breaks placeholder line if no breaks
    sed -i '' '/{{BREAKS_CONFIG}}/d' .flow/teach-config.yml
  fi

  # Commit setup
  git add .flow scripts .github
  git commit -m "chore: Initialize teaching workflow

- Add .flow/teach-config.yml (Increment 2)
- Add deployment automation scripts
- Add GitHub Actions workflow
- Branch structure: draft + production
- Semester schedule: $start_date to $end_date
- Week calculation configured

Generated by flow-cli teach-init"

  git push origin draft

  echo ""
  echo "✅ Templates installed"
}

# ============================================================================
# NEXT STEPS
# ============================================================================

_teach_show_next_steps() {
  local course_name="$1"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎉 Teaching workflow initialized!"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Next steps:"
  echo ""
  echo "  1. Review config:"
  echo "     ${FLOW_COLORS[cmd]}\$EDITOR .flow/teach-config.yml${FLOW_COLORS[reset]}"
  echo ""
  echo "  2. Update GitHub repo settings:"
  echo "     - Enable GitHub Pages from 'production' branch"
  echo "     - Set Pages source: / (root)"
  echo ""
  echo "  3. Test deployment:"
  echo "     ${FLOW_COLORS[cmd]}./scripts/quick-deploy.sh${FLOW_COLORS[reset]}"
  echo ""
  echo "  4. Start working:"
  echo "     ${FLOW_COLORS[cmd]}work $course_name${FLOW_COLORS[reset]}"
  echo ""
  echo "📚 Documentation:"
  echo "   https://data-wise.github.io/flow-cli/guides/teaching-workflow/"
  echo ""
}

_teach_create_fresh_repo() {
  local course_name="$1"

  echo "📋 No git repository detected"
  echo ""
  echo "Initialize git repository first:"
  echo "  git init"
  echo "  git add ."
  echo "  git commit -m 'Initial commit'"
  echo ""
  echo "Then run teach-init again"
  return 1
}

# commands/teach-init.zsh - Teaching workflow initialization
# Scaffolds teaching workflow in existing or new course repository

# ============================================================================
# TEACH-INIT COMMAND
# ============================================================================

teach-init() {
  local course_name="$1"

  if [[ -z "$course_name" ]]; then
    _flow_log_error "Usage: teach-init <course-name>"
    echo ""
    echo "Examples:"
    echo "  teach-init \"STAT 545\""
    echo "  teach-init \"STAT 440\""
    return 1
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

  # Generate config (Increment 1: Core Deployment)
  local course_slug=$(echo "$course_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
  local semester=$(date +"%B" | sed 's/January\|February\|March\|April\|May/spring/; s/June\|July/summer/; s/August\|September\|October\|November\|December/fall/')
  local year=$(date +%Y)
  local generated_date=$(date +"%Y-%m-%d")

  # Read template and substitute variables
  local config_template=$(cat "$template_dir/teach-config.yml.template")

  # Perform substitutions (Increment 1 placeholders only)
  echo "$config_template" | \
    sed "s/{{COURSE_NAME}}/$course_name/g" | \
    sed "s/{{COURSE_FULL_NAME}}/$course_name/g" | \
    sed "s/{{COURSE_SLUG}}/$course_slug/g" | \
    sed "s/{{SEMESTER}}/$semester/g" | \
    sed "s/{{YEAR}}/$year/g" | \
    sed "s/{{INSTRUCTOR}}/$USER/g" | \
    sed "s/{{GENERATED_DATE}}/$generated_date/g" \
    > .flow/teach-config.yml

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

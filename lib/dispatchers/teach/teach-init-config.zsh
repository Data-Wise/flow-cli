# teach-init-config.zsh - Extracted from teach-dispatcher.zsh
# ============================================================================

_teach_init() {
    local course_name=""
    local external_config=""
    local create_github=false
    local with_templates=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --config)
                shift
                external_config="$1"
                shift
                ;;
            --github)
                create_github=true
                shift
                ;;
            --with-templates)
                with_templates=true
                shift
                ;;
            --help|-h|help)
                _teach_init_help
                return 0
                ;;
            *)
                if [[ -z "$course_name" && ! "$1" =~ ^-- ]]; then
                    course_name="$1"
                fi
                shift
                ;;
        esac
    done

    # Check if already initialized
    if [[ -f ".flow/teach-config.yml" ]]; then
        _flow_log_error "Teaching project already initialized"
        echo ""
        echo "  Config exists: .flow/teach-config.yml"
        echo "  To reconfigure, edit the file or delete it first"
        return 1
    fi

    echo ""
    echo "${FLOW_COLORS[bold]}🎓 Initializing Teaching Project${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
    echo ""

    # Create .flow directory
    mkdir -p .flow

    # Load from external config if specified (v5.14.0 - Task 10)
    if [[ -n "$external_config" ]]; then
        if [[ ! -f "$external_config" ]]; then
            _flow_log_error "External config not found: $external_config"
            return 1
        fi

        echo "  ${FLOW_COLORS[info]}Loading from:${FLOW_COLORS[reset]} $external_config"
        cp "$external_config" .flow/teach-config.yml

        echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Config loaded from external file"
    else
        # Create default config
        local semester=$(date +%B)  # e.g., "January"
        local year=$(date +%Y)

        # Use provided name or prompt
        if [[ -z "$course_name" ]]; then
            course_name="My Course"
        fi

        cat > .flow/teach-config.yml << EOF
course:
  name: "$course_name"
  semester: "$semester $year"
  year: $year

git:
  draft_branch: draft
  production_branch: main
  auto_pr: true
  require_clean: true

workflow:
  teaching_mode: false
  auto_commit: false
  auto_push: false

backups:
  retention:
    assessments: archive    # Keep exam/quiz backups forever
    syllabi: archive        # Keep syllabus backups forever
    lectures: semester      # Delete lecture backups at semester end
  archive_dir: .flow/archives
EOF

        echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Created .flow/teach-config.yml"
    fi

    # Initialize git if requested (v5.14.0 - Task 10)
    if [[ "$create_github" == "true" ]]; then
        # Check if gh is available
        if ! command -v gh &>/dev/null; then
            _flow_log_error "GitHub CLI (gh) required for --github flag"
            echo "  Install: brew install gh"
            return 1
        fi

        # Check if already in git repo
        if ! git rev-parse --git-dir &>/dev/null 2>&1; then
            # Initialize git
            git init
            echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Initialized git repository"
        fi

        # Create GitHub repo
        echo ""
        echo "  ${FLOW_COLORS[info]}Creating GitHub repository...${FLOW_COLORS[reset]}"

        local repo_name=$(basename "$PWD")
        if gh repo create "$repo_name" --private --source=. --push 2>&1; then
            echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} GitHub repository created and pushed"
        else
            echo "  ${FLOW_COLORS[warning]}⚠${FLOW_COLORS[reset]} Failed to create GitHub repo (continuing anyway)"
        fi
    fi

    # Create initial branches if in git repo
    if git rev-parse --git-dir &>/dev/null 2>&1; then
        # Commit the config
        git add .flow/teach-config.yml
        git commit -m "chore: initialize teaching project

Course: $course_name
Initialized via: teach init" 2>/dev/null

        # Create draft branch if it doesn't exist
        if ! git show-ref --verify --quiet refs/heads/draft 2>/dev/null; then
            git branch draft
            echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Created draft branch"
        fi
    fi

    # Initialize templates if requested (v5.20.0 - Template Support #301)
    if [[ "$with_templates" == "true" ]]; then
        echo ""
        echo "  ${FLOW_COLORS[info]}Setting up templates...${FLOW_COLORS[reset]}"

        # Create template directories
        local template_dir
        template_dir=$(_teach_create_template_dirs)

        # Count templates synced
        local content_count=0
        local prompts_count=0

        # Sync templates from plugin
        local plugin_dir="$(_template_get_plugin_dir)"

        # Sync prompts (from claude-prompts/)
        if [[ -d "$plugin_dir/claude-prompts" ]]; then
            for tmpl in "$plugin_dir/claude-prompts"/*.md(.N); do
                cp "$tmpl" "$template_dir/prompts/"
                ((prompts_count++))
            done
        fi

        # Sync content templates (from .template files)
        for tmpl in "$plugin_dir"/*.template(.N); do
            local name="${${tmpl:t}%.template}.qmd"
            cp "$tmpl" "$template_dir/content/$name"
            ((content_count++))
        done

        echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Created .flow/templates/content/ ($content_count templates)"
        echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Created .flow/templates/prompts/ ($prompts_count templates)"
        echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Created .flow/templates/metadata/"
        echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Created .flow/templates/checklists/"
    fi

    echo ""
    echo "${FLOW_COLORS[success]}✅ Teaching project initialized!${FLOW_COLORS[reset]}"
    echo ""
    echo "  Next steps:"
    echo "    1. Review config: teach config"
    echo "    2. Check environment: teach doctor"
    if [[ "$with_templates" == "true" ]]; then
        echo "    3. List templates: teach templates list"
        echo "    4. Create content: teach templates new lecture week-01"
    else
        echo "    3. Generate content: teach exam \"Topic\""
    fi
    echo ""
}

# Help for teach config

_teach_config_edit() {
    local config_file=".flow/teach-config.yml"
    if [[ -f "$config_file" ]]; then
        ${EDITOR:-code} "$config_file"
    else
        _teach_error "No teach-config.yml found" "Run 'teach init' first"
        return 1
    fi
}


_teach_config_view() {
    local config_file=".flow/teach-config.yml"
    if [[ -f "$config_file" ]]; then
        echo "${FLOW_COLORS[info]}=== .flow/teach-config.yml ===${FLOW_COLORS[reset]}"
        cat "$config_file"
    else
        _teach_error "No teach-config.yml found" "Run 'teach init' first"
        return 1
    fi
}


_teach_config_cat() {
    local config_file=".flow/teach-config.yml"
    if [[ -f "$config_file" ]]; then
        cat "$config_file"
    else
        _teach_error "No teach-config.yml found" "Run 'teach init' first"
        return 1
    fi
}

# Help for teach init


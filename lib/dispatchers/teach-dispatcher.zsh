# teach-dispatcher.zsh - Teaching Workflow Dispatcher
# Smart teaching workflows for course websites
# Wraps Scholar plugin for unified teaching CLI experience
#
# v5.9.0+ Deep Integration Features:
#   - Config validation with JSON Schema
#   - Hash-based change detection
#   - Progress indicator (spinner + estimate)
#   - Flag validation before Scholar calls
#   - Post-generation hooks (auto-stage, .STATUS, notify)

# Source config validator if not already loaded
if [[ -z "$_FLOW_CONFIG_VALIDATOR_LOADED" ]]; then
    local validator_path="${0:A:h:h}/config-validator.zsh"
    [[ -f "$validator_path" ]] && source "$validator_path"
    typeset -g _FLOW_CONFIG_VALIDATOR_LOADED=1

# Source date management dispatcher if not already loaded
if [[ -z "$_FLOW_TEACH_DATES_LOADED" ]]; then
    local dates_path="${0:A:h}/teach-dates.zsh"
    [[ -f "$dates_path" ]] && source "$dates_path"
    typeset -g _FLOW_TEACH_DATES_LOADED=1
fi
fi

# Source git helpers for teaching workflow integration (v5.11.0+)
if [[ -z "$_FLOW_GIT_HELPERS_LOADED" ]]; then
    local git_helpers_path="${0:A:h:h}/git-helpers.zsh"
    [[ -f "$git_helpers_path" ]] && source "$git_helpers_path"
    typeset -g _FLOW_GIT_HELPERS_LOADED=1
fi

# Source git helpers for teaching workflow integration (v5.11.0+)
if [[ -z "$_FLOW_GIT_HELPERS_LOADED" ]]; then
    local git_helpers_path="${0:A:h:h}/git-helpers.zsh"
    [[ -f "$git_helpers_path" ]] && source "$git_helpers_path"
    typeset -g _FLOW_GIT_HELPERS_LOADED=1
fi

# Source teach doctor implementation (v5.14.0 - Task 2)
if [[ -z "$_FLOW_TEACH_DOCTOR_LOADED" ]]; then
    local doctor_path="${0:A:h}/teach-doctor-impl.zsh"
    [[ -f "$doctor_path" ]] && source "$doctor_path"
    typeset -g _FLOW_TEACH_DOCTOR_LOADED=1
fi

# Source validation helpers (v4.6.0 - Week 2-3: Validation Commands)
if [[ -z "$_FLOW_VALIDATION_HELPERS_LOADED" ]]; then
    local validation_helpers_path="${0:A:h:h}/validation-helpers.zsh"
    [[ -f "$validation_helpers_path" ]] && source "$validation_helpers_path"
    typeset -g _FLOW_VALIDATION_HELPERS_LOADED=1
fi

# Source teach-validate command (v4.6.0 - Week 2-3: Validation Commands)
if [[ -z "$_FLOW_TEACH_VALIDATE_LOADED" ]]; then
    local validate_path="${0:A:h:h}/../commands/teach-validate.zsh"
    [[ -f "$validate_path" ]] && source "$validate_path"
    typeset -g _FLOW_TEACH_VALIDATE_LOADED=1
fi

# Source index management helpers (v5.14.0 - Quarto Workflow Week 5-7)
if [[ -z "$_FLOW_INDEX_HELPERS_LOADED" ]]; then
    local index_helpers_path="${0:A:h:h}/index-helpers.zsh"
    [[ -f "$index_helpers_path" ]] && source "$index_helpers_path"
    typeset -g _FLOW_INDEX_HELPERS_LOADED=1
fi

# Source enhanced deploy implementation (v5.14.0 - Quarto Workflow Week 5-7)
if [[ -z "$_FLOW_TEACH_DEPLOY_ENHANCED_LOADED" ]]; then
    local deploy_enhanced_path="${0:A:h}/teach-deploy-enhanced.zsh"
    [[ -f "$deploy_enhanced_path" ]] && source "$deploy_enhanced_path"
    typeset -g _FLOW_TEACH_DEPLOY_ENHANCED_LOADED=1
fi

# Source deploy history helpers (v6.4.0 - teach deploy v2)
if [[ -z "$_FLOW_DEPLOY_HISTORY_LOADED" ]]; then
    local deploy_history_path="${0:A:h:h}/deploy-history-helpers.zsh"
    [[ -f "$deploy_history_path" ]] && source "$deploy_history_path"
    typeset -g _FLOW_DEPLOY_HISTORY_LOADED=1
fi

# Source deploy rollback helpers (v6.4.0 - teach deploy v2)
if [[ -z "$_FLOW_DEPLOY_ROLLBACK_LOADED" ]]; then
    local deploy_rollback_path="${0:A:h:h}/deploy-rollback-helpers.zsh"
    [[ -f "$deploy_rollback_path" ]] && source "$deploy_rollback_path"
    typeset -g _FLOW_DEPLOY_ROLLBACK_LOADED=1
fi

# Source profile helpers (Phase 2 - Wave 1: Profile Management)
if [[ -z "$_FLOW_PROFILE_HELPERS_LOADED" ]]; then
    local profile_helpers_path="${0:A:h:h}/profile-helpers.zsh"
    [[ -f "$profile_helpers_path" ]] && source "$profile_helpers_path"
    typeset -g _FLOW_PROFILE_HELPERS_LOADED=1
fi

# Source R package helpers (Phase 2 - Wave 1: R Package Detection)
if [[ -z "$_FLOW_R_HELPERS_LOADED" ]]; then
    local r_helpers_path="${0:A:h:h}/r-helpers.zsh"
    [[ -f "$r_helpers_path" ]] && source "$r_helpers_path"
    typeset -g _FLOW_R_HELPERS_LOADED=1
fi

# Source renv integration (Phase 2 - Wave 1: renv Support)
if [[ -z "$_FLOW_RENV_INTEGRATION_LOADED" ]]; then
    local renv_path="${0:A:h:h}/renv-integration.zsh"
    [[ -f "$renv_path" ]] && source "$renv_path"
    typeset -g _FLOW_RENV_INTEGRATION_LOADED=1
fi

# Source teach profiles command (Phase 2 - Wave 1: Profile Management)
if [[ -z "$_FLOW_TEACH_PROFILES_LOADED" ]]; then
    local profiles_path="${0:A:h:h}/../commands/teach-profiles.zsh"
    [[ -f "$profiles_path" ]] && source "$profiles_path"
    typeset -g _FLOW_TEACH_PROFILES_LOADED=1
fi

# Source hook installer (v5.14.0 - PR #277 Task 2)
if [[ -z "$_FLOW_HOOK_INSTALLER_LOADED" ]]; then
    local hook_installer_path="${0:A:h:h}/hook-installer.zsh"
    [[ -f "$hook_installer_path" ]] && source "$hook_installer_path"
    typeset -g _FLOW_HOOK_INSTALLER_LOADED=1
fi

# Source teach-migrate command (v5.20.0 - Lesson Plan Extraction #298)
if [[ -z "$_FLOW_TEACH_MIGRATE_LOADED" ]]; then
    local migrate_path="${0:A:h:h}/../commands/teach-migrate.zsh"
    [[ -f "$migrate_path" ]] && source "$migrate_path"
    typeset -g _FLOW_TEACH_MIGRATE_LOADED=1
fi

# Source teach-templates command (v5.20.0 - Template Support #301)
if [[ -z "$_FLOW_TEACH_TEMPLATES_LOADED" ]]; then
    local templates_path="${0:A:h:h}/../commands/teach-templates.zsh"
    [[ -f "$templates_path" ]] && source "$templates_path"
    typeset -g _FLOW_TEACH_TEMPLATES_LOADED=1
fi

# Source teach-macros command (v5.21.0 - LaTeX Macro Support)
if [[ -z "$_FLOW_TEACH_MACROS_LOADED" ]]; then
    local macros_path="${0:A:h:h}/../commands/teach-macros.zsh"
    [[ -f "$macros_path" ]] && source "$macros_path"
    typeset -g _FLOW_TEACH_MACROS_LOADED=1
fi

# Source teach-plan command (v5.22.0 - Lesson Plan CRUD #278)
if [[ -z "$_FLOW_TEACH_PLAN_LOADED" ]]; then
    local plan_path="${0:A:h:h}/../commands/teach-plan.zsh"
    [[ -f "$plan_path" ]] && source "$plan_path"
    typeset -g _FLOW_TEACH_PLAN_LOADED=1
fi

# Source teach-prompt command (v5.23.0 - AI Prompt Management)
if [[ -z "$_FLOW_TEACH_PROMPT_LOADED" ]]; then
    local prompt_path="${0:A:h:h}/../commands/teach-prompt.zsh"
    [[ -f "$prompt_path" ]] && source "$prompt_path"
    typeset -g _FLOW_TEACH_PROMPT_LOADED=1
fi

# ============================================================================
# TEACH DISPATCHER
# ============================================================================

# ============================================================================
# FLAG VALIDATION
# ============================================================================

# Universal content flags (v5.13.0+)
# These can be added to any Scholar command for content customization
typeset -gA TEACH_CONTENT_FLAGS=(
    # Content flags with short forms
    [explanation]="flag"
    [e]="flag"  # short for --explanation
    [no-explanation]="flag"

    [proof]="flag"
    [no-proof]="flag"

    [math]="flag"
    [m]="flag"  # short for --math
    [no-math]="flag"

    [examples]="flag"
    [x]="flag"  # short for --examples
    [no-examples]="flag"

    [code]="flag"
    [c]="flag"  # short for --code
    [no-code]="flag"

    [diagrams]="flag"
    [d]="flag"  # short for --diagrams
    [no-diagrams]="flag"

    [practice-problems]="flag"
    [p]="flag"  # short for --practice-problems
    [no-practice-problems]="flag"

    [definitions]="flag"
    [no-definitions]="flag"

    [references]="flag"
    [r]="flag"  # short for --references
    [no-references]="flag"
)

# Universal selection flags (v5.13.0+)
typeset -gA TEACH_SELECTION_FLAGS=(
    [topic]="string"
    [t]="string"  # short for --topic

    [week]="number"
    [w]="number"  # short for --week

    [style]="conceptual|computational|rigorous|applied"

    [interactive]="flag"
    [i]="flag"  # short for --interactive

    [revise]="string"
    [context]="flag"
)

# Known flags per Scholar command
typeset -gA TEACH_EXAM_FLAGS=(
    [questions]="number"
    [duration]="number"
    [types]="string"
    [format]="quarto|qti|markdown"
    [dry-run]="flag"
    [verbose]="flag"
)

typeset -gA TEACH_QUIZ_FLAGS=(
    [questions]="number"
    [time-limit]="number"
    [format]="quarto|qti|markdown"
    [dry-run]="flag"
    [verbose]="flag"
)

typeset -gA TEACH_SLIDES_FLAGS=(
    [theme]="default|academic|minimal"
    [from-lecture]="string"
    [format]="quarto|markdown"
    [dry-run]="flag"
    [verbose]="flag"
)

typeset -gA TEACH_ASSIGNMENT_FLAGS=(
    [due-date]="date"
    [points]="number"
    [format]="quarto|markdown"
    [dry-run]="flag"
    [verbose]="flag"
)

typeset -gA TEACH_SYLLABUS_FLAGS=(
    [format]="quarto|markdown|pdf"
    [dry-run]="flag"
    [verbose]="flag"
)

typeset -gA TEACH_RUBRIC_FLAGS=(
    [criteria]="number"
    [format]="quarto|markdown"
    [dry-run]="flag"
    [verbose]="flag"
)

# Validate flags for a Scholar command
# Usage: _teach_validate_flags <command> [flags...]
# Returns: 0 if valid, 1 if invalid

# ============================================================================
# TEACH DISPATCHER MODULES (split from teach-dispatcher.zsh)
# ============================================================================

local _teach_mod_path="${0:A:h}/teach/teach-main.zsh"
[[ -f "$_teach_mod_path" ]] && source "$_teach_mod_path"

local _teach_mod_path="${0:A:h}/teach/teach-content.zsh"
[[ -f "$_teach_mod_path" ]] && source "$_teach_mod_path"

local _teach_mod_path="${0:A:h}/teach/teach-help.zsh"
[[ -f "$_teach_mod_path" ]] && source "$_teach_mod_path"

local _teach_mod_path="${0:A:h}/teach/teach-init-config.zsh"
[[ -f "$_teach_mod_path" ]] && source "$_teach_mod_path"

local _teach_mod_path="${0:A:h}/teach/teach-slides.zsh"
[[ -f "$_teach_mod_path" ]] && source "$_teach_mod_path"

local _teach_mod_path="${0:A:h}/teach/teach-style.zsh"
[[ -f "$_teach_mod_path" ]] && source "$_teach_mod_path"

local _teach_mod_path="${0:A:h}/teach/teach-backup.zsh"
[[ -f "$_teach_mod_path" ]] && source "$_teach_mod_path"

local _teach_mod_path="${0:A:h}/teach/teach-status.zsh"
[[ -f "$_teach_mod_path" ]] && source "$_teach_mod_path"

local _teach_mod_path="${0:A:h}/teach/teach-archive.zsh"
[[ -f "$_teach_mod_path" ]] && source "$_teach_mod_path"

local _teach_mod_path="${0:A:h}/teach/teach-map.zsh"
[[ -f "$_teach_mod_path" ]] && source "$_teach_mod_path"


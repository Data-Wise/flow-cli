# teach-style.zsh - Extracted from teach-dispatcher.zsh
# ============================================================================

_teach_style() {
    local subcmd="${1:-show}"
    shift 2>/dev/null

    case "$subcmd" in
        show|s|"")
            _teach_style_show "$@"
            ;;
        check|c)
            _teach_style_check "$@"
            ;;
        help|--help|-h)
            _teach_style_help
            ;;
        *)
            _teach_error "Unknown style command: $subcmd"
            _teach_style_help
            return 1
            ;;
    esac
}


_teach_style_show() {
    # Color fallbacks
    if [[ -z "$_C_BOLD" ]]; then
        _C_BOLD='\033[1m'
        _C_DIM='\033[2m'
        _C_NC='\033[0m'
        _C_GREEN='\033[32m'
        _C_YELLOW='\033[33m'
        _C_CYAN='\033[36m'
    fi

    echo ""
    echo -e "${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}"
    echo -e "${_C_BOLD}│ 📚 Teaching Style Configuration              │${_C_NC}"
    echo -e "${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}"
    echo ""

    # Find source
    if ! typeset -f _teach_find_style_source >/dev/null 2>&1; then
        echo "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} Teaching style helpers not loaded"
        return 1
    fi

    local source
    source=$(_teach_find_style_source "." 2>/dev/null)

    if [[ -z "$source" ]]; then
        echo "  ${FLOW_COLORS[warning]}⚠${FLOW_COLORS[reset]}  No teaching style configured"
        echo ""
        echo "  ${FLOW_COLORS[muted]}Add a teaching_style section to .flow/teach-config.yml${FLOW_COLORS[reset]}"
        echo "  ${FLOW_COLORS[muted]}See: docs/reference/REFCARD-TEACH-CONFIG-SCHEMA.md${FLOW_COLORS[reset]}"
        echo ""
        return 0
    fi

    # IMPORTANT: Do NOT use "local path" — it shadows ZSH's $path array (tied to $PATH)
    local src_path="${source%%:*}"
    local src_type="${source##*:}"

    # Source info
    echo -e "  ${_C_BOLD}Source:${_C_NC} $src_path"
    case "$src_type" in
        teach-config)
            echo -e "  ${_C_BOLD}Type:${_C_NC}   ${_C_GREEN}Unified config${_C_NC} (recommended)"
            ;;
        legacy-md)
            if _teach_style_is_redirect "."; then
                echo -e "  ${_C_BOLD}Type:${_C_NC}   ${_C_YELLOW}Redirect shim${_C_NC} → .flow/teach-config.yml"
            else
                echo -e "  ${_C_BOLD}Type:${_C_NC}   ${_C_YELLOW}Legacy markdown${_C_NC} (consider migrating)"
            fi
            ;;
    esac
    echo ""

    # Display key settings
    if ! command -v yq &>/dev/null; then
        echo "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} yq required to display settings"
        echo "  ${FLOW_COLORS[muted]}Install: brew install yq${FLOW_COLORS[reset]}"
        return 1
    fi

    local approach=$(_teach_get_style "pedagogical_approach.primary" 2>/dev/null)
    local formality=$(_teach_get_style "explanation_style.formality" 2>/dev/null)
    local proof_style=$(_teach_get_style "explanation_style.proof_style" 2>/dev/null)
    local code_style=$(_teach_get_style "content_preferences.code_style" 2>/dev/null)
    local tools=$(_teach_get_style "content_preferences.computational_tools" 2>/dev/null)
    local exam_fmt=$(_teach_get_style "assessment_philosophy.exam_format" 2>/dev/null)

    echo -e "  ${_C_BOLD}Key Settings:${_C_NC}"
    [[ -n "$approach" && "$approach" != "null" ]]    && echo -e "    Approach:    ${_C_CYAN}$approach${_C_NC}"
    [[ -n "$formality" && "$formality" != "null" ]]  && echo -e "    Formality:   ${_C_CYAN}$formality${_C_NC}"
    [[ -n "$proof_style" && "$proof_style" != "null" ]] && echo -e "    Proofs:      ${_C_CYAN}$proof_style${_C_NC}"
    [[ -n "$code_style" && "$code_style" != "null" ]] && echo -e "    Code style:  ${_C_CYAN}$code_style${_C_NC}"
    [[ -n "$tools" && "$tools" != "null" ]]          && echo -e "    Tools:       ${_C_CYAN}$tools${_C_NC}"
    [[ -n "$exam_fmt" && "$exam_fmt" != "null" ]]    && echo -e "    Exams:       ${_C_CYAN}$exam_fmt${_C_NC}"
    echo ""

    # Show command overrides summary
    if [[ "$src_type" == "teach-config" && -f ".flow/teach-config.yml" ]]; then
        local overrides
        overrides=$(yq '.teaching_style.command_overrides // ""' ".flow/teach-config.yml" 2>/dev/null)
        if [[ -n "$overrides" && "$overrides" != "null" && "$overrides" != "" ]]; then
            local -a cmds
            cmds=($(yq '.teaching_style.command_overrides | keys | .[]' ".flow/teach-config.yml" 2>/dev/null))
            if (( ${#cmds} > 0 )); then
                echo -e "  ${_C_BOLD}Command Overrides:${_C_NC}"
                for cmd in "${cmds[@]}"; do
                    echo -e "    ${_C_CYAN}$cmd${_C_NC}"
                done
                echo ""
            fi
        fi
    fi
}


_teach_style_check() {
    echo ""
    echo "Running teaching style validation..."
    echo ""

    if ! typeset -f _teach_find_style_source >/dev/null 2>&1; then
        echo "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} Teaching style helpers not loaded"
        return 1
    fi

    local -i issues=0

    # 1. Check source exists
    local source
    source=$(_teach_find_style_source "." 2>/dev/null)

    if [[ -z "$source" ]]; then
        echo "  ${FLOW_COLORS[warning]}⚠${FLOW_COLORS[reset]}  No teaching style configured"
        ((issues++))
    else
        # Do NOT use "local path" — shadows ZSH's $path array (tied to $PATH)
        local src_path="${source%%:*}"
        local src_type="${source##*:}"
        echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Source: $src_path ($src_type)"

        # 2. Check yq can parse it
        if command -v yq &>/dev/null; then
            if [[ "$src_type" == "teach-config" ]]; then
                if yq '.teaching_style' "$src_path" &>/dev/null; then
                    echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} YAML syntax valid"
                else
                    echo "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} YAML parse error in teaching_style"
                    ((issues++))
                fi
            fi

            # 3. Check required sub-sections
            local approach=$(_teach_get_style "pedagogical_approach" 2>/dev/null)
            if [[ -z "$approach" || "$approach" == "null" ]]; then
                echo "  ${FLOW_COLORS[warning]}⚠${FLOW_COLORS[reset]}  Missing: pedagogical_approach"
                ((issues++))
            else
                echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Has pedagogical_approach"
            fi

            local explanation=$(_teach_get_style "explanation_style" 2>/dev/null)
            if [[ -z "$explanation" || "$explanation" == "null" ]]; then
                echo "  ${FLOW_COLORS[warning]}⚠${FLOW_COLORS[reset]}  Missing: explanation_style"
                ((issues++))
            else
                echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Has explanation_style"
            fi

            local content=$(_teach_get_style "content_preferences" 2>/dev/null)
            if [[ -z "$content" || "$content" == "null" ]]; then
                echo "  ${FLOW_COLORS[warning]}⚠${FLOW_COLORS[reset]}  Missing: content_preferences"
                ((issues++))
            else
                echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Has content_preferences"
            fi
        else
            echo "  ${FLOW_COLORS[warning]}⚠${FLOW_COLORS[reset]}  yq not installed (brew install yq)"
            ((issues++))
        fi

        # 4. Check redirect shim consistency
        if [[ "$src_type" == "teach-config" && -f ".claude/teaching-style.local.md" ]]; then
            if _teach_style_is_redirect "."; then
                echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Legacy shim has redirect"
            else
                echo "  ${FLOW_COLORS[warning]}⚠${FLOW_COLORS[reset]}  Legacy file exists without redirect"
                ((issues++))
            fi
        fi
    fi

    echo ""
    if (( issues == 0 )); then
        echo "  ${FLOW_COLORS[success]}✓ All checks passed${FLOW_COLORS[reset]}"
    else
        echo "  ${FLOW_COLORS[warning]}△ $issues issue(s) found${FLOW_COLORS[reset]}"
    fi
    echo ""

    return $((issues > 0 ? 1 : 0))
}



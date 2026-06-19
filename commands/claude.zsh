# commands/claude.zsh — flow claude subcommand
# Claude Code environment health checker

flow_claude() {
  local subcmd="${1:-check}"
  shift 2>/dev/null

  case "$subcmd" in
    check|doctor) _flow_claude_check "$@" ;;
    help|--help|-h) _flow_claude_help ;;
    *)
      _flow_log_error "Unknown subcommand: $subcmd"
      _flow_claude_help
      return 1
      ;;
  esac
}

_flow_claude_help() {
  local b="${BOLD:-}" r="${RESET:-}" g="${GREEN:-}" y="${YELLOW:-}" c="${CYAN:-}"
  print "${b}flow claude${r} — Claude Code environment health checker"
  print ""
  print "${b}Usage:${r}"
  print "  flow claude check          Run all environment checks"
  print "  flow claude check --fix    Run checks + auto-repair safe mismatches (C1, C6)"
  print "  flow claude doctor         Alias for check"
  print ""
  print "${b}Checks:${r}"
  print "  C1  Settings parity       settings.json env block vs zshrc exports"
  print "  C2  Hook health           post-compact-reinject.sh exists + executable + shellcheck"
  print "  C3  Memory index drift    .md file count vs MEMORY.md entry count"
  print "  C4  CLAUDE.md length      warns when > 100 lines"
  print "  C5  Shell env parity      CLAUDE_AUTOCOMPACT_PCT_OVERRIDE exported"
  print "  C6  Output token limit    CLAUDE_CODE_MAX_OUTPUT_TOKENS > 8192 (auto-fixable with --fix)"
  print ""
  print "${b}Exit codes:${r} 0=all pass  1=any ERROR  2=any WARN (no ERROR)"
}

_flow_claude_check() {
  local fix=0
  [[ "${1:-}" == "--fix" ]] && fix=1

  # Injectable paths for testing
  local claude_home="${FLOW_CLAUDE_HOME:-$HOME/.claude}"
  local zshrc_path="${FLOW_CLAUDE_ZSHRC:-${ZDOTDIR:-$HOME/.config/zsh}/.zshrc}"

  local has_error=0
  local has_warn=0

  _flow_log_info "Claude Code environment check"
  print ""

  # ── C1: Settings parity ──────────────────────────────────────────────────
  local settings_json="$claude_home/settings.json"
  if [[ ! -f "$settings_json" ]]; then
    _flow_log_warning "C1 Settings parity     settings.json not found at $settings_json"
    has_warn=1
  elif ! command -v jq &>/dev/null; then
    _flow_log_warning "C1 Settings parity     jq not installed — cannot parse settings.json"
    has_warn=1
  else
    local mismatches=()
    local env_block
    env_block=$(jq -r '.env // {} | to_entries[] | "\(.key)=\(.value)"' "$settings_json" 2>/dev/null)

    if [[ -z "$env_block" ]]; then
      _flow_log_success "C1 Settings parity     no env block in settings.json"
    else
      while IFS= read -r pair; do
        local key="${pair%%=*}"
        local val="${pair#*=}"
        if ! grep -qE "^export ${key}=" "$zshrc_path" 2>/dev/null; then
          mismatches+=("$key missing from zshrc")
          if (( fix )); then
            _flow_claude_fix_c1 "$key" "$val" "$zshrc_path"
          fi
        else
          local zshrc_val
          zshrc_val=$(grep -E "^export ${key}=" "$zshrc_path" 2>/dev/null | tail -1 | sed "s/^export ${key}=//;s/[\"']//g")
          if [[ "$zshrc_val" != "$val" ]]; then
            mismatches+=("$key: settings.json=$val zshrc=$zshrc_val")
            if (( fix )); then
              _flow_claude_fix_c1 "$key" "$val" "$zshrc_path"
            fi
          fi
        fi
      done <<< "$env_block"

      if (( ${#mismatches[@]} == 0 )); then
        _flow_log_success "C1 Settings parity     settings.json env matches zshrc"
      else
        _flow_log_warning "C1 Settings parity     ${mismatches[*]}"
        has_warn=1
      fi
    fi
  fi

  # ── C2: Hook health ──────────────────────────────────────────────────────
  local hook_file="$claude_home/hooks/post-compact-reinject.sh"
  if [[ ! -f "$hook_file" ]]; then
    _flow_log_error "C2 Hook health         post-compact-reinject.sh not found"
    has_error=1
  elif [[ ! -x "$hook_file" ]]; then
    _flow_log_error "C2 Hook health         post-compact-reinject.sh not executable"
    has_error=1
  else
    if command -v shellcheck &>/dev/null; then
      local sc_out
      sc_out=$(shellcheck "$hook_file" 2>&1)
      if [[ -n "$sc_out" ]]; then
        local first_issue
        first_issue=$(print "$sc_out" | head -1)
        _flow_log_error "C2 Hook health         shellcheck: $first_issue"
        has_error=1
      else
        _flow_log_success "C2 Hook health         hook exists, executable, shellcheck clean"
      fi
    else
      _flow_log_success "C2 Hook health         hook exists + executable (shellcheck not installed)"
    fi
  fi

  # ── C3: Memory index drift ───────────────────────────────────────────────
  local memory_dir="$claude_home/projects"
  if [[ ! -d "$memory_dir" ]]; then
    _flow_log_warning "C3 Memory index drift  $memory_dir not found"
    has_warn=1
  else
    local drift_found=0
    for proj_memory in "$memory_dir"/*/memory(/N); do
      [[ -d "$proj_memory" ]] || continue
      local memory_md="$proj_memory/MEMORY.md"
      # Count .md files excluding MEMORY.md itself
      local file_count
      file_count=$(find "$proj_memory" -maxdepth 1 -name "*.md" -not -name "MEMORY.md" 2>/dev/null | wc -l | tr -d ' ')
      if [[ -f "$memory_md" ]]; then
        local entry_count=0
        entry_count=$(grep -c '^- \[' "$memory_md" 2>/dev/null) || true
        if [[ "$file_count" != "$entry_count" ]]; then
          local proj_name="${proj_memory%/memory}"
          proj_name="${proj_name##*/}"
          _flow_log_warning "C3 Memory index drift  $proj_name: $file_count files, $entry_count MEMORY.md entries"
          has_warn=1
          drift_found=1
        fi
      fi
    done
    if (( ! drift_found )); then
      _flow_log_success "C3 Memory index drift  all memory dirs in sync"
    fi
  fi

  # ── C4: CLAUDE.md length ────────────────────────────────────────────────
  local claude_md="$claude_home/CLAUDE.md"
  if [[ ! -f "$claude_md" ]]; then
    _flow_log_success "C4 CLAUDE.md length    not found (no check)"
  else
    local line_count
    line_count=$(wc -l < "$claude_md" | tr -d ' ')
    if (( line_count > 100 )); then
      _flow_log_warning "C4 CLAUDE.md length    $line_count lines — exceeds 100-line rule (trim before adding)"
      has_warn=1
    else
      _flow_log_success "C4 CLAUDE.md length    $line_count lines — within limit"
    fi
  fi

  # ── C5: Shell env parity ────────────────────────────────────────────────
  if [[ -n "${CLAUDE_AUTOCOMPACT_PCT_OVERRIDE:-}" ]]; then
    _flow_log_info "C5 Shell env parity    CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=${CLAUDE_AUTOCOMPACT_PCT_OVERRIDE} exported"
  else
    _flow_log_info "C5 Shell env parity    CLAUDE_AUTOCOMPACT_PCT_OVERRIDE not set in current session"
  fi

  # ── C6: Output token limit ──────────────────────────────────────────────
  local token_val=""
  # Check settings.json first (canonical)
  if [[ -f "$settings_json" ]] && command -v jq &>/dev/null; then
    token_val=$(jq -r '.env.CLAUDE_CODE_MAX_OUTPUT_TOKENS // ""' "$settings_json" 2>/dev/null)
  fi
  # Fall back to zshrc
  if [[ -z "$token_val" ]] && [[ -f "$zshrc_path" ]]; then
    token_val=$(grep -E "^export CLAUDE_CODE_MAX_OUTPUT_TOKENS=" "$zshrc_path" 2>/dev/null | tail -1 | sed 's/^export CLAUDE_CODE_MAX_OUTPUT_TOKENS=//;s/[\"'\'']//g')
  fi

  if [[ -z "$token_val" ]]; then
    _flow_log_warning "C6 Output token limit  CLAUDE_CODE_MAX_OUTPUT_TOKENS not set — default 8192 cap may truncate responses"
    has_warn=1
    if (( fix )); then
      _flow_claude_fix_c6 "$zshrc_path"
    fi
  elif (( token_val <= 8192 )); then
    _flow_log_warning "C6 Output token limit  CLAUDE_CODE_MAX_OUTPUT_TOKENS=${token_val} — still at default cap (set > 8192)"
    has_warn=1
    if (( fix )); then
      _flow_claude_fix_c6 "$zshrc_path"
    fi
  else
    _flow_log_success "C6 Output token limit  CLAUDE_CODE_MAX_OUTPUT_TOKENS=${token_val}"
  fi

  # ── Summary ──────────────────────────────────────────────────────────────
  print ""
  if (( has_error )); then
    _flow_log_error "Result: checks failed (see ERRORs above)"
    return 1
  elif (( has_warn )); then
    _flow_log_warning "Result: checks passed with warnings"
    return 2
  else
    _flow_log_success "Result: all checks passed"
    return 0
  fi
}

# Repair C6: set CLAUDE_CODE_MAX_OUTPUT_TOKENS=32000 in zshrc
_flow_claude_fix_c6() {
  local zshrc="$1"
  _flow_claude_fix_c1 "CLAUDE_CODE_MAX_OUTPUT_TOKENS" "32000" "$zshrc"
}

# Repair C1: update or append an export line in zshrc
_flow_claude_fix_c1() {
  local key="$1"
  local val="$2"
  local zshrc="$3"

  if [[ ! -f "$zshrc" ]]; then
    _flow_log_warning "  --fix: zshrc not found at $zshrc — skipping $key"
    return 1
  fi

  if grep -qE "^export ${key}=" "$zshrc" 2>/dev/null; then
    # Replace existing line — use | as delimiter to avoid / conflicts in values
    sed -i '' "s|^export ${key}=.*|export ${key}=${val}|" "$zshrc"
    _flow_log_success "  --fix: updated $key in zshrc"
  else
    # Append new export line
    print "\nexport ${key}=${val}" >> "$zshrc"
    _flow_log_success "  --fix: added $key to zshrc"
  fi
}

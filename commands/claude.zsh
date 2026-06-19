# commands/claude.zsh — flow claude subcommand
# Claude Code environment health checker

flow_claude() {
  local subcmd="${1:-check}"
  shift 2>/dev/null

  case "$subcmd" in
    check|doctor) _flow_claude_check "$@" ;;
    watch) _flow_claude_watch "$@" ;;
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
  print "  flow claude check              Run all environment checks"
  print "  flow claude check --fix        Run checks + auto-repair safe mismatches (C1, C6)"
  print "  flow claude doctor             Alias for check"
  print "  flow claude watch              Start background health watcher (30-min default)"
  print "  flow claude watch --stop       Stop watcher"
  print "  flow claude watch --status     Show watcher status + last result"
  print "  flow claude watch --interval N Set poll interval in minutes"
  print ""
  print "${b}Checks:${r}"
  print "  C1  Settings parity       settings.json env block vs zshrc exports"
  print "  C2  Hook health           post-compact-reinject.sh exists + executable + shellcheck"
  print "  C3  Memory index drift    .md file count vs MEMORY.md entry count"
  print "  C4  CLAUDE.md length      warns > 100 lines, errors > 180"
  print "  C5  Shell env parity      CLAUDE_AUTOCOMPACT_PCT_OVERRIDE exported"
  print "  C6  Output token limit    CLAUDE_CODE_MAX_OUTPUT_TOKENS > 8192 (auto-fixable with --fix)"
  print "  C7  Project CLAUDE.md     per-project line count + version drift"
  print "  C8  Orphaned memory       ~/.claude/projects/ dirs for deleted projects"
  print "  C9  Rules drift           ~/.claude/rules/*.md files not cited in CLAUDE.md"
  print "  C10 Hook files            hooks in settings.json pointing to missing scripts"
  print "  C11 Plugin health         ~/.claude/plugins/ dirs missing valid plugin.json"
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
      local key val zshrc_val
      while IFS= read -r pair; do
        key="${pair%%=*}"
        val="${pair#*=}"
        if ! grep -qE "^export ${key}=" "$zshrc_path" 2>/dev/null; then
          mismatches+=("$key missing from zshrc")
          if (( fix )); then
            _flow_claude_fix_c1 "$key" "$val" "$zshrc_path"
          fi
        else
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
    local drift_found=0 memory_md file_count entry_count proj_name
    for proj_memory in "$memory_dir"/*/memory(/N); do
      [[ -d "$proj_memory" ]] || continue
      memory_md="$proj_memory/MEMORY.md"
      # Count .md files excluding MEMORY.md itself
      file_count=$(find "$proj_memory" -maxdepth 1 -name "*.md" -not -name "MEMORY.md" 2>/dev/null | wc -l | tr -d ' ')
      if [[ -f "$memory_md" ]]; then
        entry_count=0
        entry_count=$(grep -c '^- \[' "$memory_md" 2>/dev/null) || true
        if [[ "$file_count" != "$entry_count" ]]; then
          proj_name="${proj_memory%/memory}"
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
    if (( line_count > 180 )); then
      _flow_log_error "C4 CLAUDE.md length    $line_count lines — exceeds 180-line hard limit (see ~/.claude/rules/claude-md-length.md)"
      has_error=1
    elif (( line_count > 100 )); then
      _flow_log_warning "C4 CLAUDE.md length    $line_count lines — approaching 180-line limit (trim before adding)"
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

  # ── C7: Per-project CLAUDE.md audit ─────────────────────────────────────
  local projects_root="${FLOW_CLAUDE_PROJECTS_ROOT:-$HOME/projects}"
  if [[ -d "$projects_root" ]]; then
    local c7_issues=() c7_scanned=0 c7_clean=0
    local proj_file
    while IFS= read -r proj_file; do
      [[ -z "$proj_file" ]] && continue
      (( c7_scanned++ ))
      local proj_dir="${proj_file:h}"
      local rel_path="${proj_file#$projects_root/}"
      local file_has_issue=0

      # C7a: line count
      local plines
      plines=$(wc -l < "$proj_file" | tr -d ' ')
      if (( plines > 180 )); then
        c7_issues+=("$rel_path: $plines lines (> 180)")
        file_has_issue=1
      fi

      # C7b: version drift (only if repo has tags)
      local git_tag
      git_tag=$(git -C "$proj_dir" describe --tags --abbrev=0 2>/dev/null)
      if [[ -n "$git_tag" ]]; then
        local version_refs
        version_refs=$(grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' "$proj_file" 2>/dev/null)
        local vref
        while IFS= read -r vref; do
          [[ -z "$vref" ]] && continue
          if [[ "$vref" != "$git_tag" ]]; then
            c7_issues+=("$rel_path: version ref $vref (current: $git_tag)")
            file_has_issue=1
          fi
        done <<< "$version_refs"
      fi

      (( file_has_issue )) || (( c7_clean++ ))
    done <<< "$(_flow_find_project_claude_mds "$projects_root")"

    if (( ${#c7_issues[@]} > 0 )); then
      _flow_log_warning "C7 Project CLAUDE.md   ${#c7_issues[@]} issue(s) ($c7_scanned files scanned):"
      local issue
      for issue in "${c7_issues[@]}"; do
        print "    $issue"
      done
      if (( c7_clean > 0 )); then
        _flow_log_success "C7 Project CLAUDE.md   $c7_clean clean"
      fi
      has_warn=1
    else
      _flow_log_success "C7 Project CLAUDE.md   $c7_scanned files scanned, all clean"
    fi
  else
    _flow_log_success "C7 Project CLAUDE.md   projects root not found (skipped)"
  fi

  # ── C8: Orphaned memory dirs ────────────────────────────────────────────
  local claude_projects="$claude_home/projects"
  if [[ -d "$claude_projects" ]]; then
    local orphaned=() valid_count=0
    local proj_slug proj_dir_path decoded_path
    for proj_dir_path in "$claude_projects"/*(N/); do
      proj_slug="${proj_dir_path##*/}"
      decoded_path="/${proj_slug//-//}"
      if [[ ! -d "$decoded_path" ]]; then
        orphaned+=("$proj_slug (path $decoded_path not found)")
      else
        (( valid_count++ ))
      fi
    done
    if (( ${#orphaned[@]} > 0 )); then
      _flow_log_warning "C8 Orphaned memory     ${#orphaned[@]} stale dir(s):"
      local orphan
      for orphan in "${orphaned[@]}"; do
        print "    $orphan"
      done
      has_warn=1
    else
      _flow_log_success "C8 Orphaned memory     $valid_count dirs all valid"
    fi
  fi

  # ── C9: Rules drift ─────────────────────────────────────────────────────
  local rules_dir="$claude_home/rules"
  local claude_md_global="$claude_home/CLAUDE.md"
  if [[ -d "$rules_dir" ]] && [[ -f "$claude_md_global" ]]; then
    local unreferenced=() ref_count=0
    local rule_file rule_stem
    for rule_file in "$rules_dir"/*.md(N); do
      rule_stem="${rule_file:t:r}"
      if ! grep -qF "$rule_stem" "$claude_md_global" 2>/dev/null; then
        unreferenced+=("$rule_stem")
      else
        (( ref_count++ ))
      fi
    done
    if (( ${#unreferenced[@]} > 0 )); then
      _flow_log_warning "C9 Rules drift         ${#unreferenced[@]} unreferenced rule(s):"
      local rule
      for rule in "${unreferenced[@]}"; do
        print "    $rule (not mentioned in CLAUDE.md)"
      done
      has_warn=1
    else
      _flow_log_success "C9 Rules drift         $ref_count rules all referenced"
    fi
  elif [[ ! -d "$rules_dir" ]]; then
    _flow_log_success "C9 Rules drift         no rules dir found (skipped)"
  fi

  # ── C10: Missing hook files ──────────────────────────────────────────────
  if [[ -f "$settings_json" ]]; then
    if ! command -v jq &>/dev/null; then
      _flow_log_warning "C10 Hook files         jq not installed — cannot check hooks"
      has_warn=1
    else
      local missing_hooks=() hooks_present=0
      local hook_cmd hook_cmds
      hook_cmds=$(jq -r '(.hooks // {}) | to_entries[] | .value[] | .command' "$settings_json" 2>/dev/null)
      while IFS= read -r hook_cmd; do
        [[ -z "$hook_cmd" ]] && continue
        # Only check file paths (absolute or home-relative)
        if [[ "$hook_cmd" == /* ]] || [[ "$hook_cmd" == ~* ]]; then
          local expanded_cmd="${hook_cmd/#\~/$HOME}"
          local script_path="${expanded_cmd%% *}"
          if [[ ! -f "$script_path" ]]; then
            missing_hooks+=("$script_path (defined in settings.json, not found)")
          else
            (( hooks_present++ ))
          fi
        fi
      done <<< "$hook_cmds"

      if (( ${#missing_hooks[@]} > 0 )); then
        _flow_log_error "C10 Hook files         ${#missing_hooks[@]} missing:"
        local mh
        for mh in "${missing_hooks[@]}"; do
          print "    $mh"
        done
        has_error=1
      else
        _flow_log_success "C10 Hook files         $hooks_present hooks all present"
      fi
    fi
  fi

  # ── C11: Plugin health ───────────────────────────────────────────────────
  local plugins_dir="$claude_home/plugins"
  if [[ -d "$plugins_dir" ]] && command -v jq &>/dev/null; then
    local broken_plugins=() healthy_plugins=0
    local plugin_dir pjson
    for plugin_dir in "$plugins_dir"/*(N/); do
      [[ "${plugin_dir:t}" == "cache" ]] && continue
      pjson="$plugin_dir/plugin.json"
      if [[ ! -f "$pjson" ]]; then
        broken_plugins+=("${plugin_dir:t}: missing plugin.json")
      elif ! jq empty "$pjson" 2>/dev/null; then
        broken_plugins+=("${plugin_dir:t}: invalid JSON in plugin.json")
      else
        (( healthy_plugins++ ))
      fi
    done
    if (( ${#broken_plugins[@]} > 0 )); then
      _flow_log_warning "C11 Plugin health      ${#broken_plugins[@]} broken plugin(s):"
      local bp
      for bp in "${broken_plugins[@]}"; do
        print "    $bp"
      done
      has_warn=1
    else
      _flow_log_success "C11 Plugin health      $healthy_plugins plugins healthy"
    fi
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

# Find all project CLAUDE.md files under the given root
_flow_find_project_claude_mds() {
  local projects_root="${1:-$HOME/projects}"
  find "$projects_root" -maxdepth 4 -name "CLAUDE.md" \
    -not -path "*/.git/*" \
    -not -path "*/node_modules/*" \
    2>/dev/null
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
    # Replace existing line — portable temp-file approach (BSD sed needs '' suffix, GNU sed doesn't)
    local tmp_file
    tmp_file=$(mktemp "${zshrc}.XXXXXX")
    sed "s|^export ${key}=.*|export ${key}=${val}|" "$zshrc" > "$tmp_file" && mv "$tmp_file" "$zshrc"
    _flow_log_success "  --fix: updated $key in zshrc"
  else
    # Append new export line
    print "\nexport ${key}=${val}" >> "$zshrc"
    _flow_log_success "  --fix: added $key to zshrc"
  fi
}

# ── Watch daemon ──────────────────────────────────────────────────────────

_flow_claude_watch() {
  local interval=30
  local do_stop=0
  local do_status=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --stop) do_stop=1; shift ;;
      --status) do_status=1; shift ;;
      --interval) interval="${2:-30}"; shift 2 ;;
      --interval=*) interval="${1#--interval=}"; shift ;;
      *) shift ;;
    esac
  done

  if (( do_stop )); then
    _flow_claude_watch_stop
  elif (( do_status )); then
    _flow_claude_watch_status
  else
    _flow_claude_watch_start "$interval"
  fi
}

_flow_claude_watch_start() {
  local interval_min="${1:-30}"
  local interval_sec=$(( interval_min * 60 ))
  local flow_dir="$HOME/.flow"
  local pid_file="$flow_dir/claude-watch.pid"
  local state_file="$flow_dir/claude-health-state.json"
  local log_file="$flow_dir/claude-watch.log"

  mkdir -p "$flow_dir"

  # Stale PID check
  if [[ -f "$pid_file" ]]; then
    local old_pid
    old_pid=$(< "$pid_file")
    if kill -0 "$old_pid" 2>/dev/null; then
      _flow_log_warning "watch already running (PID $old_pid) — use --stop first"
      return 1
    fi
    rm -f "$pid_file"
  fi

  # Launch background loop
  (
    print $$ > "$pid_file"
    while true; do
      _flow_claude_watch_run_check "$state_file" >> "$log_file" 2>&1
      # Log rotation: keep last 50KB
      if [[ -f "$log_file" ]] && (( $(wc -c < "$log_file") > 50000 )); then
        tail -c 50000 "$log_file" > "${log_file}.tmp" && mv "${log_file}.tmp" "$log_file"
      fi
      sleep "$interval_sec"
    done
  ) &
  disown $!
  _flow_log_success "watch started (PID $!, interval ${interval_min}m)"
}

_flow_claude_watch_stop() {
  local pid_file="$HOME/.flow/claude-watch.pid"
  if [[ ! -f "$pid_file" ]]; then
    _flow_log_warning "watch not running (no pid file)"
    return 0
  fi
  local pid
  pid=$(< "$pid_file")
  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null
    rm -f "$pid_file"
    _flow_log_success "watch stopped (PID $pid)"
  else
    rm -f "$pid_file"
    _flow_log_warning "watch was not running (stale pid $pid), cleaned up"
  fi
}

_flow_claude_watch_status() {
  local pid_file="$HOME/.flow/claude-watch.pid"
  local state_file="$HOME/.flow/claude-health-state.json"

  local is_running=0 pid=""
  if [[ -f "$pid_file" ]]; then
    pid=$(< "$pid_file")
    kill -0 "$pid" 2>/dev/null && is_running=1
  fi

  if (( is_running )); then
    print "● flow claude watch   running (PID $pid)"
  else
    print "○ flow claude watch   not running"
  fi

  if [[ -f "$state_file" ]] && command -v jq &>/dev/null; then
    local last_check result interval_sec interval_min
    last_check=$(jq -r '.last_check // "unknown"' "$state_file" 2>/dev/null)
    result=$(jq -r '.result // "unknown"' "$state_file" 2>/dev/null)
    interval_sec=$(jq -r '.interval // 1800' "$state_file" 2>/dev/null)
    interval_min=$(( interval_sec / 60 ))
    print "  Last check: $last_check — $(print "$result" | tr '[:lower:]' '[:upper:]')"
    if (( is_running )); then
      print "  (interval: ${interval_min}m)"
    else
      print "  (watcher was stopped)"
    fi
  fi
}

_flow_claude_watch_run_check() {
  local state_file="${1:-$HOME/.flow/claude-health-state.json}"

  # Read previous result
  local prev_result="pass"
  if [[ -f "$state_file" ]] && command -v jq &>/dev/null; then
    prev_result=$(jq -r '.result // "pass"' "$state_file" 2>/dev/null)
  fi

  # Run check in subshell, capture exit code
  local check_rc
  _flow_claude_check > /dev/null 2>&1
  check_rc=$?

  local new_result
  case "$check_rc" in
    0) new_result="pass" ;;
    1) new_result="error" ;;
    2) new_result="warn" ;;
    *) new_result="error" ;;
  esac

  local now
  now=$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date '+%Y-%m-%dT%H:%M:%SZ')

  # Preserve interval from existing state or default to 1800
  local interval=1800
  if [[ -f "$state_file" ]] && command -v jq &>/dev/null; then
    interval=$(jq -r '.interval // 1800' "$state_file" 2>/dev/null)
  fi

  local pid_file="$HOME/.flow/claude-watch.pid"
  local pid=""
  [[ -f "$pid_file" ]] && pid=$(< "$pid_file")

  # Write new state JSON
  if command -v jq &>/dev/null; then
    jq -n \
      --arg pid "$pid" \
      --argjson interval "$interval" \
      --arg last_check "$now" \
      --arg result "$new_result" \
      '{pid: $pid, interval: $interval, last_check: $last_check, result: $result}' \
      > "$state_file" 2>/dev/null
  else
    print "{\"pid\":\"$pid\",\"interval\":$interval,\"last_check\":\"$now\",\"result\":\"$new_result\"}" > "$state_file"
  fi

  # Notify on state change
  _flow_claude_watch_notify "$prev_result" "$new_result" "Health state changed to $new_result"
}

_flow_claude_watch_notify() {
  local prev_result="$1"
  local new_result="$2"
  local summary="$3"

  # No change, silent
  [[ "$prev_result" == "$new_result" ]] && return

  # Only notify if new or old state is warn/error (skip pass↔pass)
  if [[ "$new_result" == "pass" && "$prev_result" == "pass" ]]; then return; fi

  local title="flow claude"
  local subtitle message
  if [[ "$new_result" == "pass" ]]; then
    subtitle="Health restored"
    message="All checks passing"
  elif [[ "$new_result" == "error" ]]; then
    subtitle="Health degraded — ERROR"
    message="$summary"
  else
    subtitle="Health warning"
    message="$summary"
  fi

  if command -v terminal-notifier &>/dev/null; then
    terminal-notifier -title "$title" -subtitle "$subtitle" \
      -message "$message" -sound default
  fi
  # Silent fallback on Linux (no terminal-notifier)
}

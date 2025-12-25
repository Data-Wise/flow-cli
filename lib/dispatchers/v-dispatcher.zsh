# v-dispatcher.zsh - DEPRECATED: Routes to flow command
# This file provides backward compatibility for v/vibe commands
# All functionality has been migrated to the 'flow' command

# ============================================================================
# DEPRECATION NOTICE
# ============================================================================

_v_deprecation_warning() {
  local old_cmd="$1"
  local new_cmd="$2"

  # Only show warning once per session per command
  local var_name="_V_WARNED_${old_cmd//[^a-zA-Z0-9]/_}"

  if [[ -z "${(P)var_name}" ]]; then
    echo ""
    echo "⚠️  DEPRECATED: '$old_cmd' is now 'flow $new_cmd'"
    echo "   The 'v' command will be removed in a future version."
    echo ""
    eval "$var_name=1"
  fi
}

# ============================================================================
# V / VIBE - Deprecated Dispatcher
# ============================================================================

v() {
  local cmd="${1:-}"
  shift 2>/dev/null || true

  case "$cmd" in
    # Help
    help|--help|-h|"")
      cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║  ⚠️  V/VIBE IS DEPRECATED - Use 'flow' instead                            ║
╚════════════════════════════════════════════════════════════════════════════╝

The 'v' and 'vibe' commands have been replaced by 'flow'.

MIGRATION GUIDE:
  v test          →  flow test
  v test watch    →  flow test --watch
  v coord sync    →  flow sync
  v plan          →  flow plan
  v log           →  flow log
  v check         →  flow check
  vibe            →  flow

Run 'flow help' for full command reference.
EOF
      return
      ;;

    # Test commands
    test|t)
      _v_deprecation_warning "v test" "test"
      flow test "$@"
      ;;

    # Coord/sync commands
    coord)
      local subcmd="${1:-}"
      case "$subcmd" in
        sync)
          _v_deprecation_warning "v coord sync" "sync"
          shift
          flow sync "$@"
          ;;
        *)
          _v_deprecation_warning "v coord" "sync"
          flow sync "$@"
          ;;
      esac
      ;;

    # Plan commands
    plan)
      _v_deprecation_warning "v plan" "plan"
      flow plan "$@"
      ;;

    # Log commands
    log)
      _v_deprecation_warning "v log" "log"
      flow log "$@"
      ;;

    # Check commands
    check)
      _v_deprecation_warning "v check" "check"
      flow check "$@"
      ;;

    # Build commands
    build|b)
      _v_deprecation_warning "v build" "build"
      flow build "$@"
      ;;

    # Preview commands
    preview|view|pv)
      _v_deprecation_warning "v preview" "preview"
      flow preview "$@"
      ;;

    # Status/dash commands
    dash|status)
      _v_deprecation_warning "v $cmd" "$cmd"
      flow "$cmd" "$@"
      ;;

    # Unknown - pass through to flow
    *)
      _v_deprecation_warning "v $cmd" "$cmd"
      flow "$cmd" "$@"
      ;;
  esac
}

# Vibe is alias for v
vibe() {
  _v_deprecation_warning "vibe" ""

  if [[ -z "$1" ]]; then
    flow help
  else
    v "$@"
  fi
}

# ============================================================================
# NOTICE
# ============================================================================
# To fully remove v/vibe after deprecation period:
# 1. Delete this file
# 2. Remove from lib/dispatchers/ loading in flow.plugin.zsh
# ============================================================================

#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# tok-sync.zsh — Config-driven fan-out of a secret value to GitHub Actions
#                secrets across repos.
# ══════════════════════════════════════════════════════════════════════════════
#
# Reads a flat, whitespace-delimited, chezmoi-managed config file (NEVER sourced;
# always parsed with `while read -r`) and pushes a single secret value to one or
# more `gh secret set` targets via stdin only.
#
# Config path: ${FLOW_TOK_SYNC_CONF:-$HOME/.config/flow/tok-sync.conf}
# Config format:  <token-name>  <secret-name>  <owner/repo>  [oidc]
#   - Lines starting with '#' and blank lines are ignored.
#   - `oidc` rows are surfaced as Trusted-Publishing recommendations, never pushed.
#
# Sourced by flow.plugin.zsh; consumed by the tok dispatcher (tok sync push/repos
# and the post-store auto-sync hooks).
# ══════════════════════════════════════════════════════════════════════════════

# Load guard
if [[ -n "$_TOK_SYNC_LOADED" ]]; then
    return 0 2>/dev/null || true
fi
typeset -g _TOK_SYNC_LOADED=1

# Allowlist for secret names and owner/repo slugs. Anything outside this set is
# rejected to keep arbitrary config data out of argv passed to `gh`.
typeset -gr _TOK_SYNC_FIELD_RE='^[A-Za-z0-9._/-]+$'

# ──────────────────────────────────────────────────────────────────────────────
# _tok_sync_conf_path → echo the active config file path
# ──────────────────────────────────────────────────────────────────────────────
_tok_sync_conf_path() {
    print -r -- "${FLOW_TOK_SYNC_CONF:-$HOME/.config/flow/tok-sync.conf}"
}

# ──────────────────────────────────────────────────────────────────────────────
# _tok_sync_load_targets <name>
#   Emit one line per matching row: secret<TAB>repo<TAB>flag
#   flag is "" or "oidc". Invalid rows are warned about and skipped.
#   Missing conf → emit nothing, return 0.
# ──────────────────────────────────────────────────────────────────────────────
_tok_sync_load_targets() {
    local name="$1"
    local conf
    conf="$(_tok_sync_conf_path)"

    [[ -f "$conf" ]] || return 0

    local line n secret repo flag extra
    while IFS= read -r line; do
        # Skip blank lines (any whitespace incl. tabs/CR) and comments.
        [[ -z "${line//[[:space:]]/}" ]] && continue
        local trimmed="${line#"${line%%[![:space:]]*}"}"
        [[ "$trimmed" == \#* ]] && continue

        # Split on whitespace into exactly the expected fields. `extra` catches
        # rows with too many columns (e.g. an unquoted repo containing spaces).
        n="" secret="" repo="" flag="" extra=""
        read -r n secret repo flag extra <<< "$line"

        # Only rows for the requested token name.
        [[ "$n" == "$name" ]] || continue

        # Warnings go to stderr so the emitted target list on stdout stays clean
        # (callers parse stdout line-by-line).
        # Reject rows with trailing/extra fields beyond the optional flag.
        if [[ -n "$extra" ]]; then
            _flow_log_warning "tok-sync: skipping malformed row: '$line'" >&2
            continue
        fi
        # If a flag is present it must be exactly 'oidc'.
        if [[ -n "$flag" && "$flag" != "oidc" ]]; then
            _flow_log_warning "tok-sync: skipping row with unknown flag '$flag': '$line'" >&2
            continue
        fi

        # Validate the fields that flow into `gh` argv.
        if [[ ! "$secret" =~ $_TOK_SYNC_FIELD_RE ]]; then
            _flow_log_warning "tok-sync: skipping row with invalid secret name: '$secret'" >&2
            continue
        fi
        if [[ ! "$repo" =~ $_TOK_SYNC_FIELD_RE ]]; then
            _flow_log_warning "tok-sync: skipping row with invalid repo: '$repo'" >&2
            continue
        fi

        printf '%s\t%s\t%s\n' "$secret" "$repo" "$flag"
    done < "$conf"

    return 0
}

# ──────────────────────────────────────────────────────────────────────────────
# _tok_sync_resolve_value <name>
#   Resolve the token value from the vault (manual-trigger path).
# ──────────────────────────────────────────────────────────────────────────────
_tok_sync_resolve_value() {
    local name="$1"
    sec "$name"
}

# ──────────────────────────────────────────────────────────────────────────────
# _tok_sync_oidc_note <secret> <repo>
#   Single source of truth for the Trusted-Publishing recommendation shown for
#   oidc-flagged rows. Consumed by _tok_sync_push (live) and the dispatcher's
#   _tok_sync_repos (dry-run) so the wording can't drift between the two.
# ──────────────────────────────────────────────────────────────────────────────
_tok_sync_oidc_note() {
    local secret="$1" repo="$2"
    _flow_log_info "OIDC: '$secret' for $repo — use Trusted Publishing instead of a stored secret."
    _flow_log_muted "    Add 'permissions: id-token: write' + 'pypa/gh-action-pypi-publish' to the workflow."
}

# ──────────────────────────────────────────────────────────────────────────────
# _tok_sync_push <name> [value]
#   Fan out the secret value to the configured GitHub Actions secrets.
#   Returns 0 on overall success (including non-fatal no-ops); non-zero only
#   when at least one attempted push failed.
# ──────────────────────────────────────────────────────────────────────────────
_tok_sync_push() {
    local name="$1"
    local value="$2"

    if [[ $# -lt 2 ]]; then
        value="$(_tok_sync_resolve_value "$name")"
    fi

    # Boundary guard: enforce the allowlist invariant on the token name. Keeps
    # arbitrary data out of downstream config-matching and argv passed to `gh`.
    if [[ ! "$name" =~ $_TOK_SYNC_FIELD_RE ]]; then
        _flow_log_error "tok-sync: invalid token name: '$name'"
        return 1
    fi

    # Guard: gh installed?
    if ! command -v gh >/dev/null 2>&1; then
        _flow_log_info "tok-sync: gh not installed — skipping auto-sync for '$name'"
        return 0
    fi

    # Guard: gh authenticated?
    if ! gh auth status >/dev/null 2>&1; then
        _flow_log_info "tok-sync: gh not authenticated — skipping auto-sync for '$name'"
        return 0
    fi

    # Guard: conf present?
    local conf
    conf="$(_tok_sync_conf_path)"
    if [[ ! -f "$conf" ]]; then
        _flow_log_info "tok-sync: no config at $conf — nothing to sync"
        return 0
    fi

    # Load targets.
    local -a rows
    rows=("${(@f)$(_tok_sync_load_targets "$name")}")
    # Drop empty entries (e.g. from no matches).
    rows=(${rows:#})

    if (( ${#rows} == 0 )); then
        _flow_log_info "tok-sync: no sync targets for '$name'"
        return 0
    fi

    # Partition into oidc rows vs push rows.
    local -a oidc_rows push_rows
    local row secret repo flag
    for row in "${rows[@]}"; do
        secret="${row%%	*}"
        repo="${${row#*	}%%	*}"
        flag="${row##*	}"
        if [[ "$flag" == "oidc" ]]; then
            oidc_rows+=("$secret	$repo")
        else
            push_rows+=("$secret	$repo")
        fi
    done

    # Surface OIDC recommendations (never pushed).
    for row in "${oidc_rows[@]}"; do
        secret="${row%%	*}"
        repo="${row##*	}"
        _tok_sync_oidc_note "$secret" "$repo"
    done

    if (( ${#push_rows} == 0 )); then
        return 0
    fi

    # Guard: empty value → no writes.
    if [[ -z "$value" ]]; then
        _flow_log_warning "tok-sync: resolved value for '$name' is empty — refusing to write"
        return 0
    fi

    # Show targets and confirm once (default N).
    echo "🔁 Auto-sync targets for '$name':"
    for row in "${push_rows[@]}"; do
        secret="${row%%	*}"
        repo="${row##*	}"
        echo "    $repo : $secret"
    done

    local answer
    printf 'Push to these %d target(s)? [y/N] ' "${#push_rows}"
    read -r answer
    if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
        _flow_log_info "tok-sync: aborted — no secrets written"
        return 0
    fi

    # Fan out via stdin only. Continue past failures; summarize at the end.
    local fail_count=0
    for row in "${push_rows[@]}"; do
        secret="${row%%	*}"
        repo="${row##*	}"
        # secret/repo are allowlist-validated above; value is passed only via
        # stdin, never argv (so it never lands in `ps`/history).
        if printf '%s' "$value" | gh secret set --repo "$repo" -- "$secret" >/dev/null 2>&1; then
            _flow_log_success "$repo : $secret"
        else
            _flow_log_error "$repo : $secret"
            (( fail_count++ ))
        fi
    done

    if (( fail_count > 0 )); then
        _flow_log_warning "tok-sync: $fail_count of ${#push_rows} push(es) failed"
        return 1
    fi

    return 0
}

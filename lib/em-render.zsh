#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# Email Render Pipeline — Content-type detection and rendering
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         lib/em-render.zsh
# Version:      0.1
# Date:         2026-02-10
#
# Used by:      lib/dispatchers/email-dispatcher.zsh
#
# Detection:
#   text/html + w3m available     → w3m -dump | pager
#   text/plain + markdown markers → glow
#   text/plain                    → bat --style=plain
#   fallback                      → cat
#
# ══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════
# SMART CONTENT RENDERER
# ═══════════════════════════════════════════════════════════════════

_em_render() {
    # Smart content renderer — detects type and dispatches
    # Args: content on stdin OR $1
    # Optional: $2 force_renderer (html|markdown|plain)
    local content="${1:-$(cat)}"
    local force_renderer="$2"

    [[ -z "$content" ]] && return 0

    if [[ -n "$force_renderer" ]]; then
        _em_render_with "$force_renderer" "$content"
        return
    fi

    # Detect content type
    if echo "$content" | grep -qi '<html\|<body\|<div\|<table\|<p>'; then
        _em_render_with "html" "$content"
    elif echo "$content" | grep -q '^\#\|^\*\*\|^```\|^\- \['; then
        _em_render_with "markdown" "$content"
    else
        _em_render_with "plain" "$content"
    fi
}

_em_render_with() {
    # Render content with a specific renderer
    # Args: renderer (html|markdown|plain), content
    local renderer="$1"
    local content="$2"

    case "$renderer" in
        html)
            if command -v w3m &>/dev/null; then
                echo "$content" | w3m -dump -T text/html | _em_pager
            elif command -v lynx &>/dev/null; then
                echo "$content" | lynx -stdin -dump | _em_pager
            elif command -v bat &>/dev/null; then
                echo "$content" | bat --style=plain --color=always --language=html
            else
                echo "$content"
            fi
            ;;
        markdown)
            if command -v glow &>/dev/null; then
                echo "$content" | glow -
            elif command -v bat &>/dev/null; then
                echo "$content" | bat --style=plain --color=always --language=markdown
            else
                echo "$content"
            fi
            ;;
        plain)
            if command -v bat &>/dev/null; then
                echo "$content" | bat --style=plain --color=always --paging=never
            else
                echo "$content"
            fi
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════
# SMART RENDER (stdin pipeline — kept for backwards compat)
# ═══════════════════════════════════════════════════════════════════

_em_smart_render() {
    # Content-type detection pipeline (reads from stdin)
    # Legacy interface — delegates to _em_render
    local tmpfile
    tmpfile=$(mktemp "${TMPDIR:-/tmp}/em-render-XXXXXX")
    cat > "$tmpfile"

    local content
    content=$(< "$tmpfile")

    if [[ -z "$content" ]]; then
        rm -f "$tmpfile"
        return 0
    fi

    _em_render "$content"
    rm -f "$tmpfile"
}

# ═══════════════════════════════════════════════════════════════════
# PAGER
# ═══════════════════════════════════════════════════════════════════

_em_pager() {
    # Smart pager: bat if available, otherwise less/cat
    if command -v bat &>/dev/null; then
        bat --style=plain --color=always --paging=always
    elif [[ -t 1 ]]; then
        less -R
    else
        cat
    fi
}

# ═══════════════════════════════════════════════════════════════════
# INBOX RENDERING
# ═══════════════════════════════════════════════════════════════════

_em_render_inbox() {
    # Legacy: colorize himalaya text table output (fallback)
    local line
    local is_header=true
    while IFS= read -r line; do
        if [[ "$is_header" == true ]]; then
            echo -e "${_C_BOLD}${line}${_C_NC}"
            is_header=false
        elif [[ "$line" == *"───"* || "$line" == *"━━━"* || "$line" == *"---"* ]]; then
            echo -e "${_C_DIM}${line}${_C_NC}"
        elif [[ "$line" != *"Seen"* && "$line" != *"seen"* ]]; then
            echo -e "${_C_YELLOW}${_C_BOLD}${line}${_C_NC}"
        else
            echo "$line"
        fi
    done
}

_em_render_inbox_json() {
    # Structured JSON renderer for himalaya envelope list --output json
    # Schema: {id, flags, subject, from: {name, addr}, date, has_attachment}
    if ! command -v jq &>/dev/null; then
        cat | _em_render_inbox
        return
    fi

    local json
    json=$(cat)

    if [[ -z "$json" || "$json" == "[]" ]]; then
        echo -e "  ${_C_DIM}(no emails)${_C_NC}"
        return
    fi

    # Header
    printf "  ${_C_BOLD}%-5s %-2s %-20s %-40s %s${_C_NC}\n" "ID" "" "From" "Subject" "Date"
    echo -e "  ${_C_DIM}───── ── ──────────────────── ──────────────────────────────────────── ──────────${_C_NC}"

    # Rows
    echo "$json" | jq -r '.[] | [
        (.id | tostring),
        (if (.flags | contains(["Seen"])) then " " else "*" end),
        (if .has_attachment then "+" else " " end),
        (.from.name // .from.addr // "unknown"),
        .subject,
        (.date | split("T")[0] // .date)
    ] | @tsv' | while IFS=$'\t' read -r eid flag attach sender subj edate; do
        # Truncate long fields
        [[ ${#sender} -gt 20 ]] && sender="${sender:0:17}..."
        [[ ${#subj} -gt 40 ]] && subj="${subj:0:37}..."

        local indicator="${flag}${attach}"
        if [[ "$flag" == "*" ]]; then
            printf "  ${_C_YELLOW}${_C_BOLD}%-5s %-2s %-20s %-40s %s${_C_NC}\n" "$eid" "$indicator" "$sender" "$subj" "$edate"
        else
            printf "  %-5s %-2s %-20s %-40s ${_C_DIM}%s${_C_NC}\n" "$eid" "$indicator" "$sender" "$subj" "$edate"
        fi
    done
}

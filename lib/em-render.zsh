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
#   text/html + lynx available    → lynx -dump | pager
#   text/html + pandoc available  → pandoc html→plain | pager
#   text/html + bat available     → bat (syntax highlighted)
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
            elif command -v pandoc &>/dev/null; then
                echo "$content" | pandoc -f html -t plain --wrap=auto | _em_pager
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
                echo "$content" | bat --style=plain --color=always --paging=never --language=txt
            else
                echo "$content"
            fi
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════
# MARKDOWN RENDERER (HTML → clean Markdown via pandoc)
# ═══════════════════════════════════════════════════════════════════

_em_render_markdown() {
    # Convert HTML email → clean Markdown via pandoc
    # Cleans SafeLinks, Outlook div wrappers, signatures
    # Args: $1 = HTML content
    # Renders: to terminal via glow/bat, or plain
    local html_content="$1"

    if ! command -v pandoc &>/dev/null; then
        _flow_log_error "pandoc required for --md (brew install pandoc)"
        return 1
    fi

    [[ -z "$html_content" ]] && return 0

    # Stage 1: pandoc HTML → Markdown
    local md
    md=$(echo "$html_content" | pandoc -f html -t markdown --wrap=auto 2>/dev/null)

    [[ -z "$md" ]] && return 0

    # Stage 2: Clean SafeLinks URLs — extract real URL from Outlook wrapper
    # Pattern: https://nam02.safelinks.protection.outlook.com/?url=REAL_URL&data=...
    md=$(echo "$md" | sed -E \
        -e 's|https://nam[0-9]*\.safelinks\.protection\.outlook\.com/\?url=([^&]*)&[^)]*|\1|g' \
        -e 's|https://nam[0-9]*\.safelinks\.protection\.outlook\.com/\?url=([^&]*)&[^]]*|\1|g' \
    )

    # URL-decode %3A → : , %2F → / , %23 → # , %3F → ? , %3D → = , %26 → &
    md=$(echo "$md" | sed \
        -e 's/%3A/:/g' -e 's/%3a/:/g' \
        -e 's/%2F/\//g' -e 's/%2f/\//g' \
        -e 's/%23/#/g' \
        -e 's/%3F/?/g' -e 's/%3f/?/g' \
        -e 's/%3D/=/g' -e 's/%3d/=/g' \
        -e 's/%26/\&/g' \
    )

    # Stage 3: Strip Outlook attribute blocks (multi-line aware)
    # Handles: {originalsrc="..." \n outlook-id="..."}, {style="..."},
    #          {.elementToProof style="..."}, {#id style="..."}
    # Also strips: .OWAAutoLink, .x_x_x_OWAAutoLink, lone outlook-id lines
    md=$(echo "$md" | awk '
        # Accumulate lines inside { } attribute blocks
        /\{(originalsrc|\.OWAAutoLink|\.elementToProof|#[a-zA-Z])/ {
            if (/\}/) { gsub(/\{[^}]*\}/, ""); print; next }
            buf = $0; eating = 1; next
        }
        /\{style="/ {
            if (/\}/) { gsub(/\{[^}]*\}/, ""); print; next }
            buf = $0; eating = 1; next
        }
        eating {
            buf = buf $0
            if (/\}/) {
                gsub(/\{[^}]*\}/, "", buf)
                print buf; eating = 0; buf = ""
            }
            next
        }
        # Strip standalone outlook-id lines
        /^[> ]*outlook-id="/ { next }
        # Strip OWA class names
        /^[> ]*\.x*_*O?WA/ { next }
        # Strip auth="NotApplicable" lines
        /^[> ]*auth="NotApplicable"/ { next }
        { print }
    ')

    # Stage 4: Strip pandoc fenced div wrappers from Outlook styles
    # Matches ::: , :::: , :::::::::: etc (with or without attributes)
    # Also handles > ::: prefixed quoted variants
    md=$(echo "$md" | sed -E \
        -e '/^[> ]*:{3,} *\{/d' \
        -e '/^[> ]*:{3,} *$/d' \
    )

    # Stage 5: Strip CID image refs and lone backslashes (pandoc <br>)
    md=$(echo "$md" | sed \
        -e 's/!\[[^]]*\](cid:[^)]*)//g' \
        -e '/^\[cid:/d' \
        -e '/^[> ]*\\$/d' \
    )

    # Stage 6: Clean escaped quotes and trailing noise
    md=$(echo "$md" | sed \
        -e 's/\\""/"/g' \
        -e 's/\\"/"/g' \
    )

    # Stage 7: Collapse excessive blank lines (3+ → 2)
    md=$(echo "$md" | awk '
        /^[> ]*$/ { blank++; if (blank <= 2) print; next }
        { blank=0; print }
    ')

    # Render via glow (best), bat, or plain
    if command -v glow &>/dev/null; then
        echo "$md" | glow -
    elif command -v bat &>/dev/null; then
        echo "$md" | bat --style=plain --color=always --paging=never --language=markdown
    else
        echo "$md"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# EMAIL BODY RENDERER (stdin pipeline)
# ═══════════════════════════════════════════════════════════════════

_em_render_email_body() {
    # Email-specific body renderer — always treats as plain text
    # Dims quoted lines (>) and signature blocks (-- )
    # Indents body for clean terminal display
    # For HTML rendering, use em read --html (explicit choice)
    local content
    content=$(cat)

    if [[ -z "$content" ]]; then
        echo -e "  ${_C_DIM}(no content)${_C_NC}"
        return 0
    fi

    # Strip email noise: CID refs, Safe Links, MIME markers, bare URLs
    content=$(echo "$content" | sed \
        -e 's/\[cid:[^]]*\]//g' \
        -e 's|(https://nam[0-9]*\.safelinks\.protection\.outlook\.com[^)]*)||g' \
        -e '/<#part/d' \
        -e '/<#\/part>/d' \
        -e 's/<http[^>]*>//g' \
        -e 's/(mailto:[^)]*)//g' \
    )

    # Plain text email formatting
    local line in_signature=false
    while IFS= read -r line; do
        if [[ "$in_signature" == false && ( "$line" == "-- " || "$line" == "--" ) ]]; then
            in_signature=true
            echo -e "  ${_C_DIM}${line}${_C_NC}"
        elif [[ "$in_signature" == true ]]; then
            echo -e "  ${_C_DIM}${line}${_C_NC}"
        elif [[ "$line" == ">"* ]]; then
            # Quoted reply text
            echo -e "  ${_C_DIM}${line}${_C_NC}"
        elif [[ -z "$line" ]]; then
            echo ""
        else
            echo "  $line"
        fi
    done <<< "$content"
    echo ""
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

# Additional Keywords - Prompt Flag & Pick Integration

**Generated:** 2025-12-19
**Updated:** 2025-12-19 (Corrected prompt flag description)
**Status:** ✅ **COMPLETE** - Both cc and gm dispatchers enhanced

## Summary

1. Add `prompt` / `p` keyword to both Claude (`cc`) and Gemini (`gm`) dispatchers for passing short prompts via `-p` flag
2. Integrate default behavior with `pick` - when called with no args, use `pick` to select project

---

## 1. Claude Dispatcher (`cc`)

**File:** `~/.config/zsh/functions/smart-dispatchers.zsh` (line ~246)

**Default behavior (no args):**

```zsh
cc() {
    # No arguments → use pick to select project, then launch Claude
    if [[ $# -eq 0 ]]; then
        local project_dir=$(pick)
        if [[ -n "$project_dir" ]]; then
            cd "$project_dir"
            claude
        fi
        return
    fi

    case "$1" in
        # ... existing keywords ...
    esac
}
```

**Add keyword:**

```zsh
prompt|p)
    shift
    local prompt_text="$*"
    if [[ -z "$prompt_text" ]]; then
        echo "Usage: cc p <prompt text>"
        echo "Example: cc p 'analyze this code'"
        return 1
    fi
    claude -p "$prompt_text"
    ;;
```

**Replaces alias:**

- `ccp` → `cc prompt` or `cc p`

**Usage:**

```bash
cc                           # Use pick to select project, then launch Claude
cc p "analyze this code"     # Pass short prompt to Claude via -p flag (replaces ccp)
cc prompt "fix bugs"         # Same as above, explicit keyword
```

---

## 2. Gemini Dispatcher (`gm`)

**File:** `~/.config/zsh/functions/smart-dispatchers.zsh` (line ~366)

**Default behavior (no args):**

```zsh
gm() {
    # No arguments → use pick to select project, then launch Gemini
    if [[ $# -eq 0 ]]; then
        local project_dir=$(pick)
        if [[ -n "$project_dir" ]]; then
            cd "$project_dir"
            gemini
        fi
        return
    fi

    case "$1" in
        # ... existing keywords ...
    esac
}
```

**Add keyword:**

```zsh
prompt|p)
    shift
    local prompt_text="$*"
    if [[ -z "$prompt_text" ]]; then
        echo "Usage: gm p <prompt text>"
        echo "Example: gm p 'explain this function'"
        return 1
    fi
    gemini -p "$prompt_text"
    ;;
```

**Replaces alias:**

- `gmp` → `gm prompt` or `gm p`

**Usage:**

```bash
gm                           # Use pick to select project, then launch Gemini
gm p "explain this code"     # Pass short prompt to Gemini via -p flag (replaces gmp)
gm prompt "review this"      # Same as above, explicit keyword
```

---

## Updated Consolidation Stats

**Claude dispatcher:**

- Was: 8 aliases → 8 keywords
- Now: 9 aliases → 9 keywords (added `prompt`)
- Total: ccl, cch, ccs, cco, ccplan, ccauto, ccyolo, cccode, **ccp**

**Gemini dispatcher:**

- New: 1 alias → 1 keyword (added `prompt`)
- Total: **gmp** (if exists)

---

**Note for Agent 2:** Add these keywords when enhancing cc and gm dispatchers.
**Note for Agent 3:** Add `ccp` and `gmp` to removal list (if they exist as aliases).

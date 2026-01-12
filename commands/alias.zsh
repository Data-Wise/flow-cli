# commands/alias.zsh - Alias reference command
# Display all flow-cli aliases organized by category

# ============================================================================
# ALIAS COMMAND
# ============================================================================

flow_alias() {
  local category="${1:-}"

  case "$category" in
    -h|--help|help)
      _flow_alias_help
      return 0
      ;;
    "")
      # Show all aliases
      _flow_alias_show_all
      ;;
    r|rpkg|rpackage)
      _flow_alias_show_r
      ;;
    cc|claude)
      _flow_alias_show_claude
      ;;
    focus|timer)
      _flow_alias_show_focus
      ;;
    tools)
      _flow_alias_show_tools
      ;;
    git)
      _flow_alias_show_git
      ;;
    dispatchers)
      _flow_alias_show_dispatchers
      ;;
    # NEW: Alias management commands
    doctor|doc)
      _flow_alias_doctor
      ;;
    add)
      shift
      _flow_alias_add "$@"
      ;;
    rm|remove)
      shift
      _flow_alias_remove "$@"
      ;;
    test)
      shift
      _flow_alias_test "$@"
      ;;
    find|search)
      shift
      _flow_alias_find "$@"
      ;;
    edit)
      _flow_alias_edit
      ;;
    *)
      echo "Unknown category: $category"
      echo "Try: flow alias help"
      return 1
      ;;
  esac
}

# Help function
_flow_alias_help() {
  echo ""
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[bold]}flow alias - Alias Reference & Management${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo ""
  echo "${FLOW_COLORS[bold]}Usage:${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[cmd]}flow alias${FLOW_COLORS[reset]}              Show all aliases"
  echo "  ${FLOW_COLORS[cmd]}flow alias <category>${FLOW_COLORS[reset]}   Show category-specific aliases"
  echo ""
  echo "${FLOW_COLORS[bold]}Categories:${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[cmd]}r${FLOW_COLORS[reset]}                   R package development (23 aliases)"
  echo "  ${FLOW_COLORS[cmd]}cc${FLOW_COLORS[reset]}                  Claude Code (3 aliases)"
  echo "  ${FLOW_COLORS[cmd]}focus${FLOW_COLORS[reset]}               Focus timers (2 aliases)"
  echo "  ${FLOW_COLORS[cmd]}tools${FLOW_COLORS[reset]}               Tool replacements (1 alias)"
  echo "  ${FLOW_COLORS[cmd]}git${FLOW_COLORS[reset]}                 Git plugin aliases (226+)"
  echo "  ${FLOW_COLORS[cmd]}dispatchers${FLOW_COLORS[reset]}         Smart dispatchers (8 functions)"
  echo ""
  echo "${FLOW_COLORS[bold]}Management:${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[cmd]}doctor${FLOW_COLORS[reset]}              Health check all aliases (shadows, broken, etc.)"
  echo "  ${FLOW_COLORS[cmd]}find <pattern>${FLOW_COLORS[reset]}      Search aliases by name or command"
  echo "  ${FLOW_COLORS[cmd]}edit${FLOW_COLORS[reset]}                Open .zshrc at alias section"
  echo "  ${FLOW_COLORS[cmd]}add [name=cmd]${FLOW_COLORS[reset]}      Create new alias (interactive or one-liner)"
  echo "  ${FLOW_COLORS[cmd]}rm <name>${FLOW_COLORS[reset]}           Remove alias safely (comment + backup)"
  echo "  ${FLOW_COLORS[cmd]}test <name>${FLOW_COLORS[reset]}         Test alias (coming soon)"
  echo ""
  echo "${FLOW_COLORS[bold]}EXAMPLES:${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow alias              ${FLOW_COLORS[muted]}# Show all aliases${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow alias doctor       ${FLOW_COLORS[muted]}# Check for issues${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow alias find brew    ${FLOW_COLORS[muted]}# Find brew aliases${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow alias add          ${FLOW_COLORS[muted]}# Interactive create${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow alias add gp='git push'  ${FLOW_COLORS[muted]}# One-liner create${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow alias rm gp        ${FLOW_COLORS[muted]}# Remove (comment out)${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow alias edit         ${FLOW_COLORS[muted]}# Edit .zshrc${FLOW_COLORS[reset]}"
  echo ""
  echo "${FLOW_COLORS[muted]}📚 See also:${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[cmd]}flow help${FLOW_COLORS[reset]} - Main help"
  echo "  ${FLOW_COLORS[cmd]}r help${FLOW_COLORS[reset]} - R dispatcher help"
  echo "  ${FLOW_COLORS[cmd]}g help${FLOW_COLORS[reset]} - Git dispatcher help"
  echo ""
}

# Show all aliases (summary)
_flow_alias_show_all() {
  echo ""
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[bold]}⚡ Flow CLI Alias Reference${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo ""
  echo "${FLOW_COLORS[bold]}Total:${FLOW_COLORS[reset]} 29 custom aliases + 8 dispatchers + 226+ git aliases"
  echo ""

  echo "${FLOW_COLORS[success]}📦 R Package Development${FLOW_COLORS[reset]} (23 aliases)"
  echo "  ${FLOW_COLORS[muted]}Core workflow: rload, rtest, rdoc, rcheck, rbuild, rinstall${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[cmd]}flow alias r${FLOW_COLORS[reset]} for full list"
  echo ""

  echo "${FLOW_COLORS[success]}🤖 Claude Code${FLOW_COLORS[reset]} (3 aliases)"
  echo "  ${FLOW_COLORS[muted]}ccy → cc yolo (YOLO mode - skip permissions)${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}ccp → claude -p (print mode)${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}ccr → claude -r (resume session)${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[cmd]}flow alias cc${FLOW_COLORS[reset]} for details"
  echo ""

  echo "${FLOW_COLORS[success]}⏱️  Focus Timers${FLOW_COLORS[reset]} (2 aliases)"
  echo "  ${FLOW_COLORS[muted]}f25 → focus 25 (Pomodoro)${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}f50 → focus 50 (deep work)${FLOW_COLORS[reset]}"
  echo ""

  echo "${FLOW_COLORS[success]}🛠️  Tool Replacements${FLOW_COLORS[reset]} (1 alias)"
  echo "  ${FLOW_COLORS[muted]}cat → bat (syntax highlighting)${FLOW_COLORS[reset]}"
  echo ""

  echo "${FLOW_COLORS[success]}🎯 Dispatchers${FLOW_COLORS[reset]} (8 smart functions)"
  echo "  ${FLOW_COLORS[muted]}g, cc, wt, mcp, r, qu, obs, tm${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[cmd]}flow alias dispatchers${FLOW_COLORS[reset]} for full list"
  echo ""

  echo "${FLOW_COLORS[success]}📚 Git Aliases${FLOW_COLORS[reset]} (226+ from OMZ plugin)"
  echo "  ${FLOW_COLORS[muted]}Common: gst, ga, gaa, gcmsg, gp, glo${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[cmd]}flow alias git${FLOW_COLORS[reset]} for common ones"
  echo ""

  echo "${FLOW_COLORS[muted]}Use ${FLOW_COLORS[cmd]}flow alias <category>${FLOW_COLORS[muted]} to see details${FLOW_COLORS[reset]}"
  echo ""
}

# Show R package aliases
_flow_alias_show_r() {
  echo ""
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[bold]}📦 R Package Development Aliases${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo ""

  echo "${FLOW_COLORS[bold]}Core Workflow:${FLOW_COLORS[reset]}"
  printf "  ${FLOW_COLORS[cmd]}%-12s${FLOW_COLORS[reset]} → %-30s ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" \
    "rload" "devtools::load_all()" "Load all package code"
  printf "  ${FLOW_COLORS[cmd]}%-12s${FLOW_COLORS[reset]} → %-30s ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" \
    "rtest" "devtools::test()" "Run all tests"
  printf "  ${FLOW_COLORS[cmd]}%-12s${FLOW_COLORS[reset]} → %-30s ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" \
    "rdoc" "devtools::document()" "Generate documentation"
  printf "  ${FLOW_COLORS[cmd]}%-12s${FLOW_COLORS[reset]} → %-30s ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" \
    "rcheck" "devtools::check()" "R CMD check"
  printf "  ${FLOW_COLORS[cmd]}%-12s${FLOW_COLORS[reset]} → %-30s ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" \
    "rbuild" "devtools::build()" "Build tar.gz"
  printf "  ${FLOW_COLORS[cmd]}%-12s${FLOW_COLORS[reset]} → %-30s ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" \
    "rinstall" "devtools::install()" "Install package"
  echo ""

  echo "${FLOW_COLORS[bold]}Quality & Coverage:${FLOW_COLORS[reset]}"
  printf "  ${FLOW_COLORS[cmd]}%-12s${FLOW_COLORS[reset]} → %-30s ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" \
    "rcov" "covr::package_coverage()" "Code coverage report"
  printf "  ${FLOW_COLORS[cmd]}%-12s${FLOW_COLORS[reset]} → %-30s ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" \
    "rcovrep" "covr::report()" "Open coverage in browser"
  echo ""

  echo "${FLOW_COLORS[bold]}Documentation:${FLOW_COLORS[reset]}"
  printf "  ${FLOW_COLORS[cmd]}%-12s${FLOW_COLORS[reset]} → %-30s ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" \
    "rdoccheck" "devtools::check_man()" "Check doc completeness"
  printf "  ${FLOW_COLORS[cmd]}%-12s${FLOW_COLORS[reset]} → %-30s ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" \
    "rspell" "spelling::spell_check_package()" "Spell check docs"
  printf "  ${FLOW_COLORS[cmd]}%-12s${FLOW_COLORS[reset]} → %-30s ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" \
    "rpkgdown" "pkgdown::build_site()" "Build pkgdown website"
  printf "  ${FLOW_COLORS[cmd]}%-12s${FLOW_COLORS[reset]} → %-30s ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" \
    "rpkgpreview" "pkgdown::preview_site()" "Preview pkgdown locally"
  echo ""

  echo "${FLOW_COLORS[bold]}CRAN Checks:${FLOW_COLORS[reset]}"
  printf "  ${FLOW_COLORS[cmd]}%-12s${FLOW_COLORS[reset]} → %-30s ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" \
    "rcheckfast" "devtools::check(args='--no-*')" "Fast check (~15s)"
  printf "  ${FLOW_COLORS[cmd]}%-12s${FLOW_COLORS[reset]} → %-30s ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" \
    "rcheckcran" "devtools::check(cran=TRUE)" "Full CRAN check (~60s)"
  printf "  ${FLOW_COLORS[cmd]}%-12s${FLOW_COLORS[reset]} → %-30s ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" \
    "rcheckwin" "devtools::check_win_*()" "Windows check (~5min)"
  printf "  ${FLOW_COLORS[cmd]}%-12s${FLOW_COLORS[reset]} → %-30s ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" \
    "rcheckrhub" "rhub::check_for_cran()" "R-hub check (~10min)"
  echo ""

  echo "${FLOW_COLORS[bold]}Versioning:${FLOW_COLORS[reset]}"
  printf "  ${FLOW_COLORS[cmd]}%-12s${FLOW_COLORS[reset]} → %-30s ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" \
    "rbumppatch" "usethis::use_version('patch')" "0.1.0 → 0.1.1"
  printf "  ${FLOW_COLORS[cmd]}%-12s${FLOW_COLORS[reset]} → %-30s ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" \
    "rbumpminor" "usethis::use_version('minor')" "0.1.0 → 0.2.0"
  printf "  ${FLOW_COLORS[cmd]}%-12s${FLOW_COLORS[reset]} → %-30s ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" \
    "rbumpmajor" "usethis::use_version('major')" "0.1.0 → 1.0.0"
  echo ""

  echo "${FLOW_COLORS[muted]}See also: ${FLOW_COLORS[cmd]}r help${FLOW_COLORS[muted]} for R dispatcher commands${FLOW_COLORS[reset]}"
  echo ""
}

# Show Claude Code aliases
_flow_alias_show_claude() {
  echo ""
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[bold]}🤖 Claude Code Aliases${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo ""

  printf "  ${FLOW_COLORS[cmd]}%-6s${FLOW_COLORS[reset]} → %-20s ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" \
    "ccy" "cc yolo" "YOLO mode (skip permissions)"
  printf "  ${FLOW_COLORS[cmd]}%-6s${FLOW_COLORS[reset]} → %-20s ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" \
    "ccp" "claude -p" "Print mode (non-interactive)"
  printf "  ${FLOW_COLORS[cmd]}%-6s${FLOW_COLORS[reset]} → %-20s ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" \
    "ccr" "claude -r" "Resume session picker"
  echo ""

  echo "${FLOW_COLORS[muted]}Tip: Use ${FLOW_COLORS[cmd]}cc${FLOW_COLORS[muted]} dispatcher for full Claude workflow${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[muted]}See also: ${FLOW_COLORS[cmd]}cc help${FLOW_COLORS[muted]} for all Claude commands${FLOW_COLORS[reset]}"
  echo ""
}

# Show focus timer aliases
_flow_alias_show_focus() {
  echo ""
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[bold]}⏱️  Focus Timer Aliases${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo ""

  printf "  ${FLOW_COLORS[cmd]}%-6s${FLOW_COLORS[reset]} → %-15s ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" \
    "f25" "focus 25" "25-min Pomodoro (deep work)"
  printf "  ${FLOW_COLORS[cmd]}%-6s${FLOW_COLORS[reset]} → %-15s ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" \
    "f50" "focus 50" "50-min deep work (research)"
  echo ""

  echo "${FLOW_COLORS[muted]}Use ${FLOW_COLORS[cmd]}focus <minutes>${FLOW_COLORS[muted]} for custom durations${FLOW_COLORS[reset]}"
  echo ""
}

# Show tool replacement aliases
_flow_alias_show_tools() {
  echo ""
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[bold]}🛠️  Tool Replacement Aliases${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo ""

  printf "  ${FLOW_COLORS[cmd]}%-6s${FLOW_COLORS[reset]} → %-10s ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" \
    "cat" "bat" "Syntax highlighting, line numbers, git integration"
  echo ""

  echo "${FLOW_COLORS[muted]}Tip: Use ${FLOW_COLORS[cmd]}fd${FLOW_COLORS[muted]} and ${FLOW_COLORS[cmd]}rg${FLOW_COLORS[muted]} directly (no aliases needed)${FLOW_COLORS[reset]}"
  echo ""
}

# Show common git aliases
_flow_alias_show_git() {
  echo ""
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[bold]}📚 Git Aliases (from OMZ plugin)${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo ""

  echo "${FLOW_COLORS[bold]}Common (20 most-used):${FLOW_COLORS[reset]}"
  printf "  ${FLOW_COLORS[cmd]}%-8s${FLOW_COLORS[reset]} → %-25s ${FLOW_COLORS[cmd]}%-8s${FLOW_COLORS[reset]} → %s\n" \
    "gst" "git status" "ga" "git add"
  printf "  ${FLOW_COLORS[cmd]}%-8s${FLOW_COLORS[reset]} → %-25s ${FLOW_COLORS[cmd]}%-8s${FLOW_COLORS[reset]} → %s\n" \
    "gaa" "git add --all" "gcmsg" "git commit -m"
  printf "  ${FLOW_COLORS[cmd]}%-8s${FLOW_COLORS[reset]} → %-25s ${FLOW_COLORS[cmd]}%-8s${FLOW_COLORS[reset]} → %s\n" \
    "gp" "git push" "gl" "git pull"
  printf "  ${FLOW_COLORS[cmd]}%-8s${FLOW_COLORS[reset]} → %-25s ${FLOW_COLORS[cmd]}%-8s${FLOW_COLORS[reset]} → %s\n" \
    "glo" "git log --oneline" "gd" "git diff"
  printf "  ${FLOW_COLORS[cmd]}%-8s${FLOW_COLORS[reset]} → %-25s ${FLOW_COLORS[cmd]}%-8s${FLOW_COLORS[reset]} → %s\n" \
    "gco" "git checkout" "gcb" "git checkout -b"
  printf "  ${FLOW_COLORS[cmd]}%-8s${FLOW_COLORS[reset]} → %-25s ${FLOW_COLORS[cmd]}%-8s${FLOW_COLORS[reset]} → %s\n" \
    "gba" "git branch -a" "grh" "git reset HEAD"
  printf "  ${FLOW_COLORS[cmd]}%-8s${FLOW_COLORS[reset]} → %-25s ${FLOW_COLORS[cmd]}%-8s${FLOW_COLORS[reset]} → %s\n" \
    "grhh" "git reset --hard" "gsw" "git switch"
  printf "  ${FLOW_COLORS[cmd]}%-8s${FLOW_COLORS[reset]} → %-25s ${FLOW_COLORS[cmd]}%-8s${FLOW_COLORS[reset]} → %s\n" \
    "gswc" "git switch -c" "gm" "git merge"
  printf "  ${FLOW_COLORS[cmd]}%-8s${FLOW_COLORS[reset]} → %-25s ${FLOW_COLORS[cmd]}%-8s${FLOW_COLORS[reset]} → %s\n" \
    "grb" "git rebase" "gsta" "git stash"
  printf "  ${FLOW_COLORS[cmd]}%-8s${FLOW_COLORS[reset]} → %-25s ${FLOW_COLORS[cmd]}%-8s${FLOW_COLORS[reset]} → %s\n" \
    "gstp" "git stash pop" "gstl" "git stash list"
  echo ""

  echo "${FLOW_COLORS[muted]}Total: 226+ aliases${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[muted]}Full list: Run ${FLOW_COLORS[cmd]}aliases git${FLOW_COLORS[muted]} or see OMZ git plugin docs${FLOW_COLORS[reset]}"
  echo ""
}

# Show dispatchers
_flow_alias_show_dispatchers() {
  echo ""
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[bold]}🎯 Smart Dispatchers${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo ""

  printf "  ${FLOW_COLORS[cmd]}%-6s${FLOW_COLORS[reset]} → %-50s\n" \
    "g" "Git workflows (status, commit, push, feature, etc.)"
  printf "  ${FLOW_COLORS[cmd]}%-6s${FLOW_COLORS[reset]} → %-50s\n" \
    "cc" "Claude Code launcher (pick, yolo, plan, resume, continue)"
  printf "  ${FLOW_COLORS[cmd]}%-6s${FLOW_COLORS[reset]} → %-50s\n" \
    "wt" "Git worktree management (create, list, prune, remove)"
  printf "  ${FLOW_COLORS[cmd]}%-6s${FLOW_COLORS[reset]} → %-50s\n" \
    "mcp" "MCP server management (status, logs, test, restart)"
  printf "  ${FLOW_COLORS[cmd]}%-6s${FLOW_COLORS[reset]} → %-50s\n" \
    "r" "R package development (test, doc, check, build, cran)"
  printf "  ${FLOW_COLORS[cmd]}%-6s${FLOW_COLORS[reset]} → %-50s\n" \
    "qu" "Quarto publishing (render, preview, publish, check)"
  printf "  ${FLOW_COLORS[cmd]}%-6s${FLOW_COLORS[reset]} → %-50s\n" \
    "obs" "Obsidian notes (vaults, open, search, stats, sync)"
  printf "  ${FLOW_COLORS[cmd]}%-6s${FLOW_COLORS[reset]} → %-50s\n" \
    "tm" "Terminal manager (title, profile, theme, switch, ghost)"
  echo ""

  echo "${FLOW_COLORS[muted]}Get help: ${FLOW_COLORS[cmd]}<dispatcher> help${FLOW_COLORS[muted]} (e.g., ${FLOW_COLORS[cmd]}r help${FLOW_COLORS[muted]}, ${FLOW_COLORS[cmd]}cc help${FLOW_COLORS[muted]})${FLOW_COLORS[reset]}"
  echo ""
}

# ============================================================================
# ALIAS MANAGEMENT COMMANDS (v5.4.0)
# ============================================================================

# Doctor: Health check all aliases
_flow_alias_doctor() {
  local zshrc="${ZDOTDIR:-$HOME}/.zshrc"
  [[ -f "$zshrc" ]] || zshrc="$HOME/.config/zsh/.zshrc"

  if [[ ! -f "$zshrc" ]]; then
    echo "${FLOW_COLORS[error]}Error: Cannot find .zshrc${FLOW_COLORS[reset]}"
    return 1
  fi

  echo ""
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[bold]}🩺 Alias Health Check${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo ""
  echo "Scanning: ${FLOW_COLORS[muted]}$zshrc${FLOW_COLORS[reset]}"

  # Parse aliases from zshrc
  local -a aliases_found=()
  local -a errors=()
  local -a warnings=()
  local -a healthy=()

  # Read aliases from file
  while IFS= read -r line; do
    # Format: line_num:alias name='value'
    local line_num="${line%%:*}"
    local alias_def="${line#*:}"
    # Remove 'alias ' prefix if present
    alias_def="${alias_def#alias }"
    local alias_name="${alias_def%%=*}"
    local alias_value="${alias_def#*=}"
    # Remove surrounding quotes from value
    alias_value="${alias_value#[\'\"]}"
    alias_value="${alias_value%[\'\"]}"

    # Skip if we couldn't parse
    [[ -z "$alias_name" ]] && continue

    # Get first word of alias value (the command)
    local target_cmd="${alias_value%% *}"

    # Check 1: Does alias shadow a system command?
    local shadow_path=""
    shadow_path=$(_flow_alias_check_shadow "$alias_name" 2>/dev/null)
    if [[ -n "$shadow_path" ]]; then
      errors+=("${alias_name}='${alias_value}'|Shadows system command: $shadow_path|Consider renaming to avoid confusion")
      continue
    fi

    # Check 2: Does target command exist?
    if ! _flow_alias_check_target "$target_cmd"; then
      errors+=("${alias_name}='${alias_value}'|Target not found: $target_cmd|Install the command or fix the alias")
      continue
    fi

    # Check 3: Is it a long/complex command? (warning only)
    if [[ ${#alias_value} -gt 60 ]] || [[ "$alias_value" == *"&&"* ]]; then
      warnings+=("${alias_name}='${alias_value}'|Long/complex command (${#alias_value} chars)|Consider using a function instead")
      continue
    fi

    # Passed all checks
    healthy+=("$alias_name")
  done < <(grep -n "^alias " "$zshrc")

  local total=$((${#errors[@]} + ${#warnings[@]} + ${#healthy[@]}))
  echo "Found: ${FLOW_COLORS[bold]}$total aliases${FLOW_COLORS[reset]}"
  echo ""

  # Show errors
  if [[ ${#errors[@]} -gt 0 ]]; then
    echo "${FLOW_COLORS[error]}❌ ERRORS (${#errors[@]})${FLOW_COLORS[reset]}"
    for err in "${errors[@]}"; do
      local alias_def="${err%%|*}"
      local rest="${err#*|}"
      local issue="${rest%%|*}"
      local suggestion="${rest#*|}"
      echo "  ${FLOW_COLORS[cmd]}$alias_def${FLOW_COLORS[reset]}"
      echo "    └─ $issue"
      echo "    └─ ${FLOW_COLORS[muted]}$suggestion${FLOW_COLORS[reset]}"
      echo ""
    done
  fi

  # Show warnings
  if [[ ${#warnings[@]} -gt 0 ]]; then
    echo "${FLOW_COLORS[warning]}⚠️  WARNINGS (${#warnings[@]})${FLOW_COLORS[reset]}"
    for warn in "${warnings[@]}"; do
      local alias_def="${warn%%|*}"
      local rest="${warn#*|}"
      local issue="${rest%%|*}"
      local suggestion="${rest#*|}"
      echo "  ${FLOW_COLORS[cmd]}$alias_def${FLOW_COLORS[reset]}"
      echo "    └─ $issue"
      echo "    └─ ${FLOW_COLORS[muted]}$suggestion${FLOW_COLORS[reset]}"
      echo ""
    done
  fi

  # Show healthy (compact)
  if [[ ${#healthy[@]} -gt 0 ]]; then
    echo "${FLOW_COLORS[success]}✅ HEALTHY (${#healthy[@]})${FLOW_COLORS[reset]}"
    # Show as comma-separated list, wrap at 60 chars
    local healthy_list="${(j:, :)healthy}"
    echo "  ${FLOW_COLORS[muted]}$healthy_list${FLOW_COLORS[reset]}"
    echo ""
  fi

  # Summary
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo "Summary: ${FLOW_COLORS[error]}${#errors[@]} errors${FLOW_COLORS[reset]}, ${FLOW_COLORS[warning]}${#warnings[@]} warnings${FLOW_COLORS[reset]}, ${FLOW_COLORS[success]}${#healthy[@]} healthy${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo ""

  # Return non-zero if there are errors
  [[ ${#errors[@]} -eq 0 ]]
}

# Check if alias name shadows a system command
# Returns path to shadowed command if found, empty otherwise
_flow_alias_check_shadow() {
  local name="$1"
  # Check if there's a command with this name (excluding aliases/functions)
  local cmd_path
  cmd_path=$(command -v "$name" 2>/dev/null)

  # If command exists and is a file (not alias/function), it's shadowed
  if [[ -n "$cmd_path" && -x "$cmd_path" ]]; then
    echo "$cmd_path"
  fi
}

# Check if target command exists
_flow_alias_check_target() {
  local target="$1"
  # Handle special cases
  [[ -z "$target" ]] && return 1
  # Check if command exists (allow aliases, functions, builtins, executables)
  command -v "$target" &>/dev/null || type "$target" &>/dev/null
}

# Find: Search aliases by pattern
_flow_alias_find() {
  local pattern="$1"
  if [[ -z "$pattern" ]]; then
    echo "Usage: flow alias find <pattern>"
    echo "Example: flow alias find brew"
    return 1
  fi

  local zshrc="${ZDOTDIR:-$HOME}/.zshrc"
  [[ -f "$zshrc" ]] || zshrc="$HOME/.config/zsh/.zshrc"

  echo ""
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[bold]}🔍 Aliases matching '$pattern'${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo ""

  local found=0
  while IFS= read -r line; do
    # Strip 'alias ' prefix and line number
    local def="${line#*:alias }"
    local name="${def%%=*}"
    local value="${def#*=}"
    printf "  ${FLOW_COLORS[cmd]}%-12s${FLOW_COLORS[reset]} → %s\n" "$name" "$value"
    ((found++))
  done < <(grep -n "^alias.*$pattern" "$zshrc" 2>/dev/null)

  if [[ $found -eq 0 ]]; then
    echo "  ${FLOW_COLORS[muted]}No aliases found matching '$pattern'${FLOW_COLORS[reset]}"
  fi
  echo ""
}

# Edit: Open .zshrc at alias section
_flow_alias_edit() {
  local zshrc="${ZDOTDIR:-$HOME}/.zshrc"
  [[ -f "$zshrc" ]] || zshrc="$HOME/.config/zsh/.zshrc"

  # Find first alias line
  local first_alias_line
  first_alias_line=$(grep -n "^alias " "$zshrc" | head -1 | cut -d: -f1)

  if [[ -n "$first_alias_line" ]]; then
    echo "Opening $zshrc at line $first_alias_line..."
    ${EDITOR:-vim} "+$first_alias_line" "$zshrc"
  else
    echo "Opening $zshrc..."
    ${EDITOR:-vim} "$zshrc"
  fi
}

# Add: Create new alias
# Usage: flow alias add              (interactive)
#        flow alias add name='cmd'   (one-liner)
_flow_alias_add() {
  local zshrc="${ZDOTDIR:-$HOME}/.zshrc"
  [[ -f "$zshrc" ]] || zshrc="$HOME/.config/zsh/.zshrc"

  local alias_name=""
  local alias_value=""

  # Check if one-liner format provided: name='command' or name="command"
  if [[ -n "$1" && "$1" == *"="* ]]; then
    alias_name="${1%%=*}"
    alias_value="${1#*=}"
    # Remove surrounding quotes
    alias_value="${alias_value#[\'\"]}"
    alias_value="${alias_value%[\'\"]}"
  else
    # Interactive mode
    echo ""
    echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[bold]}➕ Create New Alias${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
    echo ""

    # Get alias name
    printf "${FLOW_COLORS[bold]}Alias name:${FLOW_COLORS[reset]} "
    read -r alias_name
    if [[ -z "$alias_name" ]]; then
      echo "${FLOW_COLORS[error]}Error: Alias name cannot be empty${FLOW_COLORS[reset]}"
      return 1
    fi

    # Get alias command
    printf "${FLOW_COLORS[bold]}Command:${FLOW_COLORS[reset]} "
    read -r alias_value
    if [[ -z "$alias_value" ]]; then
      echo "${FLOW_COLORS[error]}Error: Command cannot be empty${FLOW_COLORS[reset]}"
      return 1
    fi
  fi

  # Validate alias name (alphanumeric, underscore, dash only)
  if [[ ! "$alias_name" =~ ^[a-zA-Z_][a-zA-Z0-9_-]*$ ]]; then
    echo "${FLOW_COLORS[error]}Error: Invalid alias name '$alias_name'${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[muted]}Use only letters, numbers, underscores, and dashes${FLOW_COLORS[reset]}"
    return 1
  fi

  echo ""
  echo "${FLOW_COLORS[bold]}Validating...${FLOW_COLORS[reset]}"

  local has_issues=0

  # Check 1: Does alias already exist?
  if grep -q "^alias $alias_name=" "$zshrc" 2>/dev/null; then
    echo "  ${FLOW_COLORS[error]}❌ Duplicate: '$alias_name' already defined in .zshrc${FLOW_COLORS[reset]}"
    has_issues=1
  fi

  # Check 2: Does it shadow a system command?
  local shadow_path
  shadow_path=$(_flow_alias_check_shadow "$alias_name" 2>/dev/null)
  if [[ -n "$shadow_path" ]]; then
    echo "  ${FLOW_COLORS[warning]}⚠️  Shadow: '$alias_name' shadows $shadow_path${FLOW_COLORS[reset]}"
    # Warning only, not blocking
  fi

  # Check 3: Does target command exist?
  local target_cmd="${alias_value%% *}"
  if ! _flow_alias_check_target "$target_cmd"; then
    echo "  ${FLOW_COLORS[error]}❌ Target not found: '$target_cmd'${FLOW_COLORS[reset]}"
    has_issues=1
  fi

  # Check 4: Is it too long? (warning only)
  if [[ ${#alias_value} -gt 60 ]]; then
    echo "  ${FLOW_COLORS[warning]}⚠️  Long command (${#alias_value} chars) - consider a function${FLOW_COLORS[reset]}"
  fi

  # If no blocking issues, show success
  if [[ $has_issues -eq 0 ]]; then
    echo "  ${FLOW_COLORS[success]}✅ Validation passed${FLOW_COLORS[reset]}"
  fi

  echo ""

  # Show preview
  echo "${FLOW_COLORS[bold]}Preview:${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[cmd]}alias $alias_name='$alias_value'${FLOW_COLORS[reset]}"
  echo ""

  # If there were blocking issues, ask to proceed anyway
  if [[ $has_issues -eq 1 ]]; then
    printf "${FLOW_COLORS[warning]}Add anyway? [y/N]:${FLOW_COLORS[reset]} "
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      echo "${FLOW_COLORS[muted]}Cancelled${FLOW_COLORS[reset]}"
      return 1
    fi
  else
    # Confirm
    printf "${FLOW_COLORS[bold]}Add this alias? [Y/n]:${FLOW_COLORS[reset]} "
    read -r confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
      echo "${FLOW_COLORS[muted]}Cancelled${FLOW_COLORS[reset]}"
      return 0
    fi
  fi

  # Find the best place to insert (after last alias, or at end)
  local last_alias_line
  last_alias_line=$(grep -n "^alias " "$zshrc" | tail -1 | cut -d: -f1)

  if [[ -n "$last_alias_line" ]]; then
    # Insert after last alias line using sed
    # Create temp file for safe editing
    local tmpfile=$(mktemp)
    sed "${last_alias_line}a\\
alias $alias_name='$alias_value'" "$zshrc" > "$tmpfile"
    mv "$tmpfile" "$zshrc"
    echo "${FLOW_COLORS[success]}✅ Added after line $last_alias_line${FLOW_COLORS[reset]}"
  else
    # Append to end of file
    echo "" >> "$zshrc"
    echo "# Custom alias added $(date +%Y-%m-%d)" >> "$zshrc"
    echo "alias $alias_name='$alias_value'" >> "$zshrc"
    echo "${FLOW_COLORS[success]}✅ Added at end of file${FLOW_COLORS[reset]}"
  fi

  echo ""
  echo "${FLOW_COLORS[muted]}Reload with:${FLOW_COLORS[reset]} ${FLOW_COLORS[cmd]}source $zshrc${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[muted]}Or run:${FLOW_COLORS[reset]} ${FLOW_COLORS[cmd]}exec zsh${FLOW_COLORS[reset]}"
  echo ""
}

# Remove: Safe alias removal (comment out + backup)
# Usage: flow alias rm <name>
_flow_alias_remove() {
  local alias_name="$1"

  if [[ -z "$alias_name" ]]; then
    echo "Usage: flow alias rm <alias_name>"
    echo "Example: flow alias rm myalias"
    return 1
  fi

  local zshrc="${ZDOTDIR:-$HOME}/.zshrc"
  [[ -f "$zshrc" ]] || zshrc="$HOME/.config/zsh/.zshrc"

  echo ""
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[bold]}🗑️  Remove Alias${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo ""

  # Find the alias in .zshrc
  local match
  match=$(grep -n "^alias $alias_name=" "$zshrc" 2>/dev/null)

  if [[ -z "$match" ]]; then
    echo "${FLOW_COLORS[error]}Error: Alias '$alias_name' not found in .zshrc${FLOW_COLORS[reset]}"
    echo ""
    echo "${FLOW_COLORS[muted]}Tip: Use ${FLOW_COLORS[cmd]}flow alias find $alias_name${FLOW_COLORS[muted]} to search${FLOW_COLORS[reset]}"
    return 1
  fi

  local line_num="${match%%:*}"
  local alias_def="${match#*:}"

  echo "${FLOW_COLORS[bold]}Found:${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[cmd]}$alias_def${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}Line $line_num in $zshrc${FLOW_COLORS[reset]}"
  echo ""

  # Confirm removal
  printf "${FLOW_COLORS[warning]}Remove this alias? [y/N]:${FLOW_COLORS[reset]} "
  read -r confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "${FLOW_COLORS[muted]}Cancelled${FLOW_COLORS[reset]}"
    return 0
  fi

  # Create backup
  local backup_file="${zshrc}.alias-backup"
  cp "$zshrc" "$backup_file"
  echo ""
  echo "${FLOW_COLORS[muted]}Backup created: $backup_file${FLOW_COLORS[reset]}"

  # Comment out the line (safer than deletion)
  local tmpfile=$(mktemp)
  sed "${line_num}s/^alias /# REMOVED $(date +%Y-%m-%d): alias /" "$zshrc" > "$tmpfile"
  mv "$tmpfile" "$zshrc"

  echo "${FLOW_COLORS[success]}✅ Alias '$alias_name' commented out${FLOW_COLORS[reset]}"
  echo ""
  echo "${FLOW_COLORS[bold]}To undo:${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[cmd]}flow alias edit${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}# Remove '# REMOVED...' prefix${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}Or restore from backup: cp $backup_file $zshrc${FLOW_COLORS[reset]}"
  echo ""
  echo "${FLOW_COLORS[muted]}Reload with:${FLOW_COLORS[reset]} ${FLOW_COLORS[cmd]}exec zsh${FLOW_COLORS[reset]}"
  echo ""
}

# Test: Validate and dry-run alias (stub for Phase 5)
_flow_alias_test() {
  local name="$1"
  if [[ -z "$name" ]]; then
    echo "Usage: flow alias test <alias_name>"
    return 1
  fi
  echo "${FLOW_COLORS[muted]}Coming soon: flow alias test${FLOW_COLORS[reset]}"
  echo "For now, use: ${FLOW_COLORS[cmd]}type $name${FLOW_COLORS[reset]} to see alias definition"
}

# ============================================================================
# ALIASES (backward compatibility)
# ============================================================================

# Allow both 'flow alias' and direct 'als' command
alias als='flow_alias'

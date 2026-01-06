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
  echo "${FLOW_COLORS[bold]}flow alias - Alias Reference${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo ""
  echo "${FLOW_COLORS[bold]}Usage:${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[cmd]}flow alias${FLOW_COLORS[reset]}              Show all aliases"
  echo "  ${FLOW_COLORS[cmd]}flow alias <category>${FLOW_COLORS[reset]}   Show category-specific aliases"
  echo ""
  echo "${FLOW_COLORS[bold]}Categories:${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[cmd]}r${FLOW_COLORS[reset]}                   R package development (23 aliases)"
  echo "  ${FLOW_COLORS[cmd]}cc${FLOW_COLORS[reset]}                  Claude Code (2 aliases)"
  echo "  ${FLOW_COLORS[cmd]}focus${FLOW_COLORS[reset]}               Focus timers (2 aliases)"
  echo "  ${FLOW_COLORS[cmd]}tools${FLOW_COLORS[reset]}               Tool replacements (1 alias)"
  echo "  ${FLOW_COLORS[cmd]}git${FLOW_COLORS[reset]}                 Git plugin aliases (226+)"
  echo "  ${FLOW_COLORS[cmd]}dispatchers${FLOW_COLORS[reset]}         Smart dispatchers (8 functions)"
  echo ""
  echo "${FLOW_COLORS[bold]}EXAMPLES:${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow alias              ${FLOW_COLORS[muted]}# Show all aliases${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow alias r            ${FLOW_COLORS[muted]}# R package aliases only${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow alias dispatchers  ${FLOW_COLORS[muted]}# Smart dispatchers${FLOW_COLORS[reset]}"
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
  echo "${FLOW_COLORS[bold]}Total:${FLOW_COLORS[reset]} 28 custom aliases + 8 dispatchers + 226+ git aliases"
  echo ""

  echo "${FLOW_COLORS[success]}📦 R Package Development${FLOW_COLORS[reset]} (23 aliases)"
  echo "  ${FLOW_COLORS[muted]}Core workflow: rload, rtest, rdoc, rcheck, rbuild, rinstall${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[cmd]}flow alias r${FLOW_COLORS[reset]} for full list"
  echo ""

  echo "${FLOW_COLORS[success]}🤖 Claude Code${FLOW_COLORS[reset]} (2 aliases)"
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
# ALIASES (backward compatibility)
# ============================================================================

# Allow both 'flow alias' and direct 'als' command
alias als='flow_alias'

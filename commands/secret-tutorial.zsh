#!/usr/bin/env zsh
# =============================================================================
# Interactive Token & Secret Management Tutorial
# =============================================================================
# Purpose: ADHD-friendly, step-by-step tutorial for learning token management
# Usage: dot secret tutorial
# Features:
#   - 7 interactive lessons with examples
#   - Progress tracking
#   - Real Keychain/Bitwarden integration
#   - Safe demo mode (no actual tokens created)
# =============================================================================

# Load flow-cli core for colors
[[ -f "${0:A:h}/../lib/core.zsh" ]] && source "${0:A:h}/../lib/core.zsh"

# =============================================================================
# Tutorial State Management
# =============================================================================

_tutorial_state_file="$HOME/.flow/tutorial-secret-state.json"

_tutorial_init_state() {
  mkdir -p "$(dirname "$_tutorial_state_file")"

  if [[ ! -f "$_tutorial_state_file" ]]; then
    cat > "$_tutorial_state_file" << 'EOF'
{
  "completed_steps": [],
  "current_step": 1,
  "started": "",
  "last_accessed": ""
}
EOF
  fi
}

_tutorial_mark_complete() {
  local step=$1
  _tutorial_init_state

  # Update state file
  local state=$(cat "$_tutorial_state_file")
  local updated=$(echo "$state" | jq \
    --arg step "$step" \
    --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '.completed_steps += [$step] | .completed_steps |= unique | .last_accessed = $now')

  echo "$updated" > "$_tutorial_state_file"
}

_tutorial_is_complete() {
  local step=$1
  _tutorial_init_state

  cat "$_tutorial_state_file" | jq -r --arg step "$step" \
    '.completed_steps | contains([$step])'
}

_tutorial_reset() {
  rm -f "$_tutorial_state_file"
  _tutorial_init_state
  echo "${FLOW_COLORS[success]}✓ Tutorial progress reset${FLOW_COLORS[reset]}"
}

# =============================================================================
# Tutorial UI Helpers
# =============================================================================

_tutorial_header() {
  local step=$1
  local total=7
  local title=$2

  echo ""
  echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}📚 Token & Secret Management Tutorial${FLOW_COLORS[reset]}          ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Step $step/$total: $title$(printf '%*s' $((43 - ${#title})) '')${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
}

_tutorial_section() {
  local title=$1
  echo ""
  echo "${FLOW_COLORS[section]}━━━ $title ━━━${FLOW_COLORS[reset]}"
  echo ""
}

_tutorial_info() {
  echo "${FLOW_COLORS[info]}ℹ  $*${FLOW_COLORS[reset]}"
}

_tutorial_success() {
  echo "${FLOW_COLORS[success]}✓  $*${FLOW_COLORS[reset]}"
}

_tutorial_warning() {
  echo "${FLOW_COLORS[warning]}⚠  $*${FLOW_COLORS[reset]}"
}

_tutorial_command() {
  echo ""
  echo "${FLOW_COLORS[muted]}  $ ${FLOW_COLORS[cmd]}$*${FLOW_COLORS[reset]}"
  echo ""
}

_tutorial_pause() {
  echo ""
  read -q "?${FLOW_COLORS[prompt]}Press Enter to continue...${FLOW_COLORS[reset]} "
  echo ""
}

_tutorial_ask() {
  local prompt=$1
  local default=${2:-y}

  read -q "?${FLOW_COLORS[prompt]}$prompt [${default}/n] ${FLOW_COLORS[reset]}"
  local response=$?
  echo ""
  return $response
}

# =============================================================================
# Tutorial Steps
# =============================================================================

_tutorial_step_intro() {
  _tutorial_header 1 "Introduction"

  cat << EOF
${FLOW_COLORS[section]}Welcome to the Token & Secret Management Tutorial!${FLOW_COLORS[reset]}

This interactive tutorial will teach you how to:
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Store tokens securely (GitHub, npm, PyPI)
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Retrieve tokens for scripts
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Check token expiration
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Rotate tokens safely
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Manage token lifecycle
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Troubleshoot common issues
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Follow security best practices

${FLOW_COLORS[info]}Estimated time: 10-15 minutes${FLOW_COLORS[reset]}

${FLOW_COLORS[section]}How This Tutorial Works:${FLOW_COLORS[reset]}

  • ${FLOW_COLORS[bold]}Interactive lessons${FLOW_COLORS[reset]} - You'll practice real commands
  • ${FLOW_COLORS[bold]}Safe demo mode${FLOW_COLORS[reset]} - No actual tokens created
  • ${FLOW_COLORS[bold]}Progress tracking${FLOW_COLORS[reset]} - Resume anytime
  • ${FLOW_COLORS[bold]}ADHD-friendly${FLOW_COLORS[reset]} - Clear steps, visual feedback

${FLOW_COLORS[section]}Prerequisites:${FLOW_COLORS[reset]}

  ✓ flow-cli installed and loaded
  ✓ Bitwarden CLI installed (${FLOW_COLORS[cmd]}brew install bitwarden-cli${FLOW_COLORS[reset]})
  ✓ Bitwarden account logged in
  ✓ macOS Keychain access

EOF

  if _tutorial_ask "Ready to start?" "y"; then
    _tutorial_mark_complete "intro"
    return 0
  else
    echo ""
    echo "${FLOW_COLORS[muted]}Tutorial cancelled. Run ${FLOW_COLORS[cmd]}dot secret tutorial${FLOW_COLORS[muted]} to restart.${FLOW_COLORS[reset]}"
    return 1
  fi
}

_tutorial_step_architecture() {
  _tutorial_header 2 "Architecture Overview"

  cat << EOF
${FLOW_COLORS[section]}Understanding Dual Storage${FLOW_COLORS[reset]}

flow-cli stores tokens in ${FLOW_COLORS[bold]}TWO${FLOW_COLORS[reset]} backends simultaneously:

┌─────────────────────────────────────────────────────────────┐
│                   USER ACTION                               │
│                 dot token github                            │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
┌──────────────────┐     ┌──────────────────┐
│   ${FLOW_COLORS[bold]}BITWARDEN${FLOW_COLORS[reset]}      │     │    ${FLOW_COLORS[bold]}KEYCHAIN${FLOW_COLORS[reset]}      │
│   (Cloud Sync)   │     │  (Instant Access)│
├──────────────────┤     ├──────────────────┤
│ • password:      │     │ • -w: token      │
│   token value    │     │   (protected)    │
│ • notes:         │     │ • -j: metadata   │
│   metadata JSON  │     │   (searchable)   │
│                  │     │                  │
│ Speed: ~2-5s     │     │ Speed: < 50ms    │
│ Requires unlock  │     │ Touch ID         │
│ Web accessible   │     │ Offline ready    │
└──────────────────┘     └──────────────────┘

${FLOW_COLORS[section]}Why Two Backends?${FLOW_COLORS[reset]}

${FLOW_COLORS[success]}✓ Bitwarden${FLOW_COLORS[reset]} = Source of truth (cloud backup, sync)
${FLOW_COLORS[success]}✓ Keychain${FLOW_COLORS[reset]}  = Performance cache (instant, Touch ID)

${FLOW_COLORS[section]}Metadata Format (v2.1):${FLOW_COLORS[reset]}

{
  "dot_version": "2.1",
  "type": "github",
  "token_type": "classic",
  "created": "2026-01-24T14:30:00Z",
  "expires_days": 90,
  "expires": "2026-04-24",
  "github_user": "username"
}

${FLOW_COLORS[info]}ℹ  Metadata is stored in BOTH backends for consistency${FLOW_COLORS[reset]}

EOF

  _tutorial_pause

  cat << EOF

${FLOW_COLORS[section]}Security Model:${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}Keychain Storage:${FLOW_COLORS[reset]}
  -w (password): ${FLOW_COLORS[success]}ENCRYPTED${FLOW_COLORS[reset]} - requires Touch ID/password
  -j (JSON):     ${FLOW_COLORS[info]}SEARCHABLE${FLOW_COLORS[reset]} - enables fast expiration checks
  -a (account):  ${FLOW_COLORS[info]}IDENTIFIER${FLOW_COLORS[reset]} - token name
  -s (service):  ${FLOW_COLORS[info]}NAMESPACE${FLOW_COLORS[reset]} - "flow-cli"

${FLOW_COLORS[bold]}Why -j flag is safe:${FLOW_COLORS[reset]}
  • Metadata doesn't contain secrets (only dates, types)
  • Enables expiration checks WITHOUT Touch ID prompt
  • Still encrypted in Keychain database
  • User can search tokens without unlocking

EOF

  if _tutorial_ask "Architecture clear?" "y"; then
    _tutorial_mark_complete "architecture"
    return 0
  else
    echo ""
    echo "${FLOW_COLORS[muted]}No problem! You can review the architecture later in:${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[muted]}  docs/guides/TOKEN-MANAGEMENT-COMPLETE.md${FLOW_COLORS[reset]}"
    _tutorial_pause
    return 0
  fi
}

_tutorial_step_demo_add() {
  _tutorial_header 3 "Adding a Token (Demo)"

  cat << EOF
${FLOW_COLORS[section]}Let's practice adding a token!${FLOW_COLORS[reset]}

${FLOW_COLORS[warning]}⚠  DEMO MODE${FLOW_COLORS[reset]}
We'll create a ${FLOW_COLORS[bold]}fake test token${FLOW_COLORS[reset]} to practice the workflow.
This won't create a real GitHub token.

${FLOW_COLORS[section]}The Add Token Workflow:${FLOW_COLORS[reset]}

  1. Run: ${FLOW_COLORS[cmd]}dot token github${FLOW_COLORS[reset]}
  2. Choose token type (classic or fine-grained)
  3. Browser opens to GitHub token creation page
  4. Create token with recommended scopes
  5. Paste token when prompted
  6. Token validated via GitHub API
  7. Stored in Bitwarden + Keychain

${FLOW_COLORS[info]}ℹ  For this demo, we'll simulate steps 1-6${FLOW_COLORS[reset]}

EOF

  if ! _tutorial_ask "Ready to try?" "y"; then
    echo ""
    echo "${FLOW_COLORS[muted]}Skipping demo. You can practice later with a real token.${FLOW_COLORS[reset]}"
    _tutorial_pause
    return 0
  fi

  echo ""
  _tutorial_section "DEMO: Adding GitHub Token"

  _tutorial_command "dot secret add demo-github-token"

  cat << EOF
${FLOW_COLORS[prompt]}Enter secret value:${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}ghp_DEMO_TOKEN_NOT_REAL_1234567890ABCDEF${FLOW_COLORS[reset]}
EOF

  # Actually add demo token to Keychain (safe - it's fake)
  echo "ghp_DEMO_TOKEN_NOT_REAL_1234567890ABCDEF" | \
    security add-generic-password \
      -a "demo-github-token" \
      -s "flow-cli" \
      -w /dev/stdin \
      -j '{"dot_version":"2.1","type":"demo","created":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","expires_days":90}' \
      -U 2>/dev/null

  if [[ $? -eq 0 ]]; then
    echo ""
    _tutorial_success "Demo token added to Keychain!"
    echo ""
    cat << EOF
${FLOW_COLORS[section]}What just happened:${FLOW_COLORS[reset]}

  1. ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Token value stored in Keychain (encrypted)
  2. ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Metadata stored (for expiration checks)
  3. ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Touch ID may have prompted (first time)

${FLOW_COLORS[info]}ℹ  In real usage, this would ALSO store in Bitwarden${FLOW_COLORS[reset]}

EOF
  else
    echo ""
    _tutorial_warning "Keychain add failed (may need Accessibility permissions)"
    echo ""
    cat << EOF
${FLOW_COLORS[section]}Troubleshooting:${FLOW_COLORS[reset]}

  1. Open: ${FLOW_COLORS[cmd]}System Settings → Privacy & Security${FLOW_COLORS[reset]}
  2. Click: ${FLOW_COLORS[cmd]}Accessibility${FLOW_COLORS[reset]}
  3. Enable: ${FLOW_COLORS[cmd]}Terminal.app${FLOW_COLORS[reset]} or ${FLOW_COLORS[cmd]}iTerm.app${FLOW_COLORS[reset]}
  4. Retry tutorial

EOF
  fi

  _tutorial_pause
  _tutorial_mark_complete "demo-add"
}

_tutorial_step_retrieve() {
  _tutorial_header 4 "Retrieving Tokens"

  cat << EOF
${FLOW_COLORS[section]}How to Retrieve Tokens${FLOW_COLORS[reset]}

Tokens are retrieved with: ${FLOW_COLORS[cmd]}dot secret <name>${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}Key features:${FLOW_COLORS[reset]}
  • ${FLOW_COLORS[success]}No echo${FLOW_COLORS[reset]} to terminal (security)
  • ${FLOW_COLORS[success]}Touch ID${FLOW_COLORS[reset]} prompt (first access only)
  • ${FLOW_COLORS[success]}< 50ms${FLOW_COLORS[reset]} response time
  • ${FLOW_COLORS[success]}Cached${FLOW_COLORS[reset]} in memory (session)

${FLOW_COLORS[section]}Common Usage Patterns:${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}1. Environment Variable:${FLOW_COLORS[reset]}
EOF
  _tutorial_command "export GITHUB_TOKEN=\$(dot secret github-token)"

  cat << EOF
${FLOW_COLORS[bold]}2. GitHub CLI:${FLOW_COLORS[reset]}
EOF
  _tutorial_command "gh auth login --with-token <<< \$(dot secret github-token)"

  cat << EOF
${FLOW_COLORS[bold]}3. curl API Calls:${FLOW_COLORS[reset]}
EOF
  _tutorial_command "curl -H \"Authorization: token \$(dot secret github-token)\" \\"
  echo "  https://api.github.com/user"
  echo ""

  cat << EOF
${FLOW_COLORS[bold]}4. npm Publishing:${FLOW_COLORS[reset]}
EOF
  _tutorial_command "npm config set //registry.npmjs.org/:_authToken \"\$(dot secret npm-token)\""

  echo ""
  _tutorial_section "DEMO: Retrieve Our Test Token"

  if _tutorial_ask "Try retrieving the demo token?" "y"; then
    echo ""
    _tutorial_command "dot secret demo-github-token"

    local token_value=$(security find-generic-password \
      -a "demo-github-token" \
      -s "flow-cli" \
      -w 2>/dev/null)

    if [[ -n "$token_value" ]]; then
      echo "${FLOW_COLORS[muted]}(Token retrieved - not shown for security)${FLOW_COLORS[reset]}"
      echo ""
      echo "${FLOW_COLORS[info]}Token length: ${#token_value} characters${FLOW_COLORS[reset]}"
      echo ""
      _tutorial_success "Retrieval successful!"
    else
      _tutorial_warning "Token not found (may have been skipped in previous step)"
    fi
  fi

  echo ""
  _tutorial_pause
  _tutorial_mark_complete "retrieve"
}

_tutorial_step_expiration() {
  _tutorial_header 5 "Checking Expiration"

  cat << EOF
${FLOW_COLORS[section]}Token Expiration Management${FLOW_COLORS[reset]}

Tokens expire for security (GitHub enforces 90 days max).

${FLOW_COLORS[bold]}Check expiration status:${FLOW_COLORS[reset]}
EOF
  _tutorial_command "dot token expiring"

  cat << EOF
${FLOW_COLORS[section]}Example Output:${FLOW_COLORS[reset]}

╭───────────────────────────────────────────────────╮
│  Token Expiration Status                          │
├───────────────────────────────────────────────────┤
│                                                   │
│  ${FLOW_COLORS[warning]}⚠️  github-token${FLOW_COLORS[reset]}                                  │
│      Expires: 2026-01-29 (5 days)                 │
│      Type: GitHub Classic PAT                     │
│      Action: Run 'dot token rotate'               │
│                                                   │
│  ${FLOW_COLORS[success]}✅  npm-token${FLOW_COLORS[reset]}                                     │
│      Expires: 2026-04-24 (67 days)                │
│      Type: npm Publish                            │
│                                                   │
╰───────────────────────────────────────────────────╯

${FLOW_COLORS[section]}How Expiration Checks Work:${FLOW_COLORS[reset]}

  1. Read metadata from Keychain (${FLOW_COLORS[info]}-j flag${FLOW_COLORS[reset]})
  2. Parse creation date from JSON
  3. Calculate days since creation
  4. Compare to expiration period (90 days)
  5. ${FLOW_COLORS[success]}No Touch ID prompt required!${FLOW_COLORS[reset]}

${FLOW_COLORS[info]}ℹ  This is why metadata is stored separately - fast checks${FLOW_COLORS[reset]}

EOF

  _tutorial_section "DEMO: Check Demo Token Age"

  if _tutorial_ask "Check our demo token?" "y"; then
    echo ""

    # Get demo token metadata
    local metadata=$(security find-generic-password \
      -a "demo-github-token" \
      -s "flow-cli" \
      -g 2>&1 | grep "note:" | sed 's/note: //')

    if [[ -n "$metadata" ]]; then
      local created=$(echo "$metadata" | jq -r '.created')
      local created_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$created" "+%s" 2>/dev/null)
      local now_epoch=$(date +%s)
      local age_seconds=$((now_epoch - created_epoch))
      local age_days=$((age_seconds / 86400))

      echo "${FLOW_COLORS[info]}Token created: $created${FLOW_COLORS[reset]}"
      echo "${FLOW_COLORS[info]}Age: $age_days days${FLOW_COLORS[reset]}"
      echo ""
      _tutorial_success "Metadata retrieved without Touch ID!"
    else
      _tutorial_warning "Demo token metadata not found"
    fi
  fi

  echo ""
  _tutorial_pause
  _tutorial_mark_complete "expiration"
}

_tutorial_step_rotation() {
  _tutorial_header 6 "Rotating Tokens"

  cat << EOF
${FLOW_COLORS[section]}Token Rotation${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}When to rotate:${FLOW_COLORS[reset]}
  • ${FLOW_COLORS[warning]}⚠️${FLOW_COLORS[reset]}  Token expires in < 7 days
  • ${FLOW_COLORS[error]}🔒${FLOW_COLORS[reset]}  Suspected compromise
  • ${FLOW_COLORS[info]}📅${FLOW_COLORS[reset]}  Regular schedule (every 90 days)

${FLOW_COLORS[bold]}Rotation command:${FLOW_COLORS[reset]}
EOF
  _tutorial_command "dot token rotate"

  cat << EOF
${FLOW_COLORS[section]}What Rotation Does:${FLOW_COLORS[reset]}

  1. ${FLOW_COLORS[success]}Creates backup${FLOW_COLORS[reset]} of current token
     → Name: <token>-backup-YYYYMMDD
     → 7-day retention

  2. ${FLOW_COLORS[success]}Opens browser${FLOW_COLORS[reset]} to provider token page
     → GitHub: https://github.com/settings/tokens/new
     → npm: https://www.npmjs.com/settings/~/tokens/new

  3. ${FLOW_COLORS[success]}Validates new token${FLOW_COLORS[reset]} via provider API

  4. ${FLOW_COLORS[success]}Updates both backends${FLOW_COLORS[reset]}
     → Bitwarden (password + metadata)
     → Keychain (password + metadata)

  5. ${FLOW_COLORS[warning]}Manual step${FLOW_COLORS[reset]}: Revoke old token on provider

${FLOW_COLORS[info]}ℹ  Backup remains for rollback (delete after 7 days)${FLOW_COLORS[reset]}

EOF

  _tutorial_section "DEMO: Rotation Workflow"

  cat << EOF
${FLOW_COLORS[bold]}For a real token, you would:${FLOW_COLORS[reset]}

  1. Run: ${FLOW_COLORS[cmd]}dot token rotate${FLOW_COLORS[reset]}
  2. Select token to rotate
  3. Create new token on provider
  4. Paste new token
  5. Verify rotation successful
  6. Revoke old token on provider
  7. Delete backup after 7 days

${FLOW_COLORS[warning]}⚠  We won't rotate the demo token (it's fake)${FLOW_COLORS[reset]}

EOF

  _tutorial_pause
  _tutorial_mark_complete "rotation"
}

_tutorial_step_cleanup() {
  _tutorial_header 7 "Cleanup & Best Practices"

  cat << EOF
${FLOW_COLORS[section]}Let's Clean Up the Demo Token${FLOW_COLORS[reset]}

We created a fake token for practice. Let's delete it.

${FLOW_COLORS[bold]}Delete command:${FLOW_COLORS[reset]}
EOF
  _tutorial_command "dot secret delete <name>"

  echo ""
  if _tutorial_ask "Delete demo token now?" "y"; then
    echo ""
    _tutorial_command "dot secret delete demo-github-token"

    # Delete demo token from Keychain
    security delete-generic-password \
      -a "demo-github-token" \
      -s "flow-cli" 2>/dev/null

    if [[ $? -eq 0 ]]; then
      _tutorial_success "Demo token deleted!"
    else
      _tutorial_info "Demo token already deleted or not found"
    fi
  fi

  echo ""
  _tutorial_section "Security Best Practices"

  cat << EOF
${FLOW_COLORS[bold]}Token Hygiene:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Rotate every 90 days
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Use fine-grained PATs (GitHub)
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Minimum permissions
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Delete unused tokens
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Unique token per purpose

${FLOW_COLORS[bold]}Keychain Security:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Enable Touch ID
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Lock screen when away (⌃⌘Q)
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Regular Keychain backups
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Verify Accessibility permissions

${FLOW_COLORS[bold]}Bitwarden Security:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Strong master password (14+ chars)
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Enable 2FA (authenticator app)
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Regular vault audits
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Save recovery codes

${FLOW_COLORS[bold]}Automation:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Check expiration in scripts: ${FLOW_COLORS[cmd]}dot token expiring --quiet${FLOW_COLORS[reset]}
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Use in CI/CD: ${FLOW_COLORS[cmd]}export TOKEN=\$(dot secret <name>)${FLOW_COLORS[reset]}
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Monthly audit: ${FLOW_COLORS[cmd]}dot secret list${FLOW_COLORS[reset]} + manual review

EOF

  _tutorial_pause
  _tutorial_mark_complete "cleanup"
}

_tutorial_step_conclusion() {
  clear

  cat << EOF

${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🎉 Tutorial Complete!${FLOW_COLORS[reset]}                            ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}

${FLOW_COLORS[section]}You've learned:${FLOW_COLORS[reset]}

  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Dual storage architecture (Bitwarden + Keychain)
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Adding tokens (${FLOW_COLORS[cmd]}dot token github${FLOW_COLORS[reset]})
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Retrieving tokens (${FLOW_COLORS[cmd]}dot secret <name>${FLOW_COLORS[reset]})
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Checking expiration (${FLOW_COLORS[cmd]}dot token expiring${FLOW_COLORS[reset]})
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Rotating tokens (${FLOW_COLORS[cmd]}dot token rotate${FLOW_COLORS[reset]})
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Deleting tokens (${FLOW_COLORS[cmd]}dot secret delete <name>${FLOW_COLORS[reset]})
  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Security best practices

${FLOW_COLORS[section]}Next Steps:${FLOW_COLORS[reset]}

  1. ${FLOW_COLORS[bold]}Create your first real token${FLOW_COLORS[reset]}
     ${FLOW_COLORS[cmd]}dot token github${FLOW_COLORS[reset]}

  2. ${FLOW_COLORS[bold]}Set calendar reminder${FLOW_COLORS[reset]}
     Rotate tokens every 90 days

  3. ${FLOW_COLORS[bold]}Read comprehensive guide${FLOW_COLORS[reset]}
     ${FLOW_COLORS[cmd]}cat docs/guides/TOKEN-MANAGEMENT-COMPLETE.md${FLOW_COLORS[reset]}

  4. ${FLOW_COLORS[bold]}Keep quick reference handy${FLOW_COLORS[reset]}
     ${FLOW_COLORS[cmd]}cat docs/reference/REFCARD-TOKEN-SECRETS.md${FLOW_COLORS[reset]}

  5. ${FLOW_COLORS[bold]}Run health check${FLOW_COLORS[reset]}
     ${FLOW_COLORS[cmd]}flow doctor --dot${FLOW_COLORS[reset]}

${FLOW_COLORS[section]}Useful Commands:${FLOW_COLORS[reset]}

  ${FLOW_COLORS[cmd]}dot secret help${FLOW_COLORS[reset]}        Show all secret commands
  ${FLOW_COLORS[cmd]}dot token help${FLOW_COLORS[reset]}         Show all token commands
  ${FLOW_COLORS[cmd]}dot secret list${FLOW_COLORS[reset]}        List all stored secrets
  ${FLOW_COLORS[cmd]}dot token expiring${FLOW_COLORS[reset]}     Check expiration status
  ${FLOW_COLORS[cmd]}flow doctor --dot${FLOW_COLORS[reset]}      Token health check

${FLOW_COLORS[section]}Tutorial Progress:${FLOW_COLORS[reset]}

EOF

  # Show completed steps
  local completed_count=$(cat "$_tutorial_state_file" | jq -r '.completed_steps | length')
  echo "  ${FLOW_COLORS[success]}Completed: $completed_count/7 steps${FLOW_COLORS[reset]}"
  echo ""

  if _tutorial_ask "Reset tutorial progress?" "n"; then
    _tutorial_reset
  fi

  echo ""
  echo "${FLOW_COLORS[success]}Thank you for completing the tutorial!${FLOW_COLORS[reset]}"
  echo ""
}

# =============================================================================
# Main Tutorial Function
# =============================================================================

_sec_tutorial() {
  # Initialize state
  _tutorial_init_state

  # Run tutorial steps
  if ! _tutorial_step_intro; then
    return 1
  fi

  _tutorial_step_architecture
  _tutorial_step_demo_add
  _tutorial_step_retrieve
  _tutorial_step_expiration
  _tutorial_step_rotation
  _tutorial_step_cleanup
  _tutorial_step_conclusion

  # Mark tutorial complete
  local state=$(cat "$_tutorial_state_file")
  local updated=$(echo "$state" | jq \
    --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '.tutorial_completed = true | .last_accessed = $now')
  echo "$updated" > "$_tutorial_state_file"

  return 0
}

# Run tutorial if called directly (not when sourced by plugin loader)
# ZSH_EVAL_CONTEXT is "toplevel" only when executed directly
if [[ "${ZSH_EVAL_CONTEXT}" == "toplevel" ]]; then
  _sec_tutorial "$@"
fi

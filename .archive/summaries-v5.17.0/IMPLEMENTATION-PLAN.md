# Token Automation Implementation Plan

**Worktree:** `~/.git-worktrees/flow-cli/feature-token-automation`
**Branch:** `feature/token-automation`
**Base:** `dev` branch (v5.16.0)
**Target:** Implement Phases 1+2 from brainstorm documents

---

## Overview

This implementation combines two comprehensive brainstorm documents:

1. **Core Token Automation** (36KB) - Detection, rotation, security
2. **Flow-CLI Integration** (22KB) - 9 dispatcher integration points

**Combined Scope:**

- Phase 1: Core token automation (1.5 hours)
- Phase 2: flow-cli integration (2 hours)
- Total: ~3.5 hours for complete implementation

---

## Pre-Implementation Checklist

- [x] Worktree created at `~/.git-worktrees/flow-cli/feature-token-automation`
- [x] Branch `feature/token-automation` created from `dev`
- [ ] Dependencies installed (run: `source flow.plugin.zsh`)
- [ ] Test suite verified (run: `./tests/run-all.sh`)
- [ ] GitHub token available in Keychain for testing
- [ ] Review both brainstorm documents:
  - `/Users/dt/BRAINSTORM-automated-token-management-2026-01-23.md`
  - `/Users/dt/BRAINSTORM-flow-github-integration-2026-01-23.md`

---

## Phase 1: Core Token Automation (1.5 hours)

### Task 1.1: Token Expiration Detector (15 min)

**File:** `lib/dispatchers/dot-dispatcher.zsh`
**Location:** Add after existing `_dot_token_github()` function (line ~2145)

**Implementation:**

```zsh
# ───────────────────────────────────────────────────────────────────
# TOKEN EXPIRATION DETECTION
# ───────────────────────────────────────────────────────────────────

_dot_token_expiring() {
  _flow_log_info "Checking token expiration status..."

  # Get all GitHub tokens from Keychain
  local secrets=$(dot secret list 2>/dev/null | grep "•" | sed 's/.*• //')
  local expiring_tokens=()
  local expired_tokens=()

  for secret in ${(f)secrets}; do
    # Only check GitHub tokens
    if [[ "$secret" =~ github ]]; then
      local token=$(dot secret "$secret" 2>/dev/null)

      # Validate with GitHub API
      local api_response=$(curl -s \
        -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/user" 2>/dev/null)

      if echo "$api_response" | grep -q '"message":"Bad credentials"'; then
        expired_tokens+=("$secret")
      elif echo "$api_response" | grep -q '"login"'; then
        # Check if created 83+ days ago (7-day warning before 90-day expiration)
        local token_age_days=$(_dot_token_age_days "$secret")
        if [[ $token_age_days -ge 83 ]]; then
          expiring_tokens+=("$secret")
        fi
      fi
    fi
  done

  # Report findings
  if [[ ${#expired_tokens[@]} -gt 0 ]]; then
    _flow_log_error "EXPIRED tokens (need immediate rotation):"
    for token in "${expired_tokens[@]}"; do
      echo "  🔴 $token"
    done
    echo ""
  fi

  if [[ ${#expiring_tokens[@]} -gt 0 ]]; then
    _flow_log_warning "EXPIRING tokens (< 7 days remaining):"
    for token in "${expiring_tokens[@]}"; do
      local days_left=$((90 - $(_dot_token_age_days "$token")))
      echo "  🟡 $token - $days_left days remaining"
    done
    echo ""
  fi

  if [[ ${#expired_tokens[@]} -eq 0 && ${#expiring_tokens[@]} -eq 0 ]]; then
    _flow_log_success "All GitHub tokens are current"
    return 0
  fi

  # Offer rotation
  if [[ ${#expired_tokens[@]} -gt 0 || ${#expiring_tokens[@]} -gt 0 ]]; then
    echo ""
    read -q "?Rotate tokens now? [y/n] " rotate_response
    echo ""
    if [[ "$rotate_response" == "y" ]]; then
      _dot_token_rotate
    else
      _flow_log_info "Run ${FLOW_COLORS[cmd]}dot token rotate${FLOW_COLORS[reset]} when ready"
    fi
  fi
}

_dot_token_age_days() {
  local secret_name="$1"

  # Get creation timestamp from Keychain item metadata
  local metadata=$(security find-generic-password \
    -a "$secret_name" \
    -s "$_DOT_KEYCHAIN_SERVICE" \
    -g 2>&1 | grep "note:" | sed 's/note: //')

  if [[ -z "$metadata" ]]; then
    # No metadata, assume old token (flag for rotation)
    echo 90
    return
  fi

  # Parse creation date from JSON metadata
  local created_date=$(echo "$metadata" | jq -r '.created // empty' 2>/dev/null)
  if [[ -z "$created_date" ]]; then
    echo 90
    return
  fi

  # Calculate days since creation
  local created_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$created_date" "+%s" 2>/dev/null)
  local now_epoch=$(date +%s)
  local age_seconds=$((now_epoch - created_epoch))
  local age_days=$((age_seconds / 86400))

  echo $age_days
}
```

**Testing:**

```bash
# Add test token with old date
echo '{"created":"2025-10-25T00:00:00Z"}' | \
  security add-generic-password -a "test-old-token" -s "flow-cli-secrets" -w "test" -j - -U

# Test detection
source flow.plugin.zsh
dot token expiring
# Should show: "🟡 test-old-token - 0 days remaining"

# Clean up
dot secret delete test-old-token
```

**Commit:**

```bash
git add lib/dispatchers/dot-dispatcher.zsh
git commit -m "feat(dot): add token expiration detection

- Add _dot_token_expiring() function
- Validate tokens via GitHub API
- Calculate age from Keychain metadata
- Report expired and expiring tokens
- Prompt for rotation if issues found

Ref: BRAINSTORM-automated-token-management-2026-01-23.md"
```

---

### Task 1.2: Token Metadata Tracking (15 min)

**File:** `lib/dispatchers/dot-dispatcher.zsh`
**Location:** Modify existing `_dot_token_github()` function (line ~2089)

**Implementation:**

```zsh
# In _dot_token_github(), modify metadata creation (around line 2089):

  # Build metadata (ENHANCED with github_user)
  local metadata="{
    \"dot_version\": \"2.1\",
    \"type\": \"github\",
    \"token_type\": \"${token_type}\",
    \"created\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
    \"expires_days\": ${expire_days},
    \"github_user\": \"${username}\"
  }"

  # Store in Bitwarden
  _flow_log_info "Storing token in Bitwarden..."
  # ... existing Bitwarden code ...

  # ALSO store in Keychain with metadata for instant access
  _flow_log_info "Adding to Keychain for instant access..."
  security add-generic-password \
    -a "$token_name" \
    -s "$_DOT_KEYCHAIN_SERVICE" \
    -w "$token_value" \
    -j "$metadata" \
    -U 2>/dev/null
```

**Testing:**

```bash
# Generate a test token (or use existing)
dot token github

# Verify metadata stored
security find-generic-password -a "github-token" -s "flow-cli-secrets" -g 2>&1 | grep "note:"
# Should show JSON with created date

# Test age calculation
source flow.plugin.zsh
_dot_token_age_days "github-token"
# Should show: 0 (just created)
```

**Commit:**

```bash
git add lib/dispatchers/dot-dispatcher.zsh
git commit -m "feat(dot): track token metadata in Keychain

- Store creation timestamp in Keychain notes field
- Include github_user, token_type, expiration
- Enable accurate age calculation
- Support both Bitwarden + Keychain storage

Ref: BRAINSTORM-automated-token-management-2026-01-23.md"
```

---

### Task 1.3: Semi-Automated Token Rotation (30 min)

**File:** `lib/dispatchers/dot-dispatcher.zsh`
**Location:** Add after `_dot_token_expiring()` function

**Implementation:**

```zsh
# ───────────────────────────────────────────────────────────────────
# TOKEN ROTATION WORKFLOW
# ───────────────────────────────────────────────────────────────────

_dot_token_rotate() {
  local token_name="${1:-github-token}"

  _flow_log_info "Starting token rotation for: $token_name"

  # Step 1: Verify old token exists
  local old_token=$(dot secret "$token_name" 2>/dev/null)
  if [[ -z "$old_token" ]]; then
    _flow_log_error "Token '$token_name' not found in Keychain"
    return 1
  fi

  # Step 2: Validate old token (get user info for confirmation)
  local old_token_user=$(curl -s \
    -H "Authorization: token $old_token" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/user" 2>/dev/null | jq -r '.login // "unknown"')

  echo ""
  echo "${FLOW_COLORS[header]}╭─────────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🔄 Token Rotation${FLOW_COLORS[reset]}                                ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}├─────────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Current token: ${token_name}                       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  GitHub user: ${old_token_user}                    ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[warning]}⚠ This will:${FLOW_COLORS[reset]}                                    ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    1. Generate new token (browser)                ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    2. Store in Keychain                            ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    3. Validate new token                           ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    4. Keep old token as backup                     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰─────────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""

  read -q "?Continue with rotation? [y/n] " continue_response
  echo ""
  if [[ "$continue_response" != "y" ]]; then
    _flow_log_info "Rotation cancelled"
    return 0
  fi

  # Step 3: Backup old token
  local backup_name="${token_name}-backup-$(date +%Y%m%d)"
  echo "$old_token" | dot secret add "$backup_name" 2>/dev/null
  _flow_log_info "Old token backed up as: $backup_name"

  # Step 4: Generate new token (use existing wizard)
  _flow_log_info "Step 1/4: Generating new token..."
  echo ""
  echo "Follow the wizard to create a new token."
  echo "Use the SAME scopes as before for consistency."
  echo ""

  # Call existing wizard
  _dot_token_github

  # Verify new token was created
  local new_token=$(dot secret "$token_name" 2>/dev/null)
  if [[ -z "$new_token" || "$new_token" == "$old_token" ]]; then
    _flow_log_error "New token creation failed or unchanged"
    _flow_log_info "Restoring old token..."
    echo "$old_token" | dot secret add "$token_name"
    dot secret delete "$backup_name" 2>/dev/null
    return 1
  fi

  # Step 5: Validate new token
  _flow_log_info "Step 2/4: Validating new token..."
  local new_token_user=$(curl -s \
    -H "Authorization: token $new_token" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/user" 2>/dev/null | jq -r '.login // empty')

  if [[ -z "$new_token_user" ]]; then
    _flow_log_error "New token validation failed"
    _flow_log_info "Restoring old token..."
    echo "$old_token" | dot secret add "$token_name"
    dot secret delete "$backup_name" 2>/dev/null
    return 1
  fi

  if [[ "$new_token_user" != "$old_token_user" ]]; then
    _flow_log_error "New token user ($new_token_user) doesn't match old token user ($old_token_user)"
    read -q "?Continue anyway? [y/n] " mismatch_continue
    echo ""
    if [[ "$mismatch_continue" != "y" ]]; then
      echo "$old_token" | dot secret add "$token_name"
      dot secret delete "$backup_name" 2>/dev/null
      return 1
    fi
  fi

  _flow_log_success "New token validated for user: $new_token_user"

  # Step 6: Manual revocation prompt
  _flow_log_info "Step 3/4: Revoke old token on GitHub..."
  echo ""
  echo "${FLOW_COLORS[warning]}Manual Step Required:${FLOW_COLORS[reset]}"
  echo "Visit: ${FLOW_COLORS[cmd]}https://github.com/settings/tokens${FLOW_COLORS[reset]}"
  echo "Find token for: ${old_token_user}"
  echo "Look for token created before today"
  echo "Click 'Revoke' to delete old token"
  echo ""

  read -q "?Press 'y' when revocation is complete [y/n] " revoke_confirm
  echo ""

  if [[ "$revoke_confirm" == "y" ]]; then
    # Delete backup token (old token now revoked)
    dot secret delete "$backup_name" 2>/dev/null
    _flow_log_success "Old token backup removed"
  else
    _flow_log_warning "Old token backup kept at: $backup_name"
    _flow_log_info "Delete manually after revocation: dot secret delete $backup_name"
  fi

  # Step 7: Log rotation event
  _dot_token_log_rotation "$token_name" "$new_token_user" "success"

  # Step 8: Update environment variable
  _flow_log_info "Step 4/4: Updating shell environment..."
  echo ""
  _flow_log_warning "Restart your shell to apply changes:"
  echo "  ${FLOW_COLORS[cmd]}exec zsh${FLOW_COLORS[reset]}"
  echo ""

  echo ""
  echo "${FLOW_COLORS[header]}╭─────────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[success]}✓ Token Rotation Complete${FLOW_COLORS[reset]}                        ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Token: $token_name                                ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  User: $new_token_user                             ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Next rotation: ~$(date -v+90d +%Y-%m-%d 2>/dev/null || date -d '+90 days' +%Y-%m-%d)          ${FLOW_COLORS[reset]}${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰─────────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
}

_dot_token_log_rotation() {
  local token_name="$1"
  local user="$2"
  local status="$3"

  local log_file="$HOME/.claude/logs/token-rotation.log"
  mkdir -p "$(dirname "$log_file")"

  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "$timestamp | $token_name | $user | $status" >> "$log_file"
}
```

**Testing:**

```bash
# Test rotation workflow (manual testing required)
source flow.plugin.zsh
dot token rotate github-token

# Verify:
# 1. Backup created
# 2. New token generated via wizard
# 3. New token validated
# 4. Prompt for manual revocation shown
# 5. Log entry created

# Check log
cat ~/.claude/logs/token-rotation.log
```

**Commit:**

```bash
git add lib/dispatchers/dot-dispatcher.zsh
git commit -m "feat(dot): add semi-automated token rotation

- Add _dot_token_rotate() workflow
- Backup old token before rotation
- Validate new token via GitHub API
- Prompt for manual revocation (security)
- Log rotation events with audit trail
- Keep both tokens as safety net

Ref: BRAINSTORM-automated-token-management-2026-01-23.md"
```

---

### Task 1.4: gh CLI Auto-Sync (15 min)

**File:** `lib/dispatchers/dot-dispatcher.zsh`
**Location:** Add after `_dot_token_rotate()` function

**Implementation:**

```zsh
# ───────────────────────────────────────────────────────────────────
# GH CLI INTEGRATION
# ───────────────────────────────────────────────────────────────────

_dot_token_sync_gh() {
  _flow_log_info "Syncing token with gh CLI..."

  # Get token from Keychain
  local token=$(dot secret github-token 2>/dev/null)
  if [[ -z "$token" ]]; then
    _flow_log_error "github-token not found in Keychain"
    _flow_log_info "Add one: ${FLOW_COLORS[cmd]}dot token github${FLOW_COLORS[reset]}"
    return 1
  fi

  # Check if gh CLI is installed
  if ! command -v gh &>/dev/null; then
    _flow_log_warning "gh CLI not installed"
    _flow_log_info "Install: ${FLOW_COLORS[cmd]}brew install gh${FLOW_COLORS[reset]}"
    return 1
  fi

  # Authenticate gh with token
  echo "$token" | gh auth login --with-token 2>/dev/null

  if gh auth status &>/dev/null; then
    local gh_user=$(gh api user --jq '.login' 2>/dev/null)
    _flow_log_success "gh CLI authenticated as: $gh_user"
  else
    _flow_log_error "gh authentication failed"
    return 1
  fi
}

# Modify _dot_token_rotate() to call sync after successful rotation:
# Add before the final success banner:
#   _flow_log_info "Syncing with gh CLI..."
#   _dot_token_sync_gh
```

**Testing:**

```bash
source flow.plugin.zsh

# Test sync
dot token sync gh

# Verify
gh auth status
# Should show: "Logged in to github.com as <username>"
```

**Commit:**

```bash
git add lib/dispatchers/dot-dispatcher.zsh
git commit -m "feat(dot): add gh CLI auto-sync

- Add _dot_token_sync_gh() function
- Authenticate gh with Keychain token
- Auto-sync after token rotation
- Validate gh auth status

Ref: BRAINSTORM-flow-github-integration-2026-01-23.md"
```

---

### Task 1.5: Weekly Health Check Hook (15 min)

**File:** `~/.config/zsh/.zshrc` (user's environment, not in repo)
**Alternative:** Document in CLAUDE.md for user to add manually

**Implementation (Documentation):**

Create `docs/guides/TOKEN-HEALTH-CHECK.md`:

```markdown
# Automatic Token Health Checks

## Weekly Health Check (Recommended)

Add to your `~/.config/zsh/.zshrc`:

\`\`\`bash

# Weekly token health check (runs once per week max)

\_flow_weekly_token_check() {
local last_check_file="$HOME/.cache/flow-cli/last-token-check"
  local last_check_date=$(cat "$last_check_file" 2>/dev/null || echo "0")
  local current_date=$(date +%Y%m%d)
local days_since=$((current_date - last_check_date))

if [[$days_since -ge 7]]; then # Check token status (silent)
local token_status=$(dot token expiring 2>&1)
    echo "$current_date" > "$last_check_file"

    # Only notify if issues found
    if echo "$token_status" | grep -q "EXPIRED\|EXPIRING"; then
      # macOS Notification
      osascript -e 'display notification "GitHub tokens need rotation" with title "flow-cli" sound name "default"' &>/dev/null

      # Shell prompt
      echo ""
      echo "${FLOW_COLORS[warning]}⚠ flow-cli: GitHub tokens need rotation${FLOW_COLORS[reset]}"
      echo "Run: ${FLOW_COLORS[cmd]}dot token rotate${FLOW_COLORS[reset]}"
      echo ""
    fi

fi
}

# Run async on shell startup (non-blocking)

\_flow_weekly_token_check &!
\`\`\`

## Manual Health Check

Run anytime:

\`\`\`bash
dot token expiring
\`\`\`

## Integration with flow doctor

Coming in Phase 2: `flow doctor` will include token health checks.
```

**Commit:**

```bash
git add docs/guides/TOKEN-HEALTH-CHECK.md
git commit -m "docs: add token health check guide

- Document weekly health check hook
- User adds to ~/.config/zsh/.zshrc
- Non-blocking async execution
- macOS notification on issues
- Manual check command

Ref: BRAINSTORM-automated-token-management-2026-01-23.md"
```

---

## Phase 2: flow-cli Integration (2 hours)

### Task 2.1: g Dispatcher - Token Validation (20 min)

**File:** `lib/dispatchers/g-dispatcher.zsh`
**Location:** Modify existing `g()` function

**Implementation:**

```zsh
# Add at the top of g-dispatcher.zsh (after header comments)

_g_is_github_remote() {
  # Check if current repo has GitHub remote
  git remote -v 2>/dev/null | grep -q "github.com"
}

_g_validate_github_token_silent() {
  # Quick validation without output
  # Returns 0 if valid, 1 if expired/invalid
  local token=$(dot secret github-token 2>/dev/null)
  [[ -z "$token" ]] && return 1

  local http_code=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: token $token" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/user" 2>/dev/null)

  [[ "$http_code" == "200" ]]
}

# Modify the main g() function to intercept push/pull:

g() {
  local subcommand="$1"
  shift

  # Intercept remote operations for GitHub repos
  case "$subcommand" in
    push|pull|fetch)
      if _g_is_github_remote; then
        # Validate token before operation
        if ! _g_validate_github_token_silent; then
          _flow_log_warning "GitHub token may be expired"
          _flow_log_info "Check status: ${FLOW_COLORS[cmd]}dot token dashboard${FLOW_COLORS[reset]}"
          echo ""
          read -q "?Continue anyway? [y/n] " continue_response
          echo ""
          [[ "$continue_response" != "y" ]] && return 1
        fi
      fi

      # Proceed with git operation
      git "$subcommand" "$@"
      ;;

    *)
      # Pass through to existing git commands
      git "$subcommand" "$@"
      ;;
  esac
}
```

**Testing:**

```bash
source flow.plugin.zsh

# Test with expired token (simulate)
dot secret delete github-token
g push
# Should show warning and prompt

# Test with valid token
dot token github  # Add valid token
g push
# Should proceed without prompt
```

**Commit:**

```bash
git add lib/dispatchers/g-dispatcher.zsh
git commit -m "feat(g): add token validation before remote ops

- Validate GitHub token before push/pull/fetch
- Prompt to continue if token expired
- Silent validation (no output if OK)
- Only check for GitHub remotes

Ref: BRAINSTORM-flow-github-integration-2026-01-23.md"
```

---

### Task 2.2: dash Integration - Token Status Section (20 min)

**File:** `commands/dash.zsh`
**Location:** Modify `_dash_dev()` function (around line 100-200)

**Implementation:**

```zsh
# In _dash_dev(), add GitHub Token section after existing sections:

_dash_dev() {
  # ... existing dev dashboard code ...

  # Add GitHub Token section
  echo ""
  echo "${FLOW_COLORS[header]}GitHub Token${FLOW_COLORS[reset]}"
  echo "────────────"

  local token=$(dot secret github-token 2>/dev/null)
  if [[ -z "$token" ]]; then
    echo "  ${FLOW_COLORS[muted]}Not configured${FLOW_COLORS[reset]}"
    echo "  Setup: ${FLOW_COLORS[cmd]}dot token github${FLOW_COLORS[reset]}"
  else
    # Validate token
    local api_response=$(curl -s -w "\n%{http_code}" \
      -H "Authorization: token $token" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/user" 2>/dev/null)

    local http_code=$(echo "$api_response" | tail -1)

    if [[ "$http_code" == "200" ]]; then
      local username=$(echo "$api_response" | sed '$d' | jq -r '.login')
      local age_days=$(_dot_token_age_days "github-token")
      local days_remaining=$((90 - age_days))

      if [[ $days_remaining -le 0 ]]; then
        echo "  🔴 ${FLOW_COLORS[error]}EXPIRED${FLOW_COLORS[reset]} - Rotate now!"
        echo "  Rotate: ${FLOW_COLORS[cmd]}dot token rotate${FLOW_COLORS[reset]}"
      elif [[ $days_remaining -le 7 ]]; then
        echo "  🟡 ${FLOW_COLORS[warning]}Expiring in $days_remaining days${FLOW_COLORS[reset]}"
        echo "  Rotate: ${FLOW_COLORS[cmd]}dot token rotate${FLOW_COLORS[reset]}"
      else
        echo "  ✅ ${FLOW_COLORS[success]}Current${FLOW_COLORS[reset]} (@$username)"
        echo "  Expires: $days_remaining days"
      fi
    else
      echo "  🔴 ${FLOW_COLORS[error]}Invalid${FLOW_COLORS[reset]} - Check token"
      echo "  Fix: ${FLOW_COLORS[cmd]}dot token rotate${FLOW_COLORS[reset]}"
    fi
  fi

  # ... rest of dev dashboard ...
}
```

**Testing:**

```bash
source flow.plugin.zsh
dash dev

# Should show token status section with:
# - ✅ Current if valid and > 7 days remaining
# - 🟡 Warning if < 7 days remaining
# - 🔴 Error if expired/invalid
```

**Commit:**

```bash
git add commands/dash.zsh
git commit -m "feat(dash): add GitHub token status to dev dashboard

- Show token health in dash dev section
- Color-coded status indicators (✅🟡🔴)
- Display days remaining until expiration
- Suggest rotation command if needed

Ref: BRAINSTORM-flow-github-integration-2026-01-23.md"
```

---

### Task 2.3: work Command Integration (20 min)

**File:** `commands/work.zsh`
**Location:** Modify `_work_start()` function

**Implementation:**

```zsh
# Add helper functions at top of work.zsh:

_work_project_uses_github() {
  local project="$1"
  local project_path=$(_proj_find_path "$project")

  [[ -d "$project_path/.git" ]] && \
    git -C "$project_path" remote -v 2>/dev/null | grep -q "github.com"
}

_work_get_token_status() {
  local token=$(dot secret github-token 2>/dev/null)
  [[ -z "$token" ]] && echo "not configured" && return

  local http_code=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: token $token" \
    "https://api.github.com/user" 2>/dev/null)

  if [[ "$http_code" != "200" ]]; then
    echo "expired/invalid"
    return
  fi

  local age_days=$(_dot_token_age_days "github-token")
  local days_remaining=$((90 - age_days))

  if [[ $days_remaining -le 7 ]]; then
    echo "expiring in $days_remaining days"
  else
    echo "ok"
  fi
}

# Modify _work_start() to add token status to banner:

_work_start() {
  local project="$1"

  # ... existing work start code ...

  # Add token status to banner (after showing project info)
  if _work_project_uses_github "$project"; then
    local token_status=$(_work_get_token_status)
    if [[ "$token_status" != "ok" ]]; then
      echo ""
      echo "${FLOW_COLORS[warning]}⚠ GitHub Token: $token_status${FLOW_COLORS[reset]}"
      echo "   Fix: ${FLOW_COLORS[cmd]}dot token rotate${FLOW_COLORS[reset]}"
    fi
  fi

  # ... rest of work start ...
}
```

**Testing:**

```bash
source flow.plugin.zsh

# Test with GitHub project
work flow-cli

# Should show token warning if expired/expiring
# Should be silent if token is OK
```

**Commit:**

```bash
git add commands/work.zsh
git commit -m "feat(work): show token status in session banner

- Detect if project uses GitHub
- Check token health on work start
- Show warning only if issues found
- Suggest rotation command

Ref: BRAINSTORM-flow-github-integration-2026-01-23.md"
```

---

### Task 2.4: finish Command Integration (15 min)

**File:** `commands/work.zsh`
**Location:** Modify `_work_finish()` function

**Implementation:**

```zsh
# Add helper function:

_work_will_push_to_remote() {
  # Check if current branch tracks a remote
  git rev-parse --abbrev-ref --symbolic-full-name @{u} &>/dev/null
}

# Modify _work_finish() to validate token before push:

_work_finish() {
  local message="$1"

  # ... existing finish code ...

  # If pushing to remote, validate token
  if _work_will_push_to_remote; then
    if _work_project_uses_github; then
      _flow_log_info "Validating GitHub token..."

      if ! _g_validate_github_token_silent; then
        _flow_log_error "GitHub token expired or invalid"
        echo ""
        read -q "?Rotate token now? [y/n] " rotate_response
        echo ""
        if [[ "$rotate_response" == "y" ]]; then
          dot token rotate
          [[ $? -ne 0 ]] && return 1
        else
          _flow_log_info "Skipping push due to token issue"
          _flow_log_info "Commit saved locally, push manually later"
          return 0
        fi
      fi
    fi
  fi

  # ... proceed with finish ...
}
```

**Testing:**

```bash
# Make a test change
echo "test" >> README.md

# Finish with push
finish "test commit"

# Should validate token before pushing
# Should prompt for rotation if expired
```

**Commit:**

```bash
git add commands/work.zsh
git commit -m "feat(finish): validate token before push

- Check token only if pushing to remote
- Offer rotation if token expired
- Allow local commit if user declines rotation
- Skip for non-GitHub projects

Ref: BRAINSTORM-flow-github-integration-2026-01-23.md"
```

---

### Task 2.5: flow doctor Integration (30 min)

**File:** `commands/flow.zsh`
**Location:** Modify/enhance `_flow_doctor()` function

**Implementation:**

```zsh
_flow_doctor() {
  local fix_mode=false
  [[ "$1" == "--fix" ]] && fix_mode=true

  _flow_log_header "flow-cli Health Check"
  echo ""

  # ... existing health checks ...

  # GitHub Token Health
  echo "${FLOW_COLORS[header]}GitHub Token${FLOW_COLORS[reset]}"
  echo "──────────────"

  local token=$(dot secret github-token 2>/dev/null)
  local token_issues=()

  if [[ -z "$token" ]]; then
    echo "  ❌ Not configured"
    token_issues+=("missing")
  else
    # Validate token via API
    local api_response=$(curl -s -w "\n%{http_code}" \
      -H "Authorization: token $token" \
      "https://api.github.com/user" 2>/dev/null)

    local http_code=$(echo "$api_response" | tail -1)
    local username=$(echo "$api_response" | sed '$d' | jq -r '.login // "unknown"')

    if [[ "$http_code" != "200" ]]; then
      echo "  ❌ Invalid/Expired"
      token_issues+=("invalid")
    else
      echo "  ✅ Valid (@$username)"

      # Check expiration
      local age_days=$(_dot_token_age_days "github-token")
      local days_remaining=$((90 - age_days))

      if [[ $days_remaining -le 7 ]]; then
        echo "  ⚠️  Expiring in $days_remaining days"
        token_issues+=("expiring")
      fi

      # Test token-dependent services
      echo ""
      echo "  ${FLOW_COLORS[muted]}Token-Dependent Services:${FLOW_COLORS[reset]}"

      # Test gh CLI
      if command -v gh &>/dev/null; then
        if gh auth status &>/dev/null 2>&1; then
          echo "    ✅ gh CLI authenticated"
        else
          echo "    ❌ gh CLI not authenticated"
          token_issues+=("gh-cli")
        fi
      else
        echo "    ⚠️  gh CLI not installed"
      fi

      # Test Claude Code MCP
      if [[ -f "$HOME/.claude/settings.json" ]]; then
        if grep -q "GITHUB_PERSONAL_ACCESS_TOKEN.*\${GITHUB_TOKEN}" "$HOME/.claude/settings.json"; then
          if [[ -n "$GITHUB_TOKEN" ]]; then
            echo "    ✅ Claude Code MCP configured"
          else
            echo "    ❌ \$GITHUB_TOKEN not exported"
            token_issues+=("env-var")
          fi
        else
          echo "    ⚠️  Claude MCP not using env var"
          token_issues+=("mcp-config")
        fi
      fi
    fi
  fi

  # Offer fixes if in fix mode
  if [[ "$fix_mode" == true && ${#token_issues[@]} -gt 0 ]]; then
    echo ""
    _flow_log_info "Applying fixes..."

    for issue in "${token_issues[@]}"; do
      case "$issue" in
        missing)
          _flow_log_info "Generating new GitHub token..."
          dot token github
          ;;

        invalid|expiring)
          _flow_log_info "Rotating token..."
          dot token rotate
          ;;

        gh-cli)
          _flow_log_info "Authenticating gh CLI..."
          _dot_token_sync_gh
          ;;

        env-var)
          _flow_log_warning "Add to ~/.config/zsh/.zshrc:"
          echo "export GITHUB_TOKEN=\$(dot secret github-token)"
          ;;

        mcp-config)
          _flow_log_info "Run: ${FLOW_COLORS[cmd]}dot claude tokens${FLOW_COLORS[reset]} to fix Claude MCP"
          ;;
      esac
    done

    _flow_log_success "Fixes applied - restart shell: ${FLOW_COLORS[cmd]}exec zsh${FLOW_COLORS[reset]}"
  elif [[ ${#token_issues[@]} -gt 0 ]]; then
    echo ""
    _flow_log_warning "Issues found - run: ${FLOW_COLORS[cmd]}flow doctor --fix${FLOW_COLORS[reset]}"
  fi

  # ... rest of health checks ...
}
```

**Testing:**

```bash
source flow.plugin.zsh

# Test health check
flow doctor

# Test auto-fix
flow doctor --fix
```

**Commit:**

```bash
git add commands/flow.zsh
git commit -m "feat(flow): add token health checks to flow doctor

- Validate token via GitHub API
- Check token-dependent services (gh, Claude MCP)
- Detect expiring/expired tokens
- Auto-fix with --fix flag
- Report issues and suggest commands

Ref: BRAINSTORM-flow-github-integration-2026-01-23.md"
```

---

### Task 2.6: Unified flow token Alias (5 min)

**File:** `commands/flow.zsh`
**Location:** Add to main `flow()` function

**Implementation:**

```zsh
flow() {
  local subcommand="$1"
  shift

  case "$subcommand" in
    token|tokens)
      # Delegate to dot dispatcher
      dot token "$@"
      ;;

    # ... existing commands ...
  esac
}
```

**Testing:**

```bash
source flow.plugin.zsh

# Test alias
flow token expiring
flow token rotate
flow token dashboard

# All should work identically to dot token commands
```

**Commit:**

```bash
git add commands/flow.zsh
git commit -m "feat(flow): add flow token alias for dot token

- Alias flow token to dot token
- Consistent flow namespace
- Backward compatible
- Discovery via flow help

Ref: BRAINSTORM-flow-github-integration-2026-01-23.md"
```

---

## Testing & Validation

### Comprehensive Test Suite (30 min)

**File:** `tests/test-token-automation.zsh`

Create new test file with:

```zsh
#!/usr/bin/env zsh

# Test suite for token automation features

source "$(dirname "$0")/../flow.plugin.zsh"

# Test 1: Token expiration detection
test_token_expiring() {
  # Setup: Create test token with old date
  # Test: Run dot token expiring
  # Verify: Detects expiring token
}

# Test 2: Token metadata tracking
test_token_metadata() {
  # Setup: Create token with metadata
  # Test: Retrieve metadata
  # Verify: JSON parsed correctly
}

# Test 3: Token age calculation
test_token_age() {
  # Setup: Create token with known date
  # Test: Calculate age
  # Verify: Age matches expected
}

# Test 4: gh CLI sync
test_gh_sync() {
  # Setup: Mock gh CLI
  # Test: Sync token
  # Verify: gh authenticated
}

# Test 5: Git dispatcher validation
test_g_validation() {
  # Setup: Mock git push
  # Test: Validate token before push
  # Verify: Validation runs
}

# Test 6: dash integration
test_dash_token_status() {
  # Setup: Create test token
  # Test: Run dash dev
  # Verify: Token section appears
}

# Run all tests
test_token_expiring
test_token_metadata
test_token_age
test_gh_sync
test_g_validation
test_dash_token_status

echo "All token automation tests passed!"
```

**Commit:**

```bash
git add tests/test-token-automation.zsh
git commit -m "test: add token automation test suite

- Test expiration detection
- Test metadata tracking
- Test age calculation
- Test gh CLI sync
- Test git dispatcher validation
- Test dash integration

Ref: Phase 1+2 testing requirements"
```

---

## Documentation Updates

### Task 3.1: Update CLAUDE.md (10 min)

Add token automation section:

```markdown
## Token Management

### Automated GitHub Token Rotation

**Features:**

- Expiration detection (7-day warning)
- Semi-automated rotation workflow
- Keychain integration (Touch ID)
- gh CLI auto-sync
- Dashboard integration

**Commands:**

- `dot token expiring` - Check expiration status
- `dot token rotate` - Rotate token
- `flow doctor --fix` - Auto-fix token issues
- `flow token expiring` - Alias for dot token

**Integration:**

- `g push/pull` - Validates token before remote ops
- `dash dev` - Shows token status
- `work` - Checks token on session start
- `finish` - Validates before push

**Setup:**
See `docs/guides/TOKEN-HEALTH-CHECK.md` for weekly health check setup.
```

**Commit:**

```bash
git add CLAUDE.md
git commit -m "docs: add token automation to CLAUDE.md

- Document new token commands
- List integration points
- Reference health check guide

Ref: Documentation requirements"
```

---

### Task 3.2: Update DOT-DISPATCHER-REFERENCE.md (10 min)

Add token commands section.

**Commit:**

```bash
git add docs/reference/DOT-DISPATCHER-REFERENCE.md
git commit -m "docs: add token commands to DOT reference

- Document dot token expiring
- Document dot token rotate
- Document dot token sync gh
- Add usage examples

Ref: Documentation requirements"
```

---

## Final Integration Testing

### Manual Testing Checklist (15 min)

- [ ] `dot token expiring` - Detects expiring tokens
- [ ] `dot token rotate` - Complete rotation workflow
- [ ] `flow token expiring` - Alias works
- [ ] `g push` - Validates token before push
- [ ] `dash dev` - Shows token status section
- [ ] `work flow-cli` - Shows token warning if expiring
- [ ] `finish` - Validates token before push
- [ ] `flow doctor` - Shows token health
- [ ] `flow doctor --fix` - Auto-fixes issues
- [ ] Weekly health check - Runs async
- [ ] Test suite - All tests pass

---

## Ready to Implement!

### Start Implementation

```bash
# Navigate to worktree
cd ~/.git-worktrees/flow-cli/feature-token-automation

# Source plugin
source flow.plugin.zsh

# Start with Phase 1, Task 1.1
# Open implementation file
code lib/dispatchers/dot-dispatcher.zsh

# Or use Claude Code to implement
claude
```

### Implementation Order

1. ✅ Phase 1: Core automation (1.5 hours)
   - Tasks 1.1-1.5 in sequence

2. ✅ Phase 2: Integration (2 hours)
   - Tasks 2.1-2.6 in sequence

3. ✅ Testing & docs (45 min)
   - Test suite + documentation

**Total:** ~4 hours for complete implementation

---

## After Implementation

```bash
# Run test suite
./tests/test-token-automation.zsh

# Test manually
dot token expiring
flow doctor
dash dev

# Create PR
gh pr create --base dev --title "feat: token automation" \
  --body "Implements Phase 1+2 from token automation brainstorm"

# Clean up worktree after merge
git worktree remove ~/.git-worktrees/flow-cli/feature-token-automation
git branch -d feature/token-automation
```

---

**Status:** Ready for orchestrated implementation
**Brainstorm Refs:**

- `/Users/dt/BRAINSTORM-automated-token-management-2026-01-23.md`
- `/Users/dt/BRAINSTORM-flow-github-integration-2026-01-23.md`

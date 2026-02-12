# Test Plan: `em respond --review`

**Feature:** Review/send cached AI drafts (skip classification)
**Branch:** `feature/em-dispatcher`
**Commits:** `f7c7e34f`, `c4dfc35e`, `e01457fa`

---

## Prerequisites

- email-oauth2-proxy running (`pgrep -f email-oauth2-proxy`)
- himalaya configured (`~/.config/himalaya/config.toml`)
- `$EDITOR` set (e.g., `export EDITOR=vim`)
- In the worktree: `cd ~/.git-worktrees/flow-cli/feature-em-dispatcher`
- Plugin loaded: `source flow.plugin.zsh`

---

## Test 1: Generate Drafts (Normal Mode)

**Purpose:** Populate the cache with AI-generated drafts.

```zsh
em respond --count 3
```

**Expected behavior:**
1. Header: `em respond — scanning 3 emails in INBOX`
2. Phase 1 classifies each email with category icons
3. Summary: `N actionable  M skipped  of 3 total`
4. Prompt: `Proceed to draft N replies? [Y/n]` → press **Y**
5. For each actionable email:
   - Shows email header (From, To, Subject, Date)
   - `Generating AI draft...` spinner
   - `Draft ready — opening in $EDITOR`
   - $EDITOR opens with the draft
   - After saving/closing: `Send this reply? [y/N]` → press **N** (don't actually send)
   - `Continue to next? [Y/n/q]` → press **Y** to continue
6. Summary: `0 replied  N skipped`

**Verify:** No variable names (like `content=`, `draft=`, `mid=`) appear in the output.

**Check cache:** After this test, drafts should be cached:
```zsh
em cache stats
# Should show: drafts  N items  ...  TTL=1h
```

---

## Test 2: Review Cached Drafts

**Purpose:** Verify `--review` finds and loads cached drafts.

```zsh
em respond --review --count 3
```

**Expected behavior:**
1. Header: `em respond --review — reviewing cached drafts in INBOX`
2. Lists ONLY emails that have cached drafts:
   ```
   ✓ #12345  Sender Name  Subject preview...
   ✓ #12346  Sender Name  Subject preview...
   ```
3. Summary: `N cached drafts found in 3 emails`
4. Prompt: `Review N cached drafts? [Y/n]` → press **Y**
5. For each cached draft:
   - Shows email header
   - `Cached draft loaded — opening in $EDITOR` (NO "Generating AI draft")
   - $EDITOR opens with the CACHED draft (should match what was generated in Test 1)
   - `Send this reply? [y/N]` → press **N**
   - `Continue to next? [Y/n/q]` → press **Y**
6. Summary: `0 replied  0 skipped`

**Verify:**
- No classification step (no category icons, no "actionable/skipped" summary)
- Each email gets the CORRECT draft (not another email's draft)
- No variable leaks in output
- Draft content matches what was generated in Test 1

---

## Test 3: Review With No Cached Drafts

**Purpose:** Verify graceful handling when cache is empty.

```zsh
em cache clear
em respond --review --count 3
```

**Expected behavior:**
1. Header: `em respond --review — reviewing cached drafts in INBOX`
2. Empty scan (no ✓ lines)
3. Summary: `0 cached drafts found in 3 emails`
4. Info: `No cached drafts to review`
5. Info: `Generate drafts first: em respond`
6. Exits cleanly (no error)

---

## Test 4: `-R` Shorthand

**Purpose:** Verify the short flag works identically.

```zsh
em respond -R --count 3
```

**Expected:** Same behavior as `em respond --review --count 3`.

---

## Test 5: Review + Send (End-to-End)

**Purpose:** Full workflow — generate, review, actually send.

> **Warning:** This test SENDS a real email. Use a safe recipient.

```zsh
# Step 1: Generate draft for 1 email
em respond --count 1

# Step 2: Review and send
em respond --review --count 1
# → Y to review
# → Edit draft in $EDITOR if needed
# → y to send
```

**Expected:**
- Draft opens in $EDITOR with cached content
- After confirming send: email is sent via himalaya
- Summary: `1 replied  0 skipped`

---

## Test 6: Dry Run (No Review Interaction)

**Purpose:** Verify `--dry-run` still works (classifies only, no drafts).

```zsh
em respond --dry-run --count 3
```

**Expected:**
- Classifies emails with category icons
- Summary: `N actionable  M skipped  of 3 total`
- `Dry run — no drafts generated`
- No $EDITOR, no send prompts

---

## Test 7: Help Text

```zsh
em respond --help
```

**Verify these lines appear:**
- `em respond --review|-R  Review/send cached drafts (skip classification)`
- `em respond --dry-run    Classify only (no drafts, no $EDITOR)`
- `Review: scan → find cached drafts → $EDITOR → confirm send`

---

## Test 8: Combined Flags

```zsh
# Review with custom folder
em respond --review --folder Sent --count 5

# Review with custom count
em respond -R -n 10
```

**Expected:** Flags combine correctly, no errors.

---

## Quick Smoke Test (2 minutes)

If you only have 2 minutes, run these:

```zsh
# 1. Help text
em respond --help | grep -c "review"  # Should be >= 2

# 2. Dry run (no AI needed)
em respond --dry-run --count 2

# 3. Review with empty cache
em cache clear && em respond --review --count 2
# Should say "No cached drafts to review"

# 4. Generate + review cycle
em respond --count 2          # Generate drafts, press N at send
em respond --review --count 2  # Should find the cached drafts
```

---

**Pass criteria:** All tests produce clean output with zero variable leaks, correct drafts per email, and proper flow control.

# v5.1.0 Dog-Fooding Test Guide

Manual testing guide for real-world usage of v5.1.0 features.

---

## Prerequisites

```bash
# Required tools
brew install chezmoi bitwarden-cli

# Initialize chezmoi (if not already)
chezmoi init

# Unlock Bitwarden
bw login
```

---

## Feature 1: Hash-Based File Modification Detection

### Test Scenario: Quick Edit Workflow (ADHD-Friendly)

**Before v5.1.0:** Fast edits (< 1s) would show "No changes made" (false negative)
**After v5.1.0:** All edits detected via SHA-256 hash comparison

**Test Steps:**

1. **Edit a dotfile:**

   ```bash
   dot edit .zshrc
   ```

2. **Make a quick change:**
   - Add comment: `# Test v5.1.0 hash detection`
   - Save immediately (within 1 second)
   - Exit editor

3. **Expected Result:**

   ```
   ✓ Changes detected!
   ─────────────────────────────────────────────────
   [Shows diff with added comment]
   ─────────────────────────────────────────────────
   Apply? [Y/n/d]
   ```

4. **Verify:**
   - ✅ Changes detected (not "No changes made")
   - ✅ Diff shows your added comment
   - ✅ Apply works correctly

**Why This Matters:**

- ADHD users often edit quickly between saves
- mtime-based detection misses sub-second edits
- Hash detection is deterministic (always works)

---

## Feature 2: Bitwarden Error Handling

### Test Scenario 1: Secret Not Found

**Before v5.1.0:** Generic "Item not found or access denied"
**After v5.1.0:** Specific "Secret not found" + tip to use `dot secret list`

**Test Steps:**

1. **Try to retrieve non-existent secret:**

   ```bash
   dot secret nonexistent-item-12345
   ```

2. **Expected Output:**

   ```
   ✗ Secret not found: nonexistent-item-12345
   Tip: Use 'dot secret list' to see available items
   ```

3. **Verify:**
   - ✅ Clear "not found" message
   - ✅ Actionable tip provided
   - ✅ No confusing generic error

---

### Test Scenario 2: Session Expired

**Before v5.1.0:** Generic error message
**After v5.1.0:** "Session expired. Run: dot unlock"

**Test Steps:**

1. **Expire your session:**

   ```bash
   # Clear BW_SESSION
   unset BW_SESSION
   ```

2. **Try to get secret:**

   ```bash
   dot secret github-token
   ```

3. **Expected Output:**

   ```
   ✗ Session expired
   Run: dot unlock
   ```

4. **Follow guidance:**

   ```bash
   dot unlock
   ```

5. **Verify:**
   - ✅ Clear "session expired" message
   - ✅ Shows exact command to run
   - ✅ After `dot unlock`, secret retrieval works

---

### Test Scenario 3: Vault Locked

**Before v5.1.0:** Generic error
**After v5.1.0:** "Vault is locked. Run: dot unlock"

**Test Steps:**

1. **Lock your vault:**

   ```bash
   bw lock
   ```

2. **Try to get secret:**

   ```bash
   dot secret github-token
   ```

3. **Expected Output:**

   ```
   ✗ Vault is locked
   Run: dot unlock
   ```

4. **Verify:**
   - ✅ Identifies locked vault specifically
   - ✅ Clear guidance to unlock

---

## Feature 3: Dry-Run Mode

### Test Scenario 1: Preview All Changes

**Before v5.1.0:** No preview option (apply or cancel)
**After v5.1.0:** `--dry-run` shows what would change

**Test Steps:**

1. **Make some changes:**

   ```bash
   dot edit .zshrc
   # Add: export TEST_VAR="v5.1.0"
   # Save and apply
   ```

2. **Make another change:**

   ```bash
   dot edit .zshrc
   # Add: export ANOTHER_VAR="test"
   # Save but DON'T apply (press 'n')
   ```

3. **Preview with dry-run:**

   ```bash
   dot apply --dry-run
   ```

4. **Expected Output:**

   ```
   DRY-RUN MODE - No changes will be applied

   Showing what would change (dry-run)...

   Files to update: 1

   [Shows chezmoi status]

   [Shows verbose diff of what would change]

   ✓ Dry-run complete - no changes applied
   ```

5. **Verify:**
   - ✅ Clear DRY-RUN MODE indicator
   - ✅ Shows what would change
   - ✅ No actual changes applied
   - ✅ Can inspect output safely

6. **Apply for real:**
   ```bash
   dot apply
   # Now actually apply changes
   ```

---

### Test Scenario 2: Preview Specific File

**Test Steps:**

1. **Make change to specific file:**

   ```bash
   dot edit .gitconfig
   # Change email or name
   # Save, press 'n' to not apply
   ```

2. **Preview just that file:**

   ```bash
   dot apply -n .gitconfig
   ```

3. **Expected Output:**

   ```
   DRY-RUN MODE - No changes will be applied

   Showing what would change (dry-run)...

   [Shows diff for .gitconfig only]

   ✓ Dry-run complete - no changes applied
   ```

4. **Verify:**
   - ✅ Only shows .gitconfig changes
   - ✅ `-n` short flag works
   - ✅ No prompts (non-interactive)

---

## Combined Workflow Test

**Scenario:** Full workflow with all three features

1. **Quick edit with hash detection:**

   ```bash
   dot edit .zshrc
   # Add comment, save quickly
   # → Changes detected! ✓
   ```

2. **Dry-run preview:**

   ```bash
   # Press 'n' to not apply yet
   dot apply --dry-run
   # → See what would change ✓
   ```

3. **Apply changes:**

   ```bash
   dot apply
   # → Apply for real
   ```

4. **Test secret with good errors:**

   ```bash
   dot secret wrong-name
   # → Clear error message ✓
   ```

5. **Test secret list:**
   ```bash
   dot secret list
   # → Shows available secrets
   ```

---

## Success Criteria

### Feature 1: Hash Detection ✅

- [ ] Quick edits always detected
- [ ] No false negatives
- [ ] Diff shows correct changes

### Feature 2: Error Handling ✅

- [ ] "Not found" → Shows tip to use list
- [ ] "Session expired" → Shows unlock command
- [ ] "Vault locked" → Shows unlock command
- [ ] Each error has specific guidance

### Feature 3: Dry-Run Mode ✅

- [ ] `--dry-run` shows preview
- [ ] `-n` short flag works
- [ ] No changes applied in dry-run
- [ ] Can preview single file
- [ ] Can preview all files
- [ ] Clear visual feedback

---

## Performance Notes

**Hash Calculation Overhead:**

- SHA-256 is fast (~1ms for typical dotfiles)
- Trade-off: 1-2ms delay vs. false negatives
- Worth it for ADHD workflows

**Error Handling:**

- temp file creation/cleanup is minimal overhead
- Stderr capture is secure (no leaks)

**Dry-Run:**

- Uses chezmoi's native dry-run (no performance impact)
- Same speed as normal apply

---

## Known Issues

None! All features working as expected.

---

## Automated Tests

Run the automated test suite:

```bash
./tests/test-v5.1.0-features.zsh
```

**Expected:** 12/12 tests passing

---

**Last Updated:** 2026-01-10
**Version:** v5.1.0
**Status:** Ready for release

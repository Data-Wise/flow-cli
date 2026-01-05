# Installation Documentation Updates - Homebrew Priority

**Date:** 2026-01-05
**Status:** ✅ Complete

## Summary

Updated installation documentation to make Homebrew the primary/recommended installation method for macOS users.

---

## Files Updated

### 1. README.md

**Changes:**

- ✅ Moved Homebrew to the top of installation section
- ✅ Added "Recommended for macOS" designation
- ✅ Added star (⭐) to indicate primary method in comparison table
- ✅ Kept Quick Install script as alternative
- ✅ Updated table ordering: Homebrew → Quick Install → Plugin Managers

**Key Addition:**

```bash
### Homebrew (Recommended for macOS)

brew tap data-wise/tap
brew install flow-cli
```

---

### 2. docs/getting-started/installation.md

**Changes:**

- ✅ Added Homebrew as FIRST method in Part 1
- ✅ Added benefits list (no plugin manager needed, automatic PATH, easy updates, clean uninstall)
- ✅ Added "No reload needed" note for Homebrew users
- ✅ Updated comparison table with Homebrew first
- ✅ Added Homebrew section to Updating
- ✅ Added Homebrew section to Uninstalling
- ✅ Added Homebrew-specific troubleshooting
- ✅ Updated Optional Tools section with Homebrew notes

**Major Sections Added:**

1. **Installation:**

   ```bash
   # 1. Tap the repository
   brew tap data-wise/tap

   # 2. Install flow-cli
   brew install flow-cli
   ```

2. **Updating:**

   ```bash
   brew update
   brew upgrade flow-cli
   ```

3. **Uninstalling:**

   ```bash
   brew uninstall flow-cli
   brew untap data-wise/tap  # Optional
   ```

4. **Troubleshooting:**
   - Command not found after Homebrew install
   - Homebrew not installed (with installation link)
   - Verification commands

---

## Benefits for Users

1. **Easier Installation** - One command (`brew install`) vs plugin manager configuration
2. **Automatic PATH** - No shell config changes needed
3. **Easier Updates** - `brew upgrade` instead of plugin manager commands
4. **Clean Uninstall** - `brew uninstall` removes everything
5. **No Shell Reload** - Commands immediately available after install
6. **Familiar** - Most macOS developers already use Homebrew

---

## Installation Method Priority (New)

1. **Homebrew** ⭐ (macOS users - easiest)
2. Quick Install Script (auto-detection)
3. Plugin Managers (antidote, zinit, oh-my-zsh)
4. Manual (full control)

---

## Documentation Consistency

Both README.md and docs/getting-started/installation.md now:

- ✅ Feature Homebrew prominently
- ✅ Mark it as "Recommended" with star (⭐)
- ✅ Show tap + install as first code example
- ✅ Provide complete Homebrew lifecycle (install, update, uninstall)
- ✅ Include Homebrew-specific troubleshooting

---

## Next Steps

1. [ ] Test Homebrew installation on clean macOS system
2. [ ] Update Homebrew formula to latest version (currently v4.5.5, should be v4.8.0)
3. [ ] Add Homebrew installation to Quick Start guide
4. [ ] Consider adding Homebrew badges to README
5. [ ] Update any tutorial videos to show Homebrew method first

---

## Notes

- All existing installation methods remain fully supported
- No breaking changes - just better documentation
- Homebrew tap: `data-wise/tap`
- Formula name: `flow-cli`
- Current Homebrew version: v4.5.5 (needs update to v4.8.0)

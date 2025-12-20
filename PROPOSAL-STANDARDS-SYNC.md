# [BRAINSTORM] Standards Sync Across Project Management Hubs

**Date:** 2025-12-19
**Status:** Brainstorm / Proposal
**Scope:** Sync `standards/` folder across 3 PM hubs + zsh-configuration

---

## 🎯 The Vision

Keep standards synchronized across all project management hubs:

```
zsh-configuration/standards/     ← SOURCE OF TRUTH
    ↓ sync ↓
├──→ project-hub/standards/
├──→ mediation-planning/standards/
└──→ dev-planning/standards/
```

**Why:** Standards should be accessible where planning happens, not just in zsh-configuration.

---

## 📊 Current State

### Project Management Structure

**Discovered 4 locations:**

| Location | Type | Purpose | Has Standards? |
|----------|------|---------|----------------|
| `~/projects/dev-tools/zsh-configuration/` | Standards Hub | Source of truth | ✅ Complete |
| `~/projects/project-hub/` | Master Hub | Cross-domain coordination | ❌ No |
| `~/projects/r-packages/mediation-planning/` | Domain Hub | R package coordination | ❌ No |
| `~/projects/dev-tools/dev-planning/` | Domain Hub | Dev tools coordination | ❌ No |

### Current zsh-configuration Standards

```
zsh-configuration/standards/
├── adhd/                           # 4 templates
│   ├── GETTING-STARTED-TEMPLATE.md
│   ├── QUICK-START-TEMPLATE.md
│   ├── REFCARD-TEMPLATE.md
│   └── TUTORIAL-TEMPLATE.md
├── code/                           # 3 style guides
│   ├── COMMIT-MESSAGES.md
│   ├── R-STYLE-GUIDE.md
│   └── ZSH-COMMANDS-HELP.md
├── documentation/                  # 1 guide
│   └── WEBSITE-DESIGN-GUIDE.md
├── project/                        # 3 guides (2 NEW today!)
│   ├── COORDINATION-GUIDE.md       ⭐ NEW
│   ├── PROJECT-MANAGEMENT-STANDARDS.md ⭐ NEW
│   └── PROJECT-STRUCTURE.md
└── README.md
```

**Total:** 12 standard documents + index

### Existing Sync Infrastructure

**Found in zsh-configuration:**
- `scripts/sync-zsh.sh` - Manual sync helper (ZSH→CLI adapters)
- Not automated, provides guidance only

**Pattern to follow:**
- List source files
- Show destinations
- Provide manual steps

---

## 🎨 Proposed Solution: Three Approaches

### Option A: Symlinks (Lightweight)

**Concept:** Create symlinks from PM hubs to zsh-configuration

```bash
# In project-hub/
ln -s ~/projects/dev-tools/zsh-configuration/standards standards

# In mediation-planning/
ln -s ~/projects/dev-tools/zsh-configuration/standards standards

# In dev-planning/
ln -s ~/projects/dev-tools/zsh-configuration/standards standards
```

**Pros:**
- ✅ Zero duplication
- ✅ Always up-to-date automatically
- ✅ Single source of truth maintained
- ✅ No sync script needed

**Cons:**
- ❌ Breaks if zsh-configuration moves
- ❌ Git doesn't follow symlinks well
- ❌ Confusing for collaborators

**Verdict:** 🟡 Simple but fragile

---

### Option B: Copy with Manual Sync (Current Pattern)

**Concept:** Copy standards to each hub, sync manually when changed

```bash
# When standards change
cp -r ~/projects/dev-tools/zsh-configuration/standards \
      ~/projects/project-hub/standards

cp -r ~/projects/dev-tools/zsh-configuration/standards \
      ~/projects/r-packages/mediation-planning/standards

cp -r ~/projects/dev-tools/zsh-configuration/standards \
      ~/projects/dev-tools/dev-planning/standards
```

**Pros:**
- ✅ Each hub is self-contained
- ✅ Works with Git
- ✅ Simple to understand
- ✅ No infrastructure needed

**Cons:**
- ❌ Manual work to sync
- ❌ Can drift out of sync
- ❌ Duplication (4 copies)

**Verdict:** 🟡 Works but requires discipline

---

### Option C: Automated Sync Script (Recommended)

**Concept:** Script that syncs standards + tracks versions

**Create:** `~/projects/dev-tools/zsh-configuration/scripts/sync-standards.sh`

```bash
#!/bin/bash
# Sync standards from zsh-configuration to all PM hubs

set -e

SOURCE="$HOME/projects/dev-tools/zsh-configuration/standards"
VERSION_FILE="$SOURCE/.version"

# Destination hubs
DESTINATIONS=(
    "$HOME/projects/project-hub"
    "$HOME/projects/r-packages/mediation-planning"
    "$HOME/projects/dev-tools/dev-planning"
)

# Get current version (date-based)
CURRENT_VERSION=$(date +%Y-%m-%d)

echo "🔄 Syncing standards from zsh-configuration..."
echo "📦 Source: $SOURCE"
echo "📅 Version: $CURRENT_VERSION"
echo ""

# Update version file
echo "$CURRENT_VERSION" > "$VERSION_FILE"

# Sync to each destination
for dest in "${DESTINATIONS[@]}"; do
    if [ ! -d "$dest" ]; then
        echo "⚠️  Skipping $dest (not found)"
        continue
    fi

    echo "📂 Syncing to: $dest"

    # Create standards dir if needed
    mkdir -p "$dest/standards"

    # Rsync with delete (removes old files)
    rsync -av --delete \
        "$SOURCE/" \
        "$dest/standards/"

    # Write version file
    echo "$CURRENT_VERSION" > "$dest/standards/.version"

    echo "✅ Synced $(basename $dest)"
    echo ""
done

echo "🎉 All hubs synced to version $CURRENT_VERSION"
echo ""
echo "📝 Next steps:"
echo "  1. Review changes in each hub"
echo "  2. Commit to git if needed"
echo "  3. Update .planning/NOW.md if major changes"
```

**Version tracking:**
- `.version` file in each standards folder
- Date-based versioning (YYYY-MM-DD)
- Easy to see if out of sync

**Pros:**
- ✅ Automated with one command
- ✅ Version tracking
- ✅ Removes deleted files (--delete flag)
- ✅ Shows what was synced
- ✅ Works with Git

**Cons:**
- ❌ Still requires running script
- ❌ Duplication (4 copies)
- ❌ Need to remember to run it

**Verdict:** 🟢 Best balance of automation + reliability

---

## 🚀 Recommended Implementation

**Go with Option C (Automated Sync Script) with improvements:**

### Phase 1: Initial Sync (Now)

```bash
# 1. Create sync script
vim ~/projects/dev-tools/zsh-configuration/scripts/sync-standards.sh
chmod +x ~/projects/dev-tools/zsh-configuration/scripts/sync-standards.sh

# 2. Run initial sync
~/projects/dev-tools/zsh-configuration/scripts/sync-standards.sh

# 3. Commit to each hub
cd ~/projects/project-hub
git add standards/
git commit -m "feat: add synced standards from zsh-configuration"

cd ~/projects/r-packages/mediation-planning
git add standards/
git commit -m "feat: add synced standards from zsh-configuration"

cd ~/projects/dev-tools/dev-planning
git add standards/
git commit -m "feat: add synced standards from zsh-configuration"
```

### Phase 2: Document Sync Process

**Add to COORDINATION-GUIDE.md:**

```markdown
## Standards Synchronization

**Source of Truth:** `~/projects/dev-tools/zsh-configuration/standards/`

**Synced To:**
- project-hub/standards/
- mediation-planning/standards/
- dev-planning/standards/

**When to Sync:**
- After updating any standard document
- After creating new standard
- Weekly (Friday with other reviews)

**How to Sync:**
```bash
~/projects/dev-tools/zsh-configuration/scripts/sync-standards.sh
```

**Check Sync Status:**
```bash
# See which version each hub has
cat ~/projects/project-hub/standards/.version
cat ~/projects/r-packages/mediation-planning/standards/.version
cat ~/projects/dev-tools/dev-planning/standards/.version
```
```

### Phase 3: Add Convenience Aliases

**Add to ~/.config/zsh/.zshrc:**

```bash
# Standards sync
alias sync-standards='~/projects/dev-tools/zsh-configuration/scripts/sync-standards.sh'
alias check-standards='cat ~/projects/*/standards/.version 2>/dev/null | sort | uniq -c'
```

**Usage:**
```bash
sync-standards    # Sync all hubs
check-standards   # See version in each hub
```

### Phase 4: Git Hook (Optional - Advanced)

**Automatically sync on commit to zsh-configuration:**

```bash
# Create pre-commit hook
cat > ~/projects/dev-tools/zsh-configuration/.git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Auto-sync standards if changed

# Check if standards/ files staged
if git diff --cached --name-only | grep -q "^standards/"; then
    echo "📦 Standards changed, running sync..."
    ./scripts/sync-standards.sh

    echo "⚠️  Standards synced to PM hubs"
    echo "   Remember to commit changes in:"
    echo "   - project-hub/"
    echo "   - mediation-planning/"
    echo "   - dev-planning/"
fi
EOF

chmod +x ~/projects/dev-tools/zsh-configuration/.git/hooks/pre-commit
```

---

## 📋 Sync Script Features

### Core Features

1. **Automatic sync** to all 3 PM hubs
2. **Version tracking** (.version file with date)
3. **Remove deleted files** (rsync --delete)
4. **Skip missing destinations** (graceful failure)
5. **Clear output** showing what was synced

### Enhanced Features (Future)

1. **Dry run mode:**
   ```bash
   sync-standards.sh --dry-run  # Show what would be synced
   ```

2. **Selective sync:**
   ```bash
   sync-standards.sh --hub project-hub  # Sync only one hub
   ```

3. **Check for changes:**
   ```bash
   sync-standards.sh --check  # Compare versions without syncing
   ```

4. **Generate changelog:**
   ```bash
   sync-standards.sh --changelog  # Show what changed since last sync
   ```

---

## 🔧 Alternative: Make Command

**Create Makefile for easier management:**

```makefile
# Makefile for standards management

.PHONY: sync check commit help

sync:
	@echo "🔄 Syncing standards..."
	@./scripts/sync-standards.sh

check:
	@echo "📊 Standards version status:"
	@echo ""
	@echo "Source (zsh-configuration):"
	@cat standards/.version 2>/dev/null || echo "  No version file"
	@echo ""
	@echo "project-hub:"
	@cat ~/projects/project-hub/standards/.version 2>/dev/null || echo "  Not synced"
	@echo ""
	@echo "mediation-planning:"
	@cat ~/projects/r-packages/mediation-planning/standards/.version 2>/dev/null || echo "  Not synced"
	@echo ""
	@echo "dev-planning:"
	@cat ~/projects/dev-tools/dev-planning/standards/.version 2>/dev/null || echo "  Not synced"

commit:
	@echo "📝 Committing synced standards to all hubs..."
	@cd ~/projects/project-hub && git add standards/ && git commit -m "chore: sync standards" || true
	@cd ~/projects/r-packages/mediation-planning && git add standards/ && git commit -m "chore: sync standards" || true
	@cd ~/projects/dev-tools/dev-planning && git add standards/ && git commit -m "chore: sync standards" || true
	@echo "✅ All hubs committed"

help:
	@echo "Standards Management Commands:"
	@echo ""
	@echo "  make sync     - Sync standards to all PM hubs"
	@echo "  make check    - Check version status in all hubs"
	@echo "  make commit   - Commit synced standards in all hubs"
	@echo "  make help     - Show this help"
```

**Usage:**
```bash
cd ~/projects/dev-tools/zsh-configuration
make sync       # Sync all
make check      # Check versions
make commit     # Commit all hubs
```

---

## 📅 Sync Workflow

### When Standards Change

**Immediate (< 5 min):**
1. Update standard in `zsh-configuration/standards/`
2. Run `sync-standards` (or `make sync`)
3. Check output to verify sync
4. Optionally: `make commit` to commit all hubs

**Weekly (Friday PM):**
1. Run `check-standards` (or `make check`)
2. If out of sync, run `make sync`
3. Commit if needed

**After Major Changes:**
1. Sync standards
2. Update `.planning/NOW.md` with note
3. Notify if affects active work

---

## 🎯 Decision Matrix

| Criteria | Symlinks (A) | Manual Copy (B) | Sync Script (C) |
|----------|--------------|-----------------|-----------------|
| **Setup time** | 1 min | 1 min | 10 min |
| **Maintenance** | Zero | Manual | One command |
| **Git-friendly** | ❌ No | ✅ Yes | ✅ Yes |
| **Can drift?** | ❌ Never | ✅ Easily | 🟡 If forget to sync |
| **Clarity** | 🟡 Confusing | ✅ Clear | ✅ Clear |
| **Robustness** | ❌ Fragile | ✅ Robust | ✅ Robust |
| **Version tracking** | N/A | ❌ No | ✅ Yes (.version file) |

**Recommendation:** **Option C (Sync Script)** ⭐

---

## 📝 Next Steps

**Choose your adventure:**

### Path 1: Quick Start (Symlinks)
```bash
# 5 minutes total
cd ~/projects/project-hub && ln -s ~/projects/dev-tools/zsh-configuration/standards standards
cd ~/projects/r-packages/mediation-planning && ln -s ~/projects/dev-tools/zsh-configuration/standards standards
cd ~/projects/dev-tools/dev-planning && ln -s ~/projects/dev-tools/zsh-configuration/standards standards
```

### Path 2: Manual Sync (Copy Once)
```bash
# 5 minutes total
cp -r ~/projects/dev-tools/zsh-configuration/standards ~/projects/project-hub/
cp -r ~/projects/dev-tools/zsh-configuration/standards ~/projects/r-packages/mediation-planning/
cp -r ~/projects/dev-tools/zsh-configuration/standards ~/projects/dev-tools/dev-planning/
# Remember to sync manually when standards change!
```

### Path 3: Automated Sync (Recommended)
```bash
# 15-20 minutes total
# 1. Create script (copy from this proposal)
vim ~/projects/dev-tools/zsh-configuration/scripts/sync-standards.sh
chmod +x ~/projects/dev-tools/zsh-configuration/scripts/sync-standards.sh

# 2. Run initial sync
~/projects/dev-tools/zsh-configuration/scripts/sync-standards.sh

# 3. Add aliases to .zshrc
echo "alias sync-standards='~/projects/dev-tools/zsh-configuration/scripts/sync-standards.sh'" >> ~/.config/zsh/.zshrc

# 4. Commit to each hub
# (see Phase 1 above)
```

---

## 🔗 Integration with Existing Systems

### PROJECT-HUB.md Integration

Each hub's PROJECT-HUB.md can reference standards:

```markdown
## 📚 Standards

This project follows standards from zsh-configuration:
- Location: `standards/` (synced from zsh-configuration)
- Version: 2025-12-19
- Last sync: Check `standards/.version`

**Key standards:**
- [Project Management](standards/project/PROJECT-MANAGEMENT-STANDARDS.md)
- [Coordination](standards/project/COORDINATION-GUIDE.md)
- [Website Design](standards/documentation/WEBSITE-DESIGN-GUIDE.md)
```

### COORDINATION-GUIDE.md Update

Add section about standards sync to existing COORDINATION-GUIDE.md.

### .planning/NOW.md Integration

When standards change significantly:
```markdown
## Active Coordination

**Standards sync (2025-12-19):**
- Added: PROJECT-MANAGEMENT-STANDARDS.md, COORDINATION-GUIDE.md
- Synced to: project-hub, mediation-planning, dev-planning
- Action: Review new PM standards
```

---

## ⚠️ Potential Issues

### Issue 1: Forgetting to Sync

**Solution:**
- Weekly check in Friday routine
- Git hook reminder (optional)
- `make check` command to see status

### Issue 2: Conflicting Changes

**Scenario:** Someone edits standards in a hub directly

**Prevention:**
- Document in each hub's README: "Standards are synced from zsh-configuration"
- Add .gitignore note or README warning
- Git hook could check for direct edits

**Recovery:**
- If hub has better version, copy back to source
- Then sync normally

### Issue 3: Hub Gets Deleted/Moved

**Solution:**
- Script gracefully handles missing destinations
- No error if hub doesn't exist

---

## 📊 Success Metrics

**After implementation:**
- ✅ All 4 locations have identical standards
- ✅ Version files show same date
- ✅ Can sync in < 30 seconds
- ✅ Standards referenced from PM hubs
- ✅ No drift over time

---

## 🎉 Benefits

1. **Accessibility** - Standards where planning happens
2. **Consistency** - Same standards everywhere
3. **Maintenance** - Update once, sync everywhere
4. **Version tracking** - Know if out of sync
5. **Automation** - One command to sync all

---

**Created:** 2025-12-19
**Status:** Proposal / Brainstorm
**Estimated Time:**
- Option A (Symlinks): 5 min
- Option B (Manual): 5 min + ongoing maintenance
- Option C (Automated): 20 min setup, then < 1 min per sync

**Recommendation:** **Option C** (Automated Sync Script) ⭐

Ready to implement! Which path would you like to take?

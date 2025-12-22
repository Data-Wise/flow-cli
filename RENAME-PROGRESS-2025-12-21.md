# Project Rename Progress Report

**Generated:** 2025-12-21
**Status:** Phase 1 & 2 Complete, Bulk Script Ready
**Project:** flow-cli → flow-cli

---

## ✅ Completed Changes

### Phase 1: Critical Configuration Files (COMPLETE)

All critical configuration files have been updated successfully:

1. **✅ package.json** (root)
   - Changed `"name": "flow-cli"` → `"flow-cli"`
   - Changed repository URL → `https://github.com/Data-Wise/flow-cli`

2. **✅ cli/package.json**
   - Changed `"name": "zsh-workflow-cli"` → `"@flowcli/core"` (scoped package)

3. **✅ mkdocs.yml**
   - site_name: "ZSH Configuration Docs" → "Flow CLI Documentation"
   - site_url: Updated to `https://data-wise.github.io/flow-cli`
   - repo_name: "flow-cli" → "flow-cli"
   - repo_url: Updated to `https://github.com/data-wise/flow-cli`
   - Social link: Updated GitHub link

### Phase 2: Core Documentation Files (COMPLETE)

Key user-facing documentation updated:

4. **✅ README.md**
   - Updated project structure diagram
   - Updated clone URL to `https://github.com/Data-Wise/flow-cli`
   - Updated live site URL to `https://Data-Wise.github.io/flow-cli/`
   - Changed directory name `flow-cli/` in structure examples

5. **✅ CLAUDE.md**
   - Updated cloud sync paths (`~/projects/dev-tools/flow-cli/`)

6. **✅ PROJECT-HUB.md**
   - Updated documentation site URL (3 instances)
   - All strategic references updated

7. **✅ CONTRIBUTING.md**
   - Updated project path in setup instructions
   - Updated project structure diagram

8. **✅ docs/index.md**
   - Changed page title to "Flow CLI"

9. **✅ docs/hop/README.md**
   - Updated all path references (5 instances)

---

## 📋 Remaining Work

### Files Requiring Bulk Updates

Based on grep scan, **181 files** contain "flow-cli" and **91 files** contain GitHub URLs.

**Categories:**
- ~140 documentation files in `docs/` subdirectories
- ~20 root-level planning/proposal files
- ~10 code files (CLI, tests, functions)
- ~10 standard/config files
- 91 generated HTML files in `site/` (will be regenerated)

### Bulk Update Script Created

**Location:** `/Users/dt/projects/dev-tools/flow-cli/rename-bulk.sh`

**What it does:**
1. Updates all markdown files in `docs/` directory
2. Updates GitHub URLs (all variations)
3. Updates root-level documentation
4. Updates ZSH function files
5. Updates test files
6. Updates standards files
7. Updates CLI code files
8. Creates temporary backups during process
9. Cleans up backups after completion

**Excluded from updates:**
- `node_modules/` directory
- `.git/` directory
- `site/` directory (will be regenerated)

---

## 🔄 Next Steps

### Step 1: Execute Bulk Update Script

```bash
cd /Users/dt/projects/dev-tools/flow-cli
chmod +x rename-bulk.sh
./rename-bulk.sh
```

**Expected result:** ~150-170 additional files updated

### Step 2: Review Changes

```bash
# See what was changed
git status

# Review specific changes
git diff package.json
git diff mkdocs.yml
git diff README.md

# Check docs changes
git diff docs/
```

### Step 3: Validate Configuration Files

```bash
# Verify package.json is valid JSON
cat package.json | python -m json.tool > /dev/null && echo "✓ Valid JSON"

# Verify mkdocs.yml is valid YAML
python -c "import yaml; yaml.safe_load(open('mkdocs.yml'))" && echo "✓ Valid YAML"
```

### Step 4: Test Builds

```bash
# Install dependencies (should work with renamed packages)
npm install

# Run tests
npm test

# Build documentation site
mkdocs build
```

### Step 5: Verify Documentation Site

```bash
# Serve locally to preview
mkdocs serve

# Then visit: http://127.0.0.1:8000
# Verify:
# - Site title shows "Flow CLI Documentation"
# - GitHub links point to Data-Wise/flow-cli
# - Navigation works correctly
# - Search functionality works
```

### Step 6: Handle Generated Site Files

The `site/` directory contains 91 generated HTML files with old references. These will be automatically regenerated when you run `mkdocs build`.

**Action:**
```bash
# Remove old generated site
rm -rf site/

# Rebuild with new names
mkdocs build
```

---

## 📊 Progress Statistics

| Category | Status | Count |
|----------|--------|-------|
| **Critical config files** | ✅ Complete | 3/3 |
| **Core documentation** | ✅ Complete | 6/6 |
| **Bulk documentation** | 🔄 Ready (script created) | 0/~150 |
| **Code files** | 🔄 Ready (script created) | 0/~10 |
| **Generated files** | ⏳ Pending rebuild | 0/91 |
| **Total manual edits** | ✅ Complete | 9 files |
| **Estimated remaining** | 🔄 Via script | ~160 files |

---

## ⚠️ Important Notes

### What Won't Change

- **"ZSH" technology references:** Keeping "ZSH functions", "ZSH configuration", "ZSH Workflow Manager" where appropriate
- **node_modules/:** Dependencies (excluded)
- **.git/:** Git history (excluded)
- **Binary files:** No text replacements

### What Will Change

- **Project name:** "flow-cli" → "flow-cli"
- **GitHub repo:** "Data-Wise/flow-cli" → "Data-Wise/flow-cli"
- **npm package (root):** "flow-cli" → "flow-cli"
- **npm package (cli):** "zsh-workflow-cli" → "@flowcli/core"
- **Documentation site:** All URLs updated
- **File paths:** All references to project directory

### Post-Rename Actions Needed

After completing the rename:

1. **Update GitHub repository name:**
   - Go to repo settings on GitHub
   - Rename repository from "flow-cli" to "flow-cli"
   - GitHub will handle redirects automatically

2. **Update cloud sync symlinks:**
   - Google Drive path
   - Dropbox path
   - These currently point to "flow-cli"

3. **Deploy updated documentation:**
   ```bash
   mkdocs gh-deploy
   ```

4. **Update cross-project integrations:**
   - `zsh-claude-workflow` - May have references
   - Other dev-tools projects that reference this

---

## 🎯 Success Criteria

Before considering rename complete:

- [ ] All 181 files with "flow-cli" updated
- [ ] All 91 GitHub URL references updated
- [ ] `npm install` runs successfully
- [ ] `npm test` passes all tests
- [ ] `mkdocs build` completes without errors
- [ ] Documentation site displays correct branding
- [ ] All internal links work
- [ ] Git diff shows expected changes only
- [ ] No broken references in documentation

---

## 📝 Manual Review Recommended

After bulk script execution, manually review these critical files:

1. `package.json` - Ensure valid JSON
2. `cli/package.json` - Verify scoped package name
3. `mkdocs.yml` - Ensure valid YAML
4. `README.md` - Check formatting intact
5. `CLAUDE.md` - Verify instructions still make sense
6. `docs/index.md` - Check home page looks good

---

## 🚀 Ready to Execute

The bulk update script is ready to run. Execute it with:

```bash
cd /Users/dt/projects/dev-tools/flow-cli
chmod +x rename-bulk.sh
./rename-bulk.sh
```

**Expected duration:** 2-3 minutes
**Expected changes:** ~150-170 files

After execution, proceed with validation steps above.

---

**Status:** ✅ Ready for bulk execution
**Last updated:** 2025-12-21

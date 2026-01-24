# Infrastructure as Code: Dotfile Management Plan

**Date:** 2026-01-08  
**For:** Stat-Wise (MacBook + iMac setup)  
**Architecture:** Chezmoi + Bitwarden

---

## 🎯 Problem Statement

**Current State:**
- .zshrc manually synced between iMac and MacBook
- Hardcoded API keys in config files (security risk)
- No package version management across machines
- 4-hour setup time for new machine

**Goal:**
- 10-minute setup on new machine
- Automatic dotfile sync between machines
- Secure secret management
- Consistent R/Python versions

---

## 🏗️ Recommended Architecture

### Chezmoi + Bitwarden

**Chezmoi:** Dotfile synchronization and templating  
**Bitwarden:** Secret management (API keys, credentials)  
**Mise:** Language version management (R, Python)  
**Homebrew:** Package management (declared in Brewfile)

**Why this combination:**
- ✅ ADHD-friendly (GUI fallback, mobile access)
- ✅ Open source (both tools)
- ✅ Handles machine differences automatically
- ✅ Secrets never committed to git
- ✅ Future-proof for team collaboration

---

## 📦 What Gets Synced

### Via Chezmoi (Git)

- `.zshrc`, `.zshenv` (shell configuration)
- `.gitconfig` (git settings)
- `.ssh/config` (SSH hosts)
- `Brewfile` (Homebrew packages)
- Custom scripts and functions
- Templates (machine-specific values)

### Via Bitwarden (Cloud Vault)

- API keys (Anthropic, GitHub, Desktop Commander)
- Credentials (UNM VPN, services)
- 2FA codes
- Secure notes

### Via Mise (Project-Level)

- R version (4.5.2)
- Python version (3.12)
- Node version (per-project)

### NOT Synced

- R package source code (use git per-package)
- Large data files (use cloud storage)
- IDE settings (unless explicitly added)

---

## 🚀 Implementation Plan

### Phase 1: Dotfile Management (Week 1)

**Goal:** Sync .zshrc and .gitconfig between machines

**Tools to install:**
- Chezmoi
- Git (already installed)

**Steps:**

1. **Initialize Chezmoi on iMac**

   ```bash
   chezmoi init
   ```

2. **Add current configs**

   ```bash
   chezmoi add ~/.config/zsh/.zshrc
   chezmoi add ~/.config/zsh/.zshenv
   chezmoi add ~/.gitconfig
   ```

3. **Create Brewfile**

   ```bash
   brew bundle dump --file ~/.local/share/chezmoi/Brewfile
   ```

4. **Version control**

   ```bash
   cd ~/.local/share/chezmoi
   git init
   git remote add origin git@github.com:Data-Wise/dotfiles-private.git
   git add .
   git commit -m "Initial dotfiles"
   git push -u origin main
   ```

5. **Test on iMac**

   ```bash
   # Edit config
   chezmoi edit ~/.zshrc
   
   # Preview changes
   chezmoi diff
   
   # Apply changes
   chezmoi apply
   ```

6. **Setup on MacBook**

   ```bash
   chezmoi init --apply git@github.com:Data-Wise/dotfiles-private.git
   ```

**Success Metric:**  
Edit .zshrc on iMac → push → pull on MacBook → changes appear automatically

---

### Phase 2: Secret Management (Week 2)

**Goal:** Remove hardcoded API keys from dotfiles

**Tools to install:**
- Bitwarden CLI

**Steps:**

1. **Setup Bitwarden**
   - Create account at vault.bitwarden.com (free)
   - Install Bitwarden CLI on both machines
   - Login: `bw login`

2. **Store secrets in vault**
   - Open vault.bitwarden.com
   - Create items:
     - "Desktop Commander API" → password: `DC_API_KEY value`
     - "GitHub MCP PAT" → password: `token value`
     - "Anthropic API Key" → password: `sk-ant-...`

3. **Convert .zshrc to template**

   ```bash
   # In ~/.local/share/chezmoi/
   mv dot_config/zsh/dot_zshrc dot_config/zsh/dot_zshrc.tmpl
   ```

4. **Add Bitwarden queries to template**

   ```bash
   # In dot_zshrc.tmpl, replace hardcoded secrets:
   
   {{- if lookPath "bw" }}
   {{- $dc := bitwarden "item" "Desktop Commander API" }}
   {{- $gh := bitwarden "item" "GitHub MCP PAT" }}
   export DC_API_KEY="{{ $dc.login.password }}"
   export GITHUB_MCP_PAT="{{ $gh.login.password }}"
   {{- end }}
   ```

5. **Test secret injection**

   ```bash
   export BW_SESSION=$(bw unlock --raw)
   chezmoi apply
   env | grep DC_API_KEY  # Should show key
   ```

6. **Commit and sync**

   ```bash
   cd ~/.local/share/chezmoi
   git add .
   git commit -m "Add Bitwarden secret injection"
   git push
   ```

**Success Metric:**  
`env | grep API_KEY` shows secrets on both machines without hardcoding in .zshrc

---

### Phase 3: Environment Versioning (Week 3)

**Goal:** Consistent R/Python versions across machines

**Tools to install:**
- Mise (via Brewfile)

**Steps:**

1. **Add mise to Brewfile**

   ```bash
   # In ~/.local/share/chezmoi/Brewfile
   brew "mise"
   ```

2. **Install on both machines**

   ```bash
   brew bundle --file ~/.local/share/chezmoi/Brewfile
   ```

3. **Pin versions in R package projects**

   ```bash
   cd ~/R-packages/medfit
   mise use R@4.5.2 python@3.12
   
   # This creates .mise.toml in project directory
   ```

4. **Configure shell integration**

   ```bash
   # Add to .zshrc.tmpl (if not already present)
   eval "$(mise activate zsh)"
   ```

5. **Test version consistency**

   ```bash
   cd ~/R-packages/medfit
   mise install
   R --version  # Should show 4.5.2 on both machines
   ```

**Success Metric:**  
Same R/Python versions on iMac and MacBook for all projects

---

### Phase 4 (Optional): Add Doppler

**When to add:** If you add collaborators or need dev/staging/prod environments

**What it adds:**
- Team secret sharing
- Environment management (dev/staging/prod)
- Audit logs (who accessed what when)
- CI/CD integration

**Cost:** Free for ≤5 users

**Defer until:** Mediationverse team expands or multi-environment needs arise

---

## 📋 Daily Workflows

### Update Config on iMac

```bash
# Edit dotfile
chezmoi edit ~/.zshrc

# Preview changes
chezmoi diff

# Apply changes
chezmoi apply

# Sync to git
cd ~/.local/share/chezmoi
git add . && git commit -m "Update zsh config"
git push
```

### Sync Changes on MacBook

```bash
# Pull latest changes
chezmoi update
```

### Add New Secret

```bash
# Option 1: GUI (recommended)
# Open vault.bitwarden.com → Create Item

# Option 2: CLI
bw create item --name "New API Key" --password "value"

# Update .zshrc.tmpl to reference it
chezmoi edit ~/.zshrc

# Apply
chezmoi apply
```

### Setup New Machine

```bash
# 1. Install Homebrew (if needed)
# 2. Install tools
brew install chezmoi bitwarden-cli mise

# 3. Login to Bitwarden
bw login

# 4. Clone dotfiles
chezmoi init --apply git@github.com:Data-Wise/dotfiles-private.git

# 5. Install packages
brew bundle --file ~/.local/share/chezmoi/Brewfile

# 6. Install language versions
cd ~/R-packages/medfit
mise install

# Done! (10 minutes)
```

---

## 🔧 Troubleshooting

### Bitwarden session expired

```bash
export BW_SESSION=$(bw unlock --raw)
chezmoi apply
```

### Secrets not injecting

```bash
# Check Bitwarden is unlocked
bw status

# Verify template syntax
chezmoi execute-template < ~/.local/share/chezmoi/dot_zshrc.tmpl
```

### Mise not activating

```bash
# Verify shell integration in .zshrc
grep "mise activate" ~/.zshrc

# Reload shell
exec zsh
```

### Chezmoi conflicts

```bash
# See what would change
chezmoi diff

# Force apply (use cautiously)
chezmoi apply --force
```

---

## 📊 Comparison with Alternatives

| Feature | Current | Chezmoi+BW | SOPS | Nix |
|---------|---------|------------|------|-----|
| Setup time | 0h | 6h | 5h | 20h |
| New machine | 4h | 10min | 12min | 5min |
| Secret security | 🔴 | 🟢 | 🟢 | 🟢 |
| Mobile access | ❌ | ✅ | ❌ | ❌ |
| GUI fallback | ❌ | ✅ | ❌ | ❌ |
| ADHD-friendly | 🟢 | 🟢 | 🟢 | 🔴 |
| Learning curve | - | Low | Low | High |

**Recommendation:** Chezmoi + Bitwarden

---

## 🎓 Key Concepts

### Chezmoi Templates

```bash
# Machine-specific values
{{ if eq .chezmoi.hostname "iMac.local" }}
export DATA_DIR="/Volumes/Data"
{{ else }}
export DATA_DIR="~/Data"
{{ end }}

# Secret injection
{{- $item := bitwarden "item" "API Key" }}
export API_KEY="{{ $item.login.password }}"
```

### Bitwarden Item Structure

```json
{
  "name": "Desktop Commander API",
  "login": {
    "username": "Desktop Commander",
    "password": "1lwAVb..."
  }
}
```

### Mise Configuration

```toml
# .mise.toml in project root
[tools]
R = "4.5.2"
python = "3.12"
```

---

## 📚 Resources

- [Chezmoi Documentation](https://www.chezmoi.io/)
- [Bitwarden CLI Guide](https://bitwarden.com/help/cli/)
- [Mise Documentation](https://mise.jdx.dev/)
- [Homebrew Bundle](https://github.com/Homebrew/homebrew-bundle)

---

## ✅ Success Criteria

- [ ] Phase 1: .zshrc syncs between machines (Week 1)
- [ ] Phase 2: No hardcoded secrets in dotfiles (Week 2)
- [ ] Phase 3: Same R version on both machines (Week 3)
- [ ] Can setup new machine in <15 minutes
- [ ] Secrets accessible on mobile via Bitwarden app
- [ ] All configs version-controlled in private repo

---

**Next Step:** Start Phase 1 (Dotfile Management)  
**Estimated Time:** 2 hours to complete Phase 1  
**Blocking Issues:** None (all tools available via Homebrew)

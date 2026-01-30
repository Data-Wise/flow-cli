# Teaching Workflow Demo
# Shows: teach-init → work (branch safety) → deploy
# Generated with VHS (https://github.com/charmbracelet/vhs)

Output teaching-workflow.gif

Set Shell zsh
Set FontSize 18
Set Width 1200
Set Height 700
Set Padding 20
Set Theme "Catppuccin Mocha"

# ============================================================================
# SCENE 1: Initialize Teaching Workflow
# ============================================================================

Type "# Teaching Workflow Demo"
Sleep 500ms
Enter
Type "# Scene 1: Initialize teaching workflow for a course"
Sleep 500ms
Enter
Sleep 1s

Type "cd /tmp/demo-course"
Sleep 500ms
Enter
Sleep 500ms

Type "git init"
Sleep 500ms
Enter
Sleep 1s

Type "git config user.email 'demo@example.com'"
Sleep 500ms
Enter
Sleep 300ms

Type "git config user.name 'Demo User'"
Sleep 500ms
Enter
Sleep 500ms

Type "echo '# STAT 545 - Design of Experiments' > README.md"
Sleep 500ms
Enter
Sleep 300ms

Type "git add README.md"
Sleep 500ms
Enter
Sleep 300ms

Type "git commit -m 'Initial commit'"
Sleep 500ms
Enter
Sleep 1s

Type "clear"
Sleep 500ms
Enter
Sleep 500ms

Type "# Now initialize teaching workflow"
Sleep 500ms
Enter
Sleep 1s

Type "teach-init 'STAT 545'"
Sleep 500ms
Enter
Sleep 2s

Type "1"
Sleep 500ms
Enter
Sleep 1s

Type "y"
Sleep 500ms
Enter
Sleep 3s

Type "clear"
Sleep 500ms
Enter
Sleep 500ms

# ============================================================================
# SCENE 2: Inspect What Was Created
# ============================================================================

Type "# Scene 2: Inspect what teach-init created"
Sleep 500ms
Enter
Sleep 1s

Type "ls -la .flow/"
Sleep 500ms
Enter
Sleep 1.5s

Type "ls -la scripts/"
Sleep 500ms
Enter
Sleep 1.5s

Type "git branch -a"
Sleep 500ms
Enter
Sleep 1.5s

Type "clear"
Sleep 500ms
Enter
Sleep 500ms

# ============================================================================
# SCENE 3: Production Branch Warning
# ============================================================================

Type "# Scene 3: Branch safety - warning when on production"
Sleep 500ms
Enter
Sleep 1s

Type "git checkout production"
Sleep 500ms
Enter
Sleep 1s

Type "work demo-course"
Sleep 500ms
Enter
Sleep 3s

Type "n"
Sleep 500ms
Enter
Sleep 2s

Type "clear"
Sleep 500ms
Enter
Sleep 500ms

# ============================================================================
# SCENE 4: Safe Work on Draft Branch
# ============================================================================

Type "# Scene 4: Working on draft branch (safe)"
Sleep 500ms
Enter
Sleep 1s

Type "git branch --show-current"
Sleep 500ms
Enter
Sleep 1s

Type "work demo-course"
Sleep 500ms
Enter
Sleep 3s

Ctrl+C
Sleep 500ms

Type "clear"
Sleep 500ms
Enter
Sleep 500ms

# ============================================================================
# SCENE 5: Make Changes and Deploy
# ============================================================================

Type "# Scene 5: Make changes and deploy"
Sleep 500ms
Enter
Sleep 1s

Type "echo '## Week 1: Introduction' >> lectures.md"
Sleep 500ms
Enter
Sleep 300ms

Type "git add lectures.md"
Sleep 500ms
Enter
Sleep 300ms

Type "git commit -m 'Add week 1 lecture'"
Sleep 500ms
Enter
Sleep 1s

Type "clear"
Sleep 500ms
Enter
Sleep 500ms

Type "# Deploy to production (< 2 min)"
Sleep 500ms
Enter
Sleep 1s

Type "./scripts/quick-deploy.sh"
Sleep 500ms
Enter
Sleep 4s

Type "clear"
Sleep 500ms
Enter
Sleep 500ms

# ============================================================================
# SCENE 6: Verify Deployment
# ============================================================================

Type "# Scene 6: Verify deployment succeeded"
Sleep 500ms
Enter
Sleep 1s

Type "git branch --show-current"
Sleep 500ms
Enter
Sleep 1s

Type "git log production --oneline -3"
Sleep 500ms
Enter
Sleep 2s

Type "clear"
Sleep 500ms
Enter
Sleep 500ms

# ============================================================================
# SCENE 7: Show Configuration
# ============================================================================

Type "# Scene 7: Course configuration"
Sleep 500ms
Enter
Sleep 1s

Type "cat .flow/teach-config.yml"
Sleep 500ms
Enter
Sleep 4s

Type "clear"
Sleep 500ms
Enter
Sleep 500ms

# ============================================================================
# FINAL: Summary
# ============================================================================

Type "# ✅ Teaching Workflow Demo Complete!"
Sleep 500ms
Enter
Sleep 500ms

Type "#"
Sleep 500ms
Enter
Sleep 500ms

Type "# What we demonstrated:"
Sleep 500ms
Enter
Sleep 500ms

Type "# 1. teach-init: Initialize workflow (branches + scripts)"
Sleep 500ms
Enter
Sleep 500ms

Type "# 2. Branch safety: Warning when on production"
Sleep 500ms
Enter
Sleep 500ms

Type "# 3. work command: Teaching-aware session"
Sleep 500ms
Enter
Sleep 500ms

Type "# 4. quick-deploy: Fast deployment (< 2 min)"
Sleep 500ms
Enter
Sleep 500ms

Type "# 5. Configuration: .flow/teach-config.yml"
Sleep 500ms
Enter
Sleep 500ms

Type "#"
Sleep 500ms
Enter
Sleep 500ms

Type "# Time from typo to live: < 2 minutes ⚡"
Sleep 500ms
Enter
Sleep 500ms

Type "#"
Sleep 500ms
Enter
Sleep 500ms

Type "# Learn more: https://data-wise.github.io/flow-cli/guides/TEACHING-WORKFLOW/"
Sleep 500ms
Enter
Sleep 3s

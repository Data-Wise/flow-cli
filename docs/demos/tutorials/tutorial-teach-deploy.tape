# VHS Demo: teach deploy v2 - Direct Merge, History, Rollback
# Part of flow-cli v6.4.0
# Tutorial 31: Fast Deployments with teach deploy v2

Output tutorial-teach-deploy.gif

Require echo

Set Shell zsh
Set FontSize 18
Set Width 1400
Set Height 900
Set TypingSpeed 50ms
Set PlaybackSpeed 0.8

Hide
# Source flow-cli to load latest version
Type "source ~/projects/dev-tools/flow-cli/flow.plugin.zsh" Enter
Sleep 1s
Type "cd ~/projects/teaching/scholar-demo-course" Enter
Sleep 500ms
Type "clear" Enter
Show

# Title
Type "echo '=== teach deploy v2 (flow-cli v6.4.0) ==='" Enter
Sleep 2s

# Step 1: Dry-run preview
Type "echo ''" Enter
Type "echo '1. Preview before deploying (dry-run):'" Enter
Sleep 1s
Type "teach deploy --dry-run --direct" Enter
Sleep 4s

Type "echo ''" Enter
Type "clear" Enter
Sleep 1s

# Step 2: Direct deploy
Type "echo '2. Fast direct deploy (8-15s):'" Enter
Sleep 1s
Type "teach deploy --direct -m 'content: week-05 lecture'" Enter
Sleep 5s

Type "echo ''" Enter
Type "clear" Enter
Sleep 1s

# Step 3: Check history
Type "echo '3. View deployment history:'" Enter
Sleep 1s
Type "teach deploy --history" Enter
Sleep 4s

Type "echo ''" Enter
Type "clear" Enter
Sleep 1s

# Step 4: Rollback
Type "echo '4. Rollback if something goes wrong:'" Enter
Sleep 1s
Type "teach deploy --rollback 1 --ci" Enter
Sleep 4s

Type "echo ''" Enter
Sleep 1s
Type "echo 'Done! Deploy, track, rollback — all in seconds.'" Enter
Sleep 3s

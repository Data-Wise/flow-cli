# First Session Demo
# Shows: work → (coding) → finish
# Tutorial 1: Your First Work Session
# Generated with VHS (https://github.com/charmbracelet/vhs)

Output first-session.gif

Set Shell zsh
Set FontSize 18
Set Width 1200
Set Height 600
Set Padding 20
Set Theme "Catppuccin Mocha"

# ============================================================================
# SCENE 1: Starting a Work Session
# ============================================================================

Type "echo 'Tutorial 1: Your First Work Session'"
Sleep 500ms
Enter
Type "echo 'Scene 1: Start tracking your work'"
Sleep 500ms
Enter
Sleep 1s

Type "cd ~/projects/my-project"
Sleep 500ms
Enter
Sleep 500ms

Type "echo 'Start a work session'"
Sleep 500ms
Enter
Sleep 500ms

Type "work"
Sleep 500ms
Enter
Sleep 2s

Type "clear"
Sleep 500ms
Enter
Sleep 500ms

# ============================================================================
# SCENE 2: Working on Code
# ============================================================================

Type "echo 'Scene 2: Do some work...'"
Sleep 500ms
Enter
Sleep 1s

Type "echo 'Edit a file, run tests, etc.'"
Sleep 500ms
Enter
Sleep 500ms

Type "echo 'function add(a, b) { return a + b; }' >> math.js"
Sleep 500ms
Enter
Sleep 500ms

Type "echo 'Check project status'"
Sleep 500ms
Enter
Sleep 500ms

Type "dash"
Sleep 500ms
Enter
Sleep 2s

Type "clear"
Sleep 500ms
Enter
Sleep 500ms

# ============================================================================
# SCENE 3: Finishing the Session
# ============================================================================

Type "echo 'Scene 3: Finish your session'"
Sleep 500ms
Enter
Sleep 1s

Type "echo 'End session with a quick note'"
Sleep 500ms
Enter
Sleep 500ms

Type "finish 'Added add function to math.js'"
Sleep 500ms
Enter
Sleep 2s

Type "echo 'Session tracked! See summary:'"
Sleep 500ms
Enter
Sleep 1s

Type "dash"
Sleep 500ms
Enter
Sleep 2s

# ============================================================================
# SCENE 4: Quick Reference
# ============================================================================

Type "clear"
Sleep 500ms
Enter
Sleep 500ms

Type "echo 'Quick Reference'"
Sleep 500ms
Enter
Type "echo '  work         - Start tracking a session'"
Sleep 300ms
Enter
Type "echo '  dash         - View project dashboard'"
Sleep 300ms
Enter
Type "echo '  finish       - End session with optional note'"
Sleep 300ms
Enter
Sleep 2s

Type "echo 'That's it! You've completed your first session.'"
Sleep 500ms
Enter
Sleep 3s

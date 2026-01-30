# Dopamine Features Demo
# Shows: win → yay → flow goal
# Tutorial 6: ADHD-Friendly Motivation System
# Generated with VHS (https://github.com/charmbracelet/vhs)

Output dopamine-features.gif

Set Shell zsh
Set FontSize 18
Set Width 1200
Set Height 650
Set Padding 20
Set Theme "Catppuccin Mocha"

# ============================================================================
# SCENE 1: Logging Wins
# ============================================================================

Type "echo 'Tutorial 6: Dopamine Features'"
Sleep 500ms
Enter
Type "echo 'Scene 1: Log your accomplishments'"
Sleep 500ms
Enter
Sleep 1s

Type "echo 'Log a coding win'"
Sleep 500ms
Enter
Sleep 500ms

Type "win 'Fixed authentication bug'"
Sleep 500ms
Enter
Sleep 1s

Type "echo 'Log a documentation win'"
Sleep 500ms
Enter
Sleep 500ms

Type "win 'Updated API docs'"
Sleep 500ms
Enter
Sleep 1s

Type "echo 'Log a review win'"
Sleep 500ms
Enter
Sleep 500ms

Type "win 'Reviewed PR #42'"
Sleep 500ms
Enter
Sleep 1s

Type "clear"
Sleep 500ms
Enter
Sleep 500ms

# ============================================================================
# SCENE 2: View Your Wins
# ============================================================================

Type "echo 'Scene 2: Celebrate your progress'"
Sleep 500ms
Enter
Sleep 1s

Type "echo 'See recent wins'"
Sleep 500ms
Enter
Sleep 500ms

Type "yay"
Sleep 500ms
Enter
Sleep 2s

Type "echo 'Weekly summary with graph'"
Sleep 500ms
Enter
Sleep 500ms

Type "yay --week"
Sleep 500ms
Enter
Sleep 3s

Type "clear"
Sleep 500ms
Enter
Sleep 500ms

# ============================================================================
# SCENE 3: Daily Goals
# ============================================================================

Type "echo 'Scene 3: Set daily goals'"
Sleep 500ms
Enter
Sleep 1s

Type "echo 'Set a daily goal of 3 wins'"
Sleep 500ms
Enter
Sleep 500ms

Type "flow goal set 3"
Sleep 500ms
Enter
Sleep 1s

Type "echo 'Check progress toward goal'"
Sleep 500ms
Enter
Sleep 500ms

Type "flow goal"
Sleep 500ms
Enter
Sleep 2s

Type "clear"
Sleep 500ms
Enter
Sleep 500ms

# ============================================================================
# SCENE 4: Auto-Categorization
# ============================================================================

Type "echo 'Scene 4: Auto-categorized wins'"
Sleep 500ms
Enter
Sleep 1s

Type "echo 'Wins are auto-categorized:'"
Sleep 300ms
Enter
Type "echo '  code    - Fixed, implemented, refactored'"
Sleep 300ms
Enter
Type "echo '  docs    - Documented, updated docs'"
Sleep 300ms
Enter
Type "echo '  review  - Reviewed, PR'"
Sleep 300ms
Enter
Type "echo '  ship    - Deployed, released'"
Sleep 300ms
Enter
Type "echo '  fix     - Fixed, patched, resolved'"
Sleep 300ms
Enter
Type "echo '  test    - Tested, added tests'"
Sleep 300ms
Enter
Sleep 2s

Type "echo 'Start logging your wins today!'"
Sleep 500ms
Enter
Sleep 3s

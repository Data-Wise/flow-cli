# CC Dispatcher Demo
# Shows: cc → cc pick → cc yolo → cc opus
# Tutorial 10: Launch Claude Code Anywhere
# Generated with VHS (https://github.com/charmbracelet/vhs)

Output cc-dispatcher.gif

Set Shell zsh
Set FontSize 18
Set Width 1200
Set Height 650
Set Padding 20
Set Theme "Catppuccin Mocha"

# ============================================================================
# SCENE 1: Basic Launch
# ============================================================================

Type "echo 'Tutorial 10: CC Dispatcher'"
Sleep 500ms
Enter
Type "echo 'Scene 1: Launch Claude Code'"
Sleep 500ms
Enter
Sleep 1s

Type "cd ~/projects/my-app"
Sleep 500ms
Enter
Sleep 500ms

Type "echo 'Launch Claude in current directory'"
Sleep 500ms
Enter
Sleep 500ms

Type "cc"
Sleep 500ms
Enter
Sleep 2s

Type "echo 'Press Ctrl+C to exit for demo'"
Sleep 500ms
Enter
Sleep 1s

Ctrl+C
Sleep 500ms

Type "clear"
Sleep 500ms
Enter
Sleep 500ms

# ============================================================================
# SCENE 2: Project Picker
# ============================================================================

Type "echo 'Scene 2: Pick a project, then launch Claude'"
Sleep 500ms
Enter
Sleep 1s

Type "echo 'Pick from all projects'"
Sleep 500ms
Enter
Sleep 500ms

Type "cc pick"
Sleep 500ms
Enter
Sleep 2s

Type "echo 'Shows fzf picker (interactive)'"
Sleep 500ms
Enter
Sleep 1s

Escape
Sleep 500ms

Type "clear"
Sleep 500ms
Enter
Sleep 500ms

# ============================================================================
# SCENE 3: YOLO Mode
# ============================================================================

Type "echo 'Scene 3: YOLO Mode (skip edit prompts)'"
Sleep 500ms
Enter
Sleep 1s

Type "echo 'Launch with YOLO mode'"
Sleep 500ms
Enter
Sleep 500ms

Type "cc yolo"
Sleep 500ms
Enter
Sleep 1s

Type "echo 'Equivalent: cc y'"
Sleep 500ms
Enter
Sleep 500ms

Ctrl+C
Sleep 500ms

Type "clear"
Sleep 500ms
Enter
Sleep 500ms

# ============================================================================
# SCENE 4: Model Selection
# ============================================================================

Type "echo 'Scene 4: Select model'"
Sleep 500ms
Enter
Sleep 1s

Type "echo 'Use Opus model'"
Sleep 500ms
Enter
Sleep 500ms

Type "cc opus"
Sleep 500ms
Enter
Sleep 1s

Ctrl+C
Sleep 500ms

Type "echo 'Use Haiku for quick tasks'"
Sleep 500ms
Enter
Sleep 500ms

Type "cc haiku"
Sleep 500ms
Enter
Sleep 1s

Ctrl+C
Sleep 500ms

Type "clear"
Sleep 500ms
Enter
Sleep 500ms

# ============================================================================
# SCENE 5: Unified Grammar
# ============================================================================

Type "echo 'Scene 5: Unified Grammar'"
Sleep 500ms
Enter
Sleep 1s

Type "echo 'Both orders work!'"
Sleep 500ms
Enter
Sleep 500ms

Type "cc yolo pick   # mode-first"
Sleep 300ms
Enter
Type "cc pick yolo   # target-first"
Sleep 300ms
Enter
Sleep 1s

Type "cc opus .      # launch HERE with Opus"
Sleep 300ms
Enter
Sleep 1s

Type "echo 'Quick Reference:'"
Sleep 500ms
Enter
Type "echo '  cc          - Launch here'"
Sleep 300ms
Enter
Type "echo '  cc pick     - Pick project'"
Sleep 300ms
Enter
Type "echo '  cc yolo     - Skip edit prompts'"
Sleep 300ms
Enter
Type "echo '  cc opus     - Use Opus model'"
Sleep 300ms
Enter
Type "echo '  cc resume   - Resume session'"
Sleep 300ms
Enter
Sleep 3s

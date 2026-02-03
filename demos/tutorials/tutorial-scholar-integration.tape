# VHS Demo: Scholar Integration - Template Selection
# Part of flow-cli Teaching Workflow v3.0
# Tutorial: Using Scholar templates and lesson plan auto-loading

Output tutorial-scholar-integration.gif

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
Type "echo 'Teaching Workflow v3.0: Scholar Integration'" Enter
Sleep 1s
Type "echo 'Template Selection & Lesson Plans'" Enter
Sleep 2s

Type "" Enter
Sleep 1s

# Show exam command with help
Type "echo 'Generate exam with template:'" Enter
Sleep 1s
Type "teach exam --help | head -15" Enter
Sleep 4s

Type "" Enter
Type "clear" Enter
Sleep 1s

# Example exam generation with template
Type "echo 'Create exam using course template:'" Enter
Sleep 1s
Type "teach exam 'Regression Models' --template regression --lesson-plan week-5" Enter
Sleep 5s

Type "" Enter
Sleep 1s

# Show what happened
Type "echo 'Scholar generated exam with:'" Enter
Sleep 1s
Type "echo '  • Regression template applied'" Enter
Sleep 1s
Type "echo '  • Week 5 lesson plan loaded'" Enter
Sleep 1s
Type "echo '  • Content backed up automatically'" Enter
Sleep 2s

Type "" Enter
Type "echo '✓ Exam generated with template and lesson plan!'" Enter
Sleep 2s

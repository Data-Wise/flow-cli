# VHS Demo: Teaching + Git Workflow (5 Phases)
# Documentation: https://github.com/charmbracelet/vhs

# Terminal setup
Output docs/assets/gifs/teaching-git-workflow.gif
Set Shell zsh
Set FontSize 18
Set Width 1200
Set Height 800
Set Theme "Dracula"
Set TypingSpeed 50ms
Set PlaybackSpeed 0.8

# Title card
Type "Teaching + Git Workflow Demo (v5.12.0)" Sleep 1s Enter
Sleep 1s

# Phase 1: Smart Post-Generation
Type "echo 'Phase 1: Smart Post-Generation'" Enter
Sleep 500ms
Type "teach exam 'Midterm 1'" Enter
Sleep 2s

# Simulate interactive menu
Type "echo 'Choose an option:'" Sleep 500ms Enter
Type "echo '  1) Review in editor, then commit'" Sleep 300ms Enter
Type "echo '  2) Commit now with auto-generated message'" Sleep 300ms Enter
Type "echo '  3) Skip commit (do it manually later)'" Sleep 300ms Enter
Sleep 1s
Type "2" Enter
Sleep 1s

# Show commit created
Type "git log -1 --oneline" Enter
Sleep 2s

# Phase 2: Git Deployment
Type "" Enter
Type "echo 'Phase 2: Git Deployment'" Enter
Sleep 500ms
Type "teach deploy" Enter
Sleep 2s

# Simulate pre-flight checks
Type "echo 'Pre-flight checks:'" Sleep 500ms Enter
Type "echo '  ✓ On draft branch'" Sleep 300ms Enter
Type "echo '  ✓ No uncommitted changes'" Sleep 300ms Enter
Type "echo '  ✓ No unpushed commits'" Sleep 300ms Enter
Type "echo '  ✓ No production conflicts'" Sleep 300ms Enter
Sleep 1s
Type "echo 'Creating PR: draft → main'" Sleep 500ms Enter
Sleep 1s

# Phase 3: Git-Aware Status
Type "" Enter
Type "echo 'Phase 3: Git-Aware Status'" Enter
Sleep 500ms
Type "teach status" Enter
Sleep 2s

# Simulate status output
Type "echo 'Course: STAT 545 (Fall 2024)'" Sleep 300ms Enter
Type "echo 'Week: 8 of 15'" Sleep 300ms Enter
Type "#" Sleep 100ms Enter
Type "echo '📝 Uncommitted Teaching Files:'" Sleep 300ms Enter
Type "echo '  • exams/exam02.qmd'" Sleep 300ms Enter
Type "echo '  • slides/week08.qmd'" Sleep 300ms Enter
Sleep 1s

# Phase 4: Teaching Mode
Type "" Enter
Type "echo 'Phase 4: Teaching Mode (Auto-Commit)'" Enter
Sleep 500ms
Type "echo 'Edit config: workflow.teaching_mode: true'" Enter
Sleep 1s
Type "teach quiz 'Chapter 5'" Enter
Sleep 2s
Type "echo '🎓 Teaching Mode: Auto-committing...'" Sleep 300ms Enter
Type "echo '✓ Committed: teach: add quiz for Chapter 5'" Sleep 300ms Enter
Sleep 1s

# Phase 5: Git Initialization
Type "" Enter
Type "echo 'Phase 5: Git Initialization'" Enter
Sleep 500ms
Type "teach init 'STAT 440'" Enter
Sleep 2s

# Simulate init wizard
Type "echo '→ Initializing git repository'" Sleep 300ms Enter
Type "echo '→ Copying .gitignore template (95 lines)'" Sleep 300ms Enter
Type "echo '→ Creating draft branch'" Sleep 300ms Enter
Type "echo '→ Creating main branch'" Sleep 300ms Enter
Type "echo '→ Making initial commit'" Sleep 300ms Enter
Type "echo '→ GitHub repo creation? (y/N)'" Sleep 500ms Enter
Type "n" Enter
Sleep 1s

# Final summary
Type "" Enter
Type "echo '✅ All 5 Phases Complete!'" Enter
Sleep 2s

# Show git log
Type "git log --oneline -5" Enter
Sleep 3s

# End
Type "" Enter
Sleep 2s

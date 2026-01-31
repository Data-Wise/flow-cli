# Tutorial 20 Demo 3: teach dates sync (interactive)
# Shows interactive file-by-file sync with user prompts

Output tutorial-20-dates-sync-interactive.gif
Set Shell zsh

Set FontSize 18
Set Width 1400
Set Height 1000
Set Theme "Dracula"
Set TypingSpeed 50ms
Set PlaybackSpeed 0.8

# Title
Type "Tutorial 20: Teaching Dates Automation - Part 3" Sleep 1s Enter
Sleep 1s

# Run interactive sync
Type "echo 'Apply changes interactively'" Enter
Sleep 500ms
Type "teach dates sync" Enter
Sleep 1.5s

# Simulate scanning
Type "" Enter
Type "🔍 Scanning for teaching files..." Sleep 500ms Enter
Type "✓ Found 25 files" Sleep 500ms Enter
Sleep 500ms

Type "" Enter
Type "📊 Analyzing dates..." Sleep 500ms Enter
Sleep 500ms

Type "" Enter
Type "⚠️  Date Mismatches Found" Sleep 500ms Enter
Sleep 1s

# First file prompt
Type "" Enter
Type "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" Sleep 300ms Enter
Type "File: assignments/hw1.qmd (1 mismatch)" Sleep 300ms Enter
Type "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" Sleep 300ms Enter
Sleep 500ms
Type "" Enter
Type "Line 5: due: 2025-01-20 → 2025-01-22" Sleep 300ms Enter
Sleep 800ms
Type "" Enter
Type "Apply changes to this file? [y/n/d/q]" Sleep 500ms
Sleep 1s

# User chooses 'y'
Type "y" Enter
Sleep 1s
Type "✓ Applied changes to assignments/hw1.qmd" Sleep 300ms Enter
Sleep 1.5s

# Second file prompt
Type "" Enter
Type "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" Sleep 300ms Enter
Type "File: syllabus.qmd (3 mismatches)" Sleep 300ms Enter
Type "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" Sleep 300ms Enter
Sleep 500ms
Type "" Enter
Type "Line 42: 'Homework 1 due Jan 20' → 'Homework 1 due Jan 22'" Sleep 300ms Enter
Type "Line 48: 'Homework 2 due Feb 5' → 'Homework 2 due Feb 7'" Sleep 300ms Enter
Type "Line 67: 'Midterm: March 5' → 'Midterm: March 7'" Sleep 300ms Enter
Sleep 800ms
Type "" Enter
Type "Apply changes to this file? [y/n/d/q]" Sleep 500ms
Sleep 1s

# User chooses 'y'
Type "y" Enter
Sleep 1s
Type "✓ Applied changes to syllabus.qmd" Sleep 300ms Enter
Sleep 1.5s

# Final success message
Type "" Enter
Type "✅ Date Sync Complete" Sleep 500ms Enter
Sleep 500ms
Type "" Enter
Type "Applied changes to 2 files:" Sleep 300ms Enter
Type "  ✓ assignments/hw1.qmd" Sleep 300ms Enter
Type "  ✓ syllabus.qmd" Sleep 300ms Enter
Sleep 500ms
Type "" Enter
Type "Skipped: 0 files" Sleep 300ms Enter
Sleep 2s

# Final note
Type "" Enter
Type "echo '✅ Date sync complete - all dates synchronized!'" Enter
Sleep 2s

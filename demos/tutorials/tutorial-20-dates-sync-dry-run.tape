# Tutorial 20 Demo 2: teach dates sync --dry-run
# Shows preview of date changes before applying

Output tutorial-20-dates-sync-dry-run.gif
Set Shell zsh

Set FontSize 18
Set Width 1400
Set Height 900
Set Theme "Dracula"
Set TypingSpeed 50ms
Set PlaybackSpeed 0.8

# Title
Type "Tutorial 20: Teaching Dates Automation - Part 2" Sleep 1s Enter
Sleep 1s

# Run dry-run
Type "echo 'Preview what would change (dry-run)'" Enter
Sleep 500ms
Type "teach dates sync --dry-run" Enter
Sleep 1.5s

# Simulate scanning
Type "" Enter
Type "🔍 Scanning for teaching files..." Sleep 500ms Enter
Type "✓ Found 25 files" Sleep 500ms Enter
Sleep 1s

# Simulate analyzing
Type "" Enter
Type "📊 Analyzing dates..." Sleep 500ms Enter
Sleep 1s

# Simulate mismatches found
Type "" Enter
Type "⚠️  Date Mismatches Found" Sleep 500ms Enter
Sleep 500ms

# File 1
Type "" Enter
Type "1. assignments/hw1.qmd (1 mismatch)" Sleep 400ms Enter
Type "   Line 5: due: 2025-01-20 → 2025-01-22" Sleep 400ms Enter
Sleep 800ms

# File 2
Type "" Enter
Type "2. syllabus.qmd (3 mismatches)" Sleep 400ms Enter
Type "   Line 42: 'Homework 1 due Jan 20' → 'Homework 1 due Jan 22'" Sleep 400ms Enter
Type "   Line 48: 'Homework 2 due Feb 5' → 'Homework 2 due Feb 7'" Sleep 400ms Enter
Type "   Line 67: 'Midterm: March 5' → 'Midterm: March 7'" Sleep 400ms Enter
Sleep 800ms

# File 3
Type "" Enter
Type "3. schedule.md (2 mismatches)" Sleep 400ms Enter
Type "   Line 15: Week 2: January 20, 2025 → Week 2: January 22, 2025" Sleep 400ms Enter
Type "   Line 29: Week 4: February 5, 2025 → Week 4: February 7, 2025" Sleep 400ms Enter
Sleep 1s

# Dry run notice
Type "" Enter
Type "DRY RUN MODE - No changes applied" Sleep 500ms Enter
Type "Run without --dry-run to apply changes" Sleep 500ms Enter
Sleep 2s

# Success message
Type "" Enter
Type "echo '✅ Preview complete - review and apply!'" Enter
Sleep 2s

# Tutorial 20 Demo 1: teach dates init
# Shows the interactive wizard for initializing date configuration

Output tutorial-20-dates-init.gif

Set FontSize 18
Set Width 1400
Set Height 900
Set Theme "Dracula"
Set TypingSpeed 50ms
Set PlaybackSpeed 0.8

# Title
Type "Tutorial 20: Teaching Dates Automation - Part 1" Sleep 1s Enter
Sleep 1s

# Setup: Navigate to course directory
Type "# Step 1: Navigate to course directory" Enter
Sleep 500ms
Type "cd ~/projects/teaching/stat-545" Enter
Sleep 1s

Type "" Enter
Type "# Step 2: Initialize date configuration" Enter
Sleep 500ms
Type "teach dates init" Enter
Sleep 1.5s

# Simulate wizard prompt
Type "Semester start date (YYYY-MM-DD): " Sleep 800ms
Type "2025-01-13" Enter
Sleep 2s

# Simulate output
Type "" Enter
Type "✓ Created .flow/teach-config.yml" Sleep 500ms Enter
Type "✓ Generated 15 weeks (2025-01-13 → 2025-04-28)" Sleep 500ms Enter
Type "✓ Date configuration initialized" Sleep 500ms Enter
Sleep 1s

# Verify config
Type "" Enter
Type "# Step 3: Verify config was created" Enter
Sleep 500ms
Type "cat .flow/teach-config.yml | head -20" Enter
Sleep 500ms

# Simulate YAML output
Type "semester_info:" Sleep 300ms Enter
Type "  start_date: 2025-01-13" Sleep 300ms Enter
Type "  end_date: 2025-04-28" Sleep 300ms Enter
Type "  weeks:" Sleep 300ms Enter
Type "    - number: 1" Sleep 300ms Enter
Type "      start_date: 2025-01-13" Sleep 300ms Enter
Type "      topic: ''" Sleep 300ms Enter
Type "    - number: 2" Sleep 300ms Enter
Type "      start_date: 2025-01-20" Sleep 300ms Enter
Type "      topic: ''" Sleep 300ms Enter
Sleep 2s

# Success message
Type "" Enter
Type "# ✅ Date configuration initialized!" Enter
Sleep 2s

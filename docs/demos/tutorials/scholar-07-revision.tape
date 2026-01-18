# Scholar Enhancement Tutorial Demo 7: Revision Workflow
# Shows improving existing content with revision menu

Output scholar-07-revision.gif

Set FontSize 13
Set Width 1000
Set Height 650
Set Theme "Catppuccin Mocha"
Set Padding 20
Set TypingSpeed 40ms

# Start revision
Type "teach slides --revise test-slides.qmd"
Sleep 500ms
Enter
Sleep 1s

# Show file info
Type@400ms "📝 Revising: test-slides.qmd"
Enter
Type@400ms "📅 Last modified: 2026-01-17 14:30"
Enter
Sleep 1s
Type@400ms ""
Enter

# Show revision menu
Type@400ms "📝 Revision Options"
Enter
Type@400ms ""
Enter
Type@400ms "What would you like to improve?"
Enter
Sleep 500ms
Type@400ms ""
Enter
Type@400ms "  [1] Add missing content"
Enter
Type@400ms "  [2] Improve clarity/organization"
Enter
Type@400ms "  [3] Fix errors/inconsistencies"
Enter
Type@400ms "  [4] Update examples/exercises"
Enter
Type@400ms "  [5] Enhance formatting/style"
Enter
Type@400ms "  [6] Custom instructions"
Enter
Sleep 1s
Type@400ms ""
Enter
Type "Your choice [1-6]: "
Sleep 500ms
Type "2"
Enter
Sleep 1s

# Show result
Type@400ms ""
Enter
Type@400ms "Improving clarity and organization..."
Enter
Sleep 2s
Type@400ms "✅ Revision complete"
Enter
Sleep 2s

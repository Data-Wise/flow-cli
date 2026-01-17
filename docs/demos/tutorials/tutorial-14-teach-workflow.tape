# Tutorial 14 Demo: Teaching Workflow
# Shows: teach init → deploy → status workflow

Output tutorial-14-teach-workflow.gif

Set FontSize 14
Set Width 1200
Set Height 800
Set Theme "Dracula"
Set TypingSpeed 50ms
Set PlaybackSpeed 0.8

# Title
Type "Tutorial 14: Teaching Workflow with Teach Dispatcher" Sleep 1s Enter
Sleep 1s

# Scene 1: Initialize
Type "# Part 1: Initialize a course" Enter
Sleep 500ms
Type "teach init 'STAT 545'" Enter
Sleep 1.5s

# Simulate wizard output
Type "" Enter
Type "┌─────────────────────────────────────────────────────────────┐" Sleep 300ms Enter
Type "│ 🎓 Flow Teaching Workflow Initialization                    │" Sleep 300ms Enter
Type "├─────────────────────────────────────────────────────────────┤" Sleep 300ms Enter
Type "│ Course name: STAT 545                                       │" Sleep 300ms Enter
Type "│                                                             │" Sleep 300ms Enter
Type "│ → Initializing git repository...                            │" Sleep 500ms Enter
Type "│ → Creating branches: draft, main                            │" Sleep 500ms Enter
Type "│ → Making initial commit                                     │" Sleep 500ms Enter
Type "│                                                             │" Sleep 300ms Enter
Type "│ ✅ Initialization complete!                                 │" Sleep 300ms Enter
Type "└─────────────────────────────────────────────────────────────┘" Sleep 300ms Enter
Sleep 1s

# Scene 2: Create content
Type "" Enter
Type "# Part 2: Generate teaching content" Enter
Sleep 500ms
Type "teach exam 'Midterm 1'" Enter
Sleep 1.5s

# Simulate post-generation menu
Type "" Enter
Type "📝 Generated: exams/midterm-01.qmd" Sleep 300ms Enter
Sleep 500ms
Type "" Enter
Type "Choose next step:" Sleep 300ms Enter
Type "  1) Review in editor, then commit" Sleep 200ms Enter
Type "  2) Commit now with auto message" Sleep 200ms Enter
Type "  3) Skip commit (manual later)" Sleep 200ms Enter
Sleep 1s
Type "2" Enter
Sleep 1s
Type "" Enter
Type "✓ Committed: teach: add exam for Midterm 1" Sleep 300ms Enter
Sleep 1.5s

# Scene 3: Deploy
Type "" Enter
Type "# Part 3: Deploy to production" Enter
Sleep 500ms
Type "teach deploy" Enter
Sleep 1.5s

# Simulate deploy output
Type "" Enter
Type "🚀 Teaching Deployment (draft → main)" Sleep 300ms Enter
Sleep 500ms
Type "" Enter
Type "Pre-flight checks:" Sleep 300ms Enter
Type "  ✓ On draft branch" Sleep 200ms Enter
Type "  ✓ No uncommitted changes" Sleep 200ms Enter
Type "  ✓ No unpushed commits" Sleep 200ms Enter
Type "  ✓ No production conflicts" Sleep 200ms Enter
Sleep 1s
Type "" Enter
Type "Creating pull request..." Sleep 500ms Enter
Sleep 500ms
Type "Merging PR..." Sleep 500ms Enter
Sleep 500ms
Type "Pushing to production..." Sleep 500ms Enter
Sleep 500ms
Type "" Enter
Type "✅ Deployed successfully!" Sleep 300ms Enter
Type "   https://your-site.github.io" Sleep 300ms Enter
Sleep 2s

# Scene 4: Status
Type "" Enter
Type "# Part 4: Check course status" Enter
Sleep 500ms
Type "teach status" Enter
Sleep 1.5s

# Simulate status output
Type "" Enter
Type "📊 Course: STAT 545 (Fall 2024)" Sleep 300ms Enter
Type "📅 Week: 8 of 15" Sleep 300ms Enter
Type "" Sleep 100ms Enter
Type "📝 Recent Teaching Files:" Sleep 300ms Enter
Type "  ✓ exams/midterm-01.qmd (committed)" Sleep 200ms Enter
Type "  ✓ slides/week08.qmd (committed)" Sleep 200ms Enter
Type "" Sleep 100ms Enter
Type "🌿 Git Status:" Sleep 300ms Enter
Type "  Current branch: draft" Sleep 200ms Enter
Type "  Up to date with main" Sleep 200ms Enter
Sleep 2s

# Final message
Type "" Enter
Type "# ✅ Complete teaching workflow demonstrated!" Enter
Sleep 2s

# VHS Demo: teach deploy - Preview Deployment
# Part of flow-cli Teaching Workflow v3.0
# Tutorial: Deploy with preview workflow and status checking

Output tutorial-teach-deploy.gif

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
Type "echo 'Teaching Workflow v3.0: teach deploy'" Enter
Sleep 1s
Type "echo 'Preview Deployment Workflow'" Enter
Sleep 2s

Type "" Enter
Sleep 1s

# Show help
Type "echo 'Available options:'" Enter
Sleep 1s
Type "teach deploy --help | head -20" Enter
Sleep 4s

Type "" Enter
Type "clear" Enter
Sleep 1s

# Check status before deploy
Type "echo 'Check deployment status:'" Enter
Sleep 1s
Type "teach status" Enter
Sleep 3s

Type "" Enter
Sleep 1s

# Preview deployment
Type "echo 'Deploy to preview branch:'" Enter
Sleep 1s
Type "teach deploy --preview" Enter
Sleep 5s

Type "" Enter
Sleep 1s

# Show what happened
Type "echo 'Preview deployed to gh-pages-preview branch'" Enter
Sleep 2s
Type "echo 'Review at: https://username.github.io/course/preview/'" Enter
Sleep 2s

Type "" Enter
Type "echo '✓ Preview deployment complete!'" Enter
Sleep 2s

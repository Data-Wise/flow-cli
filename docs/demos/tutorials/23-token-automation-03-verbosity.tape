# Tutorial 23 Demo 3: Verbosity Levels
# Demonstrates quiet, normal, and verbose output modes

Output ./23-token-automation-03-verbosity.gif
Set Shell zsh

Set FontSize 18
Set Width 1000
Set Height 600
Set Theme "Catppuccin Mocha"

Type "echo 'Step 6: Verbosity Levels'"
Sleep 800ms
Enter
Sleep 500ms

Type "echo 'Quiet mode (CI/CD) - minimal output'"
Sleep 1s
Enter
Sleep 500ms

Type "doctor --dot --quiet"
Sleep 500ms
Enter
Sleep 1.5s

Type "echo 'Exit code: 0 (success)'"
Sleep 800ms
Enter
Sleep 500ms

Type@500ms "# Normal mode (default) - standard output"
Sleep 1s
Enter
Sleep 500ms

Type "doctor --dot"
Sleep 500ms
Enter
Sleep 2s

Type@500ms "# Verbose mode (debugging) - detailed cache info"
Sleep 1s
Enter
Sleep 500ms

Type "doctor --dot --verbose"
Sleep 500ms
Enter
Sleep 3s

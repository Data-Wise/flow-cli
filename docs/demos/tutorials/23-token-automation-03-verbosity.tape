# Tutorial 23 Demo 3: Verbosity Levels
# Demonstrates quiet, normal, and verbose output modes

Output docs/demos/tutorials/23-token-automation-03-verbosity.gif

Set FontSize 16
Set Width 1000
Set Height 600
Set Theme "Catppuccin Mocha"

Type "# Step 6: Verbosity Levels"
Sleep 800ms
Enter
Sleep 500ms

Type "# Quiet mode (CI/CD) - minimal output"
Sleep 1s
Enter
Sleep 500ms

Type "doctor --dot --quiet"
Sleep 500ms
Enter
Sleep 1.5s

Type "echo \"Exit code: $?\""
Sleep 300ms
Enter
Sleep 1s

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

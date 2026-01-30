# Tutorial 23 Demo 1: Isolated Token Check
# Demonstrates doctor --dot for fast, focused token validation

Output ./23-token-automation-01-isolated-check.gif

Set FontSize 18
Set Width 1000
Set Height 600
Set Theme "Catppuccin Mocha"

Type "# Step 3: Isolated Check - doctor --dot"
Sleep 800ms
Enter
Sleep 500ms

Type "doctor --dot"
Sleep 500ms
Enter
Sleep 2s

Type@500ms "# That was FAST! < 1 second"
Sleep 1s
Enter
Sleep 800ms

Type "# Try again to see cache in action"
Sleep 800ms
Enter
Sleep 500ms

Type "doctor --dot"
Sleep 500ms
Enter
Sleep 1.5s

Type@500ms "# Even faster! Cache hit in ~50ms"
Sleep 2s

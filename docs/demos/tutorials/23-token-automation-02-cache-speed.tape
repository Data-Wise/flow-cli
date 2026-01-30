# Tutorial 23 Demo 2: Cache Speed Comparison
# Shows the dramatic speed difference with caching

Output ./23-token-automation-02-cache-speed.gif

Set FontSize 18
Set Width 1000
Set Height 600
Set Theme "Catppuccin Mocha"

Type "# Step 4: Cache Demonstration"
Sleep 800ms
Enter
Sleep 500ms

Type "# First check (cache MISS) - fresh GitHub API call"
Sleep 1s
Enter
Sleep 500ms

Type "doctor --dot --verbose"
Sleep 500ms
Enter
Sleep 3s

Type@500ms "# Second check (cache HIT) - instant response"
Sleep 1s
Enter
Sleep 500ms

Type "doctor --dot --verbose"
Sleep 500ms
Enter
Sleep 1.5s

Type@500ms "# 85% hit rate = 80% fewer API calls!"
Sleep 2s

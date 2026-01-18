# Scholar Enhancement Tutorial Demo 1: Help System

Output scholar-01-help.gif

Set FontSize 14
Set Width 1000
Set Height 600
Set Theme "Catppuccin Mocha"
Set Padding 20
Set TypingSpeed 50ms

Type "teach slides --help"
Sleep 800ms
Enter
Sleep 500ms

# Simulate help output
Hide
Type "cat << 'HELPEOF'"
Enter
Show
Type "teach slides - Generate lecture slides"
Sleep 200ms
Enter
Type ""
Enter
Type "Universal Flags:"
Sleep 200ms
Enter
Type "  --style PRESET        (conceptual, computational, rigorous, applied)"
Sleep 200ms
Enter
Type "  --topic TOPIC         Explicit topic"
Sleep 200ms
Enter
Type "  --week N              Week number (loads lesson plan)"
Sleep 200ms
Enter
Type ""
Enter
Type "Content Flags:"
Sleep 200ms
Enter
Type "  --explanation, -e     Conceptual explanations"
Sleep 200ms
Enter
Type "  --math, -m            Mathematical notation"
Sleep 200ms
Enter
Type "  --examples, -x        Numerical examples"
Sleep 200ms
Enter
Type "  --code, -c            Code snippets"
Sleep 200ms
Enter
Type "  --diagrams, -d        Visualizations"
Sleep 200ms
Enter
Hide
Type "HELPEOF"
Enter
Show
Sleep 3s

#!/usr/bin/env zsh
# ghostty-debug.zsh - Debug terminal compatibility
# Run with: zsh tests/ghostty-debug.zsh

echo "=== Terminal Debug ==="
echo ""

echo "1. Terminal info:"
echo "   TERM=$TERM"
echo "   TERM_PROGRAM=$TERM_PROGRAM"
echo "   COLORTERM=$COLORTERM"
echo "   SHELL=$SHELL"
echo ""

echo "2. TTY checks:"
echo "   stdin is TTY: $([[ -t 0 ]] && echo 'YES' || echo 'NO')"
echo "   stdout is TTY: $([[ -t 1 ]] && echo 'YES' || echo 'NO')"
echo "   stderr is TTY: $([[ -t 2 ]] && echo 'YES' || echo 'NO')"
echo ""

echo "3. Testing colors (autoload method):"
autoload -U colors && colors
echo "   RED: ${fg[red]}This should be red${reset_color}"
echo "   GREEN: ${fg[green]}This should be green${reset_color}"
echo "   BLUE: ${fg[blue]}This should be blue${reset_color}"
echo ""

echo "4. Testing colors (ANSI method):"
echo "   RED: \033[0;31mThis should be red\033[0m"
echo "   GREEN: \033[0;32mThis should be green\033[0m"
echo "   BLUE: \033[0;34mThis should be blue\033[0m"
echo ""

echo "5. Testing read -k1 (press any key):"
echo -n "   Press a key: "
if read -k1 key 2>/dev/null; then
  echo ""
  echo "   You pressed: '$key'"
else
  echo ""
  echo "   ERROR: read -k1 failed"
fi
echo ""

echo "6. Testing read -q (press y or n):"
echo -n "   Press y or n: "
if read -q response 2>/dev/null; then
  echo ""
  echo "   Response: yes"
else
  echo ""
  echo "   Response: no (or error)"
fi
echo ""

echo "7. Testing simple read:"
echo -n "   Type something and press Enter: "
read line
echo "   You typed: '$line'"
echo ""

echo "8. Testing tput:"
if command -v tput &>/dev/null; then
  echo "   tput cols: $(tput cols)"
  echo "   tput lines: $(tput lines)"
else
  echo "   tput not available"
fi
echo ""

echo "=== Debug Complete ==="

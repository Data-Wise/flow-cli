#!/bin/bash
# Sync ZSH functions from ~/.config/zsh/ to create/update adapters

set -e

ZSH_CONFIG="$HOME/.config/zsh"
CLI_ADAPTERS="$(dirname "$0")/../cli/adapters"

echo "🔄 Syncing ZSH functions to CLI adapters..."

# Check if ZSH config exists
if [ ! -d "$ZSH_CONFIG" ]; then
    echo "❌ ZSH config not found at $ZSH_CONFIG"
    exit 1
fi

echo "✓ Found ZSH config at $ZSH_CONFIG"

# List all function files
echo ""
echo "📂 ZSH function files:"
find "$ZSH_CONFIG/functions" -name "*.zsh" -type f | while read -r file; do
    basename "$file"
done

echo ""
echo "ℹ️  Manual steps needed:"
echo "  1. Review functions in $ZSH_CONFIG/functions/"
echo "  2. Create adapters in $CLI_ADAPTERS/ for functions you want to expose"
echo "  3. Example adapter structure:"
echo ""
echo "     // adapters/workflow.js"
echo "     const { exec } = require('child_process');"
echo "     async function startWork(project) {"
echo "       return new Promise((resolve, reject) => {"
echo "         exec(\`zsh -c 'source ~/.zshrc && work \${project}'\`, ...);"
echo "       });"
echo "     }"
echo ""
echo "📝 See cli/README.md for full adapter development guide"

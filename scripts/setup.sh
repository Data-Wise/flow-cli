#!/bin/bash
# Setup script for ZSH Workflow Manager development environment

set -e  # Exit on error

echo "🚀 Setting up ZSH Workflow Manager..."

# Check for Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js first."
    exit 1
fi

echo "✓ Node.js found: $(node --version)"

# Check for npm
if ! command -v npm &> /dev/null; then
    echo "❌ npm not found. Please install npm first."
    exit 1
fi

echo "✓ npm found: $(npm --version)"

# Install root dependencies
echo "📦 Installing root dependencies..."
npm install

# Install app dependencies
echo "📦 Installing app dependencies..."
cd app && npm install && cd ..

# Install CLI dependencies (if package.json exists)
if [ -f "cli/package.json" ]; then
    echo "📦 Installing CLI dependencies..."
    cd cli && npm install && cd ..
fi

# Verify ZSH config location
if [ ! -d "$HOME/.config/zsh" ]; then
    echo "⚠️  Warning: ~/.config/zsh/ not found"
    echo "   The CLI integration layer expects ZSH config at ~/.config/zsh/"
else
    echo "✓ ZSH config found at ~/.config/zsh/"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Start app development: cd app && npm run dev"
echo "  2. Run tests: npm test"
echo "  3. View documentation: cat README.md"

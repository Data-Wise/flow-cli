#!/usr/bin/env zsh
# Test script for _dot_preview_add and _dot_suggest_ignore_patterns

# Source dependencies
source lib/core.zsh
source lib/dotfile-helpers.zsh

# Create a test directory with various file types
TEST_DIR="/tmp/dot-preview-test-$$"
mkdir -p "$TEST_DIR"

echo "Creating test files in $TEST_DIR..."

# Small file (< 50KB)
echo "Small config file" > "$TEST_DIR/config.yml"

# Large file (> 50KB)
dd if=/dev/zero of="$TEST_DIR/large-config.json" bs=1024 count=100 2>/dev/null

# Generated files
echo "Log entry 1" > "$TEST_DIR/app.log"
dd if=/dev/zero of="$TEST_DIR/vault.sqlite" bs=1024 count=200 2>/dev/null
echo "Cache data" > "$TEST_DIR/cache.db"

# Git metadata simulation
mkdir -p "$TEST_DIR/.git"
echo "git config" > "$TEST_DIR/.git/config"

# Normal files
echo "# README" > "$TEST_DIR/README.md"
echo "script content" > "$TEST_DIR/script.sh"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Test 1: Preview single small file"
echo "═══════════════════════════════════════════════════════════"
_dot_preview_add "$TEST_DIR/config.yml"
echo "Exit code: $?"
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "Test 2: Preview single large file"
echo "═══════════════════════════════════════════════════════════"
_dot_preview_add "$TEST_DIR/large-config.json"
echo "Exit code: $?"
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "Test 3: Preview generated file"
echo "═══════════════════════════════════════════════════════════"
_dot_preview_add "$TEST_DIR/vault.sqlite"
echo "Exit code: $?"
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "Test 4: Preview entire directory (mix of files)"
echo "═══════════════════════════════════════════════════════════"
_dot_preview_add "$TEST_DIR"
echo "Exit code: $?"
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "Test 5: Test _dot_suggest_ignore_patterns"
echo "═══════════════════════════════════════════════════════════"

# Create a test chezmoi directory
CHEZMOI_TEST_DIR="/tmp/chezmoi-test-$$"
mkdir -p "$CHEZMOI_TEST_DIR"
export HOME="/tmp/chezmoi-test-$$"  # Temporarily override HOME
mkdir -p "${HOME}/.local/share/chezmoi"

echo "Adding patterns: *.log *.sqlite *.cache"
_dot_suggest_ignore_patterns "*.log" "*.sqlite" "*.cache"
echo ""

echo "Contents of .chezmoiignore:"
cat "${HOME}/.local/share/chezmoi/.chezmoiignore"
echo ""

echo "Adding duplicate patterns (should skip):"
_dot_suggest_ignore_patterns "*.log" "*.db"
echo ""

echo "Final contents of .chezmoiignore:"
cat "${HOME}/.local/share/chezmoi/.chezmoiignore"
echo ""

# Cleanup
rm -rf "$TEST_DIR"
rm -rf "$CHEZMOI_TEST_DIR"

echo "═══════════════════════════════════════════════════════════"
echo "Tests complete!"
echo "═══════════════════════════════════════════════════════════"

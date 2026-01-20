#!/usr/bin/env bash
# ==============================================================================
# TEACH DOCTOR - Interactive Demo
# ==============================================================================
#
# Demonstrates the teach doctor command with various flags
#
# Usage:
#   ./tests/demo-teach-doctor.sh

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo "${BLUE}║  TEACH DOCTOR - Interactive Demo                           ║${NC}"
echo "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Load flow-cli
source flow.plugin.zsh

echo "${YELLOW}Demo 1: Basic Health Check${NC}"
echo "Command: teach doctor"
echo ""
teach doctor
echo ""

echo "────────────────────────────────────────────────────────────"
echo ""

echo "${YELLOW}Demo 2: Quiet Mode (only problems)${NC}"
echo "Command: teach doctor --quiet"
echo ""
teach doctor --quiet
echo ""

echo "────────────────────────────────────────────────────────────"
echo ""

echo "${YELLOW}Demo 3: JSON Output (for CI/CD)${NC}"
echo "Command: teach doctor --json | jq '.summary'"
echo ""
teach doctor --json | jq '.summary' 2>/dev/null || teach doctor --json | grep -A 5 '"summary"'
echo ""

echo "────────────────────────────────────────────────────────────"
echo ""

echo "${YELLOW}Demo 4: Help${NC}"
echo "Command: teach doctor --help"
echo ""
teach doctor --help
echo ""

echo "────────────────────────────────────────────────────────────"
echo ""

echo "${GREEN}Interactive Fix Mode Demo${NC}"
echo ""
echo "To test interactive fix mode, run:"
echo "  ${BLUE}teach doctor --fix${NC}"
echo ""
echo "This will:"
echo "  • Detect missing dependencies"
echo "  • Prompt for installation: [Y/n]"
echo "  • Execute install commands"
echo "  • Re-verify installation"
echo ""
echo "Example interaction:"
echo "  ${YELLOW}✗${NC} yq not found"
echo "  ${BLUE}→${NC} Install yq? [Y/n] ${GREEN}y${NC}"
echo "  ${BLUE}→${NC} brew install yq"
echo "  ${GREEN}✓${NC} yq installed"
echo ""

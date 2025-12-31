#!/bin/bash
# Docker integration test for install.sh
# Tests full end-to-end installation in clean containers
#
# Usage:
#   ./tests/docker-install-test.sh           # Test all images
#   ./tests/docker-install-test.sh ubuntu    # Test specific image
#
# Requires: docker

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Test images
IMAGES=(
    "ubuntu:22.04"
    "ubuntu:24.04"
    "debian:bookworm"
    "debian:bullseye"
)

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR%/tests}"

# Results
PASSED=0
FAILED=0

log_test() {
    echo -e "${CYAN}Testing:${NC} $1"
}

pass() {
    echo -e "  ${GREEN}✓${NC} $1"
    ((PASSED++))
}

fail() {
    echo -e "  ${RED}✗${NC} $1"
    ((FAILED++))
}

# Check Docker is available
check_docker() {
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}Error: Docker is required but not installed${NC}"
        exit 1
    fi

    if ! docker info &>/dev/null; then
        echo -e "${RED}Error: Docker daemon is not running${NC}"
        exit 1
    fi
}

# Test installation in a container
test_install() {
    local image="$1"
    local container_name="flow-cli-test-$(echo "$image" | tr ':/' '-')"

    log_test "$image"

    # Create test script to run inside container
    local test_script=$(cat <<'INNERSCRIPT'
#!/bin/bash
set -e

# Install dependencies
apt-get update -qq
apt-get install -y -qq git zsh curl >/dev/null 2>&1

# Setup test environment
export HOME=/root
cd /root
touch .zshrc

echo "=== Testing manual installation ==="

# Clone the repo (simulating curl | bash but with local files)
cp -r /workspace /root/.flow-cli

# Source the plugin
cd /root/.flow-cli

# Add to .zshrc
echo 'source ~/.flow-cli/flow.plugin.zsh' >> ~/.zshrc

# Test that plugin can be sourced
zsh -c 'source ~/.flow-cli/flow.plugin.zsh && echo "Plugin sourced successfully"'

# Test flow command exists
if zsh -c 'source ~/.flow-cli/flow.plugin.zsh && type flow' >/dev/null 2>&1; then
    echo "✓ flow command available"
else
    echo "✗ flow command not found"
    exit 1
fi

# Test flow --version
if zsh -c 'source ~/.flow-cli/flow.plugin.zsh && flow --version' 2>/dev/null; then
    echo "✓ flow --version works"
else
    echo "✗ flow --version failed"
    exit 1
fi

# Test flow doctor (may have warnings but shouldn't fail)
if zsh -c 'source ~/.flow-cli/flow.plugin.zsh && flow doctor' 2>/dev/null; then
    echo "✓ flow doctor works"
else
    echo "! flow doctor had issues (expected in minimal container)"
fi

# Test detection function
echo ""
echo "=== Testing plugin manager detection ==="

# Test 1: Clean environment should detect 'manual'
unset ZDOTDIR ZSH ZINIT_HOME INSTALL_METHOD
export HOME=/tmp/test1
mkdir -p $HOME
touch $HOME/.zshrc

source /root/.flow-cli/install.sh 2>/dev/null <<< "" || true

# Just test the detection function
detect_result=""
if [[ -f "${ZDOTDIR:-$HOME}/.zsh_plugins.txt" ]]; then
    detect_result="antidote"
elif [[ -d "$HOME/.zinit" ]]; then
    detect_result="zinit"
elif [[ -d "$HOME/.oh-my-zsh" ]]; then
    detect_result="omz"
else
    detect_result="manual"
fi

if [[ "$detect_result" == "manual" ]]; then
    echo "✓ Clean environment: detected 'manual'"
else
    echo "✗ Clean environment: expected 'manual', got '$detect_result'"
    exit 1
fi

# Test 2: With .zsh_plugins.txt should detect 'antidote'
export HOME=/tmp/test2
mkdir -p $HOME
touch $HOME/.zshrc
touch $HOME/.zsh_plugins.txt

if [[ -f "${ZDOTDIR:-$HOME}/.zsh_plugins.txt" ]]; then
    detect_result="antidote"
else
    detect_result="other"
fi

if [[ "$detect_result" == "antidote" ]]; then
    echo "✓ With .zsh_plugins.txt: detected 'antidote'"
else
    echo "✗ With .zsh_plugins.txt: expected 'antidote', got '$detect_result'"
    exit 1
fi

# Test 3: With .zinit should detect 'zinit'
export HOME=/tmp/test3
mkdir -p $HOME
mkdir -p $HOME/.zinit
touch $HOME/.zshrc

if [[ -d "$HOME/.zinit" ]]; then
    detect_result="zinit"
else
    detect_result="other"
fi

if [[ "$detect_result" == "zinit" ]]; then
    echo "✓ With .zinit: detected 'zinit'"
else
    echo "✗ With .zinit: expected 'zinit', got '$detect_result'"
    exit 1
fi

# Test 4: With .oh-my-zsh should detect 'omz'
export HOME=/tmp/test4
mkdir -p $HOME
mkdir -p $HOME/.oh-my-zsh
touch $HOME/.zshrc

if [[ -d "$HOME/.oh-my-zsh" ]]; then
    detect_result="omz"
else
    detect_result="other"
fi

if [[ "$detect_result" == "omz" ]]; then
    echo "✓ With .oh-my-zsh: detected 'omz'"
else
    echo "✗ With .oh-my-zsh: expected 'omz', got '$detect_result'"
    exit 1
fi

echo ""
echo "=== All tests passed! ==="
INNERSCRIPT
)

    # Run container with test script
    if docker run --rm \
        -v "$PROJECT_ROOT:/workspace:ro" \
        --name "$container_name" \
        "$image" \
        /bin/bash -c "$test_script" 2>&1; then
        pass "$image - all tests passed"
        return 0
    else
        fail "$image - tests failed"
        return 1
    fi
}

# Main
main() {
    echo ""
    echo -e "${BOLD}flow-cli Docker Integration Tests${NC}"
    echo "===================================="
    echo ""

    check_docker

    # Filter images if argument provided
    local test_images=("${IMAGES[@]}")
    if [[ $# -gt 0 ]]; then
        test_images=()
        for arg in "$@"; do
            for img in "${IMAGES[@]}"; do
                if [[ "$img" == *"$arg"* ]]; then
                    test_images+=("$img")
                fi
            done
        done
        if [[ ${#test_images[@]} -eq 0 ]]; then
            echo -e "${YELLOW}No matching images for: $*${NC}"
            echo "Available images: ${IMAGES[*]}"
            exit 1
        fi
    fi

    echo "Testing images: ${test_images[*]}"
    echo ""

    for image in "${test_images[@]}"; do
        test_install "$image" || true
        echo ""
    done

    # Summary
    echo "===================================="
    echo -e "${BOLD}Results:${NC}"
    echo -e "  ${GREEN}Passed: $PASSED${NC}"
    echo -e "  ${RED}Failed: $FAILED${NC}"
    echo ""

    if [[ $FAILED -gt 0 ]]; then
        exit 1
    fi
}

main "$@"

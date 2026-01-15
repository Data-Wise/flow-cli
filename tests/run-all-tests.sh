#!/bin/bash
# run-all-tests.sh - Run all prompt dispatcher test suites

set -e

echo "======================================================================"
echo " PROMPT DISPATCHER - COMPREHENSIVE TEST SUITE"
echo "======================================================================"
echo

echo "[1/4] Running Original Combined Tests..."
zsh tests/test-prompt-dispatcher.zsh 2>&1 | grep -E "Total|Passed|Failed|✓ All"
echo

echo "[2/4] Running Unit Tests (80 tests)..."
zsh tests/test-prompt-unit.zsh 2>&1 | tail -5
echo

echo "[3/4] Running Validation Tests (29 tests)..."
zsh tests/test-prompt-validation.zsh 2>&1 | tail -5
echo

echo "[4/4] Running E2E Integration Tests (40 tests)..."
zsh tests/test-prompt-e2e.zsh 2>&1 | tail -5
echo

echo "[5/5] Running Dry-Run Mode Tests (28 tests)..."
zsh tests/test-prompt-dry-run.zsh 2>&1 | tail -5
echo

echo "======================================================================"
echo " TEST SUMMARY"
echo "======================================================================"
echo
echo "Test Suites:"
echo "  • tests/test-prompt-dispatcher.zsh     (47 combined tests)"
echo "  • tests/test-prompt-unit.zsh           (80 unit tests)"
echo "  • tests/test-prompt-validation.zsh     (29 validation tests)"
echo "  • tests/test-prompt-e2e.zsh            (40 e2e integration tests)"
echo "  • tests/test-prompt-dry-run.zsh        (28 dry-run mode tests)"
echo
echo "Total Test Count: 224+ tests across all suites"
echo
echo "Notes:"
echo "  • Validation tests may vary based on local installation"
echo "  • E2E tests validate full workflows and data consistency"
echo "  • Unit tests isolate core functionality"
echo

#!/bin/bash
# MIT License
# Copyright (c) 2025 dbjwhs

# Script to install Git hooks for the Jenkins repository

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$SCRIPT_DIR/.githooks"
GIT_HOOKS_DIR="$SCRIPT_DIR/.git/hooks"

echo "🔧 Setting up Git hooks for Jenkins repository..."
echo ""

# Check if we're in a Git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not in a Git repository"
    exit 1
fi

# Create Git hooks directory if it doesn't exist
mkdir -p "$GIT_HOOKS_DIR"

# Install pre-commit hook
echo "📦 Installing pre-commit hook..."
if [ -f "$HOOKS_DIR/pre-commit" ]; then
    cp "$HOOKS_DIR/pre-commit" "$GIT_HOOKS_DIR/pre-commit"
    chmod +x "$GIT_HOOKS_DIR/pre-commit"
    echo "✅ Pre-commit hook installed"
else
    echo "❌ Error: Pre-commit hook not found at $HOOKS_DIR/pre-commit"
    exit 1
fi

# Test the EOF newline checker
echo ""
echo "🧪 Testing EOF newline checker..."
if python3 tools/check_eof_newline.py --check --quiet; then
    echo "✅ EOF newline checker is working"
else
    echo "⚠️  Some files need EOF newline fixes"
    echo ""
    echo "To fix all files now:"
    echo "  python3 tools/check_eof_newline.py --fix --backup"
    echo "  git add -u"
fi

echo ""
echo "🎉 Git hooks setup complete!"
echo ""
echo "The pre-commit hook will now:"
echo "  • Check staged files for proper EOF newlines"
echo "  • Prevent commits if files are missing EOF newlines"
echo "  • Provide fix suggestions"
echo ""
echo "To run the EOF checker manually:"
echo "  python3 tools/check_eof_newline.py --check          # Check all files"
echo "  python3 tools/check_eof_newline.py --fix --backup  # Fix with backup"

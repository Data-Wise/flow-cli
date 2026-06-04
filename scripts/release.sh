#!/bin/bash
# release.sh - Automate version bumping and release
# Usage: ./scripts/release.sh <version>
# Example: ./scripts/release.sh 3.6.3

set -e

VERSION="$1"

if [[ -z "$VERSION" ]]; then
    echo "Usage: ./scripts/release.sh <version>"
    echo "Example: ./scripts/release.sh 3.6.3"
    exit 1
fi

# Validate version format
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be in format X.Y.Z (e.g., 3.6.3)"
    exit 1
fi

echo "🚀 Releasing v$VERSION"
echo ""

# 1. Update package.json
echo "📦 Updating package.json..."
sed -i '' "s/\"version\": \"[^\"]*\"/\"version\": \"$VERSION\"/" package.json

# 2. Update README badge
echo "🏷️  Updating README badge..."
sed -i '' "s/version-[0-9]*\.[0-9]*\.[0-9]*/version-$VERSION/" README.md
sed -i '' "s/releases\/tag\/v[0-9]*\.[0-9]*\.[0-9]*/releases\/tag\/v$VERSION/" README.md

# 3. Update CLAUDE.md
echo "📝 Updating CLAUDE.md..."
sed -i '' "s/v[0-9]*\.[0-9]*\.[0-9]*/v$VERSION/g" CLAUDE.md

# 4. Update flow.plugin.zsh
echo "🔌 Updating flow.plugin.zsh..."
sed -i '' "s/FLOW_VERSION=\"[^\"]*\"/FLOW_VERSION=\"$VERSION\"/" flow.plugin.zsh

# 4b. Update man-page .TH version lines (anti-drift backstop for the CI guard)
echo "📚 Updating man pages (man/man1/*.1)..."
for _man in man/man1/*.1; do
    [[ -f "$_man" ]] || continue
    # Only rewrite flow-cli pages; leave vendored pages (e.g. scribe.1) alone.
    sed -i '' "s/\"flow-cli [0-9]*\.[0-9]*\.[0-9]*\"/\"flow-cli $VERSION\"/" "$_man"
done

# 5. Update CC-DISPATCHER-REFERENCE.md (archived)
echo "📖 Updating CC-DISPATCHER-REFERENCE.md..."
if [[ -f "docs/reference/.archive/CC-DISPATCHER-REFERENCE.md" ]]; then
    sed -i '' "s/Version: v[0-9]*\.[0-9]*\.[0-9]*/Version: v$VERSION/" docs/reference/.archive/CC-DISPATCHER-REFERENCE.md
fi

# Show changes
echo ""
echo "📋 Changes made:"
git diff --stat

echo ""
echo "✅ Version files updated to v$VERSION"
echo ""
echo "Next steps:"
echo "  1. Review changes: git diff"
echo "  2. Commit: git add -A && git commit -m 'chore: bump version to $VERSION'"
echo "  3. Tag: git tag -a v$VERSION -m 'v$VERSION'"
echo "  4. Push: git push origin main && git push origin v$VERSION"

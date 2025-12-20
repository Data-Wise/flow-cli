#!/bin/bash
# Sync standards from zsh-configuration to all PM hubs
# Created: 2025-12-19

set -e

SOURCE="$HOME/projects/dev-tools/zsh-configuration/standards"
VERSION_FILE="$SOURCE/.version"

# Destination hubs
DESTINATIONS=(
    "$HOME/projects/project-hub"
    "$HOME/projects/r-packages/mediation-planning"
    "$HOME/projects/dev-tools/dev-planning"
)

# Get current version (date-based)
CURRENT_VERSION=$(date +%Y-%m-%d)

echo "🔄 Syncing standards from zsh-configuration..."
echo "📦 Source: $SOURCE"
echo "📅 Version: $CURRENT_VERSION"
echo ""

# Update version file in source
echo "$CURRENT_VERSION" > "$VERSION_FILE"

# Sync to each destination
for dest in "${DESTINATIONS[@]}"; do
    if [ ! -d "$dest" ]; then
        echo "⚠️  Skipping $dest (not found)"
        continue
    fi

    echo "📂 Syncing to: $dest"

    # Create standards dir if needed
    mkdir -p "$dest/standards"

    # Rsync with delete (removes old files)
    rsync -av --delete \
        "$SOURCE/" \
        "$dest/standards/"

    # Write version file
    echo "$CURRENT_VERSION" > "$dest/standards/.version"

    echo "✅ Synced $(basename $dest)"
    echo ""
done

echo "🎉 All hubs synced to version $CURRENT_VERSION"
echo ""
echo "📝 Next steps:"
echo "  1. Review changes in each hub"
echo "  2. Commit to git if needed"
echo "  3. Update .planning/NOW.md if major changes"

# Vendored from zsh-claude-workflow

**Source:** https://github.com/Data-Wise/zsh-claude-workflow
**Version:** 1.5.0
**License:** MIT
**Vendored:** 2025-12-20

## Files Included

- `project-detector.sh` - Project type detection (8+ types)
- `core.sh` - Shared utilities (path handling, cloud detection)

## Why Vendored

These functions are copied (vendored) to make flow-cli independently installable via npm without requiring users to install zsh-claude-workflow separately.

## Attribution

Original work by DT as part of zsh-claude-workflow.
Licensed under MIT. See LICENSE file.

## Sync Process

To update vendored code from upstream:

```bash
cp ~/projects/dev-tools/zsh-claude-workflow/lib/project-detector.sh \
   cli/vendor/zsh-claude-workflow/

cp ~/projects/dev-tools/zsh-claude-workflow/lib/core.sh \
   cli/vendor/zsh-claude-workflow/
```

Check for updates periodically, especially if:
- New project types added
- Bug fixes in detection logic
- Performance improvements

**Recommended sync frequency:** Quarterly (every 3 months) or when needed

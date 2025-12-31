# awesome-zsh-plugins Entry

Add to the **Plugins** section (alphabetically under "f"):

## Entry

```markdown
- [flow-cli](https://github.com/Data-Wise/flow-cli) - ADHD-optimized workflow tools with session tracking, win logging, and smart dispatchers for Claude Code, R, Quarto, and Git.
```

## How to Submit

1. Fork [unixorn/awesome-zsh-plugins](https://github.com/unixorn/awesome-zsh-plugins)
2. Edit `README.md`
3. Find the Plugins section, locate the "f" entries
4. Add the entry above (maintaining alphabetical order)
5. Submit a PR

## Alternative: CLI Submission

```bash
# Fork and clone
gh repo fork unixorn/awesome-zsh-plugins --clone
cd awesome-zsh-plugins

# Create branch
git checkout -b add-flow-cli

# Edit README.md to add the entry
# (manually or with sed)

# Commit and push
git add README.md
git commit -m "Add flow-cli - ADHD workflow tools"
git push origin add-flow-cli

# Create PR
gh pr create --title "Add flow-cli" --body "Adds flow-cli - ZSH workflow tools designed for ADHD brains.

Features:
- Session tracking with \`work\` / \`finish\`
- Win logging with dopamine feedback
- Smart dispatchers for Claude Code, R, Quarto, Git
- Sub-10ms response time

https://github.com/Data-Wise/flow-cli"
```

## Category

The plugin fits in:
- **Plugins** (main listing)
- Possibly also under **Productivity** if that section exists

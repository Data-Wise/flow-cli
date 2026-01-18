# Scholar Enhancement Tutorial GIF Demos

This directory contains VHS tape files for generating GIF demonstrations used in the Scholar Enhancement tutorials.

## Prerequisites

Install VHS (terminal recorder):

```bash
brew install vhs
```

## Generating GIFs

### Generate All Demos

```bash
# From this directory
for tape in scholar-*.tape; do
  vhs "$tape"
done
```

### Generate Individual Demo

```bash
vhs scholar-01-help.tape
vhs scholar-02-generate.tape
vhs scholar-03-customize.tape
vhs scholar-04-lesson-plan.tape
vhs scholar-05-week-based.tape
vhs scholar-06-interactive.tape
vhs scholar-07-revision.tape
vhs scholar-08-context.tape
```

## Demo Files

| Tape File | Output GIF | Tutorial | Topic |
|-----------|------------|----------|-------|
| `scholar-01-help.tape` | `scholar-01-help.gif` | Level 1, Step 2 | Help System |
| `scholar-02-generate.tape` | `scholar-02-generate.gif` | Level 1, Step 3 | Generate First Slides |
| `scholar-03-customize.tape` | `scholar-03-customize.gif` | Level 1, Step 5 | Customize with Flags |
| `scholar-04-lesson-plan.tape` | `scholar-04-lesson-plan.gif` | Level 2, Step 2 | Create Lesson Plan |
| `scholar-05-week-based.tape` | `scholar-05-week-based.gif` | Level 2, Step 3 | Week-Based Generation |
| `scholar-06-interactive.tape` | `scholar-06-interactive.gif` | Level 2, Step 8 | Interactive Mode |
| `scholar-07-revision.tape` | `scholar-07-revision.gif` | Level 3, Step 2 | Revision Workflow |
| `scholar-08-context.tape` | `scholar-08-context.gif` | Level 3, Step 8 | Context Integration |

## Tutorial References

These GIFs are embedded in:

- `docs/tutorials/scholar-enhancement/01-getting-started.md` (3 GIFs)
- `docs/tutorials/scholar-enhancement/02-intermediate.md` (3 GIFs)
- `docs/tutorials/scholar-enhancement/03-advanced.md` (2 GIFs)

## Customizing Demos

Edit the `.tape` files to customize:

- **Terminal theme:** `Set Theme "Catppuccin Mocha"`
- **Dimensions:** `Set Width 1200` / `Set Height 800`
- **Font size:** `Set FontSize 16`
- **Timing:** `Sleep 2s` (adjust delays)

## Notes

- The tapes simulate Scholar command execution with text output
- Real Scholar commands require Claude Code and the Scholar plugin
- GIF files are generated in the same directory as the tape files
- Generated GIFs should be committed to the repository

## Regenerating After Updates

If tutorials change, update the corresponding `.tape` file and regenerate:

```bash
# Edit tape file
vim scholar-01-help.tape

# Regenerate GIF
vhs scholar-01-help.tape

# Commit changes
git add scholar-01-help.tape scholar-01-help.gif
git commit -m "docs: update help demo GIF"
```

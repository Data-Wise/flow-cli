---
tags:
  - tutorial
  - teaching
---

# Tutorial 28: Managing AI Teaching Prompts

> Learn to customize how Scholar generates content for your courses.

## What You'll Learn

- List and explore available teaching prompts
- Create course-specific prompt overrides
- Validate prompts for correctness
- Export rendered prompts for debugging

## Prerequisites

- flow-cli v5.23.0+
- A teaching project (`teach init` completed)
- Familiarity with `teach` dispatcher basics

## Step 1: See What's Available

List all prompts across all tiers:

```bash
teach prompt list
```

Output:

```
Available Teaching Prompts
─────────────────────────────────────────

  lecture-notes          [P]  AI prompt for generating comprehensive lecture notes
  revealjs-slides        [P]  RevealJS Presentation Generator
  derivations-appendix   [P]  Mathematical Derivations Appendix

Legend: [C] Course  [U] User  [P] Plugin  * = overrides lower tier
```

The `[P]` indicator means these come from the plugin defaults. You can customize any of them.

## Step 2: View a Prompt

See what a prompt contains:

```bash
teach prompt show lecture-notes
```

This opens the prompt in your `$PAGER` (usually `less`). You'll see the YAML frontmatter with metadata, followed by the prompt body with `{{VARIABLE}}` placeholders.

For quick output without a pager:

```bash
teach prompt show lecture-notes --raw
```

## Step 3: Create a Course Override

The real power is customization. Say you want to modify how lecture notes are generated for your specific course:

```bash
teach prompt edit lecture-notes
```

This:

1. Copies the plugin default to `.flow/templates/prompts/lecture-notes.md`
2. Opens it in your `$EDITOR`

Now edit the prompt to match your course style. For example, add your preferred notation conventions, emphasize certain pedagogical approaches, or adjust the structure.

After saving, verify the override:

```bash
teach prompt list
```

```
  lecture-notes          [C*] AI prompt for generating comprehensive lecture notes
```

The `[C*]` means it's now a **Course** override, and the `*` indicates it shadows the plugin default.

## Step 4: Validate Your Prompts

Check that all prompts are syntactically correct:

```bash
teach prompt validate
```

```
Validating Teaching Prompts...

  ✓ lecture-notes          Valid (course override)
  ✓ revealjs-slides        Valid (plugin default)
  ✓ derivations-appendix   Valid (plugin default)

3 valid, 0 warnings, 0 errors
```

For stricter checking (treats warnings as errors):

```bash
teach prompt validate --strict
```

## Step 5: Export Rendered Output

See what a prompt looks like after variable substitution:

```bash
teach prompt export lecture-notes
```

This reads your `teach-config.yml` for variable values like `{{COURSE}}`, `{{INSTRUCTOR}}`, and `{{SEMESTER}}`, then renders the prompt with those values filled in.

Include LaTeX macros:

```bash
teach prompt export lecture-notes --macros
```

Export as JSON (useful for debugging Scholar integration):

```bash
teach prompt export lecture-notes --json
```

## Step 6: Understand Auto-Resolution

When you run Scholar commands like:

```bash
teach lecture "ANOVA"
```

The system automatically:

1. Looks for a prompt matching the command name (`lecture` -> `lecture-notes`)
2. Resolves it through the 3-tier system (your override first)
3. Renders variables (COURSE, TOPIC="ANOVA", MACROS, etc.)
4. Passes the rendered prompt to Scholar

You don't need to do anything special - prompts "just work" once configured.

## Understanding the 3-Tier System

```
Priority 1: Course (.flow/templates/prompts/)
  → Your course-specific customizations
  → Created via: teach prompt edit <name>

Priority 2: User (~/.flow/prompts/)
  → Your personal defaults across all courses
  → Created via: teach prompt edit <name> --global

Priority 3: Plugin (lib/templates/teaching/claude-prompts/)
  → Built-in defaults
  → Updated when flow-cli updates
```

First match wins. This means:

- A course override always takes priority
- User defaults apply to all courses without overrides
- Plugin defaults are the fallback

## Tips

- **Start with plugin defaults.** Only override when you need course-specific behavior.
- **Use `--raw`** with `show` for piping to other commands.
- **Validate after editing** to catch YAML frontmatter errors.
- **Variables are UPPERCASE_UNDERSCORE** format only (e.g., `{{COURSE}}`, `{{TOPIC}}`).

## Quick Reference

```bash
teach pr ls              # List all prompts
teach pr cat exam        # View exam prompt
teach pr ed exam         # Override exam prompt
teach pr val             # Validate all
teach pr x exam          # Render with variables
```

## Next Steps

- Explore `teach macros` to manage LaTeX macros used in prompts
- See `teach templates` for content templates
- Read the [REFCARD-PROMPTS.md](../reference/REFCARD-PROMPTS.md) for complete flag reference
- See how prompts integrate with Scholar wrappers: [Scholar Wrappers Guide](../guides/SCHOLAR-WRAPPERS-GUIDE.md)
- Full config reference: [Config Schema](../reference/TEACH-CONFIG-SCHEMA.md)

---

*v5.23.0 - teach prompt command*

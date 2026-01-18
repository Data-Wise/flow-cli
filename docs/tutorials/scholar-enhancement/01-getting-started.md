# Getting Started with Scholar Enhancement

**Duration:** ~10 minutes
**Level:** Beginner
**Prerequisites:** flow-cli v5.13.0+, Claude Code

---

## Overview

Learn how to use the Scholar Enhancement to generate teaching materials with AI. This tutorial covers the basics: style presets, content flags, and your first AI-generated slides.

### What You'll Learn

- ✅ Verify Scholar Enhancement is available
- ✅ Generate slides with a style preset
- ✅ Customize content with flags
- ✅ View help and available options

**Total Steps:** 7 (3 interactive)

---

## Step 1: Introduction

The Scholar Enhancement adds AI-powered content generation to the teach dispatcher. Instead of manually creating slides, exams, or assignments, you describe what you want and Scholar generates it using Claude.

**Key Concepts:**
- **Style Presets**: 4 predefined content styles (conceptual, computational, rigorous, applied)
- **Content Flags**: 9 flags to add/remove specific content types
- **Scholar Commands**: slides, exam, quiz, lecture, assignment, etc.

---

## Step 2: Verify Installation

Let's check that Scholar Enhancement is available.

```bash
teach slides --help
```

**Expected Output:**
You should see a help message with a "Universal Flags" section listing style presets and content flags.

![Check Installation](../../demos/tutorials/scholar-01-help.gif)

**Troubleshooting:**
- If you don't see "Universal Flags", you may be on an older version
- Upgrade: `git pull && source flow.plugin.zsh`

---

## Step 3: Your First AI-Generated Slides

Let's generate slides for "Linear Regression" using the computational style.

```bash
teach slides "Linear Regression" --style computational
```

**What happens:**
1. Scholar validates the command
2. Sends prompt to Claude Code
3. Generates slides with:
   - Conceptual explanations
   - Numerical examples
   - Code snippets (R/Python)
   - Practice problems

**Wait Time:** 30-60 seconds (Claude Code processing)

![Generate Slides](../../demos/tutorials/scholar-02-generate.gif)

**Success Indicators:**
- ✅ "Generating slides..." message
- ✅ File created in current directory
- ✅ No error messages

---

## Step 4: Understanding Style Presets

The Scholar Enhancement provides 4 style presets:

| Preset | Includes | Best For |
|--------|----------|----------|
| `conceptual` | explanation, definitions, examples | Introductory courses |
| `computational` | explanation, examples, code, practice | Applied courses, data science |
| `rigorous` | definitions, explanation, math, proof | Graduate courses, theory |
| `applied` | explanation, examples, code, practice | Hands-on workshops |

**Try Different Styles:**

```bash
# Conceptual style (theory-focused)
teach slides "Probability Theory" --style conceptual

# Rigorous style (math-heavy)
teach exam "Hypothesis Testing" --style rigorous
```

Each preset automatically includes the appropriate content types for that teaching style.

---

## Step 5: Customizing with Content Flags

You can override presets by adding or removing content types.

**Add Content:**
```bash
# Add diagrams to computational preset
teach slides "ANOVA" --style computational --diagrams

# Add references to conceptual preset
teach lecture "Statistics History" --style conceptual --references
```

**Remove Content:**
```bash
# Rigorous without proofs
teach exam "Regression" --style rigorous --no-proof

# Computational without practice problems
teach slides "Topic" --style computational --no-practice-problems
```

![Customize Content](../../demos/tutorials/scholar-03-customize.gif)

**9 Content Flags:**
- `--explanation` / `-e` - Conceptual explanations
- `--definitions` - Formal definitions
- `--proof` - Mathematical proofs
- `--math` / `-m` - Mathematical notation
- `--examples` / `-x` - Numerical examples
- `--code` / `-c` - Code snippets
- `--diagrams` / `-d` - Visualizations
- `--practice-problems` / `-p` - Practice problems
- `--references` / `-r` - Citations

Each flag has a `--no-` version to exclude content.

---

## Step 6: Getting Help

View detailed help for any Scholar command:

```bash
# Slides-specific help
teach slides help

# Exam-specific help
teach exam help

# General teach help
teach help
```

The help system shows:
- Universal flags (work with all commands)
- Command-specific options
- Usage examples
- Short form aliases

**Pro Tip:** Use tab completion to explore flags:
```bash
teach slides --[TAB]
# Shows all available flags
```

---

## Step 7: Next Steps

Congratulations! You've learned the basics of Scholar Enhancement.

**What You Mastered:**
- ✅ Generating content with style presets
- ✅ Customizing with content flags
- ✅ Using help system

**Continue Learning:**

**→ [Intermediate Tutorial](02-intermediate.md)** - Learn lesson plans and interactive mode
- Week-based generation with YAML lesson plans
- Interactive wizards for step-by-step content creation
- Context-aware generation

**→ [Advanced Tutorial](03-advanced.md)** - Master revision and complex workflows
- Revision workflow (6 improvement options)
- Context integration
- Complex flag combinations

**Quick Reference:**
- [API Reference](../../reference/SCHOLAR-ENHANCEMENT-API.md)
- [Architecture Guide](../../architecture/SCHOLAR-ENHANCEMENT-ARCHITECTURE.md)

---

## Common Issues

**Issue:** "Invalid style preset" error
```
Solution: Use one of: conceptual, computational, rigorous, applied
```

**Issue:** "Conflicting flags" error
```
Solution: Don't use both --flag and --no-flag
Example: --math --no-math ❌
Correct: --math ✓ or --no-math ✓
```

**Issue:** Scholar takes a long time
```
This is normal! Claude Code processing can take 30-60 seconds.
```

---

## Summary

In this tutorial, you learned:

1. ✅ **Verify** - Check Scholar Enhancement is available
2. ✅ **Generate** - Create slides with style presets
3. ✅ **Customize** - Add/remove content with flags
4. ✅ **Help** - Access documentation

**Time to Productivity:** ~10 minutes
**Commands Learned:** 3 (slides, help, with flags)
**Ready For:** Intermediate tutorial

---

**Navigation:**
- ← [Tutorial Overview](../index.md)
- → [Intermediate: Lesson Plans & Interactive Mode](02-intermediate.md)
- ↑ [Documentation Home](../../index.md)

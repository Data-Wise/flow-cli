# Implementation Instructions

## Branch: feature/teaching-prompts

### What This PR Adds

1. **`lib/templates/teaching/claude-prompts/`** - New directory for Claude Code prompts
2. **`lecture-notes.md`** - Prompt for 20-40 page lecture documents
3. **`revealjs-slides.md`** - Prompt for 25+ slide presentations
4. **`derivations-appendix.md`** - Prompt for mathematical theory appendices
5. **`README.md`** - Documentation for the prompts

### Testing

1. **Verify files are in place:**

   ```bash
   ls -la lib/templates/teaching/claude-prompts/
   ```

2. **Test prompt content validity:**
   - Each prompt should be valid Markdown
   - Code blocks should have proper syntax highlighting
   - Tables should render correctly

3. **Integration test with teach dispatcher:**

   ```bash
   # Verify teach init includes new templates
   flow teach init --dry-run
   ```

### Usage

These prompts are used in two ways:

1. **With Scholar Plugin:**

   ```bash
   /teaching:lecture "Topic"   # Uses lecture-notes.md structure
   /teaching:slides "Topic"    # Uses revealjs-slides.md structure
   ```

2. **Standalone Reference:**

   ```
   Claude, create lecture notes following the structure in
   lib/templates/teaching/claude-prompts/lecture-notes.md
   ```

### Integration Points

1. **teach-dispatcher.zsh:**
   - Could add `teach prompt lecture` command to display prompt
   - Could add `teach validate-prompt` to check course compliance

2. **ai-recipes.zsh:**
   - Could add `[teach-lecture]`, `[teach-slides]` recipes
   - Would reference these prompts

3. **Scholar Plugin:**
   - Prompts complement Scholar's teaching style system
   - Users configure `.claude/teaching-style.local.md` for customization

### Future Work

After this PR is merged, consider:

1. **Additional prompts:**
   - `assignment.md` - Homework/project assignments
   - `exam.md` - Exam generation
   - `syllabus.md` - Course syllabus
   - `rubric.md` - Grading rubrics

2. **teach-dispatcher integration:**

   ```bash
   flow teach prompt lecture     # Display lecture prompt
   flow teach prompt slides      # Display slides prompt
   flow teach prompt list        # List available prompts
   ```

3. **Validation command:**

   ```bash
   flow teach validate-style     # Validate teaching-style.local.md
   ```

4. **Template customization:**
   - Allow `teach init` to copy prompts to course
   - Support course-specific prompt overrides

### Merge Checklist

- [ ] All prompts are valid Markdown
- [ ] README accurately describes usage
- [ ] No conflicts with existing templates
- [ ] Compatible with Scholar plugin

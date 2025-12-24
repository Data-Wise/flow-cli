# Architecture Decision Records (ADR) Process Guide

**How to document architectural decisions in flow-cli**

**Last Updated:** 2025-12-24
**Target Audience:** Contributors and maintainers making architectural decisions

---

## Table of Contents

- [What is an ADR?](#what-is-an-adr)
- [When to Write an ADR](#when-to-write-an-adr)
- [ADR Template](#adr-template)
- [Writing Process](#writing-process)
- [Review and Approval](#review-and-approval)
- [Updating ADRs](#updating-adrs)
- [Examples](#examples)

---

## What is an ADR?

**Architecture Decision Record (ADR)** - A document that captures an important architectural decision along with its context and consequences.

### Why ADRs?

**Benefits:**

1. **Historical context** - Future developers understand _why_ decisions were made
2. **Prevent revisiting** - Avoid rehashing the same discussions
3. **Team alignment** - Ensure everyone understands architectural direction
4. **Onboarding tool** - New contributors learn architecture philosophy
5. **Knowledge preservation** - Decisions survive team changes

**What ADRs are NOT:**

- ❌ Not for every small decision
- ❌ Not implementation details
- ❌ Not feature specifications
- ❌ Not bug reports

---

## When to Write an ADR

### Write an ADR for:

✅ **Architecture patterns**

- Choosing Clean Architecture over MVC
- Deciding on event sourcing
- Selecting module API over REST API

✅ **Technology choices**

- Choosing Node.js over Python
- Selecting SQLite over PostgreSQL
- Picking Jest over Mocha

✅ **Design principles**

- Vendoring code vs npm dependencies
- Monorepo vs multi-repo structure
- Synchronous vs asynchronous API

✅ **Significant trade-offs**

- Performance vs simplicity
- Flexibility vs constraints
- Developer experience vs user experience

### Don't write an ADR for:

❌ **Implementation details**

- Variable naming conventions
- File organization within a module
- Specific algorithm choices (unless architectural impact)

❌ **Temporary decisions**

- "We'll use X until Y is ready"
- Experimental features
- Short-term workarounds

❌ **Obvious choices**

- Using Git for version control
- Following JavaScript standard syntax
- Running tests before deployment

---

## ADR Template

```markdown
# ADR-XXX: [Decision Title]

**Status:** [Proposed | Accepted | Deprecated | Superseded by ADR-YYY]
**Date:** YYYY-MM-DD
**Deciders:** [Names or @usernames]
**Technical Story:** [Link to issue/PR]

---

## Context and Problem Statement

[Describe the context and problem that needs solving.
Keep it factual and objective. Include relevant constraints.]

### Decision Drivers

- Driver 1 (e.g., performance requirements)
- Driver 2 (e.g., maintainability)
- Driver 3 (e.g., team expertise)

---

## Considered Options

### Option A: [Name]

**Description:** [How this option works]

**Pros:**

- ✅ Benefit 1
- ✅ Benefit 2

**Cons:**

- ❌ Drawback 1
- ❌ Drawback 2

**Examples:** [Code examples or references]

---

### Option B: [Name]

[Same structure as Option A]

---

### Option C: [Name]

[Same structure as Option A]

---

## Decision Outcome

**Chosen option:** Option [A/B/C] - [Name]

**Rationale:**

- Reason 1
- Reason 2
- Reason 3

### Consequences

**Good:**

- ✅ Consequence 1
- ✅ Consequence 2

**Bad:**

- ❌ Consequence 1 (and how we'll mitigate)
- ❌ Consequence 2 (and how we'll mitigate)

**Neutral:**

- 🔶 Consequence 1
- 🔶 Consequence 2

---

## Implementation

**Action items:**

- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

**Affected components:**

- Component 1 (how it's affected)
- Component 2 (how it's affected)

---

## Validation

**How we'll know this decision was correct:**

- Success metric 1
- Success metric 2
- Success metric 3

**Review date:** [Optional: When to revisit this decision]

---

## Links

- [ADR-XXX: Related Decision](./ADR-XXX-title.md)
- [Original Discussion](https://github.com/.../issues/XXX)
- [Implementation PR](https://github.com/.../pull/XXX)
- [External Reference](https://example.com)
```

---

## Writing Process

### Step 1: Identify the Decision

**Triggers for ADR:**

- Architecture discussion in PR review
- Multiple valid approaches to a problem
- Trade-off between competing qualities
- Team disagreement on direction

**Ask yourself:**

- Will future developers wonder why we did this?
- Could this decision be challenged later?
- Are there significant trade-offs?

### Step 2: Research Options

**Gather information:**

```bash
# Look at existing ADRs
ls docs/decisions/

# Review similar decisions
grep -r "similar-topic" docs/

# Research external approaches
# Read blog posts, documentation, case studies
```

**Document at least 2-3 options:**

- What's the mainstream approach?
- What's the innovative approach?
- What's the simple/pragmatic approach?

### Step 3: Draft the ADR

**File naming:**

```
docs/decisions/ADR-XXX-short-decision-title.md
```

**Numbering:**

- Sequential: ADR-001, ADR-002, ADR-003...
- Check last number: `ls docs/decisions/ | sort | tail -1`
- Use next available number

**Status:**

- Start with `Status: Proposed`
- Changes to `Accepted` after approval
- Can become `Deprecated` or `Superseded by ADR-XXX`

### Step 4: Write Clear Rationale

**Good rationale:**

```markdown
## Decision Outcome

**Chosen option:** Option A - Clean Architecture

**Rationale:**

- Our domain logic (Session, Project) is complex and needs isolation
- Testing becomes easier with clear boundaries (265 unit tests prove this)
- Team has experience with layered architecture from previous projects
- Allows switching adapters (file system → database) without touching domain
- Industry standard for medium/large applications
```

**Bad rationale:**

```markdown
## Decision Outcome

**Chosen option:** Option A - Clean Architecture

**Rationale:**

- It's better
- Everyone uses it
- Sounds professional
```

### Step 5: Document Consequences

**Be honest about trade-offs:**

```markdown
### Consequences

**Good:**

- ✅ Clear separation of concerns - easier to test
- ✅ Domain logic is portable (can use in browser, CLI, server)
- ✅ New developers learn a transferable architecture pattern

**Bad:**

- ❌ More boilerplate code (Repository interfaces, Use Cases)
  - Mitigation: Templates and generator scripts reduce friction
- ❌ Steeper learning curve for contributors
  - Mitigation: Comprehensive architecture documentation
- ❌ Can feel over-engineered for simple features
  - Mitigation: Pragmatic application - not dogmatic

**Neutral:**

- 🔶 Three layers instead of two (Domain, Use Cases, Adapters)
- 🔶 Dependency injection via Container pattern
```

---

## Review and Approval

### Creating the PR

```bash
# Create branch
git checkout -b docs/adr-005-event-sourcing

# Write ADR
# Create file: docs/decisions/ADR-005-event-sourcing.md

# Commit with clear message
git add docs/decisions/ADR-005-event-sourcing.md
git commit -m "docs: add ADR-005 for event sourcing decision"

# Push and create PR
git push origin docs/adr-005-event-sourcing
gh pr create --title "ADR-005: Event Sourcing for Session History"
```

### PR Description

```markdown
## ADR Summary

This ADR proposes using event sourcing for session history to enable:

- Complete audit trail of all session changes
- Time-travel debugging
- Undo/redo functionality

## Request for Feedback

Specifically looking for input on:

1. Is the added complexity worth the benefits?
2. Have we considered all alternatives?
3. Are the mitigation strategies for downsides sufficient?

cc @maintainer1 @maintainer2
```

### Review Process

**Reviewers should check:**

1. **Clarity**
   - Is the problem statement clear?
   - Are options well-explained?
   - Is rationale convincing?

2. **Completeness**
   - Are all reasonable options considered?
   - Are trade-offs documented honestly?
   - Are consequences thought through?

3. **Feasibility**
   - Can this actually be implemented?
   - Do we have the skills/resources?
   - What's the implementation timeline?

4. **Alignment**
   - Does this fit with project goals?
   - Is it consistent with other ADRs?
   - Does it align with team values?

### Approval and Merge

**Merge criteria:**

- ✅ At least one maintainer approval
- ✅ All review comments addressed
- ✅ Status updated to `Accepted`
- ✅ Added to ADR index/navigation

**After merge:**

```bash
# Update ADR status
Status: Accepted

# Add to mkdocs.yml navigation
- ADR-005 Event Sourcing: decisions/ADR-005-event-sourcing.md
```

---

## Updating ADRs

### When Circumstances Change

**ADR lifecycle:**

```
Proposed → Accepted → [Deprecated | Superseded]
```

**If decision needs revision:**

1. **Don't delete the original ADR**
   - Keep history intact
   - Shows evolution of thinking

2. **Create new ADR that supersedes old one**

   ```markdown
   # In ADR-005:

   Status: Superseded by ADR-012

   # In ADR-012:

   Status: Accepted
   Supersedes: ADR-005
   ```

3. **Explain what changed**

   ```markdown
   ## Context

   ADR-005 chose event sourcing for session history. After 6 months
   of use, we've discovered that:

   - Complexity outweighs benefits for our use case
   - Team struggles to maintain event store
   - Performance issues with large event logs

   This ADR proposes reverting to simpler snapshot-based approach.
   ```

### Marking as Deprecated

```markdown
# ADR-003: Bridge Pattern for Shell Integration

**Status:** Deprecated (as of 2025-12-24)
**Reason:** Replaced by direct Node.js implementation in v2.0

---

[Original ADR content remains unchanged]

---

## Deprecation Note

As of v2.0, we've moved away from shell integration in favor of
pure Node.js implementation. See ADR-008 for details.

This ADR is kept for historical reference.
```

---

## Examples

### Example 1: Technology Choice

```markdown
# ADR-001: Use Vendored Code Pattern for External Scripts

**Status:** Accepted
**Date:** 2025-12-20

## Context and Problem Statement

We need zsh-claude-workflow shell scripts in our project. Should we:

1. Use as git submodule
2. Vendor (copy) the code
3. Use npm dependency

### Decision Drivers

- Reliability (no external dependencies)
- Simplicity (easy for contributors)
- Maintenance (keep updated)

## Considered Options

### Option A: Git Submodule

- ✅ Always latest version
- ❌ Requires separate clone step
- ❌ Contributors often forget to update

### Option B: Vendor Code

- ✅ Self-contained repository
- ✅ Known working version
- ❌ Manual sync needed

### Option C: NPM Package

- ✅ Version management
- ❌ Requires publishing to npm
- ❌ Adds dependency

## Decision Outcome

**Chosen option:** Option B - Vendor Code

**Rationale:**

- Reliability > convenience
- No external network required for build
- Clear documentation of sync process
- Most shell projects use this pattern

### Consequences

**Good:**

- ✅ Clone and go - no setup needed
- ✅ Offline development works

**Bad:**

- ❌ Manual sync required
  - Mitigation: Document clear sync process
```

### Example 2: Architecture Pattern

```markdown
# ADR-002: Adopt Clean Architecture

**Status:** Accepted
**Date:** 2025-12-20

## Context and Problem Statement

As flow-cli grows, we need architectural structure that:

- Keeps business logic testable
- Allows switching adapters (file system, database)
- Supports multiple interfaces (CLI, API, TUI)

## Considered Options

### Option A: MVC Pattern

[Details...]

### Option B: Clean Architecture (Hexagonal/Ports & Adapters)

[Details...]

### Option C: Simple Layered Architecture

[Details...]

## Decision Outcome

**Chosen option:** Option B - Clean Architecture

[Rationale and consequences...]

## Implementation

**Action items:**

- [x] Create domain entities (Session, Project, Task)
- [x] Implement use cases (CreateSession, EndSession)
- [x] Build adapters (FileSystemRepository)
- [x] Add dependency injection container
- [x] Write architecture documentation

## Validation

**Success metrics:**

- 150+ domain tests with no I/O dependencies ✅
- Can swap file system for different storage ✅
- 100% test pass rate maintained ✅
```

---

## Best Practices

### DO ✅

1. **Write ADRs early**
   - Before implementation starts
   - While options are still open
   - When discussion is fresh

2. **Be objective**
   - Present all options fairly
   - Document real trade-offs
   - Admit unknowns

3. **Keep it concise**
   - 2-4 pages maximum
   - Use bullets over paragraphs
   - Code examples over prose

4. **Update navigation**
   - Add to mkdocs.yml
   - Link from related docs
   - Update ADR index

5. **Link to implementation**
   - Reference PRs that implement decision
   - Link to affected code
   - Track completion status

### DON'T ❌

1. **Don't write ADRs in isolation**
   - Discuss with team first
   - Get feedback on options
   - Build consensus

2. **Don't hide downsides**
   - Every decision has trade-offs
   - Acknowledge them honestly
   - Plan mitigation strategies

3. **Don't make it permanent**
   - Circumstances change
   - Technology evolves
   - It's okay to supersede

4. **Don't use jargon**
   - Write for future contributors
   - Explain technical terms
   - Assume less context

5. **Don't skip consequences**
   - Implementation implications
   - Testing requirements
   - Maintenance burden

---

## Quick Reference

### ADR Checklist

**Before writing:**

- [ ] Verified decision is architectural (not implementation detail)
- [ ] Researched at least 2-3 options
- [ ] Discussed with team/maintainers
- [ ] Have clear decision drivers

**While writing:**

- [ ] Used ADR template
- [ ] Assigned next sequential number
- [ ] Set status to "Proposed"
- [ ] Documented all serious options
- [ ] Included pros/cons for each
- [ ] Explained rationale clearly
- [ ] Listed consequences (good/bad/neutral)
- [ ] Added implementation action items

**After writing:**

- [ ] Created PR with ADR
- [ ] Requested reviews from stakeholders
- [ ] Addressed feedback
- [ ] Updated status to "Accepted"
- [ ] Added to navigation (mkdocs.yml)
- [ ] Linked from related docs

### File Naming

```bash
# Pattern
docs/decisions/ADR-XXX-short-kebab-case-title.md

# Examples
docs/decisions/ADR-001-use-vendored-code-pattern.md
docs/decisions/ADR-002-adopt-clean-architecture.md
docs/decisions/ADR-003-bridge-pattern.md
docs/decisions/ADR-004-module-api-not-rest.md
```

### Essential Sections

**Minimum viable ADR:**

1. Status and date
2. Context and problem
3. 2-3 options with pros/cons
4. Decision with rationale
5. Consequences

**Full ADR:**

1. All of above plus:
2. Decision drivers
3. Implementation plan
4. Validation criteria
5. Related links

---

## Related Documentation

- [Contributing Guide](../../CONTRIBUTING.md) - General contribution guidelines
- [PR Workflow Guide](PR-WORKFLOW-GUIDE.md) - How to create pull requests
- [Architecture Overview](../architecture/README.md) - Current architecture
- [Existing ADRs](../decisions/README.md) - Browse all ADRs

---

## Resources

**ADR Philosophy:**

- [ADR GitHub Org](https://adr.github.io/) - ADR best practices
- [Michael Nygard's Post](http://thinkrelevance.com/blog/2011/11/15/documenting-architecture-decisions) - Original ADR concept

**Examples from other projects:**

- [Spotify ADRs](https://github.com/spotify/backstage/tree/master/docs/architecture-decisions)
- [Rust RFCs](https://github.com/rust-lang/rfcs) - Similar concept
- [Python PEPs](https://peps.python.org/) - Enhancement proposals

---

**Last Updated:** 2025-12-24
**Version:** v2.0.0-beta.1
**Questions?** Open an issue or discussion on GitHub

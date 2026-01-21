# Specification Review: Intelligent Content Analysis

**Reviewing:** `SPEC-intelligent-content-analysis-2026-01-20.md`
**Reviewer:** Claude Sonnet 4.5
**Review Date:** 2026-01-20
**Status:** Critical review for implementation readiness

---

## 🎯 Executive Summary

**Overall Assessment:** 🟢 **STRONG FOUNDATION** - Spec is comprehensive and well-structured, but needs refinements in 5 key areas before implementation.

**Key Strengths:**

1. ✅ Clear user stories with measurable acceptance criteria
2. ✅ Well-designed architecture with Mermaid diagram
3. ✅ Comprehensive data models with JSON schemas
4. ✅ ADHD-friendly UX patterns
5. ✅ Phased implementation approach (66 hours, 6 phases)

**Critical Issues to Address (5):**

1. ⚠️ **Open Question #1** - AI service integration decision blocks Phase 2+
2. ⚠️ **Cache invalidation** - Strategy not fully defined
3. ⚠️ **Performance targets** - Some targets may be unrealistic
4. ⚠️ **Phase 1 scope** - Too large for MVP (should be split)
5. ⚠️ **Frontmatter schema** - Missing from spec

---

## 📋 Section-by-Section Review

### 1. Overview & User Stories

**Rating:** 🟢 **EXCELLENT**

**Strengths:**

- Clear primary user story with measurable acceptance criteria
- Secondary stories cover all major use cases
- Acceptance criteria are testable

**Refinements:**

#### Acceptance Criteria Adjustment

**Original:** "✅ `teach analyze` completes in < 30s for single lecture"

**Issue:** 30s is slow for ADHD-friendly CLI. User will lose focus.

**Refined:**

```
Performance Targets (Tiered):
- Cached analysis: < 100ms ✅ (ADHD-friendly)
- Heuristic-only: < 5s ✅ (acceptable)
- AI-powered analysis: < 30s ⚠️ (requires progress indicator)
- Batch analysis: async background ✅ (non-blocking)
```

**Rationale:** 30s is only acceptable if:

1. User sees continuous progress (not silent)
2. Results are heavily cached (85%+ hit rate)
3. Async option available for batch analysis

---

### 2. Architecture

**Rating:** 🟡 **GOOD - Needs Clarification**

**Strengths:**

- Clean separation of concerns (5 services)
- File-based storage (no external DB)
- Integration points well-defined

**Refinements:**

#### Missing: Cache Invalidation Strategy

**Issue:** Mermaid diagram shows `CacheInvalidator` service but no spec for it.

**Add to Spec:**

```markdown
### Cache Invalidation Service

**Triggers:**

1. Content hash changes (file modified)
2. lesson-plan.yml updated (affects prerequisites)
3. teach-config.yml updated (affects analysis settings)
4. Manual: teach analyze --force

**Strategy:**

- Content-hash based (SHA-256 of file content)
- Cascade invalidation (if Week 3 changes, invalidate Week 4-15 prerequisite checks)
- Partial invalidation (only affected sections, not entire file)

**Performance:**

- < 10ms to check if cache valid
- < 50ms to rebuild cache index after invalidation
- Target 85-90% cache hit rate in typical workflow
```

#### Missing: Error Handling Architecture

**Add to Spec:**

```markdown
### Error Handling Strategy

**Graceful Degradation:**

1. Scholar API unavailable → Fall back to heuristic-only analysis
2. Cache corrupted → Rebuild cache, continue analysis
3. lesson-plan.yml malformed → Use frontmatter-only prerequisites
4. Memory limit exceeded → Switch to file-based processing

**User Notification:**

- Silent fallback for non-critical (cached → uncached)
- Visible warning for degraded functionality (AI → heuristic)
- Blocking error only for critical failures (file not found, permissions)
```

---

### 3. Data Models

**Rating:** 🟢 **EXCELLENT**

**Strengths:**

- Comprehensive JSON schemas
- Clear versioning strategy
- Practical field choices

**Refinements:**

#### Missing: Frontmatter Schema

**Issue:** Spec references `concepts:` field in frontmatter but doesn't provide schema.

**Add to Spec:**

```yaml
---
# Standard Quarto frontmatter
title: 'Linear Regression Assumptions'
week: 5
date: 2026-02-10

# Analysis-specific fields (optional)
concepts:
  introduces:
    - id: regression-assumptions
      title: 'Regression Assumptions' # Optional: defaults to id
      difficulty: medium # easy|medium|hard

    - id: homoscedasticity
      title: 'Homoscedasticity Testing'
      difficulty: hard

  requires:
    - correlation # From Week 3
    - variance # From Week 1

  related: # Optional: for concept graph
    - residual-analysis
    - diagnostic-plots

learning_objectives:
  - id: fit-model
    title: 'Fit and interpret regression model in R'
    bloom: apply # remember|understand|apply|analyze|evaluate|create
    min_examples: 3

  - id: check-assumptions
    title: 'Validate regression assumptions using diagnostic tests'
    bloom: evaluate
    min_examples: 2
---
```

**Validation Rules:**

1. `concepts.introduces` - Array of concepts introduced in this file
2. `concepts.requires` - Array of concept IDs (must exist in earlier weeks)
3. `learning_objectives` - Array of objectives with Bloom taxonomy levels
4. All fields are optional (graceful defaults if missing)

#### Concept Graph: Add Bloom Taxonomy Levels

**Enhancement:** Track cognitive complexity for better analysis.

**Add to `concepts` object:**

```json
{
  "concepts": {
    "regression-assumptions": {
      // ... existing fields ...
      "bloom_level": "evaluate", // NEW
      "cognitive_load": 0.7, // NEW: 0.0 (low) to 1.0 (high)
      "teaching_time_minutes": 45 // NEW: estimated teaching time
    }
  }
}
```

**Benefit:** Can detect if Week 5 requires "evaluate" level but prerequisites only teach "remember" level (pedagogical gap).

---

### 4. API Design

**Rating:** 🟡 **GOOD - Simplification Needed**

**Strengths:**

- Comprehensive flag coverage
- Good examples
- Clear integration points

**Refinements:**

#### teach analyze - Too Many Flags

**Issue:** 16 flags is overwhelming (ADHD unfriendly).

**Simplify:**

```bash
teach analyze [files...] [options]

# Core flags (always visible in --help)
  --week N, -w N              Analyze specific week
  --all                       Analyze all content (default if no files)
  --interactive, -i           Step through suggestions
  --summary, -s               Compact summary only

# Output flags
  --format json|text          Output format (default: text)
  --report [FILE]             Generate HTML report (optional filename)
  --quiet, -q                 No progress indicators

# Analysis flags (advanced - shown in --help-advanced)
  --mode strict|moderate|relaxed   Strictness (default: from config)
  --force                     Ignore cache
  --extract-concepts          AI concept extraction (Phase 3+)
  --slide-breaks              Analyze slide structure (Phase 4+)
  --costs                     Show API costs

# Examples remain the same
```

**Rationale:**

- 7 primary flags (ADHD-friendly)
- 6 advanced flags (opt-in via `--help-advanced`)
- Progressive disclosure

#### teach validate --quality → teach validate --deep

**Issue:** "Quality" is vague. "Deep" better conveys comprehensive analysis.

**Change:**

```bash
# OLD
teach validate --quality

# NEW
teach validate --deep
# Runs Layers 1-6: YAML, syntax, render, chunks, images, + content analysis
```

**Benefit:** Matches existing `--deep` pattern in tech industry (deep scan, deep copy, deep equals).

---

### 5. Configuration

**Rating:** 🟡 **GOOD - Simplification Needed**

**Strengths:**

- Tiered strictness modes
- Configurable severities
- Per-week concept definitions

**Refinements:**

#### lesson-plan.yml - Simplify Analysis Config

**Issue:** Config has 3 nested levels (analysis → modes → mode_name). Too complex.

**Simplify:**

```yaml
# Simplified analysis config
analysis:
  enabled: true
  mode: moderate # strict|moderate|relaxed
  cache_ttl_hours: 168 # 7 days

  # Thresholds (can override per mode)
  min_examples_per_objective: 2
  require_all_prerequisites: true
  warn_missing_concepts: true

  # Advanced (optional)
  background_analysis: false # Auto-analyze on file save
  save_reports: true
  report_dir: .teach/analysis

# Per-week concept definitions remain unchanged
weeks:
  - number: 5
    concepts:
      - id: slr-basics
        required: true
      # ...
```

**Benefit:** Flatter structure, easier to read and modify.

#### Add Defaults for Missing Config

**Add to Spec:**

```markdown
### Configuration Defaults

If `analysis:` section missing from lesson-plan.yml:

- `enabled: false` (opt-in only)
- `mode: moderate`
- `cache_ttl_hours: 168`
- `min_examples_per_objective: 2`

If `weeks[N].concepts` missing:

- Extract concepts from frontmatter only
- No prerequisite validation for that week
```

---

### 6. Open Questions - Resolution Required

**Rating:** 🔴 **CRITICAL - Blocks Implementation**

#### Q1: AI Service Integration (MUST RESOLVE)

**Current Recommendation:** B (Scholar service)

**Issue:** Scholar service may not have semantic analysis capabilities.

**Deep Dive:**

- **Scholar Service:** Designed for content generation (lectures, exams)
- **Semantic Analysis:** Requires NLP, concept extraction, prerequisite inference
- Scholar may not expose these APIs

**UPDATED Recommendation:** **Option D (NEW)**

**Option D: Hybrid with Fallback**

1. **Phase 1 (MVP):** Heuristic-only (no AI)
   - Extract concepts from frontmatter
   - Validate prerequisites (user-defined only)
   - Readability scores (textstat-style algorithms)
   - **Benefit:** Zero API dependency, instant results

2. **Phase 2:** Scholar integration (if available)
   - Check if Scholar exposes concept extraction API
   - If yes: integrate
   - If no: continue with heuristics

3. **Phase 3+:** Claude API direct (if needed)
   - Only if Scholar limitations found
   - Add API key management
   - Cost tracking

**Decision Required Before Phase 1:**

- [ ] Test Scholar API for semantic analysis capabilities
- [ ] If unavailable, commit to heuristic-only MVP
- [ ] Document API key management if Claude API needed

---

#### Q2: Analysis Caching Strategy (RESOLVED ✅)

**Current Recommendation:** A (JSON files)

**Enhancement:** Add specific cache file structure.

**Add to Spec:**

```
.teach/
├── analysis-cache/
│   ├── lectures/
│   │   ├── week-01-lecture.json  # Mirrors source structure
│   │   ├── week-02-lecture.json
│   │   └── week-03-lecture.json
│   ├── assignments/
│   │   └── hw-01.json
│   └── cache-index.json  # Metadata for all cached files
├── concepts.json
└── prerequisites.json
```

**cache-index.json schema:**

```json
{
  "version": "1.0",
  "last_updated": "2026-01-20T15:00:00Z",
  "cache_stats": {
    "total_files": 15,
    "cached_files": 12,
    "cache_hit_rate": 0.87,
    "total_size_bytes": 245678
  },
  "files": {
    "lectures/week-03-lecture.qmd": {
      "cache_file": ".teach/analysis-cache/lectures/week-03-lecture.json",
      "content_hash": "sha256:abc123...",
      "cached_at": "2026-01-20T14:30:00Z",
      "ttl_expires": "2026-01-27T14:30:00Z",
      "status": "valid"
    }
  }
}
```

---

#### Q3: teach validate Integration (NEEDS REVISION)

**Current Recommendation:** B (`--deep` flag)

**Issue:** Name changed from `--deep` to `--quality` in spec, but `--deep` is better.

**Final Decision:** Use `--deep` flag (matches Q4 refinement above).

```bash
# Validation layers
teach validate [file]          # Layers 1-5 (syntax, render, etc)
teach validate --deep [file]   # Layers 1-6 (adds content analysis)
```

---

#### Q4: Performance vs Accuracy (RESOLVED ✅)

**Current Recommendation:** C (hybrid: heuristics first, AI on demand)

**Enhancement:** Make this explicit in command design.

**Add to `teach analyze` API:**

```bash
# Fast heuristics only (< 5s)
teach analyze --fast

# AI-powered analysis (30s+)
teach analyze --ai

# Default: heuristics only in Phase 1, hybrid in Phase 3+
teach analyze  # Uses config default
```

---

#### Q5: teach slides --optimize Output (RESOLVED ✅)

**Current Recommendation:** C (terminal) + optional B (`--save-report`)

**No changes needed.** This is good.

---

### 7. Implementation Phasing

**Rating:** 🟡 **NEEDS ADJUSTMENT**

**Issue:** Phase 1 scope too large (12 hours is not MVP).

**Recommended Re-phasing:**

#### NEW Phase 0: Ultra-MVP (4-5 hours) ← START HERE

**Goal:** Prove the concept with minimal features.

**Scope:**

1. Create `lib/concept-extraction.zsh` (heuristic-only)
   - Extract concepts from frontmatter `concepts:` field
   - Build simple concept graph (ID + prerequisites)
   - Save to `.teach/concepts.json`

2. Create `commands/teach-analyze.zsh` (basic)
   - `teach analyze [file]` - single file only
   - Display concepts found
   - Check prerequisites (user-defined only)
   - Text output only

3. Integration
   - Source libraries in `flow.plugin.zsh`
   - Add routing in `teach-dispatcher.zsh`
   - Add basic help text

4. Tests
   - 15 unit tests (concept extraction)
   - 5 integration tests (full workflow)

**Deliverable:** Working `teach analyze` command that validates user-defined prerequisites. No AI, no caching, no advanced features.

**Success Criteria:**

- User can add `concepts:` to frontmatter
- `teach analyze lectures/week-03.qmd` validates prerequisites
- Warning if Week 5 requires concept from Week 7
- < 2s analysis time

---

#### NEW Phase 1: Foundation (6-8 hours)

**Goal:** Add caching and batch analysis.

**Scope:**

1. Add caching (content-hash based)
2. Add `--all` and `--week N` flags
3. Add `--format json` output
4. Improve help text with examples
5. Add 20 more tests

**Move to Later Phases:**

- Learning objective validation → Phase 3
- Interactive mode → Phase 4
- AI extraction → Phase 5
- Slide optimization → Phase 6

---

### 8. Missing Sections

**Add to Spec:**

#### Security Considerations

```markdown
## 🔒 Security Considerations

### API Key Management (if using Claude API)

- Store in macOS Keychain (via `security` command)
- Never log API keys
- Rotate keys quarterly
- Rate limiting to prevent abuse

### File Access

- Analysis reads files in project directory only
- No network access except AI APIs
- Cache files in `.teach/` (git-ignored)

### User Privacy

- No telemetry by default
- Opt-in analytics (crash reports only)
- No content sent to external services without user consent
```

---

#### Backward Compatibility

```markdown
## ♻️ Backward Compatibility

### Zero Breaking Changes Required

- All analysis features are opt-in
- Existing commands work unchanged
- New frontmatter fields are optional
- lesson-plan.yml analysis section is optional

### Migration Path

1. Users can adopt gradually (no flag day)
2. Start with Phase 0 (basic prerequisite checking)
3. Add frontmatter fields incrementally
4. Enable caching when comfortable
5. Add AI analysis in Phase 5+

### Versioning

- Features versioned by phase (not semver)
- Cache schema versioned (v1, v2, etc.)
- Graceful handling of old cache files (rebuild if schema mismatch)
```

---

## 🎯 Revised Recommendations

### Immediate Actions (Before Implementation)

1. **Resolve Q1 (AI Service)** ✅ CRITICAL
   - Test Scholar API semantic analysis capabilities
   - If unavailable, commit to heuristic-only MVP (Phase 0)
   - Document decision in spec

2. **Simplify Phase 0 Scope** ✅ REQUIRED
   - Extract 4-5 hour MVP from current Phase 1
   - Defer advanced features to later phases
   - Update `PLAN-teach-analyze-phase1.md`

3. **Add Missing Sections** ⚠️ IMPORTANT
   - Security considerations
   - Backward compatibility
   - Frontmatter schema
   - Cache invalidation strategy

4. **Simplify Configuration** ⚠️ NICE-TO-HAVE
   - Flatten lesson-plan.yml analysis config
   - Document defaults for missing config

5. **Refine Performance Targets** ⚠️ IMPORTANT
   - Tier targets (cached/heuristic/AI)
   - Add progress indicators requirement
   - Document async option for batch

---

### Long-term Considerations

1. **Extension Points**
   - Design API for third-party validators
   - Allow custom concept extractors
   - Plugin system for analysis modes

2. **Observability**
   - Add `teach analyze --stats` for cache metrics
   - Log analysis performance to `.teach/performance-log.json`
   - Dashboard for analysis history

3. **Teaching Assistants**
   - Multi-instructor support (different prerequisite definitions)
   - Shared concept graph across course sections
   - Merge conflicts in lesson-plan.yml

---

## 📊 Spec Maturity Assessment

| Section                 | Status              | Confidence | Blockers                   |
| ----------------------- | ------------------- | ---------- | -------------------------- |
| Overview & User Stories | 🟢 Ready            | 95%        | None                       |
| Architecture            | 🟡 Needs refinement | 85%        | Cache invalidation spec    |
| Data Models             | 🟢 Ready            | 90%        | Add frontmatter schema     |
| API Design              | 🟡 Simplify         | 80%        | Too many flags             |
| Configuration           | 🟡 Simplify         | 80%        | Flatten structure          |
| Open Questions          | 🔴 Blocking         | 60%        | Q1 must resolve            |
| Implementation Plan     | 🟡 Revise           | 75%        | Split Phase 0 from Phase 1 |
| Testing Strategy        | 🟢 Ready            | 90%        | None                       |
| Documentation Plan      | 🟢 Ready            | 90%        | None                       |

**Overall Readiness:** 🟡 **82% - REFINE BEFORE IMPLEMENTATION**

---

## ✅ Approval Checklist

**Before creating feature branch:**

- [ ] Q1 (AI Service) resolved with implementation path
- [ ] Phase 0 scope extracted and documented
- [ ] Frontmatter schema added to spec
- [ ] Cache invalidation strategy documented
- [ ] Security considerations added
- [ ] Backward compatibility section added
- [ ] `teach analyze` flags simplified to 7 primary + 6 advanced
- [ ] lesson-plan.yml config flattened
- [ ] Performance targets tiered (cached/heuristic/AI)
- [ ] All refinements incorporated into spec

**Implementation can proceed when:**

- [ ] Spec updated status → `ready`
- [ ] Phase 0 plan created (separate from Phase 1)
- [ ] User approves Phase 0 scope
- [ ] Feature branch created: `feature/teach-analyze`

---

## 📝 Recommended Spec Updates

### 1. Update Open Question #1

```diff
- **Recommendation:** Start with B (Scholar), migrate to C if limitations found
+ **RESOLVED:** Option D (Hybrid with Fallback)
+ Phase 0-1: Heuristic-only (no AI dependency)
+ Phase 2: Test Scholar API, integrate if available
+ Phase 3+: Claude API direct if needed
+ Decision: Proceed with heuristic-only MVP
```

### 2. Add Section: Frontmatter Schema

Insert after "Data Models" section (line 257).

### 3. Update teach analyze Flags

Simplify from 16 flags to 7 primary + 6 advanced.

### 4. Add Section: Cache Invalidation Strategy

Insert in Architecture section (line 151).

### 5. Add Section: Security Considerations

Insert before "Review Checklist" (line 580).

### 6. Add Section: Backward Compatibility

Insert after "Security Considerations".

### 7. Split Phase 1 into Phase 0 + Phase 1

Update "Implementation Notes" section (line 634).

---

## 🎬 Next Steps

### Option A: Update Spec Immediately

I can update the spec file with all refinements right now.

### Option B: Review Refinements First

Discuss specific refinements before updating spec.

### Option C: Create Phase 0 Plan

Skip spec updates, create minimal Phase 0 implementation plan.

### Option D: All of the Above

Update spec, then create Phase 0 plan in sequence.

**Recommended:** Option D (update spec, then plan Phase 0)

**Your choice?**

# Phase 2 Implementation Plan - Quarto Workflow Enhancements

**Version:** 1.0.0
**Created:** 2026-01-20
**Branch:** feature/quarto-workflow
**Target:** Weeks 9-12 (Profile Management, Parallel Rendering, Custom Validators, Performance Monitoring)

---

## Executive Summary

**Goal:** Enhance Quarto teaching workflow with advanced features for profile management, parallel rendering (3-10x speedup), custom validation framework, and performance monitoring.

**Approach:** Orchestrated implementation using specialized agents (same approach as Phase 1)

**Estimated Effort:** 10-12 hours (orchestrated) vs 40-50 hours (manual)
**Time Savings:** ~80-85%

**Success Criteria:**

- Profile management system with Quarto profile detection and switching
- Parallel rendering achieving 3-10x speedup on multi-file operations
- Extensible custom validator framework with 3+ built-in validators
- Performance monitoring with trend visualization
- 180+ comprehensive tests (100% passing)
- Complete documentation updates

---

## Phase 2 Overview

### Features by Week

| Week           | Feature                              | Impact | Complexity |
| -------------- | ------------------------------------ | ------ | ---------- |
| **Week 9**     | Profile Management + R Auto-Install  | Medium | Medium     |
| **Week 10-11** | Parallel Rendering (3-10x speedup)   | High   | High       |
| **Week 11-12** | Custom Validators + Advanced Caching | Medium | Medium     |
| **Week 12**    | Performance Monitoring               | Low    | Low        |

### Technical Scope

**New Files to Create:** 15-18 files (~4,500-5,500 lines)
**Files to Modify:** 3-5 files
**Test Suites:** 6 new suites (180+ tests)
**Documentation:** 4,000+ lines

---

## Wave Structure

### Wave 1: Profile Management + R Package Detection (2-3 hours)

**Goal:** Implement Quarto profile management and R package auto-installation

**Files to Create:**

1. `lib/profile-helpers.zsh` (300-350 lines)
   - Profile detection from \_quarto.yml
   - Profile switching logic
   - Profile validation

2. `lib/r-helpers.zsh` (250-300 lines)
   - R package detection from teaching.yml
   - Installation verification
   - renv lockfile parsing

3. `lib/renv-integration.zsh` (150-200 lines)
   - renv.lock file reading
   - Package dependency resolution
   - Installation status tracking

4. `commands/teach-profiles.zsh` (200-250 lines)
   - teach profiles list
   - teach profiles show <name>
   - teach profiles set <name>
   - teach profiles create <name>

**Files to Modify:**

- `lib/dispatchers/teach-dispatcher.zsh` - Add profiles subcommand
- `lib/dispatchers/teach-doctor-impl.zsh` - Add R package checks with --fix

**Testing:**

- `tests/test-teach-profiles-unit.zsh` (40-50 tests)
- `tests/test-r-helpers-unit.zsh` (30-40 tests)
- Profile detection, switching, creation
- R package detection from multiple sources
- Auto-install prompts and execution

**Success Criteria:**

- ✅ Detect Quarto profiles from \_quarto.yml
- ✅ Switch profiles with environment activation
- ✅ Create new profiles from template
- ✅ Detect R packages from teaching.yml and renv.lock
- ✅ Auto-install missing R packages via teach doctor --fix
- ✅ All tests passing

**Dependencies:** None (independent wave)

---

### Wave 2: Parallel Rendering Infrastructure (3-4 hours)

**Goal:** Implement parallel rendering with 3-10x speedup for multi-file operations

**Files to Create:**

1. `lib/parallel-helpers.zsh` (400-500 lines)
   - Worker pool management
   - Job queue implementation
   - Progress tracking
   - Core detection (sysctl/nproc)
   - Error aggregation

2. `lib/render-queue.zsh` (250-300 lines)
   - Smart queue optimization
   - Dependency-aware ordering
   - Estimated time calculation
   - Load balancing

3. `lib/parallel-progress.zsh` (150-200 lines)
   - Real-time progress bar
   - Worker status display
   - ETA calculation
   - Statistics collection

**Files to Modify:**

- `lib/dispatchers/teach-dispatcher.zsh` - Add --parallel flag to validate
- `lib/validation-helpers.zsh` - Integrate parallel rendering

**Implementation Details:**

**Worker Pool Pattern:**

```zsh
_create_worker_pool() {
    local num_workers="${1:-$(sysctl -n hw.ncpu)}"
    local queue_file="$(mktemp)"
    local result_file="$(mktemp)"

    # Start workers
    for i in {1..$num_workers}; do
        _worker_process "$queue_file" "$result_file" &
        workers+=($!)
    done
}

_worker_process() {
    local queue="$1"
    local results="$2"

    while true; do
        # Atomic job fetch
        local job=$(flock "$queue" -c "head -n1 '$queue' && sed -i '' '1d' '$queue'")
        [[ -z "$job" ]] && break

        # Execute job
        local start=$(date +%s)
        quarto render "$job" 2>&1
        local status=$?
        local duration=$(($(date +%s) - start))

        # Write result atomically
        flock "$results" -c "echo '$job,$status,$duration' >> '$results'"
    done
}
```

**Smart Queue Optimization:**

```zsh
_optimize_render_queue() {
    local files=("$@")
    local optimized=()

    # Categorize by estimated render time
    local fast=()      # < 10s (based on history)
    local medium=()    # 10-30s
    local slow=()      # > 30s

    for file in $files; do
        local est=$(_estimate_render_time "$file")
        if (( est < 10 )); then
            fast+=("$file")
        elif (( est < 30 )); then
            medium+=("$file")
        else
            slow+=("$file")
        fi
    done

    # Optimal ordering: slow files first (maximize parallelism)
    # then medium, then fast (fill gaps)
    optimized=($slow $medium $fast)
    echo "${optimized[@]}"
}
```

**Testing:**

- `tests/test-parallel-rendering-unit.zsh` (50-60 tests)
- `tests/test-render-queue-unit.zsh` (30-40 tests)
- Worker pool creation and cleanup
- Job queue operations (add, fetch, complete)
- Progress tracking accuracy
- Error handling and aggregation
- Queue optimization logic

**Performance Benchmarks:**
| Scenario | Serial | Parallel (8 cores) | Speedup |
|----------|--------|-------------------|---------|
| 12 files, avg 13s | 156s | 45s | 3.5x |
| 20 files, avg 8s | 160s | 28s | 5.7x |
| 30 files, mixed | 420s | 65s | 6.5x |

**Success Criteria:**

- ✅ Auto-detect CPU cores (macOS/Linux)
- ✅ Create worker pool with N workers
- ✅ Distribute jobs optimally
- ✅ Real-time progress display
- ✅ Achieve 3-10x speedup on benchmark
- ✅ Graceful error handling
- ✅ All tests passing

**Dependencies:** None (independent wave)

---

### Wave 3: Custom Validators Framework (2-3 hours)

**Goal:** Create extensible validation framework with plugin support

**Files to Create:**

1. `lib/custom-validators.zsh` (300-350 lines)
   - Validator discovery (.teach/validators/)
   - Validator execution engine
   - Result aggregation
   - Plugin API definition

2. `.teach/validators/check-citations.zsh` (150-200 lines)
   - Extract [@citations] from .qmd files
   - Verify against references.bib
   - Report missing/invalid citations

3. `.teach/validators/check-links.zsh` (150-200 lines)
   - Extract [links](urls) and ![images](paths)
   - Verify internal links exist
   - Check external URLs (HTTP status)
   - Report broken links

4. `.teach/validators/check-formatting.zsh` (100-150 lines)
   - Check heading structure (h1 → h2 → h3)
   - Verify code chunk options
   - Check consistent quote styles
   - Report formatting issues

**Files to Modify:**

- `lib/dispatchers/teach-dispatcher.zsh` - Add --custom flag to validate

**Validator Plugin API:**

```zsh
#!/usr/bin/env zsh
# .teach/validators/example-validator.zsh

# Required: Validator metadata
VALIDATOR_NAME="Example Validator"
VALIDATOR_VERSION="1.0.0"
VALIDATOR_DESCRIPTION="Checks example conditions"

# Required: Main validation function
_validate() {
    local file="$1"
    local errors=()

    # Validation logic here
    # Add errors: errors+=("Error message")

    # Return 0 if valid, 1 if errors found
    [[ ${#errors[@]} -eq 0 ]]
}

# Optional: Initialization
_validator_init() {
    # Setup code (check dependencies, etc.)
}

# Optional: Cleanup
_validator_cleanup() {
    # Cleanup code
}
```

**Testing:**

- `tests/test-custom-validators-unit.zsh` (40-50 tests)
- `tests/test-builtin-validators-unit.zsh` (30-40 tests)
- Validator discovery and loading
- Citation checking logic
- Link validation (internal/external)
- Formatting checks
- Error reporting and aggregation

**Success Criteria:**

- ✅ Discover validators in .teach/validators/
- ✅ Execute validators with file input
- ✅ Aggregate results across validators
- ✅ 3 built-in validators working
- ✅ Clear plugin API documentation
- ✅ All tests passing

**Dependencies:** None (independent wave)

---

### Wave 4: Advanced Caching Strategies (1-2 hours)

**Goal:** Implement selective cache management and analysis

**Files to Create:**

1. `lib/cache-analysis.zsh` (200-250 lines)
   - Cache size breakdown by directory
   - File age analysis
   - Cache hit rate calculation
   - Optimization recommendations

**Files to Modify:**

- `lib/cache-helpers.zsh` - Add selective clear operations
- `lib/dispatchers/teach-dispatcher.zsh` - Enhance teach cache command

**New Cache Commands:**

```bash
teach cache clear --lectures     # Clear lectures/ only
teach cache clear --assignments  # Clear assignments/ only
teach cache clear --old          # Clear files > 30 days
teach cache clear --unused       # Clear never-hit files

teach cache analyze              # Detailed breakdown
teach cache analyze --recommend  # With suggestions
```

**Cache Analysis Output:**

```
Cache Analysis Report
─────────────────────────────────────────────────────
Total: 71MB (342 files)

By Directory:
  lectures/      45MB (215 files)  63%
  assignments/   22MB (108 files)  31%
  slides/         4MB  (19 files)   6%

By Age:
  < 7 days       18MB  (85 files)  25%
  7-30 days      31MB (158 files)  44%
  > 30 days      22MB  (99 files)  31%

Cache Performance:
  Hit rate:      94% (last 7 days)
  Miss rate:      6%
  Avg hit time:   0.3s
  Avg miss time: 12.5s

Recommendations:
  • Clear > 30 days: Save 22MB (99 files)
  • Clear unused: Save 8MB (34 files)
  • Keep < 30 days: Preserve 94% hit rate
```

**Testing:**

- `tests/test-cache-analysis-unit.zsh` (30-40 tests)
- Selective clearing operations
- Size/age analysis accuracy
- Recommendation logic

**Success Criteria:**

- ✅ Selective cache clearing (by dir, by age)
- ✅ Detailed cache analysis
- ✅ Hit rate tracking
- ✅ Optimization recommendations
- ✅ All tests passing

**Dependencies:** Wave 2 (for hit rate tracking)

---

### Wave 5: Performance Monitoring System (1-2 hours)

**Goal:** Track render performance and visualize trends

**Files to Create:**

1. `lib/performance-monitor.zsh` (250-300 lines)
   - Performance log management
   - Metric collection (render time, cache hits)
   - Trend calculation (moving averages)
   - Visualization helpers (ASCII graphs)

2. `.teach/performance-log.json` (template)
   - JSON schema for performance data
   - Sample entries

**Files to Modify:**

- `lib/dispatchers/teach-dispatcher.zsh` - Add teach status --performance
- `lib/validation-helpers.zsh` - Instrument validation with metrics

**Performance Log Schema:**

```json
{
  "version": "1.0",
  "entries": [
    {
      "timestamp": "2026-01-20T14:30:00Z",
      "operation": "validate",
      "files": 12,
      "duration_sec": 45,
      "parallel": true,
      "workers": 8,
      "speedup": 3.5,
      "cache_hits": 8,
      "cache_misses": 4,
      "cache_hit_rate": 0.67,
      "avg_render_time_sec": 3.8,
      "slowest_file": "lectures/week-08.qmd",
      "slowest_time_sec": 15.2
    }
  ]
}
```

**Performance Dashboard:**

```bash
teach status --performance

Performance Trends (Last 7 Days)
─────────────────────────────────────────────────────
Render Time (avg per file):
  Today:     3.8s  ████████░░ (vs 5.2s week avg)
  Trend:     ↓ 27% improvement

Total Validation Time:
  Today:     45s   ██████████ (12 files, parallel)
  Serial:    156s  (estimated)
  Speedup:   3.5x

Cache Hit Rate:
  Today:     94%   █████████▓
  Week avg:  91%   █████████░
  Trend:     ↑ 3% improvement

Parallel Efficiency:
  Workers:   8
  Speedup:   3.5x  ███████░░░ (ideal: 8x)
  Efficiency: 44%   (good for I/O bound)

Top 5 Slowest Files:
  1. lectures/week-08.qmd    15.2s
  2. lectures/week-06.qmd    12.8s
  3. assignments/final.qmd   11.5s
  4. lectures/week-04.qmd     9.2s
  5. lectures/week-07.qmd     8.9s
```

**Testing:**

- `tests/test-performance-monitor-unit.zsh` (30-40 tests)
- Log writing and reading
- Metric calculation
- Trend analysis
- Visualization rendering

**Success Criteria:**

- ✅ Track render time per operation
- ✅ Calculate cache hit rates
- ✅ Compute moving averages
- ✅ Display ASCII trend graphs
- ✅ Identify slowest files
- ✅ All tests passing

**Dependencies:** Wave 2 (parallel metrics), Wave 4 (cache metrics)

---

### Wave 6: Integration + Documentation (2-3 hours)

**Goal:** Integrate all Phase 2 features and create comprehensive documentation

**Tasks:**

1. **Integration Testing** (1 hour)
   - `tests/test-phase2-integration.zsh` (40-50 tests)
   - End-to-end workflows combining multiple features
   - Profile + parallel rendering
   - Custom validators + performance monitoring
   - Full teach workflow with all Phase 2 features

2. **Documentation** (1.5 hours)
   - Update `docs/reference/TEACH-DISPATCHER-REFERENCE-v4.6.0.md`
   - Create `docs/guides/QUARTO-WORKFLOW-PHASE-2-GUIDE.md` (4,000+ lines)
   - Update README.md with Phase 2 features
   - Update CHANGELOG.md with v4.7.0 entry
   - Update CLAUDE.md with Phase 2 completion

3. **Performance Verification** (0.5 hours)
   - Run benchmarks on real teaching projects
   - Verify 3-10x speedup claims
   - Document actual performance improvements

**Documentation Outline:**

`docs/guides/QUARTO-WORKFLOW-PHASE-2-GUIDE.md`:

- Overview of Phase 2 features
- Profile Management
  - Profile detection and listing
  - Creating custom profiles
  - Switching between profiles
  - R package auto-installation
- Parallel Rendering
  - How it works (worker pools, queue optimization)
  - Performance benchmarks
  - Troubleshooting parallel rendering
- Custom Validators
  - Built-in validators (citations, links, formatting)
  - Creating custom validators
  - Validator API reference
- Performance Monitoring
  - Understanding performance metrics
  - Interpreting trend graphs
  - Optimizing slow files
- Complete Workflows
  - Daily teaching workflow with Phase 2
  - Semester setup with profiles
  - Large-scale content updates with parallel rendering
- Troubleshooting
  - Common issues and solutions
  - Performance debugging
  - Validator errors

**Testing:**

- Run all Phase 2 test suites (180+ tests)
- Verify 100% pass rate
- Performance benchmarks on sample projects

**Success Criteria:**

- ✅ All integration tests passing
- ✅ Comprehensive documentation complete
- ✅ Performance benchmarks documented
- ✅ All Phase 2 features working together
- ✅ Ready for PR to dev

**Dependencies:** Waves 1-5 (all previous waves)

---

## Risk Assessment

| Risk                               | Probability | Impact | Mitigation                             |
| ---------------------------------- | ----------- | ------ | -------------------------------------- |
| Parallel rendering complexity      | Medium      | High   | Start with simple worker pool, iterate |
| macOS-specific core detection      | Low         | Medium | Test on multiple macOS versions        |
| Custom validator plugin API        | Low         | Low    | Follow established plugin patterns     |
| Performance overhead of monitoring | Low         | Low    | Lazy initialization, sampling          |
| R package auto-install failures    | Medium      | Medium | Robust error handling, user prompts    |

---

## Testing Strategy

**Unit Tests:** 180+ tests across 6 test suites

- `tests/test-teach-profiles-unit.zsh` (40-50 tests)
- `tests/test-r-helpers-unit.zsh` (30-40 tests)
- `tests/test-parallel-rendering-unit.zsh` (50-60 tests)
- `tests/test-custom-validators-unit.zsh` (40-50 tests)
- `tests/test-cache-analysis-unit.zsh` (30-40 tests)
- `tests/test-performance-monitor-unit.zsh` (30-40 tests)

**Integration Tests:** 40-50 tests

- `tests/test-phase2-integration.zsh` (40-50 tests)
- End-to-end workflows
- Feature interaction testing

**Performance Benchmarks:**

- Serial vs parallel rendering (multiple file counts)
- Cache hit rate impact on performance
- Custom validator execution overhead
- Performance monitoring overhead

**Target:** 100% pass rate on all tests

---

## Implementation Timeline

**Orchestrated Approach (Estimated 10-12 hours):**

| Wave   | Duration | Dependencies | Agent Type           |
| ------ | -------- | ------------ | -------------------- |
| Wave 1 | 2-3h     | None         | backend-architect    |
| Wave 2 | 3-4h     | None         | performance-engineer |
| Wave 3 | 2-3h     | None         | backend-architect    |
| Wave 4 | 1-2h     | Wave 2       | backend-architect    |
| Wave 5 | 1-2h     | Waves 2, 4   | backend-architect    |
| Wave 6 | 2-3h     | Waves 1-5    | documentation-writer |

**Parallel Execution:**

- Waves 1, 2, 3 can run in parallel (independent)
- Wave 4 depends on Wave 2 completion
- Wave 5 depends on Waves 2 and 4
- Wave 6 depends on all previous waves

**Optimal Strategy:**

1. Launch Waves 1, 2, 3 in parallel (3 agents)
2. After Wave 2 completes → Launch Wave 4
3. After Waves 2 and 4 complete → Launch Wave 5
4. After all waves complete → Launch Wave 6

**Expected Completion:** 10-12 hours (orchestrated) vs 40-50 hours (manual)
**Time Savings:** 80-85%

---

## Success Metrics

**Functional:**

- ✅ Profile management system working
- ✅ Parallel rendering achieving 3-10x speedup
- ✅ Custom validator framework with 3+ validators
- ✅ Performance monitoring with trend visualization
- ✅ All 180+ tests passing (100%)

**Documentation:**

- ✅ 4,000+ lines of user-facing documentation
- ✅ Complete API reference for new features
- ✅ Updated CHANGELOG.md and README.md

**Performance:**

- ✅ Parallel rendering: 3-10x speedup (verified)
- ✅ Custom validators: < 5s overhead for 3 validators
- ✅ Performance monitoring: < 100ms overhead
- ✅ Cache analysis: < 2s for 1000+ files

**Quality:**

- ✅ No breaking changes to Phase 1 features
- ✅ Backward compatible with existing teaching.yml configs
- ✅ Clear error messages and user guidance
- ✅ Comprehensive test coverage

---

## Files Summary

**New Files (15-18):**

```
lib/profile-helpers.zsh
lib/r-helpers.zsh
lib/renv-integration.zsh
commands/teach-profiles.zsh
lib/parallel-helpers.zsh
lib/render-queue.zsh
lib/parallel-progress.zsh
lib/custom-validators.zsh
.teach/validators/check-citations.zsh
.teach/validators/check-links.zsh
.teach/validators/check-formatting.zsh
lib/cache-analysis.zsh
lib/performance-monitor.zsh
.teach/performance-log.json
tests/test-teach-profiles-unit.zsh
tests/test-r-helpers-unit.zsh
tests/test-parallel-rendering-unit.zsh
tests/test-render-queue-unit.zsh
tests/test-custom-validators-unit.zsh
tests/test-cache-analysis-unit.zsh
tests/test-performance-monitor-unit.zsh
tests/test-phase2-integration.zsh
docs/guides/QUARTO-WORKFLOW-PHASE-2-GUIDE.md
```

**Files to Modify (3-5):**

```
lib/dispatchers/teach-dispatcher.zsh
lib/dispatchers/teach-doctor-impl.zsh
lib/validation-helpers.zsh
lib/cache-helpers.zsh
flow.plugin.zsh (source new helpers)
```

**Total Lines:** ~4,500-5,500 new lines
**Test Lines:** ~1,800-2,200 test lines
**Documentation Lines:** ~4,000-5,000 lines

---

## Next Steps

1. **Review Plan:** Get user approval for Phase 2 approach
2. **Launch Wave 1:** Profile Management + R Package Detection
3. **Launch Waves 2-3:** Parallel Rendering + Custom Validators (parallel)
4. **Launch Waves 4-5:** Advanced Caching + Performance Monitoring (sequential)
5. **Launch Wave 6:** Integration + Documentation
6. **Create PR:** Phase 2 complete → PR to dev

---

**Plan Status:** ✅ Complete - Ready for Implementation
**Last Updated:** 2026-01-20

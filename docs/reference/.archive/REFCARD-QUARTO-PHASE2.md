# Quarto Workflow Phase 2 - Quick Reference

**Version:** 5.14.0
**Status:** Production Ready
**Test Coverage:** 322/322 tests passing (100%)

## Quick Start

```bash
# Enable Phase 2 features
export QUARTO_PARALLEL_RENDER=1       # Parallel rendering (default: on)
export QUARTO_MAX_PARALLEL=4          # Max parallel jobs (default: 4)
export QUARTO_ENABLE_VALIDATORS=1     # Custom validators
export QUARTO_ENABLE_CACHE_ANALYSIS=1 # Cache analysis tools

# Test Phase 2 features
teach cache status                     # View cache performance
teach validate --parallel              # Parallel validation
teach performance trends               # View performance trends
```

## Core Commands

### Parallel Rendering

```bash
# Automatic parallel rendering (when enabled)
teach deploy                          # Uses parallel rendering
teach render lectures/week-01.qmd     # Single file (no parallel)

# Queue management
teach queue status                    # View render queue
teach queue clear                     # Clear failed jobs
teach queue optimize                  # Optimize job order

# Performance monitoring
teach performance status              # Current metrics
teach performance trends              # Historical trends
teach performance report              # Detailed report
```

### Cache Management

```bash
# Cache status and analysis
teach cache status                    # Quick overview
teach cache analyze                   # Deep analysis
teach cache verify                    # Verify cache integrity

# Cache operations
teach cache clear --stale             # Clear old cache
teach cache clear --force             # Clear all cache
teach cache rebuild                   # Force rebuild

# Cache recommendations
teach cache doctor                    # Get optimization tips
```

### Custom Validators

```bash
# Run validators
teach validate                        # All validators
teach validate --parallel             # Parallel validation
teach validate lectures/              # Specific directory
teach validate --validator citations  # Single validator

# Built-in validators
teach validate --validator citations  # Check citation format
teach validate --validator formatting # Check YAML/code blocks
teach validate --validator links      # Check cross-references

# Custom validator management
teach validate list                   # List all validators
teach validate create my-check        # Create new validator
teach validate test my-check          # Test validator
```

## Performance Features

### Benchmarking

```bash
# Run benchmarks
teach benchmark render                # Render performance
teach benchmark validate              # Validation performance
teach benchmark full                  # Complete workflow

# Compare results
teach benchmark compare v1.0 v2.0     # Compare two versions
teach benchmark history               # View all benchmarks
```

### Optimization

```bash
# Auto-optimize settings
teach performance optimize            # Analyze & suggest

# Manual tuning
export QUARTO_MAX_PARALLEL=8          # Increase parallelism
export QUARTO_CHUNK_SIZE=2            # Smaller work chunks
export QUARTO_WORKER_TIMEOUT=300      # 5-minute timeout
```

## Configuration

### Environment Variables

```bash
# Parallel Rendering
QUARTO_PARALLEL_RENDER=1              # Enable parallel (default: 1)
QUARTO_MAX_PARALLEL=4                 # Max workers (default: 4)
QUARTO_CHUNK_SIZE=1                   # Files per job (default: 1)
QUARTO_WORKER_TIMEOUT=300             # Timeout in seconds (default: 300)

# Cache Management
QUARTO_ENABLE_CACHE_ANALYSIS=1        # Enable analysis (default: 1)
QUARTO_CACHE_TTL=86400                # Cache lifetime (default: 24h)
QUARTO_CACHE_MAX_SIZE=1G              # Max cache size (default: 1G)

# Validation
QUARTO_ENABLE_VALIDATORS=1            # Enable validators (default: 1)
QUARTO_PARALLEL_VALIDATE=1            # Parallel validation (default: 1)
QUARTO_VALIDATOR_TIMEOUT=60           # Validator timeout (default: 60s)

# Performance
QUARTO_ENABLE_PERFORMANCE_LOG=1       # Log performance (default: 1)
QUARTO_PERFORMANCE_LOG_FILE=.teach/performance-log.json
```

### Project Configuration

```yaml
# .teach/config.yml additions for Phase 2
quarto:
  parallel:
    enabled: true
    max_workers: 4
    chunk_size: 1
    timeout: 300

  cache:
    analysis_enabled: true
    ttl: 86400
    max_size: "1G"

  validation:
    enabled: true
    parallel: true
    timeout: 60
    validators:
      - citations
      - formatting
      - links

  performance:
    logging: true
    log_file: .teach/performance-log.json
    retention_days: 90
```

## Custom Validators

### Creating a Validator

```bash
# Create validator skeleton
teach validate create check-equations

# Edit .teach/validators/check-equations.zsh
# Add validation logic
# Test it
teach validate test check-equations
```

### Validator Template

```bash
#!/usr/bin/env zsh
# check-equations.zsh - Validate LaTeX equations

# Function must return: 0 (pass) or 1 (fail)
validate_file() {
    local file="$1"
    local errors=0

    # Your validation logic here
    if grep -q '\\equation{' "$file"; then
        echo "ERROR: Use \\begin{equation} not \\equation{}"
        ((errors++))
    fi

    return $errors
}

# Entry point
validate_file "$1"
```

### Validator API

```bash
# Available helper functions
_flow_log_error "Message"              # Error message
_flow_log_warning "Message"            # Warning message
_flow_log_success "Message"            # Success message

# File utilities
grep -E 'pattern' "$file"              # Search patterns
wc -l < "$file"                        # Count lines
basename "$file"                       # Get filename
```

## Performance Monitoring

### Metrics Tracked

- **Render time**: Per-file and total
- **Validation time**: Per-validator and total
- **Cache hit rate**: Percentage of cache hits
- **Queue efficiency**: Parallel vs sequential time
- **Memory usage**: Peak memory per operation

### Reading Performance Logs

```bash
# View recent performance
cat .teach/performance-log.json | jq '.[-5:]'

# Calculate cache hit rate
teach cache analyze | grep "Hit rate"

# View slowest files
teach performance report | grep "slowest"

# Compare before/after
teach performance compare before.json after.json
```

## Common Workflows

### Deploy with Full Validation

```bash
# Sequential (traditional)
teach validate && teach deploy

# Parallel (Phase 2)
teach validate --parallel && teach deploy
# (deploy already uses parallel rendering)
```

### Weekly Content Update

```bash
# 1. Render new content
teach render lectures/week-05.qmd

# 2. Validate everything
teach validate --parallel

# 3. Check performance
teach cache status
teach performance status

# 4. Deploy if good
teach deploy
```

### Performance Tuning Session

```bash
# 1. Baseline benchmark
teach benchmark full > baseline.txt

# 2. Clear cache for clean test
teach cache clear --force

# 3. Adjust settings
export QUARTO_MAX_PARALLEL=8
export QUARTO_CHUNK_SIZE=2

# 4. Re-benchmark
teach benchmark full > optimized.txt

# 5. Compare
teach benchmark compare baseline.txt optimized.txt

# 6. Check recommendations
teach performance optimize
```

### Custom Validator Development

```bash
# 1. Create validator
teach validate create check-style

# 2. Edit implementation
code .teach/validators/check-style.zsh

# 3. Test on single file
teach validate test check-style lectures/week-01.qmd

# 4. Test on all files
teach validate --validator check-style

# 5. Add to config
# Edit .teach/config.yml to include in default validators
```

## Troubleshooting

### Parallel Rendering Issues

```bash
# Check worker status
teach queue status

# View failed jobs
teach queue status | grep FAILED

# Clear failed jobs
teach queue clear

# Disable parallel temporarily
export QUARTO_PARALLEL_RENDER=0
teach deploy
```

### Cache Problems

```bash
# Verify cache integrity
teach cache verify

# Clear stale cache
teach cache clear --stale

# Force full rebuild
teach cache clear --force
teach deploy
```

### Validator Failures

```bash
# Test single validator
teach validate test citations lectures/week-01.qmd

# Debug validator output
zsh -x .teach/validators/check-citations.zsh lectures/week-01.qmd

# Disable problematic validator temporarily
export QUARTO_ENABLE_VALIDATORS=0
teach deploy
```

### Performance Issues

```bash
# Check system resources
teach performance status | grep "system"

# Reduce parallelism
export QUARTO_MAX_PARALLEL=2
teach deploy

# Clear cache to free memory
teach cache clear --stale

# Check for slow files
teach performance report | grep "slowest"
```

## Performance Benchmarks

### Expected Speedup (Phase 2 vs Phase 1)

| Operation          | Phase 1 | Phase 2 | Speedup |
|--------------------|---------|---------|---------|
| Deploy 10 lectures | 120s    | 35s     | 3.4x    |
| Validate full site | 45s     | 15s     | 3.0x    |
| Render single week | 12s     | 12s     | 1.0x    |

### Optimal Settings by Course Size

| Course Size    | Max Parallel | Chunk Size | Workers |
|----------------|--------------|------------|---------|
| Small (< 10)   | 2            | 1          | 2       |
| Medium (10-20) | 4            | 1          | 4       |
| Large (> 20)   | 8            | 2          | 8       |

## Key Files

### Phase 2 Libraries

```
lib/
├── parallel-helpers.zsh         # Parallel rendering system
├── parallel-progress.zsh        # Progress tracking
├── render-queue.zsh             # Job queue management
├── cache-analysis.zsh           # Cache analytics
├── cache-helpers.zsh            # Cache operations
├── custom-validators.zsh        # Validator framework
└── performance-monitor.zsh      # Performance tracking
```

### Phase 2 Tests

```
tests/
├── test-parallel-rendering-unit.zsh    # 508 tests
├── test-render-queue-unit.zsh          # 571 tests
├── test-cache-analysis-unit.zsh        # 536 tests
├── test-custom-validators-unit.zsh     # 546 tests
├── test-builtin-validators-unit.zsh    # 547 tests
├── test-performance-monitor-unit.zsh   # 733 tests
└── test-phase2-integration.zsh         # 1235 tests
```

### Configuration Files

```
.teach/
├── config.yml                   # Main configuration
├── performance-log.json         # Performance history
└── validators/                  # Custom validators
    ├── check-citations.zsh
    ├── check-formatting.zsh
    └── check-links.zsh
```

## Advanced Topics

### Worker Pool Architecture

Phase 2 uses a worker pool with atomic job distribution:

```
Master Process
    ↓
Job Queue (flock-based)
    ↓
Worker Pool (N workers)
    ├── Worker 1 → Job A
    ├── Worker 2 → Job B
    ├── Worker 3 → Job C
    └── Worker 4 → Job D
    ↓
Results Collection
```

### Cache Strategy

Smart caching with dependency tracking:

```
Source File Changes
    ↓
Check Dependencies (sourced R, cross-refs)
    ↓
Invalidate Affected Cache
    ↓
Rebuild Only Changed Files
```

### Validator Plugin System

Custom validators use a simple plugin API:

```bash
# Auto-discovered from .teach/validators/
# Must export validate_file() function
# Returns 0 (pass) or 1 (fail)
# Has access to flow-cli utilities
```

## See Also

- **Full Guide**: `docs/guides/QUARTO-WORKFLOW-PHASE-2-GUIDE.md`
- **Teaching Workflow**: `docs/reference/.archive/REFCARD-TEACHING-V3.md`
- **Git Integration**: `docs/reference/.archive/TEACHING-GIT-WORKFLOW-REFCARD.md`
- **API Reference**: `docs/reference/.archive/TEACH-DISPATCHER-REFERENCE-v4.6.0.md`

---

**Last Updated:** 2026-01-20
**Version:** 5.14.0

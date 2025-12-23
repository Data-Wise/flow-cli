# Architecture Health Dashboard

Real-time metrics for maintaining Clean Architecture principles.

## Features

✅ **Layer Distribution** - File count and percentage by layer
✅ **Dependency Violations** - Detects outward dependencies (breaks Clean Architecture)
✅ **Test Coverage** - Test count by layer
✅ **Code Complexity** - Lines of code distribution
✅ **Health Score** - Overall architectural health (0-100)

## Usage

```bash
# Run dashboard
npm run arch-dashboard

# Or directly
node cli/tools/arch-dashboard/index.js
```

## Metrics Explained

### Layer Distribution

Shows how code is distributed across the 4 layers:
- **Domain** - Should contain core business logic
- **Use Cases** - Application workflows
- **Adapters** - Interface implementations
- **Frameworks** - External dependencies

**Healthy balance:** Domain 15-25%, Use Cases 20-30%, Adapters 30-40%, Frameworks 15-25%

### Dependency Violations

Checks for **outward dependencies** (breaks Clean Architecture):

❌ **Violations:**
- Domain imports from Use Cases/Adapters/Frameworks
- Use Cases import from Adapters/Frameworks

✅ **Allowed:**
- Any layer imports from Domain
- Use Cases import from Domain
- Adapters import from Domain + Use Cases
- Frameworks import from anywhere

### Test Coverage

Total test files and breakdown by layer.

**Healthy ratio:** At least 0.5 tests per source file (50% coverage)

**Priority:** Domain and Use Cases should have highest test coverage

### Health Score

Composite score (0-100):

- **90-100**: ✅ Excellent - Clean Architecture maintained
- **75-89**: 🟢 Good - Minor issues
- **60-74**: 🟡 Fair - Needs attention
- **0-59**: 🔴 Needs Improvement - Significant violations

**Deductions:**
- Dependency violations: -20 points each (max -40)
- Low test coverage (< 50%): -30 points
- Low domain percentage (< 15%): -10 points

## CI Integration

Add to `package.json`:

```json
{
  "scripts": {
    "arch-check": "node cli/tools/arch-dashboard/index.js"
  }
}
```

Add to CI pipeline:

```yaml
# .github/workflows/ci.yml
- name: Architecture Health Check
  run: npm run arch-check
```

**Note:** Dashboard exits with code 1 if violations are found (fails CI build)

## Example Output

```
═══════════════════════════════════════════════════
   ARCHITECTURE HEALTH DASHBOARD
═══════════════════════════════════════════════════

📊 LAYER DISTRIBUTION
──────────────────────────────────────────────────
  domain         12 files  ████████████ 24%
  use-cases       8 files  ████████ 16%
  adapters       18 files  ████████████████████ 36%
  frameworks     12 files  ████████████ 24%
  TOTAL          50 files

🔗 DEPENDENCY HEALTH
──────────────────────────────────────────────────
  ✅ PERFECT: No dependency violations detected
     Checked 20 files

🧪 TEST COVERAGE
──────────────────────────────────────────────────
  Total Test Files: 28
  By Layer:
    domain           10 tests
    useCases          8 tests
    adapters          7 tests
    integration       3 tests

📏 CODE COMPLEXITY (Lines of Code)
──────────────────────────────────────────────────
  domain        1200 lines (30%)
  use-cases      800 lines (20%)
  adapters      1400 lines (35%)
  frameworks     600 lines (15%)
  TOTAL         4000 lines

🏆 OVERALL HEALTH SCORE
──────────────────────────────────────────────────
  95/100  ✅ EXCELLENT

═══════════════════════════════════════════════════
```

## Troubleshooting

### "No files found"

**Cause:** Running from wrong directory

**Fix:**
```bash
cd /path/to/flow-cli
npm run arch-dashboard
```

### False Positives

**Issue:** Legitimate cross-layer imports flagged as violations

**Fix:** Update detection patterns in `index.js`:

```javascript
// Exclude test files
if (file.includes('.test.js')) continue

// Exclude specific allowed patterns
if (content.match(/from\s+['"]\.\.\/adapters\/.*Repository/)) continue
```

## Future Enhancements

- [ ] Web dashboard (HTML/CSS visualization)
- [ ] Historical trend tracking
- [ ] Configurable thresholds
- [ ] Export to JSON/CSV
- [ ] Integration with code coverage tools (Istanbul, c8)
- [ ] Cyclomatic complexity metrics
- [ ] Coupling metrics (afferent/efferent)

---

**Last Updated:** 2025-12-23
**Part of:** Architecture Enhancement Plan (Phase 3)

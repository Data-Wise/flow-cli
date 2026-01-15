# RFC: Flow-CLI + Scholar Configuration Protocol

**RFC Number:** RFC-001
**Status:** Draft
**Created:** 2026-01-14
**Author:** DT (via Claude Code brainstorm session)
**Target:** Scholar v2.2.0, flow-cli v5.9.0

---

## Summary

This RFC proposes a formal configuration protocol between flow-cli and Scholar to enable deep integration for teaching workflows. The protocol establishes:

1. A shared JSON Schema for `.flow/teach-config.yml` validation
2. Clear ownership boundaries (which tool owns which config section)
3. Hash-based change detection for config synchronization
4. A `--config` flag for explicit config path passing

---

## Problem Statement

### Current State

flow-cli and Scholar both read `.flow/teach-config.yml` but with no formal coordination:

1. **Config Discovery**: Scholar searches parent directories, which can fail silently
2. **No Validation**: Invalid configs cause cryptic errors inside Claude
3. **No Sync**: Config changes mid-session aren't detected
4. **Unclear Ownership**: Both tools might write to the same section

### Pain Points Identified

| Issue | Impact | Frequency |
|-------|--------|-----------|
| Scholar can't find config from subdirs | Command fails | Common |
| Invalid config values | Cryptic errors | Occasional |
| Config edited mid-session | Stale data used | Rare |
| Section ownership ambiguous | Potential conflicts | Theoretical |

---

## Proposal

### 1. Shared JSON Schema

Create a shared schema file that both tools validate against:

**Location:** `lib/templates/teaching/teach-config.schema.json` (flow-cli)
**Also used by:** Scholar (via npm package or direct reference)

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["course"],
  "properties": {
    "course": { "$ref": "#/definitions/course" },
    "semester_info": { "$ref": "#/definitions/semester_info" },
    "branches": { "$ref": "#/definitions/branches" },
    "deployment": { "$ref": "#/definitions/deployment" },
    "scholar": { "$ref": "#/definitions/scholar" }
  }
}
```

### 2. Ownership Protocol

| Section | Owner | Read By | Write By |
|---------|-------|---------|----------|
| `course` | flow-cli | Both | flow-cli only |
| `semester_info` | flow-cli | Both | flow-cli only |
| `branches` | flow-cli | flow-cli | flow-cli only |
| `deployment` | flow-cli | flow-cli | flow-cli only |
| `scholar` | Scholar | Scholar | Scholar only |
| `examark` | Shared | Both | Manual only |
| `shortcuts` | flow-cli | flow-cli | flow-cli only |

**Rule:** Each tool MUST NOT write to sections it doesn't own.

### 3. Hash-Based Change Detection

flow-cli computes SHA-256 hash of config file:

```bash
# Stored at: $FLOW_DATA_DIR/cache/teach-config.hash
hash=$(shasum -a 256 .flow/teach-config.yml | cut -d' ' -f1)
```

On each command:
1. Compute current hash
2. Compare with cached hash
3. If different: reload config, update cache
4. Optional: notify Scholar if running

### 4. Explicit Config Flag (`--config`)

Scholar teaching commands accept `--config` flag:

```bash
# Current (implicit discovery)
claude --print "/teaching:exam Midterm"

# Proposed (explicit)
claude --print "/teaching:exam Midterm --config ~/.flow/teach-config.yml"
```

flow-cli wrapper automatically passes this flag:

```bash
# In teach-dispatcher.zsh
local config_path=$(_teach_find_config)
if [[ -n "$config_path" ]]; then
    scholar_cmd+=" --config \"$config_path\""
fi
```

---

## Implementation

### Phase 1: flow-cli (Completed in v5.9.0)

- [x] JSON Schema created: `lib/templates/teaching/teach-config.schema.json`
- [x] Config validator: `lib/config-validator.zsh`
- [x] Hash-based detection: `_flow_config_hash()`, `_flow_config_changed()`
- [x] Flag validation: `_teach_validate_flags()`
- [x] Enhanced status: Full inventory display

### Phase 2: Scholar Changes (This RFC)

**Required changes in Scholar:**

1. **Add `--config` flag support**
   - Location: `src/teaching/commands/*.ts`
   - Parse flag, use path for config loading
   - Skip directory search if explicit path provided

2. **Add JSON Schema validation**
   - Validate config on load
   - Use Zod or Ajv for runtime validation
   - Clear error messages for invalid configs

3. **Respect ownership protocol**
   - Only write to `scholar.*` section
   - Document this in CLAUDE.md

4. **Support hash notification (optional)**
   - Accept external signal to reload config
   - Via environment variable or file watch

### Phase 3: Integration Testing

- Test flow-cli → Scholar config passing
- Test validation error handling
- Test hash-based reload
- Test ownership boundaries

---

## Alternatives Considered

### A. Separate Config Files

**Idea:** `.flow/teach-config.yml` (flow-cli) + `.flow/scholar-config.yml` (Scholar)

**Rejected because:**
- Duplicates course info
- Users must edit two files
- More complex to maintain

### B. Environment Variable Config

**Idea:** Pass config as env var `TEACH_CONFIG_JSON`

**Rejected because:**
- Shell escaping issues
- Size limits on env vars
- Harder to debug

### C. No Formal Protocol

**Idea:** Keep current implicit behavior

**Rejected because:**
- Pain points continue
- Integration limited
- User friction unresolved

---

## Migration Path

### For Existing flow-cli Users

1. **No action required** - flow-cli v5.9.0 is backward compatible
2. Schema validation is non-blocking (warnings only)
3. `teach status` shows validation results

### For Scholar

1. Add `--config` flag with fallback to current behavior
2. Validate but don't block on first release
3. Strict validation in subsequent release

---

## Security Considerations

- Config paths validated against traversal attacks
- No secrets should be stored in teach-config.yml
- Schema prevents injection via malformed YAML

---

## Timeline

| Milestone | Target | Status |
|-----------|--------|--------|
| flow-cli implementation | v5.9.0 | ✅ Done |
| RFC finalized | 2026-01-14 | ✅ Done |
| Scholar PR created | TBD | Pending |
| Scholar implementation | v2.2.0 | Pending |
| Integration testing | After Scholar | Pending |

---

## References

- [SPEC-flow-scholar-integration-improvements-2026-01-14.md](SPEC-flow-scholar-integration-improvements-2026-01-14.md)
- [JSON Schema spec](https://json-schema.org/specification.html)
- [Turborepo config patterns](https://turborepo.dev/docs/reference/package-configurations)

---

## Appendix: Example Config

```yaml
# .flow/teach-config.yml - v3.0 (Scholar Integration)

# COURSE INFO (flow-cli owns)
course:
  name: "STAT 440"
  full_name: "Regression Analysis"
  semester: "Spring"
  year: 2026
  instructor: "Dr. Smith"

# SEMESTER INFO (flow-cli owns)
semester_info:
  start_date: "2026-01-13"
  end_date: "2026-05-01"

# BRANCHES (flow-cli owns)
branches:
  draft: "draft"
  production: "production"

# DEPLOYMENT (flow-cli owns)
deployment:
  web:
    type: "github-pages"
    branch: "production"
    url: "https://example.github.io/stat-440"

# SCHOLAR SETTINGS (Scholar owns)
scholar:
  course_info:
    level: "undergraduate"
    field: "statistics"
    difficulty: "intermediate"
  style:
    tone: "formal"
    notation: "statistical"
    examples: true
  topics:
    - "Linear Regression"
    - "Multiple Regression"
    - "Model Diagnostics"
```

---

**Document Version:** 1.0
**Review Status:** Ready for Scholar team review

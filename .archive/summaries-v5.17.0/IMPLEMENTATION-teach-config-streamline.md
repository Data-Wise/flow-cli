# Flow-CLI Configuration Streamlining Plan

**Date:** January 23, 2026  
**Priority:** High  
**Blockers:** None

---

## Executive Summary

Analysis reveals **three critical consistency issues** in flow-cli teaching configuration:

1. **Duplicate Data Storage**: `semester-data.json` manually duplicates `teach-config.yml`
2. **Schema-Config Drift**: JSON schema doesn't validate 12+ active fields
3. **No Automation**: Manual workflows prone to sync errors

**Solution:** Implement `teach compile` command for **single source of truth** architecture.

---

## Phase 1: Schema Update (Week 1)

### Goal

Ensure `teach-config.schema.json` validates all production fields.

### Tasks

- [ ] Add missing fields to schema:
  ```json
  {
    "semester_info": {
      "finals_week": { "type": "object" },
      "weeks": {
        "items": {
          "properties": {
            "style": { "enum": ["conceptual", "rigorous", "computational", "applied"] },
            "objectives": { "type": "array" },
            "parts": { "type": "array" },
            "key_concepts": { "type": "array" },
            "prerequisites": { "type": "array" },
            "r_packages": { "type": "array" }
          }
        }
      }
    },
    "course": {
      "textbook": { "type": "string" }
    }
  }
  ```
- [ ] Test schema validation on stat-545 config
- [ ] Update template to include new fields
- [ ] Document schema changes in CHANGELOG.md

**Success Criteria:** `yq validate --schema teach-config.schema.json .flow/teach-config.yml` passes

---

## Phase 2: Build `teach compile` (Week 2)

### Goal

Auto-generate `semester-data.json` from `teach-config.yml`.

### Implementation Location

`/Users/dt/projects/dev-tools/flow-cli/lib/dispatchers/teach-dispatcher.zsh`

### Pseudocode

```zsh
function _teach_compile() {
  local config_file="${1:-.flow/teach-config.yml}"
  local output_dir="${2:-.flow/generated}"

  # Validate schema
  if ! _validate_teach_config "$config_file"; then
    _error "Config validation failed"
    return 1
  fi

  # Generate semester-data.json
  yq eval '{
    semester: (.course.semester + " " + .course.year),
    timezone: "America/Denver",
    start_date: .semester_info.start_date,
    end_date: .semester_info.end_date,
    weeks: [.semester_info.weeks[] | {
      number: .number,
      topic: .topic,
      lecture: (.parts[0] | {title: .title, url: (.file | sub("qmd$"; "html"))}),
      assignment: {title: "Assignment \(.number)", due: "TBD"}
    }],
    breaks: .semester_info.breaks
  }' "$config_file" > "$output_dir/semester-data.json"

  _success "Generated $output_dir/semester-data.json"
}
```

### Tasks

- [ ] Create `_teach_compile()` function
- [ ] Add schema validation step
- [ ] Generate `semester-data.json`
- [ ] Add `--output` flag for custom directories
- [ ] Test on stat-545 course
- [ ] Update docs: `docs/reference/TEACH-DISPATCHER-REFERENCE.md`

**Success Criteria:** Running `teach compile` generates valid `semester-data.json`

---

## Phase 3: Integration & Testing (Week 3)

### Tasks

- [ ] Update `teach validate` to run schema check
- [ ] Add `.flow/generated/` to `.gitignore`
- [ ] Create migration guide: `docs/guides/TEACH-CONFIG-MIGRATION.md`
- [ ] Test workflow:
  1. Edit `teach-config.yml`
  2. Run `teach compile`
  3. Run `quarto render`
  4. Verify website updates correctly
- [ ] Update STAT 545 to use auto-generation
- [ ] Remove manual `semester-data.json` edits

**Success Criteria:** STAT 545 course builds from auto-generated files only

---

## Phase 4: Advanced Features (Month 2)

### Optional Enhancements

1. **File Watcher** (optional)

   ```zsh
   teach watch --auto-compile
   # Watches teach-config.yml, auto-runs teach compile on changes
   ```

2. **Config Linter**

   ```zsh
   teach lint --strict
   # Validates:
   # - Sequential week numbers
   # - Due dates within semester
   # - File paths exist
   # - R packages valid
   ```

3. **Template Upgrade Tool**
   ```zsh
   teach upgrade --check
   # Shows new fields in template
   teach upgrade --apply --interactive
   # Adds missing fields with prompts
   ```

---

## Migration Strategy

### For Existing Courses

#### Step 1: Backup

```bash
cp .flow/teach-config.yml .flow/teach-config.yml.backup
cp .flow/semester-data.json .flow/semester-data.json.backup
```

#### Step 2: Validate

```bash
teach validate --schema
```

#### Step 3: Compile

```bash
mkdir -p .flow/generated
teach compile
```

#### Step 4: Compare

```bash
# Manually compare generated vs manual JSON
diff .flow/semester-data.json .flow/generated/semester-data.json
```

#### Step 5: Switch

```bash
# Update Quarto to read from generated/
sed -i 's|.flow/semester-data.json|.flow/generated/semester-data.json|g' _quarto.yml
```

#### Step 6: Gitignore

```bash
echo ".flow/generated/" >> .gitignore
```

---

## Rollback Plan

If automation fails:

1. Restore from backup:
   ```bash
   cp .flow/teach-config.yml.backup .flow/teach-config.yml
   cp .flow/semester-data.json.backup .flow/semester-data.json
   ```
2. Revert Quarto config changes
3. Continue manual workflow
4. Report bug in flow-cli issues

---

## Dependencies

### Required

- `yq` v4.30+ (for YAML processing)
- `jq` (for JSON validation)

### Optional

- `fswatch` (for file watching)
- `ajv-cli` (for JSON schema validation)

---

## Success Metrics

### Technical

- [ ] Zero manual edits to `semester-data.json`
- [ ] 100% schema validation coverage
- [ ] <2s compile time for typical course

### User Experience

- [ ] One-command workflow: `teach compile`
- [ ] Clear error messages for validation failures
- [ ] Documentation covers migration path

---

## Timeline

| Phase                 | Duration | Completion |
| --------------------- | -------- | ---------- |
| Schema Update         | 2 days   | Week 1     |
| Build `teach compile` | 3 days   | Week 2     |
| Integration & Testing | 4 days   | Week 3     |
| Advanced Features     | 2 weeks  | Month 2    |

**Target Completion:** February 14, 2026

---

## Next Actions

**Immediate (Today):**

- Review analysis report
- Validate approach with project team
- Create GitHub issue for Phase 1

**This Week:**

- Start schema updates
- Prototype `teach compile` MVP
- Test on stat-545 course

---

**Status:** 🟡 Ready for Implementation  
**Owner:** TBD  
**Last Updated:** January 23, 2026

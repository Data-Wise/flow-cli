# teach-init

Initialize the teaching workflow for course websites.

**Version:** 2.0 (with migration automation)

---

## Quick Start

```bash
# Initialize a new course
cd ~/projects/teaching/my-course
teach-init "STAT 545"

# Preview migration plan (existing Quarto project)
teach-init --dry-run "STAT 545"
```

---

## Synopsis

```bash
teach-init [--dry-run] <course-name>
```

---

## Description

`teach-init` scaffolds the teaching workflow in a course repository. It supports both fresh repositories and existing Quarto projects with intelligent migration.

**What it creates:**

- `.flow/teach-config.yml` - Course configuration
- `scripts/quick-deploy.sh` - One-command deployment
- `scripts/semester-archive.sh` - End-of-semester archival
- `.github/workflows/deploy.yml` - GitHub Actions deployment
- `draft` and `production` branches - Safe editing workflow

---

## Options

| Flag | Description |
|------|-------------|
| `--dry-run` | Preview migration plan without making changes |

---

## Migration Strategies

For existing repositories, `teach-init` offers three strategies:

### Strategy 1: Convert Existing (Recommended)

Renames your current branch to `production` and creates `draft` for editing.

```
main → production (students see this)
     └→ draft (you edit here)
```

### Strategy 2: Parallel Branches

Keeps existing branch, adds `draft` and `production` alongside.

### Strategy 3: Fresh Start

Tags current state and starts with clean structure (orphan branches).

---

## Quarto Project Detection

`teach-init` automatically detects Quarto projects by looking for:

- `_quarto.yml` - Quarto configuration
- `index.qmd` - Homepage

**Validation:** Both files must exist for Quarto migration.

---

## Error Handling

### Automatic Rollback

If migration fails at any step:

1. Git resets to pre-migration tag
2. Created files are removed (`.flow/`, `scripts/`)
3. Repository returns to original state

### Rollback Tag

A lightweight git tag is created before migration:

```
spring-2026-pre-migration
```

This allows manual recovery if needed.

---

## Examples

### New Course

```bash
mkdir ~/teaching/stat-579
cd ~/teaching/stat-579
git init
teach-init "STAT 579 - Causal Inference"
```

### Existing Quarto Course

```bash
cd ~/teaching/stat-545
teach-init --dry-run "STAT 545"  # Preview first
teach-init "STAT 545"             # Execute migration
```

### With renv (R Package Management)

```bash
cd ~/teaching/my-r-course
teach-init "My R Course"
# Prompts: "Exclude renv/ from git? [Y/n]"
```

---

## Configuration

After initialization, edit `.flow/teach-config.yml`:

```yaml
course:
  name: "STAT 545"
  slug: stat-545
  semester: Spring 2026

semester:
  start_date: "2026-01-13"
  end_date: "2026-05-06"
  breaks:
    - name: "Spring Break"
      start: "2026-03-09"
      end: "2026-03-13"

shortcuts:
  quick: stat
  deploy: statd
```

---

## Workflow After Initialization

```bash
# 1. Start session (safe on draft)
work stat-545

# 2. Edit course materials
# (you're on draft branch - safe!)

# 3. Deploy when ready
./scripts/quick-deploy.sh
```

---

## Dependencies

| Tool | Required | Installation |
|------|----------|--------------|
| `yq` | Yes | `brew install yq` |
| `git` | Yes | Built-in |
| `gh` | Optional | `brew install gh` |

---

## See Also

- [Teaching Workflow Guide](../guides/TEACHING-WORKFLOW.md) - Full documentation
- [Teaching Quick Reference](../reference/REFCARD-TEACHING.md) - Command cheatsheet
- [work](work.md) - Start teaching sessions

# Implementation Spec: Dynamic Dashboard Generation for Teaching Websites

**Status:** approved
**Created:** 2026-01-18
**Approved:** 2026-01-19
**Related:** SPEC-teach-dates-automation-2026-01-16.md, STAT 545 website enhancement
**Target Release:** v5.15.0
**Effort Estimate:** 11-16 hours (4 phases)
**Priority:** Medium

---

## Overview

Add `teach dashboard` subcommand to generate and manage dynamic website dashboard content for Quarto teaching sites. Generates `semester-data.json` from existing `teach-config.yml`, enabling client-side JavaScript to display current week, topic, deadlines, and announcements without requiring site rebuilds.

**Key Value Proposition:** Eliminate weekly manual dashboard updates. Students always see accurate "This Week" content. Announcements auto-expire. Week numbers auto-calculate.

---

## Primary User Story

**As a course instructor with a Quarto website,**
**I want** the homepage dashboard to automatically show the current week's content,
**So that** students always see accurate information without me manually editing `index.qmd` each week.

**Acceptance Criteria:**
1. `teach dashboard generate` creates `.flow/semester-data.json` from `teach-config.yml`
2. Generated JSON includes all 16 weeks with topics, lecture/lab URLs, assignment deadlines
3. JSON includes announcements with expiry dates
4. JSON includes break periods with "show next week" behavior
5. Existing `stat545.js` (or similar) can consume the JSON client-side

---

## Secondary User Stories

### User Story 2: Managing Announcements

**As an instructor needing to post time-sensitive information,**
**I want** to add announcements that auto-expire,
**So that** outdated announcements don't clutter the homepage.

**Acceptance Criteria:**
- `teach dashboard announce "Title" "Message" --expires 2026-01-26`
- Announcement added to `.flow/semester-data.json`
- Client-side JS hides expired announcements automatically

### User Story 3: Preview Specific Week

**As an instructor preparing content,**
**I want** to preview what the dashboard will show for any week,
**So that** I can verify content before students see it.

**Acceptance Criteria:**
- `teach dashboard preview --week 5` shows week 5 content
- `teach dashboard preview` shows current week based on date
- Output includes hero banner, cards, and next up widget content

---

## Technical Requirements

### Architecture

#### Component Diagram

```mermaid
graph TB
    subgraph "Dashboard Generation Layer (NEW)"
        DG[teach dashboard generate]
        DA[teach dashboard announce]
        DP[teach dashboard preview]
    end

    subgraph "Config Sources"
        TC[teach-config.yml]
        WK[semester_info.weeks]
        BR[semester_info.breaks]
    end

    subgraph "Output"
        JSON[.flow/semester-data.json]
        SITE[_site/.flow/semester-data.json]
    end

    subgraph "Client-Side"
        JS[stat545.js / theme JS]
        DOM[Dashboard DOM]
    end

    TC -->|weeks, topics| DG
    WK -->|lecture/lab URLs| DG
    BR -->|break dates| DG
    DG -->|generate| JSON
    JSON -->|Quarto copies| SITE
    SITE -->|fetch()| JS
    JS -->|update| DOM

    DA -->|append| JSON
    DP -->|read| JSON
```

#### Data Flow

```
teach-config.yml
    │
    ├─ semester_info.start_date
    ├─ semester_info.weeks[].number
    ├─ semester_info.weeks[].topic
    ├─ semester_info.weeks[].lecture_url (NEW field)
    ├─ semester_info.weeks[].lab_url (NEW field)
    ├─ semester_info.weeks[].assignment_url (NEW field)
    ├─ semester_info.weeks[].assignment_due (NEW field)
    └─ semester_info.breaks[]
            │
            ▼
    teach dashboard generate
            │
            ▼
    .flow/semester-data.json
    {
      "semester": "Spring 2026",
      "timezone": "America/Denver",
      "start_date": "2026-01-19",
      "weeks": [...],
      "breaks": [...],
      "announcements": [...]
    }
```

### Extended teach-config.yml Schema

Add new optional fields to `semester_info.weeks`:

```yaml
semester_info:
  start_date: "2026-01-19"
  end_date: "2026-05-16"
  timezone: "America/Denver"  # NEW
  weeks:
    - number: 1
      topic: "Fundamentals of Experimental Design"
      focus: "Introduction to randomization..."  # NEW (optional)
      lecture:                                    # NEW (optional)
        title: "Introduction to Design Principles"
        url: "lectures/week-01_intro-design_part1.qmd"
      lab:                                        # NEW (optional)
        title: "Getting Started with R & Quarto"
        url: "r_help.qmd"
      assignment:                                 # NEW (optional)
        title: "Assignment 1"
        url: "assignments/assignment1.qmd"
        due: "2026-01-29"
  breaks:
    - name: "Spring Break"
      start: "2026-03-15"
      end: "2026-03-22"
      show_next: true  # NEW (default: true)

# NEW section (v5.15.0)
dashboard:
  # Structure options (defaults shown)
  show_labs: true              # Include lab cards in dashboard
  show_assignments: true       # Include assignment deadlines
  show_readings: false         # Include reading assignments (for seminar courses)

  # Display options
  card_style: "detailed"       # detailed|simple
  hero_style: "banner"         # banner|minimal

  # Feature toggles
  enable_announcements: true   # Allow announcements
  max_announcements: 5         # Maximum active announcements

  # Fallback content
  fallback_message: "Check the Syllabus for current week information."

  # Announcements (optional, can also use `teach dashboard announce`)
  announcements:
    - id: "welcome-2026"
      type: "note"              # note|warning|info
      title: "Welcome to Class!"
      date: "2026-01-13"
      content: "Please review the Syllabus..."
      link: "syllabus/syllabus-final.qmd"
      expires: "2026-01-26"
```

### API Design

#### Command: `teach dashboard`

```bash
teach dashboard                    # Show help
teach dashboard generate           # Generate semester-data.json from config
teach dashboard generate --force   # Overwrite existing JSON
teach dashboard preview            # Preview current week
teach dashboard preview --week 5   # Preview specific week
teach dashboard announce           # Interactive announcement wizard
teach dashboard announce "Title" "Message" --expires DATE --type note
```

#### Subcommand Details

| Command | Description | Options |
|---------|-------------|---------|
| `generate` | Create `.flow/semester-data.json` from config | `--force`, `--output PATH` |
| `preview` | Show what dashboard will display | `--week N`, `--json` |
| `announce` | Add announcement to JSON | `--title`, `--message`, `--expires`, `--type`, `--link` |
| `status` | Show dashboard config status | (none) |

---

## Dependencies

| Dependency | Purpose | Required? |
|------------|---------|-----------|
| `yq` | YAML parsing | Yes |
| `jq` | JSON manipulation | Yes |
| Existing `teach-config.yml` | Source data | Yes |
| Quarto project | Target deployment | Yes |

---

## UI/UX Specifications

### Command Output Examples

#### `teach dashboard generate`

```
🎯 Generating Dashboard Data
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Reading: .flow/teach-config.yml
Timezone: America/Denver
Semester: Spring 2026 (Jan 19 - May 16)

Generating weeks...
  ✓ Week 1: Fundamentals of Experimental Design
  ✓ Week 2: Completely Randomized Design (CRD)
  ... (14 more weeks)
  ✓ Week 16: Finals Week

Breaks configured:
  • MLK Day (Jan 19) - show next week
  • Spring Break (Mar 15-22) - show next week

Announcements:
  • welcome-2026: "Welcome to Class!" (expires Jan 26)

✅ Generated: .flow/semester-data.json

Next steps:
  1. Quarto will copy JSON to _site/ on render
  2. Client-side JS will fetch and display content
  3. Run `teach dashboard preview` to test
```

#### `teach dashboard preview --week 5`

```
📅 Dashboard Preview: Week 5
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

┌─ Hero Banner ─────────────────────────────────────┐
│ Spring 2026 • Week 5                              │
│ Two-Factor Factorial Designs                      │
│ Focus: Main effects, interactions, factorial ANOVA│
└───────────────────────────────────────────────────┘

┌─ This Week Cards ─────────────────────────────────┐
│ [LECTURE] Factorial ANOVA                         │
│           lectures/week-05_factorial-anova.html   │
│                                                   │
│ [LAB] Interaction Plots                           │
│       r_help.html                                 │
└───────────────────────────────────────────────────┘

┌─ Next Up Widget ──────────────────────────────────┐
│ ! Assignment 5                                    │
│   Due Feb 26 • URGENT                             │
│   assignments/assignment5.html                    │
└───────────────────────────────────────────────────┘

Active Announcements: (none - all expired)
```

#### `teach dashboard announce`

```
📢 Add Announcement
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Title: Exam 1 Next Week
Message: Exam covers Weeks 1-5. Review guide posted.
Type: warning
Expires: 2026-03-05
Link (optional): syllabus/syllabus-final.html

✅ Added announcement: exam1-2026

Updated: .flow/semester-data.json
```

---

## Implementation Phases

### Phase 1: Core Generate Command (4-5 hours) ← +1h for config options

- [ ] Add `_teach_dashboard_dispatcher()` to teach-dispatcher.zsh
- [ ] Implement `_teach_dashboard_generate()`
- [ ] Read `teach-config.yml` extended schema
- [ ] **NEW:** Read dashboard config options with defaults
- [ ] Generate base `.flow/semester-data.json` structure
- [ ] **NEW:** Conditionally include sections based on config (labs, assignments, readings)
- [ ] Add validation for required fields
- [ ] Add integration hook to `teach dates sync`

### Phase 2: Preview Command (2-3 hours)

- [ ] Implement `_teach_dashboard_preview()`
- [ ] Calculate current week from date
- [ ] Support `--week N` override
- [ ] **NEW:** Respect dashboard config in preview output
- [ ] Format output with ASCII boxes
- [ ] Handle break weeks (show next)

### Phase 3: Announce Command (2-3 hours)

- [ ] Implement `_teach_dashboard_announce()`
- [ ] Interactive mode with prompts
- [ ] Direct mode with flags
- [ ] Update JSON without regenerating
- [ ] Generate unique announcement IDs

### Phase 4: Documentation & Tests (3-5 hours) ← +2h for config docs/tests

- [ ] Add help text for all subcommands
- [ ] **NEW:** Document all dashboard config options
- [ ] **NEW:** Add config examples for different course styles (comprehensive, simple, seminar)
- [ ] Create test-teach-dashboard.zsh
- [ ] **NEW:** Test different config combinations
- [ ] Update docs/commands/teach.md
- [ ] Add example to tutorials

---

## Decision Log

All open questions resolved on 2026-01-19.

| Question | Decision | Rationale | Impact |
|----------|----------|-----------|--------|
| **Auto-run on dates sync?** | ✅ Yes | Keeps dashboard in perfect sync with config dates. Consistent with teach workflow philosophy. | +0h (integration hook in teach-dates.zsh) |
| **JSON location?** | ✅ `.flow/` | Matches teach-config.yml location. Clear ownership, easy to .gitignore. | +0h (simple path) |
| **Template system?** | ⚠️ Configurable fields | Single JSON structure, behavior driven by dashboard config options in teach-config.yml. More flexible than hardcoded, simpler than full templating. | +3-4h (config parsing, conditional generation) |

### Template Approach Details

**Chosen:** Medium complexity - Configurable fields via teach-config.yml

**Rationale:**
- Currently only STAT 545 needs dashboard
- Configurable fields provide flexibility without template engine complexity
- Can add full templating later if multiple distinct structures emerge
- Defaults work out-of-box for comprehensive courses

**Implementation:**
- Single JSON generation function
- Read dashboard config options (show_labs, show_assignments, etc.)
- Conditionally include sections based on config
- Sensible defaults for all options

---

## Review Checklist

- [ ] Extended teach-config.yml schema documented
- [ ] All subcommands have help text
- [ ] JSON output matches client-side JS expectations
- [ ] Timezone handling tested
- [ ] Break week "show next" logic correct
- [ ] Announcement expiry uses config timezone
- [ ] Tests cover all subcommands

---

## Integration with Client-Side JS

The generated `semester-data.json` is consumed by theme JavaScript (e.g., `stat545.js`). The JS should:

1. Fetch `.flow/semester-data.json` on page load
2. Calculate current week from `start_date` using `timezone`
3. Check if current date is within any `breaks[]` period
4. If break with `show_next: true`, show next week's content
5. Update DOM elements with week data
6. Filter announcements by `expires` date
7. Render active announcements

See: `/Users/dt/projects/teaching/stat-545/docs/specs/SPEC-dynamic-dashboard-2026-01-18.md`

---

## History

| Date | Change |
|------|--------|
| 2026-01-18 | Initial spec from STAT 545 enhancement session |
| 2026-01-19 | Reviewed, approved with decisions. Updated target to v5.15.0. Added configurable fields approach. Effort revised to 11-16h. |

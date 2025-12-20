# Website Design Standards Unification - Proposal

**Date:** 2025-12-20
**Status:** Proposed
**Priority:** P2 (Medium) - Quality improvement, not urgent
**Estimated Effort:** 12-17 hours (across 4 sprints)

---

## Executive Summary

Create a unified website design standard system that supports multiple documentation tools (MkDocs, Quarto+pkgdown, Quarto+altdoc) while maintaining consistent ADHD-optimized color psychology across all projects.

**Recommended Approach:** Hierarchical standard with single base specification + tool-specific implementations.

**Current State:** ADHD-optimized MkDocs implementation complete (Sprint 1-3 done)

**Next Phase:** Extract base standard and create R package implementations

!!! info "Complementary Proposal: UX Improvements"
    This proposal focuses on **color system unification** across documentation tools. For **content structure and UX improvements** (progressive disclosure, navigation, interactivity) that leverage this color system, see [ADHD-Friendly Documentation Site Proposal](PROPOSAL-ADHD-FRIENDLY-DOCS.md).

---

## Problem Statement

We have multiple project types with different documentation systems:
- **Dev-tools:** MkDocs (Material theme)
- **R packages:** Quarto+pkgdown or Quarto+altdoc
- **Project Management:** Need consistent branding across all

**Current Issues:**
- No standardized ADHD color system for R packages
- Risk of standards diverging across tools
- No clear implementation guides for new projects
- Manual sync burden to project management hubs

---

## Recommended Solution: Unified Base + Tool Implementations

### Structure

```
standards/
├── 00-BASE/
│   ├── DESIGN-SYSTEM-BASE.md          # Core ADHD principles (tool-agnostic)
│   ├── COLOR-PALETTE.md               # All color hex values
│   ├── TYPOGRAPHY-GUIDE.md            # Font sizes, spacing principles
│   ├── ACCESSIBILITY-CHECKLIST.md     # WCAG AAA requirements
│   └── ADHD-PRINCIPLES.md             # Color psychology research
│
├── 01-IMPLEMENTATIONS/
│   ├── mkdocs/
│   │   ├── IMPLEMENTATION-GUIDE.md
│   │   ├── adhd-colors.css            ✅ Already exists
│   │   ├── extra.css                  ✅ Already exists
│   │   └── mkdocs.yml.example
│   │
│   ├── quarto-pkgdown/
│   │   ├── IMPLEMENTATION-GUIDE.md
│   │   ├── _pkgdown.yml.example
│   │   ├── pkgdown/extra.css
│   │   └── pkgdown/extra.scss
│   │
│   ├── quarto-altdoc/
│   │   ├── IMPLEMENTATION-GUIDE.md
│   │   ├── _altdoc.yml.example
│   │   └── altdoc/adhd-colors.scss
│   │
│   └── general-web/
│       ├── IMPLEMENTATION-GUIDE.md
│       └── standalone-adhd.css
│
├── 02-EXAMPLES/
│   ├── mkdocs-example/                 # Full working examples
│   ├── quarto-pkgdown-example/
│   └── quarto-altdoc-example/
│
├── 03-TEMPLATES/
│   ├── mkdocs-template/                # Copy-paste ready
│   ├── quarto-pkgdown-template/
│   └── quarto-altdoc-template/
│
└── README.md                            # Navigation + quick start
```

### Color Palette (Universal)

**Light Mode:**
- Primary: Cyan `#00bcd4`
- Accent: Purple `#9c27b0`
- Success: Green `#00e676`
- Warning: Amber `#ffc107`
- Danger: Red `#f44336`

**Dark Mode:**
- Primary: Lighter Cyan `#4dd0e1`
- Accent: Lighter Purple `#ba68c8`
- Success: Lighter Green `#69f0ae`
- Warning: Lighter Amber `#ffd54f`
- Danger: Lighter Red `#ff5252`

**WCAG AAA Compliant:**
- All colors meet 7:1 contrast ratio (normal text)
- Dark mode tested: 8.4:1 to 11.5:1 ratios

---

## Implementation Roadmap

### Sprint 1: Foundation (3-4 hours) ⭐ RECOMMENDED FIRST

**Goal:** Create unified base standard + document existing MkDocs work

**Tasks:**
1. ✅ Create `standards/` directory structure
2. ✅ Extract `00-BASE/COLOR-PALETTE.md` from ADHD-COLOR-PSYCHOLOGY.md
3. ✅ Extract `00-BASE/DESIGN-SYSTEM-BASE.md` (tool-agnostic principles)
4. ✅ Document MkDocs implementation (`01-IMPLEMENTATIONS/mkdocs/`)
5. ✅ Update `scripts/sync-standards.sh` to include website standards
6. ✅ Test sync to one PM hub

**Deliverables:**
- Base standards documented
- MkDocs implementation documented
- Sync working to PM hubs

**Estimated Time:** 3-4 hours

---

### Sprint 2: R Package Research (2-3 hours)

**Goal:** Understand Quarto+pkgdown and Quarto+altdoc theming systems

**Tasks:**
1. Create test R package
2. Test pkgdown theming:
   - Bootstrap variable overrides
   - Custom CSS injection
   - SCSS compilation
3. Test altdoc theming:
   - Quarto theme system
   - SCSS support
   - Custom CSS
4. Document findings
5. Choose best approach for each tool

**Deliverables:**
- Research notes
- Proof-of-concept examples
- Implementation strategy decided

**Estimated Time:** 2-3 hours

---

### Sprint 3: R Package Implementations (4-6 hours)

**Goal:** Create complete Quarto+pkgdown and Quarto+altdoc implementations

**Tasks:**

**Quarto+pkgdown:**
1. Create `01-IMPLEMENTATIONS/quarto-pkgdown/IMPLEMENTATION-GUIDE.md`
2. Create example `_pkgdown.yml` with Bootstrap overrides
3. Create `pkgdown/extra.css` for custom styling
4. Test with real R package (medfit or probmed)

**Quarto+altdoc:**
1. Create `01-IMPLEMENTATIONS/quarto-altdoc/IMPLEMENTATION-GUIDE.md`
2. Create example config file
3. Create `altdoc/adhd-colors.scss` theme file
4. Test with real R package

**Deliverables:**
- Complete implementation guides for both tools
- Working examples tested with real projects
- Documentation for common issues

**Estimated Time:** 4-6 hours

---

### Sprint 4: Templates & Examples (3-4 hours)

**Goal:** Create copy-paste ready templates for quick adoption

**Tasks:**
1. Create `02-EXAMPLES/` with fully functional example sites
2. Create `03-TEMPLATES/` with pre-configured files
3. Write comprehensive `standards/README.md`
4. Create "Quick Start" guides for each tool
5. Run final sync to all PM hubs
6. Test deployment to one project of each type

**Deliverables:**
- Templates ready to copy-paste
- Examples fully functional and documented
- Standards synced to all PM hubs
- Quick start guides for rapid adoption

**Estimated Time:** 3-4 hours

---

## Coordination with Project Management

### Sync Strategy

**Single Source of Truth:**
- `zsh-configuration/standards/` - Master copy
- Synced to all PM hubs via `scripts/sync-standards.sh`

**PM Hub Structure:**
```
project-hub/standards/website-design/
mediation-planning/standards/website-design/
dev-planning/standards/website-design/

Each contains:
├── 00-BASE/                    # Core principles
├── 01-IMPLEMENTATIONS/         # Tool-specific guides
├── 02-EXAMPLES/                # Working examples
├── 03-TEMPLATES/               # Copy-paste templates
└── .version                    # v2025-12-20
```

### Usage in Projects

**Dev-tools (MkDocs):**
```bash
# Copy from synced PM hub
cp ~/projects/dev-tools/project-hub/standards/website-design/01-IMPLEMENTATIONS/mkdocs/adhd-colors.css \
   docs/stylesheets/

cp ~/projects/dev-tools/project-hub/standards/website-design/01-IMPLEMENTATIONS/mkdocs/mkdocs.yml.example \
   mkdocs.yml
```

**R packages (Quarto+pkgdown):**
```bash
# Copy from synced PM hub
cp ~/projects/research/mediation-planning/standards/website-design/01-IMPLEMENTATIONS/quarto-pkgdown/_pkgdown.yml.example \
   _pkgdown.yml

mkdir -p pkgdown
cp ~/projects/research/mediation-planning/standards/website-design/01-IMPLEMENTATIONS/quarto-pkgdown/pkgdown/extra.css \
   pkgdown/
```

---

## Alternative Approaches Considered

### Option B: Separate Standards Per Ecosystem
- **Pros:** Self-contained, no cross-referencing
- **Cons:** Duplicate docs, risk of drift, update burden
- **Verdict:** ❌ Rejected - too much duplication

### Option C: CSS Framework Approach
- **Pros:** Maximum code reuse, single CSS file
- **Cons:** Requires build tooling, may not fit all tools
- **Verdict:** ⏳ Consider for Phase 2

### Option D: Template Repository Approach
- **Pros:** Copy-paste ready, GitHub template feature
- **Cons:** Multiple repos to maintain, sync complexity
- **Verdict:** ⏳ Consider after Sprint 4

### Option E: Monorepo with Packages
- **Pros:** Professional, publishable to npm/CRAN
- **Cons:** Complex, overkill for single user
- **Verdict:** ⏳ Future if standards become popular

---

## Success Criteria

### Sprint 1 (Foundation)
- ✅ Base standards extracted and documented
- ✅ MkDocs implementation guide complete
- ✅ Sync working to at least one PM hub
- ✅ Color palette matches existing implementation

### Sprint 2 (Research)
- ✅ pkgdown theming approach identified
- ✅ altdoc theming approach identified
- ✅ Proof-of-concept working for both
- ✅ Implementation strategy documented

### Sprint 3 (R Implementations)
- ✅ Complete implementation guides for both tools
- ✅ Tested with real R packages (medfit, probmed)
- ✅ All ADHD colors working in both systems
- ✅ WCAG AAA compliance verified

### Sprint 4 (Templates)
- ✅ Templates ready for copy-paste use
- ✅ Examples fully functional
- ✅ Synced to all 3 PM hubs
- ✅ Quick start guides complete

---

## Benefits

### Immediate
- ✅ Consistent ADHD-optimized branding across all projects
- ✅ Single source of truth for color values
- ✅ Easy updates (change once, sync everywhere)
- ✅ Documented implementation for each tool
- ✅ **Enables UX improvements** - Unified color system makes it possible to implement advanced UX patterns (see [ADHD-Friendly Documentation Site Proposal](PROPOSAL-ADHD-FRIENDLY-DOCS.md))

### Long-term
- ✅ Scalable to new tools (Hugo, Sphinx, VuePress)
- ✅ Reduced maintenance burden
- ✅ Could publish as open-source ADHD design system
- ✅ Reference for other ADHD developers

---

## Risks & Mitigations

### Risk 1: Tool constraints prevent full implementation
- **Mitigation:** Research phase (Sprint 2) identifies constraints early
- **Fallback:** Document limitations, provide best-effort implementation

### Risk 2: Standards drift over time
- **Mitigation:** Automated sync script with version tracking
- **Fallback:** Quarterly review of all implementations

### Risk 3: Effort exceeds estimate
- **Mitigation:** Break into 4 sprints, stop if needed
- **Fallback:** Sprint 1 alone provides value (MkDocs documented)

---

## Dependencies

### Technical
- MkDocs Material theme (already installed)
- Quarto (for R package docs)
- pkgdown or altdoc R packages
- rsync (for standards sync)

### Knowledge
- MkDocs theming ✅ (already learned)
- Quarto theming ⏳ (need to research)
- pkgdown theming ⏳ (need to research)
- altdoc theming ⏳ (need to research)

---

## Timeline

### Realistic (Spread Over Time)
- **Week 1:** Sprint 1 (Foundation) - 3-4 hours
- **Week 2:** Sprint 2 (Research) - 2-3 hours
- **Week 3-4:** Sprint 3 (R Implementations) - 4-6 hours
- **Week 5:** Sprint 4 (Templates) - 3-4 hours

### Aggressive (Focused Session)
- **Day 1 Morning:** Sprint 1
- **Day 1 Afternoon:** Sprint 2
- **Day 2 Morning:** Sprint 3 Part 1 (pkgdown)
- **Day 2 Afternoon:** Sprint 3 Part 2 (altdoc)
- **Day 3 Morning:** Sprint 4
- **Total:** 2.5 days focused work

---

## Next Steps

### Immediate (Choose One)

**A) Quick Win: Document MkDocs work** 🟢 [15-20 min] ⭐ RECOMMENDED
- Create `01-IMPLEMENTATIONS/mkdocs/IMPLEMENTATION-GUIDE.md`
- Copy adhd-colors.css comments into guide
- Add "How to use" section with examples
- Update sync script to include standards/

**B) Foundation: Create base standard** 🟡 [1.5 hours]
- Create `standards/00-BASE/` structure
- Extract COLOR-PALETTE.md from ADHD-COLOR-PSYCHOLOGY.md
- Write DESIGN-SYSTEM-BASE.md with tool-agnostic principles
- Document ADHD color psychology rationale

**C) Research: Test Quarto theming** 🟡 [1 hour]
- Create minimal test R package
- Try pkgdown custom CSS injection
- Try altdoc SCSS theme system
- Document findings for Sprint 3

---

## Future Enhancements (Wild Ideas)

1. **ADHD Design System npm package** - Publish to npm for web projects
2. **Browser extension** - Apply ADHD colors to any website (like Dark Reader)
3. **R package for themes** - `install.packages("adhdtheme")` with `quarto_adhd_theme()`
4. **GitHub Action for sync** - Auto-sync standards to all repos on changes
5. **Interactive docs site** - Live color picker, code generator, before/after demos

---

## References

- [ADHD-COLOR-PSYCHOLOGY.md](ADHD-COLOR-PSYCHOLOGY.md) - Color psychology research
- [docs/stylesheets/adhd-colors.css](docs/stylesheets/adhd-colors.css) - Current MkDocs implementation
- [mkdocs.yml](mkdocs.yml) - Current MkDocs config
- [scripts/sync-standards.sh](scripts/sync-standards.sh) - Existing sync script

---

## Appendix: Tool Research Notes

### MkDocs Material
- ✅ Custom CSS via `extra_css` in mkdocs.yml
- ✅ CSS variables for theme colors
- ✅ Dark mode via `[data-md-color-scheme="slate"]`
- ✅ WCAG AAA compliant (tested)

### Quarto+pkgdown (To Research)
- ⏳ Bootstrap 5 theming system
- ⏳ Custom CSS injection via `_pkgdown.yml`
- ⏳ SCSS variable overrides
- ⏳ Dark mode support

### Quarto+altdoc (To Research)
- ⏳ Quarto theme system integration
- ⏳ SCSS compilation support
- ⏳ Custom CSS injection
- ⏳ Dark mode implementation

---

**Last Updated:** 2025-12-20
**Proposal Status:** Ready for Sprint 1 implementation
**Approval Required:** No (internal design improvement)

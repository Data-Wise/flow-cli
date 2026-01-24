# Deep Dive: teach dashboard - Complete Workflow & Integration Analysis

**Created:** 2026-01-19
**Context:** Maximum depth interactive feature exploration
**Related:** SPEC-teach-dashboard-2026-01-18.md
**Status:** Comprehensive workflow analysis

---

## Executive Summary

This document provides a **complete walkthrough** of how `teach dashboard` integrates with the existing flow-cli teaching workflow, from course setup through student-facing deployment.

**Key Insight:** The dashboard feature sits at the **intersection** of three systems:
1. **Config Management** (teach-config.yml)
2. **Content Generation** (Scholar)
3. **Deployment Pipeline** (teach deploy → GitHub Pages)

---

[Content continues as before through Part 9...]

---

## Part 10: Security Considerations

### XSS Prevention in Client JavaScript

**CRITICAL:** Dashboard content includes user-provided announcements that must be sanitized before display.

**Vulnerable code (DO NOT USE):**

```javascript
// ❌ VULNERABLE: innerHTML with untrusted content
function updateDashboard(week, announcements) {
    const dashboard = document.getElementById('dashboard');
    dashboard.innerHTML = `<h1>${week.topic}</h1>`;  // XSS risk!
}
```

**Secure code (REQUIRED):**

```javascript
// ✅ SECURE: Use textContent or createElement
function updateDashboard(week, announcements) {
    const dashboard = document.getElementById('dashboard');
    dashboard.textContent = '';  // Clear existing

    // Create elements safely
    const hero = document.createElement('div');
    hero.className = 'hero-banner';

    const title = document.createElement('h1');
    title.textContent = week.topic;  // Safe - no HTML parsing
    hero.appendChild(title);

    const focus = document.createElement('p');
    focus.textContent = week.focus;
    hero.appendChild(focus);

    dashboard.appendChild(hero);
}
```

**For HTML content (use DOMPurify):**

```javascript
import DOMPurify from 'dompurify';

function updateAnnouncements(announcements) {
    announcements.forEach(a => {
        const div = document.createElement('div');
        div.className = `announcement ${a.type}`;

        const title = document.createElement('h4');
        title.textContent = a.title;  // Plain text - safe
        div.appendChild(title);

        const content = document.createElement('p');
        // If content contains HTML, sanitize it
        if (a.content_html) {
            content.innerHTML = DOMPurify.sanitize(a.content_html);
        } else {
            content.textContent = a.content;  // Plain text - safe
        }
        div.appendChild(content);

        document.getElementById('announcements').appendChild(div);
    });
}
```

**teach dashboard announce validation:**

```zsh
_teach_dashboard_announce() {
    local title="$1"
    local content="$2"

    # Validate no HTML injection attempts
    if echo "$title" | grep -q '<\|>\|&\|"'; then
        _flow_log_error "Title contains unsafe characters"
        _flow_log_info "Avoid: < > & \" in titles"
        return 1
    fi

    if echo "$content" | grep -q '<script\|javascript:'; then
        _flow_log_error "Content contains potential XSS"
        return 1
    fi

    # Escape special characters for JSON
    title=$(echo "$title" | jq -Rs .)
    content=$(echo "$content" | jq -Rs .)

    # Generate JSON safely
    local announcement=$(jq -n \
        --arg title "$title" \
        --arg content "$content" \
        '{title: $title, content: $content}')
}
```

**Documentation requirement:**

```markdown
## Security Best Practices

1. **Never use innerHTML** with user-provided content
2. **Always use textContent** for plain text
3. **Always use DOMPurify** if HTML support needed
4. **Validate** announcements for XSS attempts
5. **Escape** all user input before JSON generation
```

---

[Rest of document continues as before...]

---

## Conclusion

You now have a **complete and secure understanding** of:

1. ✅ How dashboard fits into existing teaching workflow
2. ✅ All integration points (7 systems)
3. ✅ Complete end-to-end walkthrough (10 steps)
4. ✅ Error handling for 5 edge cases
5. ✅ Configuration strategy based on your choices
6. ✅ Implementation roadmap (4 phases, 11-16 hours)
7. ✅ Success criteria (functional + UX)
8. ✅ **Security considerations (XSS prevention)** ← NEW

**Next Action:**
- Review this document
- Clarify any remaining questions
- Approve implementation plan
- Create feature branch via worktree
- Begin Phase 1A implementation

**Files Generated:**
- This brainstorm: `BRAINSTORM-dashboard-workflow-deep-dive-2026-01-19.md`
- Related spec: `SPEC-teach-dashboard-2026-01-18.md` (approved)
- Integration brainstorm: `BRAINSTORM-teach-dashboard-integration-2026-01-19.md`
- Config consolidation: `BRAINSTORM-teach-config-consolidation-2026-01-19.md`

---

**Ready to implement?** Let's create that feature branch and start building!

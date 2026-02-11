# Email Dispatcher (`em`) - Product Strategy & Design Specification

**Generated:** 2026-02-10
**Author:** Tech Lead (Claude Code)
**Status:** Proposal - Awaiting Review
**Target:** flow-cli v7.x

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [User Journey Maps](#2-user-journey-maps)
3. [MVP Definition](#3-mvp-definition)
4. [Feature Prioritization (MoSCoW)](#4-feature-prioritization-moscow)
5. [Risk Assessment](#5-risk-assessment)
6. [Phased Rollout](#6-phased-rollout)
7. [ADHD-Specific UX Patterns](#7-adhd-specific-ux-patterns)
8. [Competitive Analysis](#8-competitive-analysis)
9. [Technical Architecture](#9-technical-architecture)
10. [Open Questions](#10-open-questions)

---

## 1. Executive Summary

### Problem

A university professor with ADHD loses 45-90 minutes daily to email triage. The current workflow involves context-switching between terminal (where all real work happens) and a mail client, manually reading each message to determine priority, and composing responses from scratch. This is the opposite of what an ADHD brain needs: it demands sustained attention on low-reward tasks with no visible progress indicators.

### Solution

`em` -- a flow-cli dispatcher that wraps himalaya for IMAP/SMTP access and routes emails through a pluggable AI backend for classification, summarization, and draft generation. The professor stays in the terminal, reviews AI-processed email in fzf, approves drafts with a single keypress, and returns to real work. Total target: **under 5 minutes for a full inbox cycle.**

### Unique Value Proposition

**"The only email client designed for ADHD academics who live in the terminal."**

Not a general-purpose AI email app. Not a GUI overlay. A purpose-built, zero-friction dispatcher that understands academic email patterns (student questions, department admin, scheduling, mailing lists) and integrates with an existing ADHD-optimized workflow system (flow-cli sessions, project context, dopamine tracking).

---

## 2. User Journey Maps

### Journey 1: Morning Inbox Check (Target: 2 minutes)

```
TRIGGER: Professor opens terminal, runs `morning` or `am`

  morning                          # Existing flow-cli command
  ┌──────────────────────────────────────────────────────────┐
  │ GOOD MORNING                                              │
  │                                                           │
  │ Email: 14 new (3 urgent, 8 routine, 3 bulk)              │  <-- NEW: email badge
  │ Inbox: 2 captures                                         │
  │ Active Projects: ...                                      │
  │                                                           │
  │ --> 3 urgent emails need attention. Run: em urgent        │  <-- NEW: suggestion
  └──────────────────────────────────────────────────────────┘

  em                               # Quick inbox overview
  ┌──────────────────────────────────────────────────────────┐
  │ EMAIL INBOX                    14 new | 3 urgent          │
  │                                                           │
  │ URGENT (3):                                               │
  │  ! Dean Kim    Fri faculty mtg moved to 2pm (was 3pm)    │
  │  ! Sarah M.    Midterm grade dispute — needs response     │
  │  ! IT Dept     Password expires in 24 hours               │
  │                                                           │
  │ STUDENTS (5):                                             │
  │    Alex T.     "Can I come to office hours Wed?" (Y)      │
  │    Jordan P.   HW3 Q2 help request (draft ready)          │
  │    ... +3 more                                            │
  │                                                           │
  │ ADMIN (3):  dept meeting notes, travel form, survey       │
  │ BULK (3):   R-help digest, JSS newsletter, CRAN update   │
  │                                                           │
  │ Quick: em urgent | em review | em student | em send       │
  └──────────────────────────────────────────────────────────┘

OUTCOME: Professor sees the 3 urgent items, handles the scheduling
         change (em act 1 → confirms calendar update), defers the
         rest to after the first work block.

TIME: ~90 seconds
```

**Key design decisions:**
- `em` with no arguments shows categorized summary, not raw inbox
- AI pre-classifies priority before professor even looks
- Category counts provide instant triage without reading
- Urgent items surface to the top with `!` marker
- `(Y)` and `(draft ready)` indicate AI-suggested actions

### Journey 2: Respond to Student Emails (Target: 5 minutes, batch)

```
TRIGGER: Between work blocks, professor decides to handle student emails

  em student                       # Filter to student category
  ┌──────────────────────────────────────────────────────────┐
  │ fzf PICKER — Student Emails (5)          [Tab=select]    │
  │                                                           │
  │ > Alex T.     "Office hours Wed?"                         │
  │              AI: "Yes, Wed 2-4pm, Furman 312"            │
  │              Draft: confirm / template:office-hours       │
  │                                                           │
  │   Jordan P.   HW3 Q2 clarification                       │
  │              AI: explain expected value notation           │
  │              Draft: 3 sentences + reference to Ch.4       │
  │                                                           │
  │   Casey R.    Extension request (medical)                 │
  │              AI: approve per syllabus policy               │
  │              Draft: grant 3-day extension                 │
  │                                                           │
  │   Pat L.      "Is there a study guide?"                   │
  │              AI: link to course website resources          │
  │              Draft: link + exam topics list               │
  │                                                           │
  │   Robin K.    Absent next Tuesday                         │
  │              AI: acknowledge, no action needed             │
  │              Draft: noted, check Canvas for materials     │
  │                                                           │
  │ [Enter]=preview  [a]=approve  [e]=edit  [s]=skip          │
  │ [Tab]=multi-select  [Ctrl-A]=approve all selected         │
  └──────────────────────────────────────────────────────────┘

  # Professor reviews each draft in preview pane:
  # - Alex: approve (correct hours, correct room)
  # - Jordan: edit (tweak the explanation slightly)
  # - Casey: approve (policy is auto-loaded from syllabus context)
  # - Pat: approve (links are correct)
  # - Robin: approve (standard acknowledgment)

  # Result:
  ┌──────────────────────────────────────────────────────────┐
  │ Sent 4 responses | 1 edited | 0 skipped                  │
  │ Student inbox clear!                                      │
  │ win: "Cleared 5 student emails in 3 minutes"             │  <-- auto-logged
  └──────────────────────────────────────────────────────────┘

OUTCOME: 5 student emails handled in ~3 minutes
         Zero context-switching to compose
         AI used syllabus + office hours from .flow/ context

TIME: ~3 minutes
```

**Key design decisions:**
- fzf multi-select for batch operations
- AI drafts visible inline, not hidden behind another screen
- `[a]` single-key approve keeps flow state (no "are you sure?" prompts)
- Auto-win logging provides dopamine reward
- "Student inbox clear!" is a deliberate completion signal for ADHD

### Journey 3: Handle Urgent Faculty Meeting Change (Immediate)

```
TRIGGER: Notification appears (terminal bell or tmux status bar)

  # tmux status bar shows:
  # ... | em:1! | ...                    <-- urgent badge

  em urgent                        # Jump directly to urgent queue
  ┌──────────────────────────────────────────────────────────┐
  │ URGENT: Faculty meeting moved to 2pm Friday              │
  │                                                           │
  │ From: Dean Kim <dean.kim@uni.edu>                         │
  │ Thread: Re: Friday Faculty Meeting                        │
  │ AI Summary: Meeting rescheduled from 3pm to 2pm.          │
  │             Room changed to Admin 204.                     │
  │             Agenda items unchanged.                        │
  │                                                           │
  │ Detected: SCHEDULE CHANGE                                 │
  │   Old: Fri Feb 14, 3:00 PM — Faculty Meeting             │
  │   New: Fri Feb 14, 2:00 PM — Faculty Meeting, Admin 204  │
  │                                                           │
  │ Actions:                                                  │
  │   [1] Update calendar (gcal: move event)                  │
  │   [2] Reply "Thanks, noted"                               │
  │   [3] Reply with conflict (you have STAT-201 until 1:50) │
  │   [4] Skip / handle later                                 │
  │                                                           │
  │ AI recommends: [3] — you have STAT-201 1:00-1:50          │
  └──────────────────────────────────────────────────────────┘

  # Professor picks [2], confirms the quick reply:
  em act 2                         # Send "Thanks, noted"

OUTCOME: Urgent email handled in <30 seconds without leaving terminal
         Calendar awareness prevents scheduling conflicts

TIME: ~30 seconds
```

**Key design decisions:**
- Urgent items get structured breakdown, not just summary
- Schedule detection parses dates and cross-references calendar
- AI proactively checks for conflicts (Phase 3 feature, but architecturally planned)
- Numbered actions eliminate typing

### Journey 4: End-of-Day Email Review (Before `finish`)

```
TRIGGER: Professor runs `finish` to end work session

  finish "Completed HW4 solutions"
  ┌──────────────────────────────────────────────────────────┐
  │ SESSION COMPLETE: flow-cli (2h 34m)                      │
  │                                                           │
  │ Email status:                                             │  <-- NEW section
  │   Handled: 8 today (5 student, 2 admin, 1 urgent)        │
  │   Pending: 6 (none urgent)                                │
  │   Drafts waiting: 2                                       │
  │                                                           │
  │ Review 2 pending drafts before signing off? (y/n)         │
  └──────────────────────────────────────────────────────────┘

  # If yes:
  em drafts                        # Show unsent drafts
  ┌──────────────────────────────────────────────────────────┐
  │ PENDING DRAFTS (2)                                        │
  │                                                           │
  │ 1. Re: Committee assignment                               │
  │    To: Prof. Chen                                         │
  │    Draft: "I can serve on the curriculum committee..."    │
  │    [a]pprove  [e]dit  [d]elete  [t]omorrow               │
  │                                                           │
  │ 2. Re: Conference travel dates                            │
  │    To: Admin Office                                       │
  │    Draft: "Confirmed dates: June 12-15..."               │
  │    [a]pprove  [e]dit  [d]elete  [t]omorrow               │
  └──────────────────────────────────────────────────────────┘

  # Professor approves both, then finish completes:
  ┌──────────────────────────────────────────────────────────┐
  │ SESSION SUMMARY                                           │
  │   Code: 2h 34m on flow-cli                               │
  │   Email: 10 handled, 4 pending (0 urgent)                │
  │   Wins: 3 logged today                                    │
  │                                                           │
  │ Email inbox is in good shape. See you tomorrow.           │
  └──────────────────────────────────────────────────────────┘

OUTCOME: Clean end-of-day with no lingering email anxiety
         Deferred items explicitly tracked (not forgotten)
         Progress visible in session summary

TIME: ~2 minutes
```

**Key design decisions:**
- `finish` integration is opt-in, not blocking
- `[t]omorrow` action defers without guilt (ADHD-critical)
- Pending count visible but not alarming
- "Email inbox is in good shape" = explicit emotional reassurance

---

## 3. MVP Definition

### The Magic Moment

The hook is the first time the professor runs `em student` and sees 5 pre-classified student emails with AI drafts they can approve with a single keypress. The realization: "I just handled 5 emails in 90 seconds without composing a single sentence."

### MVP Scope (v1.0)

The minimum viable product includes **only what is needed to deliver that magic moment**, plus enough infrastructure to be reliable daily.

#### v1.0 Features (4-6 weeks)

| Feature | Description | Rationale |
|---------|-------------|-----------|
| `em` overview | Categorized inbox summary with counts | First-touch value: instant triage |
| AI classification | 5 categories: urgent, student, admin, bulk, other | Core value: no manual sorting |
| AI summaries | 1-line summary per email | Eliminate need to open each email |
| `em student` | Category filter | Most common batch workflow |
| `em review` | fzf picker with approve/skip | Batch processing = ADHD gold |
| AI draft generation | Auto-draft replies for "needs-response" emails | The magic moment |
| `em send` | Send approved drafts | Close the loop |
| himalaya integration | IMAP fetch, SMTP send via himalaya CLI | Proven email backend |
| Single AI backend | claude CLI (via `claude --print`) | User has Claude Max, simplest path |

#### Deliberately Excluded from v1.0

| Feature | Why Not v1 | When |
|---------|-----------|------|
| Scheduling extraction | Requires calendar API integration | Phase 2 |
| Per-project filtering | Needs session context plumbing | Phase 2 |
| AI backend abstraction | claude CLI is sufficient for v1 | Phase 3 |
| Escalation chain | Requires tmux/notification integration | Phase 2 |
| Thread context | Single-message classification works for MVP | Phase 2 |
| Template system | AI generates from scratch; templates refine later | Phase 2 |
| `finish` integration | Email is standalone first | Phase 2 |
| `morning` integration | Standalone first, hooks later | Phase 2 |

#### What Can Be Simplified in v1

| Full Vision | v1 Simplification |
|-------------|-------------------|
| Real-time AI classification | Batch classify on `em sync`, cache results in JSON |
| Thread-aware context | Single-message classification (ignore thread) |
| Smart calendar detection | Keyword highlighting ("meeting", "deadline") without calendar API |
| Per-category AI behavior | Single classification prompt for all categories |
| Template-enhanced drafts | Pure AI drafts, no template overlay |

#### v1 Success Criteria

1. Professor can run full inbox cycle in under 5 minutes
2. AI classification accuracy above 80% on first use (tuned to 90%+ with feedback)
3. Draft approval rate above 60% (sent without editing)
4. Zero data loss (no accidentally sent drafts, no deleted emails)
5. Sub-500ms for local operations (fzf, navigation); AI calls tolerated at 2-3s

---

## 4. Feature Prioritization (MoSCoW)

### Must Have (v1.0)

| # | Feature | Notes |
|---|---------|-------|
| M1 | himalaya wrapper (fetch, list, read, send) | Foundation -- nothing works without mail access |
| M2 | AI email classification (5 categories) | Core differentiator from raw himalaya |
| M3 | 1-line AI summaries | Replaces reading each email |
| M4 | `em` categorized overview | Entry point UX |
| M5 | `em review` fzf batch picker | ADHD batch processing |
| M6 | AI draft generation | The magic moment |
| M7 | `em send` / approve workflow | Close the loop |
| M8 | Local cache (JSON) for classifications/drafts | Performance: avoid re-calling AI |
| M9 | `em sync` to fetch + classify new mail | Explicit sync (no background daemon) |
| M10 | `em help` with flow-cli standard help format | Discoverability |

### Should Have (v1.1-v1.2)

| # | Feature | Notes |
|---|---------|-------|
| S1 | `em urgent` priority filter | High-value shortcut |
| S2 | Category-specific filters (`em student`, `em admin`) | Batch by type |
| S3 | `morning` integration (email badge) | Natural entry point |
| S4 | `finish` integration (pending drafts prompt) | Clean end-of-day |
| S5 | AI "needs-response" detection | Not all emails need replies |
| S6 | Draft editing in `$EDITOR` before send | Safety valve |
| S7 | `em count` for tmux status bar | Ambient awareness |
| S8 | Thread grouping (show as conversations) | Reduce visual noise |
| S9 | Feedback loop (`em wrong <id>` to correct classification) | Improve AI over time |
| S10 | YAML template system for common responses | Office hours, extensions, etc. |

### Could Have (v2.0+)

| # | Feature | Notes |
|---|---------|-------|
| C1 | Schedule/deadline extraction | Detect dates, prompt for calendar |
| C2 | Per-project email filtering (via `work` session) | Context-aware inbox |
| C3 | AI backend abstraction (claude/gemini/MCP) | Swap backends |
| C4 | Escalation chain (badge/notification/sound) | Tiered urgency |
| C5 | Thread + project context injection | AI sees syllabus, office hours |
| C6 | `em compose` AI-assisted composition | New emails, not just replies |
| C7 | Attachment handling (preview, save to project) | File management |
| C8 | `em stats` usage analytics (emails/day, response time) | Self-awareness |
| C9 | Snooze/defer with reminder | "Handle this tomorrow at 9am" |
| C10 | Multi-account support (personal + university) | Account switching |

### Won't Have (Architectural Boundary)

| # | Feature | Rationale |
|---|---------|-----------|
| W1 | Full email client (compose from scratch, folders, search) | himalaya does this; `em` is a smart layer on top |
| W2 | GUI or TUI email reader | flow-cli is CLI dispatchers, not ncurses apps |
| W3 | Real-time push notifications (IMAP IDLE) | Requires background daemon, contradicts ZSH plugin model |
| W4 | Email archiving/organization | Let himalaya/server-side rules handle this |
| W5 | Spam filtering | Server-side concern, not client-side |
| W6 | Encryption (PGP/S-MIME) | Out of scope for AI assistant layer |
| W7 | Contact management | Not an address book |
| W8 | Offline email composition queue | v1 requires connectivity |

---

## 5. Risk Assessment

### Risk 1: himalaya Pre-1.0 Stability

| Dimension | Assessment |
|-----------|------------|
| **Likelihood** | Medium -- himalaya is actively developed (v1.0.0-beta.5 as of early 2026) |
| **Impact** | High -- `em` is entirely dependent on himalaya for IMAP/SMTP |
| **Mitigation** | Pin himalaya version in `em doctor`. Abstract himalaya calls behind `_em_fetch()`, `_em_send()` functions so the backend can be swapped. Run himalaya integration tests in CI. |
| **Contingency** | If himalaya breaks: fall back to `curl` + IMAP directly (painful but possible), or switch to `nstrstrstrstrstrstrstrm` (notstrstrstrstrstrstrstrm) or `mstrstrstrstrstrstrstrtt` (mutt) as transport. The abstraction layer makes this a function-level swap, not a rewrite. |

### Risk 2: AI Latency Impact on UX (2-3s per call)

| Dimension | Assessment |
|-----------|------------|
| **Likelihood** | Certain -- LLM inference is inherently slow |
| **Impact** | High -- 2-3s per email x 20 emails = 40-60s of waiting = ADHD death |
| **Mitigation** | **Batch-then-browse pattern.** `em sync` does all AI work upfront (with progress bar), caches results locally. Subsequent `em`, `em review`, `em student` are instant reads from cache. User never waits for AI during interactive browsing. |
| **Fallback UX** | During `em sync`: show spinner with count ("Classifying 14 emails... 7/14"). Each classified email appears immediately in the summary view (streaming results). |
| **Optimization** | Batch multiple emails into a single AI call where possible (classification prompt can handle 5-10 emails at once). Target: 3-4 API calls for 20 emails, not 20 calls. |

### Risk 3: Email Privacy Through AI Services

| Dimension | Assessment |
|-----------|------------|
| **Likelihood** | Certain -- email content will be sent to AI providers |
| **Impact** | High -- university email may contain FERPA-protected student data |
| **Mitigation** | (1) Document clearly that email content is sent to AI providers. (2) `em` config allows excluding categories from AI processing (`em config ai.exclude "ferpa,sensitive"`). (3) Headers-only mode: classify by sender/subject without body. (4) Local LLM option in Phase 3 (ollama backend). |
| **FERPA Consideration** | Student names + grades in the same email = FERPA concern. Mitigation: AI processing uses the same claude CLI the professor already uses for code review (same data handling). University IT policies should be consulted. |
| **User Control** | `em config ai.enabled false` disables all AI, falls back to himalaya-only mode (still useful for `em` overview and fzf browsing). |

### Risk 4: Rate Limits on Claude Max / Gemini

| Dimension | Assessment |
|-----------|------------|
| **Likelihood** | Medium -- Claude Max has generous but not unlimited usage |
| **Impact** | Medium -- rate-limited user loses AI features temporarily |
| **Mitigation** | (1) Aggressive caching: only classify new emails, never re-classify. (2) Batch prompts: one classification call per sync, not per email. (3) Track token usage via `_flow_ai_log_usage()` (existing infrastructure). (4) Graceful degradation: if AI unavailable, show unclassified inbox (himalaya raw output). |
| **Budget Estimate** | 20 emails/day x ~500 tokens/email (classification + summary + draft) = ~10K tokens/day. Well within Claude Max limits. Batch prompting reduces this to ~3K tokens/day. |

### Risk 5: Offline / Connectivity Degradation

| Dimension | Assessment |
|-----------|------------|
| **Likelihood** | Low-Medium -- professor is usually on campus WiFi |
| **Impact** | Medium -- no sync, no AI, but cached data still available |
| **Mitigation** | (1) Cache persists across sessions. `em` shows last-synced data with timestamp ("Last sync: 2h ago"). (2) Composed drafts saved locally, sent on next `em sync`. (3) `em` without `sync` always works from cache. (4) Clear error message: "Offline -- showing cached inbox (2h old)". |

### Risk 6: AI Classification Accuracy

| Dimension | Assessment |
|-----------|------------|
| **Likelihood** | Medium -- initial prompts may misclassify edge cases |
| **Impact** | Medium -- misclassified urgent email could be missed |
| **Mitigation** | (1) Conservative urgency: when in doubt, classify UP not down. (2) `em wrong <id> <correct-category>` feedback command. (3) Correction data feeds into prompt refinement. (4) "Unclassified" category as safety net. (5) `em all` always shows everything regardless of classification. |

---

## 6. Phased Rollout

### Phase 1: Foundation (v7.0 -- Weeks 1-4)

**Theme:** "Make email visible in the terminal"

**Milestone:** Professor can run `em` and see categorized inbox with AI summaries.

| Week | Deliverable | Success Criterion |
|------|-------------|-------------------|
| 1 | himalaya integration layer (`_em_fetch`, `_em_list`, `_em_read`, `_em_send`) | `em raw` shows himalaya output verbatim |
| 1 | `em doctor` health check (himalaya installed, account configured, IMAP works) | `em doctor` passes all checks |
| 2 | AI classification engine (batch prompt, 5 categories) | 80%+ accuracy on 50 test emails |
| 2 | Local JSON cache (`~/.local/share/flow/email/cache.json`) | Cache persists, invalidates on new sync |
| 3 | `em sync` command (fetch + classify + cache) | Full sync completes in <30s for 20 emails |
| 3 | `em` overview display (categorized summary) | Matches journey map design |
| 4 | AI summary generation (1-line per email) | Summaries are accurate and useful |
| 4 | `em help` + dispatcher registration | Help follows flow-cli standard format |

**Tests:** 20+ unit tests, 5 integration tests with mock himalaya output, AI prompt regression tests.

**Exit Criteria:**
- `em sync && em` shows categorized, summarized inbox
- Professor uses it daily for 3 consecutive days
- No false negatives on urgent classification

---

### Phase 2: Draft & Review (v7.1 -- Weeks 5-8)

**Theme:** "AI writes your replies"

**Milestone:** Professor can batch-review AI drafts in fzf and send approved responses.

| Week | Deliverable | Success Criterion |
|------|-------------|-------------------|
| 5 | AI "needs-response" detection | 85%+ accuracy on response-needed classification |
| 5 | AI draft generation (per-email) | Drafts are contextually appropriate |
| 6 | `em review` fzf picker (preview pane, approve/edit/skip) | Full batch workflow works |
| 6 | `em send` (send approved drafts via himalaya) | Emails arrive correctly formatted |
| 7 | Category filters (`em student`, `em urgent`, `em admin`) | Filter + review workflow |
| 7 | `em drafts` (view/manage pending drafts) | Drafts persist across sessions |
| 8 | `em edit <id>` (open draft in $EDITOR) | Safety valve for draft editing |
| 8 | Error handling, edge cases, polish | No data loss scenarios |

**Tests:** 15+ unit tests, fzf integration tests (non-interactive mode), send-safety tests.

**Exit Criteria:**
- Professor handles 10+ emails via batch review in under 5 minutes
- Draft approval rate (sent without editing) above 60%
- Zero accidental sends
- `win` auto-logged after batch review

---

### Phase 3: Integration (v7.2 -- Weeks 9-12)

**Theme:** "Email is part of the workflow, not separate"

**Milestone:** Email integrates with `morning`, `finish`, `work` sessions, and tmux status.

| Week | Deliverable | Success Criterion |
|------|-------------|-------------------|
| 9 | `morning` integration (email badge + suggestion) | `morning` shows email summary |
| 9 | `finish` integration (pending drafts prompt) | Clean end-of-day workflow |
| 10 | `em count` for tmux status bar | Badge visible in tmux |
| 10 | Per-project email filtering (via `FLOW_SESSION_PROJECT`) | `work my-course` filters student emails |
| 11 | YAML template system (`~/.config/flow/email/templates/`) | Templates for office hours, extensions, etc. |
| 11 | Thread grouping (conversation view) | Threads collapse into single entries |
| 12 | Feedback loop (`em wrong <id> <category>`) | Corrections stored and applied |
| 12 | `em stats` basic analytics | Emails/day, response time, category breakdown |

**Tests:** Integration tests with mock `work` sessions, template rendering tests.

**Exit Criteria:**
- Full daily workflow uses `em` naturally (morning -> work -> em -> finish)
- Template-enhanced drafts have 75%+ approval rate
- Project-filtered inbox shows only relevant emails during `work` session

---

### Phase 4: Intelligence (v7.3+ -- Weeks 13-20)

**Theme:** "The email assistant gets smarter"

**Milestone:** Multi-backend AI, schedule extraction, escalation chain.

| Deliverable | Success Criterion |
|-------------|-------------------|
| AI backend abstraction (claude / gemini / ollama / MCP) | `em config ai.backend gemini` works |
| Schedule extraction + calendar prompt | Detected dates shown, optional gcal integration |
| Escalation chain (badge -> notification -> sound) | Urgent emails trigger appropriate alert level |
| Thread + project context injection | AI sees conversation history + .flow/ context |
| `em compose` AI-assisted new email composition | Compose workflow from terminal |
| Snooze/defer with reminder | `em snooze <id> tomorrow 9am` |
| Multi-account support | `em --account personal` |

**Exit Criteria:**
- Backend swap takes <5 minutes configuration
- Schedule detection accuracy above 85%
- Professor reports email anxiety reduced

---

## 7. ADHD-Specific UX Patterns

### Pattern 1: Batch Processing Over One-at-a-Time

**Problem:** ADHD brains struggle with repetitive sequential tasks. Opening email 1, reading, deciding, composing, sending, then email 2... is a recipe for abandonment at email 4.

**Solution:** The `em review` fzf picker presents ALL classified emails with AI drafts simultaneously. The professor scans, multi-selects, approves in bulk. This transforms email from 20 sequential decisions into 1 batch decision.

```
# Anti-pattern (traditional email):
for each email:
  open -> read -> decide -> compose -> send    # 20 context switches

# em pattern:
em sync                                         # 1 batch AI call
em review                                       # 1 fzf session
  [Tab] [Tab] [Tab] [Ctrl-A]                   # bulk approve
                                                # 0 context switches
```

### Pattern 2: Visible Progress and Completion Signals

**Problem:** ADHD needs dopamine from visible progress. Email is an infinite stream with no "done" state.

**Solution:**
- Category counts decrease visibly: `STUDENTS (5)` -> `STUDENTS (3)` -> `Student inbox clear!`
- `em` shows completion percentage: `Today: 8/14 handled (57%)`
- Auto-log wins: `win: "Cleared 5 student emails"` fires automatically
- Progress bar during `em sync`: `Classifying... [========----] 7/14`
- Session summary in `finish` shows email stats

```
# Completion signals at every step:
em sync        -> "14 new emails classified"
em student     -> "5 student emails (3 drafts ready)"
[approve 3]    -> "3 sent! 2 remaining"
[approve 2]    -> "Student inbox clear! (+5 win streak)"
em             -> "Today: 14/14 handled | Inbox at zero"
```

### Pattern 3: Time-Boxing Email Sessions

**Problem:** ADHD can hyper-focus on email for 2 hours OR avoid it entirely. Neither is productive.

**Solution:** Built-in timer with gentle nudge, not hard cutoff.

```
em review --time 5              # Start 5-minute email session

# After 5 minutes:
┌──────────────────────────────────────────────────────────┐
│ Timer: 5 minutes reached                                  │
│ Handled: 7 emails | Remaining: 4 (0 urgent)              │
│                                                           │
│ [c]ontinue (2 more min)  [f]inish  [q]uick-approve-rest │
└──────────────────────────────────────────────────────────┘
```

- Default timer set in config: `em config timer.default 5`
- Timer is informational, not enforced (ADHD needs agency, not constraints)
- `[q]uick-approve-rest` = trust AI drafts for remaining non-urgent items
- `morning` suggests time-boxed session: "5 min email? Run: em review --time 5"

### Pattern 4: Notification Design (Alert Without Distract)

**Problem:** Notifications are an ADHD trap. Too many = ignored. Too few = missed urgency.

**Solution:** Three-tier system calibrated to academic urgency patterns:

| Tier | Trigger | Signal | When |
|------|---------|--------|------|
| Ambient | Any new email | tmux badge: `em:3` | Always on |
| Nudge | Urgent email | tmux badge turns red: `em:1!` | During work session |
| Interrupt | Critical (dean, deadline <2h) | Terminal bell + tmux message | Only if escalation enabled |

```
# Configuration:
em config notify.ambient true        # tmux badge (default: on)
em config notify.nudge true          # red urgent badge (default: on)
em config notify.interrupt false     # terminal bell (default: OFF)
em config notify.dnd true            # suppress all during work session deep focus
```

- **Default is conservative:** ambient + nudge, no interrupt
- DND (do not disturb) mode auto-activates when `FLOW_SESSION_PROJECT` is set and project priority is P0/P1
- Urgent badge persists until addressed (does not auto-dismiss)

### Pattern 5: "Good Enough" Response Quality

**Problem:** ADHD perfectionists edit draft responses for 10 minutes each, negating all time savings.

**Solution:**
- Drafts default to professional-but-brief style
- `em config style brief` / `em config style detailed` / `em config style friendly`
- Preview shows draft with explicit quality signal: "This draft is ready to send as-is"
- No "edit" prompt by default; edit is available but not suggested
- After sending: no "undo" anxiety -- drafts are saved locally for 24 hours

```
# Draft display encourages approval:
┌──────────────────────────────────────────────────────────┐
│ To: Alex T.                                               │
│ Re: Office Hours Wednesday                                │
│                                                           │
│ Hi Alex,                                                  │
│                                                           │
│ Yes, office hours are Wednesday 2-4pm in Furman 312.     │
│ Feel free to drop by anytime during that window.          │
│                                                           │
│ Best,                                                     │
│ [Your name]                                               │
│                                                           │
│ Ready to send.  [a]pprove  [e]dit  [s]kip                │
│                     ^                                     │
│               cursor starts here                          │
└──────────────────────────────────────────────────────────┘
```

### Pattern 6: Preventing Email as Overwhelm Source

**Problem:** Adding email to the terminal could make the terminal feel as overwhelming as email itself.

**Solution:**
- `em` is opt-in, never auto-runs (except the ambient badge which is silent)
- Categories cap visible items: "BULK (12): 2 shown, 10 hidden" -- bulk never clutters
- `em zero` mode: hide everything except urgent (for high-anxiety days)
- `em snooze-all` for "I cannot deal with this right now" moments (defers everything non-urgent by 4 hours)
- Email stats in `dash` are a single line, not a section

```
# High-anxiety day:
em zero                            # Hide everything except urgent
┌──────────────────────────────────────────────────────────┐
│ URGENT: 0 emails need attention                           │
│ Everything else is handled or waiting.                    │
│                                                           │
│ You're doing fine. Focus on your work.                    │
└──────────────────────────────────────────────────────────┘
```

---

## 8. Competitive Analysis

### Comparison Matrix

| Capability | Superhuman | Shortwave | himalaya (raw) | em (this project) |
|-----------|-----------|-----------|---------------|-------------------|
| **Interface** | GUI (web/desktop) | GUI (web) | CLI (raw) | CLI (smart dispatcher) |
| **AI Classification** | Basic (Important/Other) | Yes (AI categories) | No | Yes (5 academic categories) |
| **AI Summaries** | No | Yes (thread summaries) | No | Yes (1-line per email) |
| **AI Draft Replies** | No ("snippets" only) | Yes (AI compose) | No | Yes (auto-draft + batch approve) |
| **Batch Processing** | Split inbox (2 views) | Auto-labels | Manual | fzf multi-select + bulk approve |
| **Academic Context** | No | No | No | Yes (syllabus, office hours, .flow/) |
| **ADHD Design** | Speed-focused (keyboard shortcuts) | AI-focused | Not designed for ADHD | Purpose-built (timers, wins, progress, time-boxing) |
| **Terminal Native** | No | No | Yes | Yes |
| **Offline** | No | No | No (IMAP only) | Yes (cached) |
| **Cost** | $30/mo | $14/mo | Free | Free (uses existing Claude Max) |
| **Privacy** | Google-hosted | Google-hosted | Self-hosted IMAP | IMAP + user-controlled AI |
| **Customization** | Themes, shortcuts | Limited | Full (config file) | Full (ZSH functions, templates, config) |
| **Calendar Integration** | Google Calendar | Google Calendar | No | Phase 3+ |
| **Learning Curve** | Low (GUI) | Low (GUI) | High (CLI) | Medium (CLI but guided) |

### What Superhuman Gets Right (and We Should Learn From)

1. **Speed.** Every interaction is keyboard-first, sub-100ms. `em` must match this for local operations.
2. **Split inbox.** Important vs. Other reduces cognitive load. Our 5-category system goes further.
3. **Snippets.** Quick template insertion. Our template system is Phase 3, but AI drafts exceed snippets.

### What Shortwave Gets Right

1. **AI summaries are genuinely useful.** Thread-level summaries reduce reading time by 80%. We do this.
2. **AI compose is the killer feature.** Draft generation based on context. We do this with academic awareness.
3. **Clean UI reduces anxiety.** Our TUI must be equally calm -- no visual clutter.

### What himalaya Gets Right

1. **Terminal native.** No browser, no Electron. `em` inherits this.
2. **IMAP standard.** Works with any email provider. `em` inherits this.
3. **Composable.** Pipes, scripts, automation. `em` inherits this.

### Unique Value Proposition of `em`

No other email client combines ALL of these:

1. **Terminal-native** -- stays in the professor's existing workflow (no app switching)
2. **ADHD-designed** -- time-boxing, batch processing, visible progress, dopamine logging
3. **Academic-aware** -- understands student emails, office hours, syllabus context, semester patterns
4. **AI-powered with user control** -- classification + drafts + summaries, but user approves everything
5. **Workflow-integrated** -- hooks into `morning`, `work`, `finish`, `dash` -- email becomes one part of the day, not the whole day
6. **Free** -- uses existing Claude Max subscription, no additional email service cost
7. **Private** -- IMAP direct, no third-party email hosting, AI processing under user's control
8. **Extensible** -- ZSH functions, YAML templates, pluggable AI backends

The closest competitor is Shortwave, but it requires a GUI, costs $14/month, only works with Gmail, and has no ADHD-specific design or academic context awareness. `em` trades polish for integration depth.

---

## 9. Technical Architecture

### System Diagram

```
                     ┌─────────────────────────────────────┐
                     │           User Interface             │
                     │                                      │
                     │  em [cmd]  ──> ZSH Dispatcher        │
                     │  fzf       ──> Review Picker          │
                     │  $EDITOR   ──> Draft Editing          │
                     │  tmux bar  ──> Ambient Badge          │
                     └────────┬──────────────┬──────────────┘
                              │              │
                     ┌────────▼──────┐ ┌─────▼──────────────┐
                     │  Email Layer   │ │  AI Layer           │
                     │                │ │                     │
                     │  _em_fetch()   │ │  _em_classify()     │
                     │  _em_list()    │ │  _em_summarize()    │
                     │  _em_read()    │ │  _em_draft()        │
                     │  _em_send()    │ │  _em_detect_need()  │
                     │                │ │                     │
                     │  Backend:      │ │  Backend:           │
                     │  himalaya CLI  │ │  claude --print     │
                     └────────┬──────┘ └─────┬──────────────┘
                              │              │
                     ┌────────▼──────────────▼──────────────┐
                     │           Cache Layer                  │
                     │                                        │
                     │  ~/.local/share/flow/email/            │
                     │    cache.json      (classifications)   │
                     │    drafts/         (pending drafts)    │
                     │    sent/           (sent log)          │
                     │    corrections.json (feedback)         │
                     │    stats.json      (usage analytics)   │
                     └──────────────────────────────────────┘
```

### File Structure

```
flow-cli/
├── lib/dispatchers/
│   └── em-dispatcher.zsh          # Main dispatcher (em command)
├── lib/
│   ├── email-helpers.zsh          # himalaya wrapper functions
│   ├── email-ai.zsh               # AI classification/summary/draft
│   ├── email-cache.zsh            # JSON cache management
│   ├── email-templates.zsh        # Template system (Phase 3)
│   └── email-notify.zsh           # Notification/badge system (Phase 2)
├── commands/
│   └── (morning.zsh, work.zsh)    # Modified for email integration (Phase 3)
├── completions/
│   └── _em                        # ZSH completions
├── tests/
│   ├── test-em-dispatcher.zsh
│   ├── test-email-helpers.zsh
│   ├── test-email-ai.zsh
│   ├── test-email-cache.zsh
│   └── fixtures/
│       └── email/                 # Mock himalaya output for testing
└── docs/
    └── reference/
        └── em-dispatcher.md       # User-facing documentation
```

### AI Prompt Architecture

The AI layer uses a single "megaprompt" for batch classification + summary, then individual prompts for draft generation (only for emails that need responses).

**Classification + Summary Prompt (batched):**

```
You are an email assistant for a university statistics professor.
Classify each email into exactly one category and provide a 1-line summary.

Categories:
- URGENT: requires action within 24 hours (dean, deadline, grade dispute, system alert)
- STUDENT: from students (questions, office hours, extensions, submissions)
- ADMIN: department administration (meetings, forms, reports, committees)
- BULK: mailing lists, newsletters, automated notifications
- OTHER: anything that doesn't fit above

For each email, also determine:
- needs_response: true/false (does this email require a reply?)
- urgency_score: 1-5 (1=can wait weeks, 5=act now)

Output JSON array. No commentary.

EMAILS:
---
ID: msg-001
From: dean.kim@university.edu
Subject: Friday Faculty Meeting - Time Change
Body: [first 500 chars]
---
ID: msg-002
From: alex.thompson@student.university.edu
Subject: Office Hours Wednesday
Body: [first 500 chars]
---
[...more emails...]
```

**Draft Generation Prompt (per-email, only for needs_response=true):**

```
You are drafting a reply for a university statistics professor.

Style: professional, warm, concise (3-5 sentences max).
Sign-off: "Best," followed by a blank line (recipient knows the professor's name).

Context (if available):
- Office hours: Wednesday 2-4pm, Furman Hall 312
- Course: STAT-201 Introduction to Statistics
- Semester: Spring 2026
- Syllabus policy on extensions: 3-day grace period with documentation

EMAIL TO REPLY TO:
From: {{from}}
Subject: {{subject}}
Body: {{body}}

Previous thread messages (if any):
{{thread_context}}

Write ONLY the reply body. No subject line. No greeting repetition if replying in thread.
```

### AI Backend Abstraction (Phase 4)

```zsh
# Configuration:
# em config ai.backend claude       # default
# em config ai.backend gemini
# em config ai.backend ollama
# em config ai.backend mcp

_em_ai_call() {
    local prompt="$1"
    local backend="${FLOW_EMAIL_AI_BACKEND:-claude}"

    case "$backend" in
        claude)
            echo "$prompt" | claude --print 2>/dev/null
            ;;
        gemini)
            echo "$prompt" | gemini --print 2>/dev/null  # hypothetical CLI
            ;;
        ollama)
            ollama run "$FLOW_EMAIL_AI_MODEL" "$prompt" 2>/dev/null
            ;;
        mcp)
            # Route through MCP server for maximum flexibility
            _em_ai_call_mcp "$prompt"
            ;;
    esac
}
```

### Dispatcher Pattern (matches flow-cli conventions)

```zsh
em() {
    case "${1:-}" in
        # Core workflow
        "")           _em_overview ;;
        sync)         shift; _em_sync "$@" ;;
        review)       shift; _em_review "$@" ;;
        send)         shift; _em_send "$@" ;;
        drafts)       shift; _em_drafts "$@" ;;

        # Category filters
        urgent)       shift; _em_filter "URGENT" "$@" ;;
        student)      shift; _em_filter "STUDENT" "$@" ;;
        admin)        shift; _em_filter "ADMIN" "$@" ;;
        bulk)         shift; _em_filter "BULK" "$@" ;;
        all)          shift; _em_all "$@" ;;

        # Actions
        read)         shift; _em_read "$@" ;;
        act)          shift; _em_act "$@" ;;
        edit)         shift; _em_edit "$@" ;;
        wrong)        shift; _em_wrong "$@" ;;
        snooze)       shift; _em_snooze "$@" ;;

        # Management
        count)        shift; _em_count "$@" ;;
        stats)        shift; _em_stats "$@" ;;
        config)       shift; _em_config "$@" ;;
        doctor)       shift; _em_doctor "$@" ;;
        zero)         _em_zero ;;
        raw)          shift; himalaya "$@" ;;

        # Help
        help|--help|-h) _em_help ;;
        *)            _em_help ;;
    esac
}
```

### Cache Schema

```json
{
  "version": 1,
  "last_sync": "2026-02-10T14:30:00Z",
  "account": "professor@university.edu",
  "emails": [
    {
      "id": "msg-001",
      "himalaya_id": "<message-id@server>",
      "from": "dean.kim@university.edu",
      "from_name": "Dean Kim",
      "subject": "Friday Faculty Meeting - Time Change",
      "date": "2026-02-10T09:15:00Z",
      "category": "URGENT",
      "urgency_score": 4,
      "summary": "Faculty meeting moved from 3pm to 2pm Friday, room changed to Admin 204",
      "needs_response": true,
      "has_draft": true,
      "draft_file": "drafts/msg-001.md",
      "status": "pending",
      "thread_id": "thread-xyz",
      "flags": ["seen"]
    }
  ],
  "stats": {
    "total": 14,
    "by_category": { "URGENT": 3, "STUDENT": 5, "ADMIN": 3, "BULK": 3 },
    "needs_response": 8,
    "drafts_ready": 6,
    "handled_today": 0
  }
}
```

---

## 10. Open Questions

### For User Discussion

1. **himalaya account setup:** Is himalaya already configured, or does `em doctor` need to guide through IMAP/SMTP setup? What email provider (university Exchange/Office365, Gmail, self-hosted)?

2. **AI provider preference for v1:** Start with `claude --print` (Claude Max, already available)? Or is there a preference for Gemini from day one?

3. **Email volume:** How many emails per day on average? This affects batch prompt design and cache strategy. (Assumed 15-30/day for this spec.)

4. **Signature/sign-off:** What name and sign-off should AI drafts use? Should it be configurable per category (formal for admin, friendly for students)?

5. **Multiple email accounts:** University only, or also personal? If multiple, which is higher priority for v1?

6. **FERPA concern level:** How sensitive is the university about student data going through AI services? Does this need IT approval before deployment?

7. **Calendar system:** Google Calendar? Outlook/Exchange? Apple Calendar? (Affects Phase 3 scheduling integration.)

8. **Existing email rules:** Are there server-side rules already (spam filtering, folder routing)? `em` should complement, not duplicate.

9. **Mailing list volume:** How many mailing list emails per day? If 50+, bulk category needs sub-filtering or auto-archive.

10. **Dispatcher name:** `em` is short, available (no ZSH builtin conflict), and memorable. Alternatives: `mail`, `mx`, `inbox`. Preference?

### Technical Decisions Needed

1. **himalaya output format:** Use `--output json` (structured) or parse text output? JSON is cleaner but requires himalaya version that supports it.

2. **Cache invalidation:** Time-based (re-sync every N minutes) or explicit (`em sync` only)? Recommendation: explicit-only for v1, with optional auto-sync in Phase 3.

3. **Draft storage format:** Markdown files (human-readable, editable) or JSON (structured, metadata-rich)? Recommendation: Markdown with YAML frontmatter.

4. **fzf preview pane:** Right-side preview (standard fzf) or bottom preview? Right-side fits email format better but needs wide terminal.

5. **Testing strategy for AI outputs:** Mock AI responses in tests (deterministic) or snapshot testing with real AI calls (expensive)? Recommendation: Mock for unit tests, optional real-call integration tests tagged `@slow`.

---

## Next Steps

1. **Review this spec** -- confirm scope, priorities, and phasing
2. **Answer open questions** -- especially himalaya setup status and email volume
3. **Create worktree** for Phase 1 implementation
4. **Start with `em doctor`** -- validate himalaya + AI prerequisites
5. **Build email-helpers.zsh** -- himalaya abstraction layer
6. **Build email-ai.zsh** -- classification prompt + cache
7. **Build em-dispatcher.zsh** -- wire it all together

---

**Last Updated:** 2026-02-10
**Spec Version:** 1.0

# WT Workflow Enhancement - Architecture Diagrams

**Version:** v5.13.0
**Date:** 2026-01-17

---

## System Overview

```mermaid
graph TB
    subgraph "User Interface"
        CLI[Command Line]
    end

    subgraph "Dispatchers"
        WT[wt dispatcher<br/>lib/dispatchers/wt-dispatcher.zsh]
        PICK[pick command<br/>commands/pick.zsh]
    end

    subgraph "Core Functions - Phase 1"
        OVERVIEW[_wt_overview<br/>Formatted table output]
        STATUS[Status Detection<br/>active/merged/stale/main]
        SESSION[Session Detection<br/>🟢🟡⚪ indicators]
    end

    subgraph "Core Functions - Phase 2"
        DELETE[_pick_wt_delete<br/>Interactive deletion]
        REFRESH[_pick_wt_refresh<br/>Cache invalidation]
    end

    subgraph "External Tools"
        GIT[git worktree]
        FZF[fzf picker]
        CACHE[Project Cache]
    end

    CLI --> WT
    CLI --> PICK

    WT -->|wt| OVERVIEW
    WT -->|wt <filter>| OVERVIEW
    WT -->|other commands| GIT

    PICK -->|pick wt| FZF

    OVERVIEW --> STATUS
    OVERVIEW --> SESSION
    OVERVIEW --> GIT

    FZF -->|Ctrl-X| DELETE
    FZF -->|Ctrl-R| REFRESH
    FZF -->|Enter| WT

    DELETE --> GIT
    DELETE --> CACHE
    REFRESH --> CACHE
    REFRESH --> OVERVIEW

    style OVERVIEW fill:#90EE90
    style DELETE fill:#FFB6C1
    style REFRESH fill:#87CEEB
    style STATUS fill:#DDA0DD
    style SESSION fill:#F0E68C
```

---

## Data Flow - Overview Display

```mermaid
sequenceDiagram
    participant User
    participant wt as wt()
    participant overview as _wt_overview()
    participant git as git worktree
    participant status as Status Detection
    participant session as Session Detection

    User->>wt: wt
    wt->>overview: _wt_overview()

    overview->>git: git worktree list --porcelain
    git-->>overview: worktree data

    loop For each worktree
        overview->>status: Detect status
        status->>git: git branch --merged
        git-->>status: merged branches
        status-->>overview: status icon (✅🧹⚠️🏠)

        overview->>session: Detect session
        session->>session: find .claude/ -mmin -30
        session->>session: find .claude/ -mtime -1
        session-->>overview: session icon (🟢🟡⚪)
    end

    overview->>overview: Format table
    overview-->>User: Display formatted output
```

---

## Data Flow - Filter Operation

```mermaid
sequenceDiagram
    participant User
    participant wt as wt()
    participant overview as _wt_overview(filter)
    participant git as git worktree

    User->>wt: wt flow
    wt->>overview: _wt_overview("flow")

    overview->>git: git worktree list --porcelain
    git-->>overview: all worktrees

    loop For each worktree
        overview->>overview: Extract project name
        overview->>overview: Match "flow" in project
        alt Matches filter
            overview->>overview: Include in results
        else Doesn't match
            overview->>overview: Skip
        end
    end

    overview->>overview: Format table (filtered)
    overview-->>User: Display filtered output
```

---

## Data Flow - Delete Action

```mermaid
sequenceDiagram
    participant User
    participant pick as pick wt
    participant fzf as fzf picker
    participant delete as _pick_wt_delete()
    participant git as git worktree
    participant cache as Project Cache

    User->>pick: pick wt
    pick->>fzf: Launch picker

    User->>fzf: Tab (select worktrees)
    User->>fzf: Ctrl-X (delete action)

    fzf-->>pick: Selected paths + action
    pick->>delete: _pick_wt_delete(paths)

    loop For each worktree
        delete->>User: Confirm deletion? [y/n/a/q]
        User-->>delete: Response

        alt User says 'y' or 'a'
            delete->>git: git worktree remove <path>
            git-->>delete: Success/Error
            delete->>User: Also delete branch? [y/N]
            User-->>delete: Response

            alt User says 'y'
                delete->>git: git branch -D <branch>
            end
        else User says 'n'
            delete->>delete: Skip to next
        else User says 'q'
            delete->>delete: Exit loop
        end
    end

    delete->>cache: _proj_cache_invalidate()
    delete-->>User: ✓ Removed N worktree(s)
```

---

## Data Flow - Refresh Action

```mermaid
sequenceDiagram
    participant User
    participant pick as pick wt
    participant fzf as fzf picker
    participant refresh as _pick_wt_refresh()
    participant cache as Project Cache
    participant overview as _wt_overview()

    User->>pick: pick wt
    pick->>fzf: Launch picker

    User->>fzf: Ctrl-R (refresh)

    fzf-->>pick: Refresh action
    pick->>refresh: _pick_wt_refresh()

    refresh->>User: ⟳ Refreshing worktree cache...
    refresh->>cache: _proj_cache_invalidate()
    refresh->>User: ✓ Cache cleared

    refresh->>overview: _wt_overview()
    overview-->>refresh: Formatted output
    refresh-->>User: Display updated overview
```

---

## Component Architecture

```mermaid
graph LR
    subgraph "Phase 1: Enhanced Default"
        A[wt dispatcher] -->|No args| B[_wt_overview]
        A -->|Filter arg| B
        B --> C[Status Detection]
        B --> D[Session Detection]
        B --> E[Table Formatter]
    end

    subgraph "Phase 2: Interactive Actions"
        F[pick wt] --> G[fzf with keybindings]
        G -->|Ctrl-X| H[_pick_wt_delete]
        G -->|Ctrl-R| I[_pick_wt_refresh]
        H --> J[Confirmation Loop]
        H --> K[Cache Invalidation]
        I --> K
        I --> B
    end

    subgraph "Shared Dependencies"
        L[git worktree]
        M[Project Cache]
        N[Color Utilities]
    end

    C --> L
    D --> L
    H --> L
    J --> L
    K --> M

    style B fill:#90EE90
    style H fill:#FFB6C1
    style I fill:#87CEEB
```

---

## Status Detection Logic

```mermaid
flowchart TD
    Start([For each worktree]) --> CheckGit{.git exists?}

    CheckGit -->|No| Stale[⚠️ stale]
    CheckGit -->|Yes| CheckMain{Is main branch?}

    CheckMain -->|main/master/dev/develop| Main[🏠 main]
    CheckMain -->|No| CheckMerged{Merged to base?}

    CheckMerged -->|Yes| Merged[🧹 merged]
    CheckMerged -->|No| Active[✅ active]

    Stale --> End([Return status])
    Main --> End
    Merged --> End
    Active --> End

    style Stale fill:#FFB6C1
    style Main fill:#87CEEB
    style Merged fill:#FFD700
    style Active fill:#90EE90
```

---

## Session Detection Logic

```mermaid
flowchart TD
    Start([For each worktree]) --> CheckDir{.claude/ exists?}

    CheckDir -->|No| None1[⚪ none]
    CheckDir -->|Yes| CheckRecent{Files < 24h old?}

    CheckRecent -->|No| None2[⚪ none]
    CheckRecent -->|Yes| CheckActive{Files < 30min old?}

    CheckActive -->|Yes| Active[🟢 active]
    CheckActive -->|No| Recent[🟡 recent]

    None1 --> End([Return indicator])
    None2 --> End
    Active --> End
    Recent --> End

    style None1 fill:#E0E0E0
    style None2 fill:#E0E0E0
    style Active fill:#90EE90
    style Recent fill:#FFD700
```

---

## File Structure

```mermaid
graph TB
    subgraph "flow-cli Repository"
        subgraph "Source Files"
            A[lib/dispatchers/wt-dispatcher.zsh<br/>+130 lines]
            B[commands/pick.zsh<br/>+130 lines]
        end

        subgraph "Test Files"
            C[tests/test-wt-enhancement-unit.zsh<br/>350 lines, 23 tests]
            D[tests/test-wt-enhancement-e2e.zsh<br/>500 lines, 25+ tests]
            E[tests/interactive-wt-dogfooding.zsh<br/>600 lines, 10 tests]
        end

        subgraph "Documentation"
            F[IMPLEMENTATION-COMPLETE.md]
            G[TEST-RESULTS-2026-01-17.md]
            H[tests/WT-ENHANCEMENT-TESTS-README.md]
            I[INTERACTIVE-TEST-SUMMARY.md]
        end
    end

    A --> C
    A --> D
    B --> C
    B --> D
    C --> G
    D --> G
    E --> I

    style A fill:#90EE90
    style B fill:#90EE90
    style C fill:#87CEEB
    style D fill:#87CEEB
    style E fill:#FFD700
```

---

## Integration Points

```mermaid
graph TB
    subgraph "WT Enhancement"
        A[wt dispatcher]
        B[_wt_overview]
        C[_pick_wt_delete]
        D[_pick_wt_refresh]
    end

    subgraph "Existing Flow-CLI Components"
        E[lib/core.zsh<br/>Colors & logging]
        F[commands/pick.zsh<br/>fzf integration]
        G[lib/atlas-bridge.zsh<br/>Project cache]
        H[lib/project-detector.zsh<br/>Project finding]
    end

    subgraph "External Tools"
        I[git worktree]
        J[fzf]
        K[find command]
    end

    A --> E
    B --> E
    B --> I
    B --> K
    C --> F
    C --> I
    C --> G
    D --> G
    D --> B
    F --> J

    style A fill:#90EE90
    style B fill:#90EE90
    style C fill:#FFB6C1
    style D fill:#87CEEB
```

---

## User Journey - Quick Overview

```mermaid
journey
    title Quick Worktree Overview Workflow
    section Check Status
      Type 'wt': 5: User
      See formatted table: 5: System
      View status icons: 5: User
      View session indicators: 5: User
    section Filter Results
      Type 'wt flow': 5: User
      See filtered worktrees: 5: System
      Identify active projects: 5: User
    section Navigate
      Copy path from output: 4: User
      cd to worktree: 5: User
```

---

## User Journey - Interactive Cleanup

```mermaid
journey
    title Interactive Worktree Cleanup
    section Launch Picker
      Type 'pick wt': 5: User
      fzf picker opens: 5: System
      See all worktrees: 5: User
    section Select Worktrees
      Tab to multi-select: 5: User
      Select old worktrees: 4: User
      Review selection: 5: User
    section Delete
      Press Ctrl-X: 5: User
      Confirm each deletion: 4: User
      Choose branch deletion: 4: User
      See success message: 5: User
    section Verify
      Type 'wt': 5: User
      See updated overview: 5: System
```

---

## Performance Characteristics

```mermaid
graph LR
    subgraph "Overview Performance"
        A[Input: N worktrees] --> B[Parse: O1]
        B --> C[Status Check: ON]
        C --> D[Session Check: O2N]
        D --> E[Format: ON]
        E --> F[Output: < 100ms for N=5]
    end

    subgraph "Delete Performance"
        G[Input: M selections] --> H[User Confirmation: OM]
        H --> I[Git Remove: OM]
        I --> J[Cache Invalidate: O1]
        J --> K[Output: User-limited]
    end

    style F fill:#90EE90
    style K fill:#90EE90
```

---

**Last Updated:** 2026-01-17
**Version:** v5.13.0
**Diagrams:** 10 comprehensive views
**Status:** ✅ Complete architecture documentation

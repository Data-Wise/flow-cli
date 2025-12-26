# Flow CLI - Architecture Diagrams

**Version:** 2.0.0-beta.1
**Architecture:** Clean Architecture (4-Layer)
**Last Updated:** 2025-12-24

---

## Table of Contents

- [System Overview](#system-overview)
- [Clean Architecture Layers](#clean-architecture-layers)
- [Component Diagram](#component-diagram)
- [Sequence Diagrams](#sequence-diagrams)
- [Data Flow](#data-flow)
- [Deployment Architecture](#deployment-architecture)

---

## System Overview

```mermaid
graph TB
    subgraph "User Interface"
        ZSH[ZSH Functions<br/>work, finish, dash]
        CLI[flow CLI<br/>status, dashboard]
        TUI[Interactive TUI<br/>blessed]
        WEB[Web Dashboard<br/>Express + WS]
    end

    subgraph "Application Layer"
        CONTROLLERS[Controllers<br/>StatusController]
        USECASES[Use Cases<br/>GetStatus, CreateSession]
    end

    subgraph "Domain Layer"
        ENTITIES[Entities<br/>Session, Project]
        VALUEOBJECTS[Value Objects<br/>SessionState, ProjectType]
        EVENTS[Domain Events<br/>SessionStarted, SessionEnded]
    end

    subgraph "Infrastructure"
        REPOS[Repositories<br/>FileSystemSessionRepo]
        GATEWAYS[Gateways<br/>GitGateway, StatusFileGateway]
        CACHE[Cache<br/>ProjectScanCache]
    end

    subgraph "Data Storage"
        FILES[JSON Files<br/>~/.config/zsh/.sessions/]
        STATUS[.STATUS Files<br/>Project directories]
        GIT[Git Metadata<br/>.git/]
    end

    ZSH --> CONTROLLERS
    CLI --> CONTROLLERS
    TUI --> CONTROLLERS
    WEB --> CONTROLLERS

    CONTROLLERS --> USECASES
    USECASES --> ENTITIES
    USECASES --> REPOS
    USECASES --> GATEWAYS

    ENTITIES --> VALUEOBJECTS
    ENTITIES --> EVENTS

    REPOS --> FILES
    REPOS --> CACHE
    GATEWAYS --> STATUS
    GATEWAYS --> GIT

    style ENTITIES fill:#e1f5fe
    style USECASES fill:#fff9c4
    style CONTROLLERS fill:#f1f8e9
    style REPOS fill:#fce4ec
```

---

## Clean Architecture Layers

### Layer Dependencies

```mermaid
graph LR
    subgraph "Dependency Flow (Inward Only)"
        FW[Frameworks<br/>CLI, ZSH, Web]
        AD[Adapters<br/>Controllers, Repos]
        UC[Use Cases<br/>Business Logic]
        DOM[Domain<br/>Entities, Rules]

        FW -.->|depends on| AD
        AD -.->|depends on| UC
        UC -.->|depends on| DOM
        DOM -.->|no dependencies| NONE[ ]

        style DOM fill:#e1f5fe
        style UC fill:#fff9c4
        style AD fill:#f1f8e9
        style FW fill:#fce4ec
    end
```

**Dependency Rule:** Source code dependencies point ONLY inward. Inner layers know nothing about outer layers.

---

### Layer Details

```mermaid
graph TB
    subgraph "Layer 4: Frameworks & Drivers"
        direction LR
        CLI_BIN[flow.js]
        ZSH_FUNCS[ZSH Functions]
        DASHBOARD_UI[Dashboard.js]
        WEB_DASH[WebDashboard.js]
    end

    subgraph "Layer 3: Adapters (Interface)"
        direction LR
        CTRL[Controllers]
        REPOS_IMPL[Repository Impl]
        GATEWAYS_IMPL[Gateway Impl]
        EVENTS_PUB[Event Publisher]
    end

    subgraph "Layer 2: Use Cases (Application)"
        direction LR
        GET_STATUS[GetStatusUseCase]
        CREATE_SESSION[CreateSessionUseCase]
        END_SESSION[EndSessionUseCase]
        SCAN_PROJECTS[ScanProjectsUseCase]
    end

    subgraph "Layer 1: Domain (Core)"
        direction LR
        SESSION[Session Entity]
        PROJECT[Project Entity]
        TASK[Task Entity]
        VO[Value Objects]
        EVENTS[Domain Events]
        REPOS_IFACE[Repository Interfaces]
    end

    CLI_BIN --> CTRL
    ZSH_FUNCS --> CTRL
    DASHBOARD_UI --> CTRL
    WEB_DASH --> CTRL

    CTRL --> GET_STATUS
    CTRL --> CREATE_SESSION
    CTRL --> END_SESSION
    CTRL --> SCAN_PROJECTS

    GET_STATUS --> SESSION
    GET_STATUS --> PROJECT
    GET_STATUS --> REPOS_IFACE
    CREATE_SESSION --> SESSION
    CREATE_SESSION --> REPOS_IFACE
    END_SESSION --> SESSION
    END_SESSION --> REPOS_IFACE
    SCAN_PROJECTS --> PROJECT
    SCAN_PROJECTS --> REPOS_IFACE

    SESSION --> VO
    SESSION --> EVENTS
    PROJECT --> VO

    REPOS_IMPL -.implements.-> REPOS_IFACE
    GATEWAYS_IMPL -.provides data to.-> GET_STATUS

    style SESSION fill:#e1f5fe
    style PROJECT fill:#e1f5fe
    style GET_STATUS fill:#fff9c4
    style CREATE_SESSION fill:#fff9c4
    style CTRL fill:#f1f8e9
    style CLI_BIN fill:#fce4ec
```

---

## Component Diagram

### Domain Layer Components

```mermaid
classDiagram
    class Session {
        +String id
        +String project
        +String task
        +SessionState state
        +Date startTime
        +Date endTime
        +validate()
        +end(outcome)
        +pause()
        +resume()
        +getDuration() number
        +isInFlowState() boolean
        +getSummary() Object
        +getEvents() Array
    }

    class Project {
        +String id
        +String name
        +ProjectType type
        +String path
        +Number totalSessions
        +Number totalDuration
        +touch()
        +recordSession(duration)
        +getAverageSessionDuration() number
        +isRecentlyAccessed(hours) boolean
        +getSummary() Object
    }

    class SessionState {
        <<value object>>
        +String value
        +isActive() boolean
        +isPaused() boolean
        +isEnded() boolean
    }

    class ProjectType {
        <<value object>>
        +String value
        +getIcon() string
        +getDisplayName() string
    }

    class SessionEvent {
        <<abstract>>
        +String eventType
        +Date occurredAt
        +String aggregateId
        +Object payload
    }

    class ISessionRepository {
        <<interface>>
        +save(session)*
        +findById(id)*
        +findActive()*
        +list(options)*
    }

    class IProjectRepository {
        <<interface>>
        +save(project)*
        +findById(id)*
        +findAll()*
        +findRecent(hours, limit)*
    }

    Session --> SessionState
    Session --> SessionEvent
    Project --> ProjectType
    Session ..> ISessionRepository : persisted by
    Project ..> IProjectRepository : persisted by
```

---

### Use Cases Components

```mermaid
classDiagram
    class GetStatusUseCase {
        -ISessionRepository sessionRepo
        -IProjectRepository projectRepo
        -GitGateway gitGateway
        -StatusFileGateway statusFileGateway
        +execute(input) Promise~Object~
        -calculateMetrics(sessions) Object
        -calculateStreak(sessions) number
    }

    class CreateSessionUseCase {
        -ISessionRepository sessionRepo
        -IProjectRepository projectRepo
        -IEventPublisher eventPublisher
        +execute(input) Promise~Object~
    }

    class EndSessionUseCase {
        -ISessionRepository sessionRepo
        -IProjectRepository projectRepo
        -IEventPublisher eventPublisher
        +execute(input) Promise~Object~
    }

    class ScanProjectsUseCase {
        -IProjectRepository projectRepo
        -ProjectScanCache cache
        +execute(input) Promise~Object~
    }

    GetStatusUseCase --> ISessionRepository
    GetStatusUseCase --> IProjectRepository
    GetStatusUseCase --> GitGateway
    GetStatusUseCase --> StatusFileGateway

    CreateSessionUseCase --> ISessionRepository
    CreateSessionUseCase --> IProjectRepository
    CreateSessionUseCase --> Session

    EndSessionUseCase --> ISessionRepository
    EndSessionUseCase --> IProjectRepository
    EndSessionUseCase --> Session

    ScanProjectsUseCase --> IProjectRepository
    ScanProjectsUseCase --> ProjectScanCache
```

---

## Sequence Diagrams

### Create Session Flow

```mermaid
sequenceDiagram
    participant User
    participant CLI as flow CLI
    participant Controller as StatusController
    participant UseCase as CreateSessionUseCase
    participant Entity as Session
    participant Repo as SessionRepository
    participant EventPub as EventPublisher
    participant Files as ~/.sessions/

    User->>CLI: flow work my-project
    CLI->>Controller: createSession({ project: 'my-project' })

    Controller->>UseCase: execute({ project: 'my-project' })

    UseCase->>Repo: findActive()
    Repo-->>UseCase: null (no active session)

    UseCase->>Entity: new Session(uuid, 'my-project')
    Entity->>Entity: validate()
    Entity->>Entity: emit SessionStartedEvent

    UseCase->>Repo: save(session)
    Repo->>Files: write session-uuid.json
    Files-->>Repo: success

    UseCase->>EventPub: publish(SessionStartedEvent)
    EventPub-->>UseCase: published

    UseCase-->>Controller: { session, created: true }
    Controller-->>CLI: "Session started: my-project"
    CLI-->>User: ✓ Session started (8 minutes ago)
```

---

### Get Status Flow

```mermaid
sequenceDiagram
    participant User
    participant CLI as flow CLI
    participant Controller as StatusController
    participant UseCase as GetStatusUseCase
    participant SessionRepo as SessionRepository
    participant ProjectRepo as ProjectRepository
    participant GitGateway
    participant StatusGateway
    participant Files as File System

    User->>CLI: flow status -v
    CLI->>Controller: showStatus({ verbose: true })

    Controller->>UseCase: execute({ includeRecentSessions: true })

    UseCase->>SessionRepo: findActive()
    SessionRepo->>Files: read active session
    Files-->>SessionRepo: session data
    SessionRepo-->>UseCase: Session entity

    UseCase->>GitGateway: getStatus(session.cwd)
    GitGateway->>Files: git status --porcelain
    Files-->>GitGateway: git output
    GitGateway-->>UseCase: { branch, dirty, ahead, behind }

    UseCase->>StatusGateway: read(session.cwd)
    StatusGateway->>Files: read .STATUS file
    Files-->>StatusGateway: status content
    StatusGateway-->>UseCase: { status, progress, next }

    UseCase->>SessionRepo: list({ since: 7days })
    SessionRepo->>Files: scan session files
    Files-->>SessionRepo: session files
    SessionRepo-->>UseCase: recent sessions

    UseCase->>ProjectRepo: findRecent(24h, 5)
    ProjectRepo-->>UseCase: recent projects

    UseCase->>UseCase: calculateMetrics(sessions)
    UseCase-->>Controller: status object

    Controller->>Controller: formatStatus(status, verbose)
    Controller-->>CLI: ASCII formatted output
    CLI-->>User: [Beautiful status display]
```

---

### End Session Flow

```mermaid
sequenceDiagram
    participant User
    participant CLI as flow CLI
    participant Controller
    participant UseCase as EndSessionUseCase
    participant SessionRepo as SessionRepository
    participant ProjectRepo as ProjectRepository
    participant Entity as Session
    participant Files

    User->>CLI: flow finish "Completed feature"
    CLI->>Controller: endSession({ outcome: 'completed' })

    Controller->>UseCase: execute({ outcome: 'completed' })

    UseCase->>SessionRepo: findActive()
    SessionRepo-->>UseCase: active session

    UseCase->>Entity: session.end('completed')
    Entity->>Entity: validate outcome
    Entity->>Entity: set endTime
    Entity->>Entity: emit SessionEndedEvent
    Entity-->>UseCase: session ended

    UseCase->>SessionRepo: save(session)
    SessionRepo->>Files: update session file
    Files-->>SessionRepo: success

    UseCase->>ProjectRepo: findById(session.project)
    ProjectRepo-->>UseCase: project

    UseCase->>Entity: project.recordSession(duration)
    Entity->>Entity: update stats
    Entity-->>UseCase: updated project

    UseCase->>ProjectRepo: save(project)
    ProjectRepo-->>UseCase: success

    UseCase-->>Controller: { session, duration: 45 }
    Controller-->>CLI: "Session ended: 45 minutes"
    CLI-->>User: ✓ Completed session (45 min)
```

---

## Data Flow

### Status Command Data Flow

```mermaid
graph LR
    subgraph "Input"
        USER[User Types<br/>flow status -v]
    end

    subgraph "Processing"
        PARSE[Parse Args<br/>verbose: true]
        ROUTE[Route to<br/>status.js]
        CTRL[StatusController<br/>.showStatus]
        UC[GetStatusUseCase<br/>.execute]
    end

    subgraph "Data Sources"
        SESSION_FILES[~/.sessions/<br/>*.json]
        STATUS_FILES[project/<br/>.STATUS]
        GIT[.git/<br/>metadata]
        WORKLOG[~/.worklog]
    end

    subgraph "Data Aggregation"
        SESSIONS[Load Sessions]
        PROJECTS[Scan Projects]
        GIT_STATUS[Get Git Status]
        METRICS[Calculate Metrics]
    end

    subgraph "Presentation"
        FORMAT[Format Output<br/>ASCII charts]
        DISPLAY[Terminal<br/>Display]
    end

    USER --> PARSE
    PARSE --> ROUTE
    ROUTE --> CTRL
    CTRL --> UC

    UC --> SESSION_FILES
    UC --> STATUS_FILES
    UC --> GIT
    UC --> WORKLOG

    SESSION_FILES --> SESSIONS
    STATUS_FILES --> PROJECTS
    GIT --> GIT_STATUS
    WORKLOG --> SESSIONS

    SESSIONS --> METRICS
    PROJECTS --> METRICS
    GIT_STATUS --> METRICS

    METRICS --> FORMAT
    FORMAT --> DISPLAY
    DISPLAY --> USER

    style UC fill:#fff9c4
    style METRICS fill:#e1f5fe
    style FORMAT fill:#f1f8e9
```

---

### Project Scanning Flow

```mermaid
graph TB
    START[Scan Request] --> CACHE{Cache<br/>Valid?}

    CACHE -->|Yes < 1hr| CACHE_HIT[Return<br/>Cached Data]
    CACHE -->|No| SCAN_START[Start Scan]

    SCAN_START --> FIND[find /<br/>-name .STATUS]
    FIND --> PARALLEL[Parallel<br/>Processing]

    PARALLEL --> READ1[Read .STATUS]
    PARALLEL --> READ2[Read .STATUS]
    PARALLEL --> READ3[Read .STATUS]

    READ1 --> PARSE1[Parse Status]
    READ2 --> PARSE2[Parse Status]
    READ3 --> PARSE3[Parse Status]

    PARSE1 --> FILTER[Apply Filters]
    PARSE2 --> FILTER
    PARSE3 --> FILTER

    FILTER --> SORT[Sort Results]
    SORT --> CACHE_SAVE[Save to Cache]
    CACHE_SAVE --> RETURN[Return Projects]

    CACHE_HIT --> RETURN

    style CACHE fill:#fff9c4
    style PARALLEL fill:#e1f5fe
    style CACHE_SAVE fill:#f1f8e9
```

**Performance:**

- First scan: ~3ms (60 projects)
- Cached scan: <1ms
- Cache TTL: 1 hour
- Parallel processing: Promise.all

---

## Deployment Architecture

### Local Development

```mermaid
graph TB
    subgraph "User Environment"
        TERMINAL[iTerm2<br/>Terminal]
        ZSH_CONFIG[~/.config/zsh/]
    end

    subgraph "Flow CLI (Node.js)"
        CLI_BIN[/opt/homebrew/bin/flow]
        CLI_CODE[~/projects/dev-tools/<br/>flow-cli/cli/]
    end

    subgraph "Data Storage"
        SESSIONS[~/.config/zsh/<br/>.sessions/]
        WORKLOG[~/.config/zsh/<br/>.worklog]
        PROJECT_STATUS[~/projects/**/<br/>.STATUS]
    end

    subgraph "External Tools"
        GIT[git CLI]
        NODE[Node.js 18+]
    end

    TERMINAL --> ZSH_CONFIG
    ZSH_CONFIG --> CLI_BIN
    CLI_BIN --> CLI_CODE
    CLI_CODE --> SESSIONS
    CLI_CODE --> WORKLOG
    CLI_CODE --> PROJECT_STATUS
    CLI_CODE --> GIT
    CLI_CODE --> NODE

    style CLI_CODE fill:#e1f5fe
    style SESSIONS fill:#fff9c4
```

---

### Production (GitHub Pages)

```mermaid
graph TB
    subgraph "GitHub Actions CI/CD"
        PUSH[git push] --> BUILD[npm run build]
        BUILD --> TEST[npm test]
        TEST --> DOCS[mkdocs build]
        DOCS --> DEPLOY[Deploy to<br/>GitHub Pages]
    end

    subgraph "Hosting"
        PAGES[GitHub Pages<br/>Data-Wise.github.io/flow-cli]
        CDN[GitHub CDN]
    end

    subgraph "Visitors"
        BROWSER[User Browser]
    end

    DEPLOY --> PAGES
    PAGES --> CDN
    CDN --> BROWSER

    style BUILD fill:#fff9c4
    style PAGES fill:#e1f5fe
```

---

### System Context

```mermaid
C4Context
    title System Context - Flow CLI

    Person(user, "User", "Developer with ADHD")

    System(flow, "Flow CLI", "ADHD-optimized workflow<br/>session management")

    System_Ext(git, "Git", "Version control")
    System_Ext(zsh, "ZSH", "Shell environment")
    System_Ext(fs, "File System", "Project files")

    Rel(user, flow, "Uses", "CLI/ZSH")
    Rel(flow, git, "Reads status", "git CLI")
    Rel(flow, zsh, "Integrates with", "functions")
    Rel(flow, fs, "Reads/writes", ".STATUS, sessions")

    UpdateLayoutConfig($c4ShapeInRow="3", $c4BoundaryInRow="1")
```

---

## Architecture Patterns

### Repository Pattern

```mermaid
graph LR
    subgraph "Use Case Layer"
        UC[GetStatusUseCase]
    end

    subgraph "Domain Layer"
        IFACE[ISessionRepository<br/>interface]
    end

    subgraph "Adapter Layer"
        FS_IMPL[FileSystemSessionRepository<br/>implementation]
        PG_IMPL[PostgresSessionRepository<br/>implementation]
    end

    subgraph "Infrastructure"
        FILES[JSON Files]
        DB[(PostgreSQL)]
    end

    UC --> IFACE
    IFACE <|.. FS_IMPL
    IFACE <|.. PG_IMPL

    FS_IMPL --> FILES
    PG_IMPL --> DB

    style IFACE fill:#e1f5fe
    style UC fill:#fff9c4
    style FS_IMPL fill:#f1f8e9
```

**Benefits:**

- Domain layer independent of infrastructure
- Easy to swap implementations
- Testable with mock repositories
- Multiple storage backends

---

### Event Sourcing (Domain Events)

```mermaid
sequenceDiagram
    participant Entity as Session Entity
    participant UseCase
    participant EventPub as Event Publisher
    participant Listener1 as Analytics
    participant Listener2 as Notifications

    Entity->>Entity: session.end('completed')
    Entity->>Entity: emit SessionEndedEvent

    UseCase->>Entity: getEvents()
    Entity-->>UseCase: [SessionEndedEvent]

    UseCase->>EventPub: publish(SessionEndedEvent)

    EventPub->>Listener1: handle(SessionEndedEvent)
    Listener1->>Listener1: record completion

    EventPub->>Listener2: handle(SessionEndedEvent)
    Listener2->>Listener2: send notification

    UseCase->>Entity: clearEvents()
```

**Benefits:**

- Decoupled side effects
- Audit trail of domain changes
- Easy to add new event listeners
- Supports event-driven architecture

---

## See Also

- [API Reference](../api/API-REFERENCE.md)
- [ADR-002: Clean Architecture](../decisions/ADR-002-adopt-clean-architecture.md)
- [Architecture Patterns Analysis](ARCHITECTURE-PATTERNS-ANALYSIS.md)
- [Testing Guide](../testing/TESTING.md)

---

**Generated:** 2025-12-24
**Version:** 2.0.0-beta.1

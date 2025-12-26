# Flow CLI Documentation

**Project:** flow-cli
**Version:** 0.1.0
**Status:** Week 1 Complete ✅

---

## Documentation Index

### API Documentation

- **[Complete API Reference](api/API-REFERENCE.md)** - Full system API (800+ lines) ⭐ **NEW (Dec 24)**
  - Domain Layer (Session, Project, Task entities with business rules)
  - Use Cases Layer (GetStatus, CreateSession, EndSession, ScanProjects)
  - Adapters Layer (Controllers, Repositories, Gateways)
  - Code examples for every major component
  - Testing strategies and patterns

- **[Interactive Examples](api/INTERACTIVE-EXAMPLES.md)** - 13 runnable code examples ⭐ **NEW (Dec 24)**
  - Quick start workflows (create session, check status)
  - Session management (pause/resume, flow state tracking)
  - Project tracking (scanning with filters, search)
  - Custom integrations (Slack notifications, CSV export)
  - Advanced patterns (PostgreSQL repository, webhook publisher)
  - Testing examples (unit and integration tests)

- **[API Overview](api/API-OVERVIEW.md)** - System API reference
  - All 8 modules documented (1 complete, 2 partial, 5 planned)
  - Architecture diagrams and dependencies
  - Usage patterns and examples
  - Implementation timeline

- **[Project Detector API](api/PROJECT-DETECTOR-API.md)** - Project type detection
  - `detectProjectType()` - Single project detection
  - `detectMultipleProjects()` - Batch parallel detection
  - `getSupportedTypes()` - List all supported types
  - `isTypeSupported()` - Validate project types

### Architecture

- **[Architecture Diagrams](architecture/ARCHITECTURE-DIAGRAM.md)** - 15 Mermaid diagrams ⭐ **NEW (Dec 24)**
  - System overview and Clean Architecture layer dependencies
  - Component diagrams (UML class diagrams for entities)
  - Sequence diagrams (Create Session, Get Status, End Session flows)
  - Data flow diagrams (status command, project scanning)
  - Deployment architecture (local development + GitHub Pages)
  - Pattern documentation (Repository, Event Sourcing)

- **[Architecture Patterns Analysis](architecture/ARCHITECTURE-PATTERNS-ANALYSIS.md)** - Clean Architecture & DDD
  - Clean Architecture 4-layer mapping
  - Domain-Driven Design principles
  - Hexagonal Architecture (Ports & Adapters)
  - Complete implementation examples
  - Phase 1-3 migration roadmap

- **[API Design Review](architecture/API-DESIGN-REVIEW.md)** - Design principles applied
  - All 8 modules reviewed
  - Best practices and anti-patterns
  - Recommended improvements
  - Code examples for fixes

- **[Vendor Integration Architecture](architecture/VENDOR-INTEGRATION-ARCHITECTURE.md)** - System design and patterns
  - Architecture layers and data flow
  - Design patterns (vendoring, bridge, type mapping)
  - Performance characteristics
  - Maintenance and security

### User Guides

- **[Project Detection Guide](reference/PROJECT-DETECTION-GUIDE.md)** - User-friendly tutorial
  - Quick start and examples
  - Supported project types
  - Common use cases
  - Troubleshooting

### Planning & Progress

- **[Project Scope](../PROJECT-SCOPE.md)** - Overall project plan
- **[Architecture Integration](../ARCHITECTURE-INTEGRATION.md)** - System overview
- **[Porting Plan](../PLAN-UPDATE-PORTING-2025-12-20.md)** - Vendoring decision

---

## Quick Links

### For Users

1. **New to project detection?** → Start with [Project Detection Guide](reference/PROJECT-DETECTION-GUIDE.md)
2. **Need API details?** → See [Project Detector API](api/PROJECT-DETECTOR-API.md)
3. **Want examples?** → Check out the [User Guide examples](reference/PROJECT-DETECTION-GUIDE.md#examples-with-real-projects)

### For Developers

1. **Understanding the architecture?** → Read [Vendor Integration Architecture](architecture/VENDOR-INTEGRATION-ARCHITECTURE.md)
2. **Adding features?** → See [Architecture layers](architecture/VENDOR-INTEGRATION-ARCHITECTURE.md#architecture-layers)
3. **Running tests?** → Check [Testing section](api/PROJECT-DETECTOR-API.md#testing)

### For Maintainers

1. **Syncing vendored code?** → Follow [Sync process](architecture/VENDOR-INTEGRATION-ARCHITECTURE.md#syncing-vendored-code)

2. **Planning next steps?** → Check [Project Scope](../PROJECT-SCOPE.md)

---

## Documentation Structure

```
docs/
├── README.md                    # This file - documentation index
│
├── api/                         # API reference documentation
│   └── PROJECT-DETECTOR-API.md  # Complete API reference
│
├── architecture/                # System architecture docs
│   └── VENDOR-INTEGRATION-ARCHITECTURE.md  # Design and patterns
│
└── user/                        # User-facing guides
    └── PROJECT-DETECTION-GUIDE.md  # Tutorial and examples
```

---

## What's Documented

### Week 1 Implementation ✅

**Completed Features:**

- Project type detection (6 types: R, Quarto, research, git, unknown)
- JavaScript bridge to vendored shell scripts
- Parallel batch detection
- Comprehensive error handling
- Type mapping and validation

**Documentation Coverage:**

- ✅ API reference with all functions
- ✅ Architecture diagrams (Mermaid)
- ✅ User guide with examples
- ✅ Troubleshooting guide
- ✅ Testing documentation
- ✅ Maintenance procedures

---

## Coming Soon

### Phase 2 (Week 2-3)

- CLI tool documentation
- Project scanner guide
- Caching implementation
- TypeScript type definitions

### Phase 3 (Month 2+)

- Additional project types (Python, Node.js, Rust, Go)
- Plugin system documentation
- API server deployment guide
- Performance tuning guide

---

## Contributing to Documentation

### Documentation Standards

- **Clear examples** - Every feature should have working examples
- **Real projects** - Use actual project paths from the codebase
- **Troubleshooting** - Include common problems and solutions
- **Architecture diagrams** - Use Mermaid for consistency
- **API consistency** - Keep API docs synchronized with code

### Adding New Documentation

1. Choose the appropriate directory:
   - `api/` - API reference and technical specs
   - `architecture/` - System design and patterns
   - `user/` - Tutorials and guides

2. Follow the template structure:
   - Overview section
   - Quick start
   - Detailed content
   - Examples
   - Troubleshooting
   - Related docs

3. Update this README index

4. Link from related documents

---

## Documentation Maintenance

### Review Schedule

- **Weekly** - Update progress reports
- **Monthly** - Review and update examples
- **Quarterly** - Sync with vendored code changes
- **Per release** - Update version numbers

### Keeping Docs Fresh

- Run tests before updating API docs
- Verify examples against real projects
- Update architecture diagrams when adding features
- Archive outdated documentation

---

## Tools Used

### Documentation Generation

- **Markdown** - All documentation in GitHub-flavored Markdown
- **Mermaid** - Architecture diagrams and flowcharts
- **JSDoc** - Inline code documentation
- **Examples** - Real code snippets from the codebase

### Validation

- **Link checking** - Ensure all internal links work
- **Code testing** - All examples are executable
- **Spell checking** - Grammar and spelling review
- **Consistency** - Uniform formatting and structure

---

## Getting Help

### Finding What You Need

1. **Start here** - This README indexes all documentation
2. **Search** - Use Cmd+F to find topics
3. **Follow links** - Documents cross-reference each other
4. **Check examples** - Most docs include working code

### Still Need Help?

- Check the [Troubleshooting section](reference/PROJECT-DETECTION-GUIDE.md#troubleshooting)

- Ask Claude Code: "How do I...?"

---

## Documentation Stats

### Coverage (2025-12-24)

- **Documentation Files:** 214 files
- **Total Lines:** 96,151 lines
- **Site Pages:** 63 pages across 9 sections
- **API Reference:** 800+ lines (complete)
- **Interactive Examples:** 13 runnable examples
- **Architecture Diagrams:** 15 Mermaid diagrams
- **Code Examples:** 88+ production-ready patterns

### Quality Metrics

- ✅ Clean Architecture documented (Domain, Use Cases, Adapters)
- ✅ All major entities documented with business rules
- ✅ Sequence diagrams for key workflows
- ✅ Testing strategies documented (559 tests, 100% passing)
- ✅ 4 ADHD-friendly tutorials
- ✅ Troubleshooting guides included
- ✅ Real project examples throughout

---

## Version History

### v2.0.0-beta.1 (2025-12-24) - Phase P6 Complete

**Major Documentation Updates:**

- Complete API Reference (800+ lines with code examples)
- Interactive Examples (13 runnable patterns)
- Architecture Diagrams (15 Mermaid diagrams)
- 4 ADHD-friendly tutorials
- Comprehensive testing guide (600+ lines)
- Production Use Phase documentation

**Coverage:**

- 214 documentation files (96K+ lines)
- 63-page documentation site
- 15 visual diagrams
- 100% API coverage
- 559 passing tests documented

### v0.1.0 (2025-12-20) - Week 1 Complete

**Documentation Created:**

- Project Detector API reference (comprehensive)
- Vendor Integration Architecture (complete)
- Project Detection User Guide (beginner-friendly)
- Documentation index

---

## Quick Reference

### Most Common Tasks

| Task                     | Documentation                                                                                 |
| ------------------------ | --------------------------------------------------------------------------------------------- |
| Detect project type      | [API: detectProjectType](api/PROJECT-DETECTOR-API.md#detectprojecttypeprojectpath)            |
| Detect multiple projects | [API: detectMultipleProjects](api/PROJECT-DETECTOR-API.md#detectmultipleprojectsprojectpaths) |
| List supported types     | [API: getSupportedTypes](api/PROJECT-DETECTOR-API.md#getsupportedtypes)                       |
| Understand architecture  | [Architecture Overview](architecture/VENDOR-INTEGRATION-ARCHITECTURE.md#system-overview)      |
| Sync vendored code       | [Maintenance](architecture/VENDOR-INTEGRATION-ARCHITECTURE.md#syncing-vendored-code)          |
| Troubleshoot issues      | [Troubleshooting](reference/PROJECT-DETECTION-GUIDE.md#troubleshooting)                       |

---

**Last Updated:** 2025-12-20
**Maintainer:** DT
**Status:** ✅ Complete and up-to-date

# Contributing to ZSH Configuration

Thank you for your interest in contributing! This guide will help you get started.

---

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Development Workflow](#development-workflow)
- [Documentation](#documentation)
- [Testing](#testing)
- [Code Style](#code-style)
- [Submitting Changes](#submitting-changes)

---

## Quick Start

### Prerequisites

- **ZSH** (already installed if you're using this project)
- **Node.js** 18+ (for CLI tools)
- **Git** (for version control)
- **Text editor** (VS Code recommended for TypeScript support)

### Setup

1. **Clone or navigate to project:**

   ```bash
   cd ~/projects/dev-tools/flow-cli
   ```

2. **Install dependencies:**

   ```bash
   npm install
   ```

3. **Run tests:**

   ```bash
   npm test
   ```

4. **Build documentation site (optional):**
   ```bash
   mkdocs serve
   # Visit http://127.0.0.1:8000
   ```

---

## Project Structure

```
flow-cli/
├── cli/                      # Node.js CLI integration
│   ├── adapters/             # Adapters for ZSH functions
│   ├── lib/                  # Shared library code
│   └── README.md             # CLI documentation
│
├── docs/                     # All documentation
│   ├── architecture/         # Architecture docs
│   ├── user/                 # User guides
│   ├── api/                  # API documentation
│   ├── planning/             # Planning documents
│   ├── implementation/       # Implementation tracking
│   ├── reference/            # Reference materials
│   └── archive/              # Historical documents
│
├── config/                   # Configuration files
├── scripts/                  # Utility scripts
├── test/                     # CLI tests
│
└── mkdocs.yml               # Documentation site config
```

**Important:** The actual ZSH configuration files live in `~/.config/zsh/` (not in this repo).

---

## Development Workflow

### Making Changes

1. **Create a feature branch:**

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes:**
   - ZSH functions: Edit files in `~/.config/zsh/functions/`
   - CLI adapters: Edit files in `cli/adapters/`
   - Documentation: Edit files in `docs/`

3. **Test your changes:**

   ```bash
   # CLI tests
   npm test

   # ZSH function tests
   ~/.config/zsh/tests/test-adhd-helpers.zsh
   ```

4. **Update documentation:**
   - If adding features, update relevant docs in `docs/`
   - If changing APIs, update `docs/api/`
   - Keep `CLAUDE.md` in sync with major changes

5. **Commit your changes:**
   ```bash
   git add .
   git commit -m "feat: add new feature"
   ```

### Commit Message Format

We use conventional commits:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**

```
feat(cli): add project detector adapter
fix(validation): handle empty paths correctly
docs(architecture): add quick wins guide
```

---

## Documentation

### Adding New Documentation

1. **Choose the right location:**

   | Content Type            | Directory                                              |
   | ----------------------- | ------------------------------------------------------ |
   | User guides             | `docs/user/`                                           |
   | Architecture            | `docs/architecture/`                                   |
   | API docs                | `docs/api/`                                            |
   | Planning                | `docs/planning/current/` or `docs/planning/proposals/` |
   | Implementation tracking | `docs/implementation/`                                 |
   | Completed work          | `docs/archive/`                                        |

2. **Follow naming conventions:**
   - Use CAPS for visibility: `PROPOSAL-feature-name.md`
   - Use descriptive names: `ALIAS-REFERENCE-CARD.md`
   - Add dates for planning: `SPRINT-REVIEW-2025-12-21.md`

3. **Use consistent format:**

   ```markdown
   # Title

   **TL;DR:** Brief summary in 3-5 bullet points

   **Last Updated:** YYYY-MM-DD

   ---

   ## Section 1

   Content...

   ---

   **Last Updated:** YYYY-MM-DD
   **See Also:** [Related Doc](link.md)
   ```

4. **Add to mkdocs.yml navigation:**

   ```yaml
   nav:
     - Section Name:
         - Page Title: path/to/file.md
   ```

5. **Update doc-index.md** if adding major documents

### Documentation Guidelines

**ADHD-Friendly Writing:**

- ✅ Use visual hierarchy (headers, bullets, tables)
- ✅ Keep sections short (< 200 words)
- ✅ Add TL;DR at top of major sections
- ✅ Use examples liberally
- ✅ Provide quick wins vs long-term items

**Technical Writing:**

- ✅ Code examples should be copy-paste ready
- ✅ Include file paths and line numbers
- ✅ Link to related documents
- ✅ Keep language clear and direct

---

## Testing

### Running Tests

```bash
# CLI tests (Node.js)
npm test

# Specific test file
npm test -- test/test-project-detector.js

# ZSH function tests
~/.config/zsh/tests/test-adhd-helpers.zsh
```

### Writing Tests

**CLI Tests (Node.js):**

```javascript
// test/test-your-feature.js

import { strict as assert } from 'assert';
import { yourFunction } from '../lib/your-module.js';

describe('Your Feature', () => {
  it('should do what it's supposed to do', async () => {
    // Arrange
    const input = 'test input';

    // Act
    const result = await yourFunction(input);

    // Assert
    assert.strictEqual(result, 'expected output');
  });
});
```

**ZSH Function Tests:**

```zsh
# ~/.config/zsh/tests/test-your-feature.zsh

source ~/.config/zsh/functions/your-feature.zsh

test_your_function() {
  local result
  result=$(your_function "test input")

  if [[ "$result" == "expected output" ]]; then
    echo "✅ your_function: PASS"
    return 0
  else
    echo "❌ your_function: FAIL (got: $result)"
    return 1
  fi
}

# Run test
test_your_function
```

**Test Guidelines:**

- Write tests for all new features
- Test happy path + error cases
- Use descriptive test names: `should...`
- Follow AAA pattern: Arrange, Act, Assert

---

## Code Style

### JavaScript/Node.js

**General:**

- ES6 modules (`import`/`export`)
- Async/await over callbacks
- Descriptive variable names
- JSDoc comments for public APIs

**Example:**

```javascript
/**
 * Detect project type from directory
 *
 * @param {string} projectPath - Absolute path to project directory
 * @returns {Promise<string>} - Project type (e.g., 'r-package', 'node')
 * @throws {ValidationError} - If path is invalid
 */
export async function detectProjectType(projectPath) {
  validateAbsolutePath(projectPath)

  const result = await executeShellFunction(detectorScript, 'get_project_type', [projectPath])

  return mapProjectType(result)
}
```

### ZSH Functions

**General:**

- Follow conventions in [ZSH-DEVELOPMENT-GUIDELINES.md](docs/ZSH-DEVELOPMENT-GUIDELINES.md)
- Use `local` for all variables
- Add `--help` support
- Error messages to stderr

**Example:**

```zsh
# Load R package and run tests
# Usage: rload-test [options]
rload-test() {
  # Help text
  if [[ "$1" == "--help" ]]; then
    cat << 'EOF'
Usage: rload-test [options]

Load R package and run tests

Options:
  --filter PATTERN  Run tests matching pattern
  --help            Show this help
EOF
    return 0
  fi

  # Validate we're in R package
  if [[ ! -f "DESCRIPTION" ]]; then
    echo "Error: Not in R package directory" >&2
    return 1
  fi

  # Load and test
  local filter=""
  [[ "$1" == "--filter" ]] && filter="$2"

  devtools::load_all()
  devtools::test(filter = "$filter")
}
```

---

## Submitting Changes

### Pull Request Process

1. **Ensure all tests pass:**

   ```bash
   npm test
   ~/.config/zsh/tests/test-adhd-helpers.zsh
   ```

2. **Update documentation:**
   - Update relevant docs in `docs/`
   - Add entry to changelog if major change
   - Update `.STATUS` with your work

3. **Create pull request:**

   ```bash
   git push origin feature/your-feature-name
   ```

4. **PR description should include:**
   - What changed and why
   - Link to related issues/proposals
   - Screenshots (if UI changes)
   - Testing instructions

### Code Review

**Reviewers will check:**

- ✅ Tests pass
- ✅ Code follows style guidelines
- ✅ Documentation updated
- ✅ No breaking changes (or properly documented)
- ✅ ADHD-friendly (if user-facing)

---

## Architecture Guidelines

When adding features that touch architecture, follow these patterns:

### 1. Error Handling

- Use semantic error classes (see [Architecture Quick Wins](docs/architecture/ARCHITECTURE-QUICK-WINS.md#error-handling))
- Throw errors at boundaries
- Log errors with context

### 2. Validation

- Validate at API entry points
- Fail fast with clear messages
- Use reusable validation functions

### 3. Layer Organization

```
lib/domain/      # Business logic (no external dependencies)
lib/use-cases/   # Application logic
lib/adapters/    # External integrations (file system, shell, etc)
lib/utils/       # Shared utilities
```

### 4. Testing

- Unit tests for domain/use-cases (fast, no I/O)
- Integration tests for adapters (with real dependencies)
- Use in-memory adapters for testing

**For full details, see:**

- [Architecture Quick Wins](docs/architecture/ARCHITECTURE-QUICK-WINS.md)
- [Architecture Patterns](docs/architecture/ARCHITECTURE-PATTERNS-ANALYSIS.md)
- [ADRs](docs/architecture/decisions/README.md)

---

## Questions?

- **Documentation:** See [Complete Documentation Index](docs/doc-index.md)
- **Architecture:** See [Architecture Hub](docs/architecture/README.md)
- **ZSH Functions:** See [Development Guidelines](docs/ZSH-DEVELOPMENT-GUIDELINES.md)
- **Issues:** Create a `.md` file in the root or `docs/` directory

---

## Recognition

Contributors who make significant improvements will be recognized in:

- Project README
- Documentation
- Changelog

Thank you for contributing! 🎉

---

**Last Updated:** 2025-12-21
**Maintainer:** DT
**Questions?** See [docs/doc-index.md](docs/doc-index.md)

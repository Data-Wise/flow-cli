# Dependency Management Strategies - Independent Package

**Created:** 2025-12-20
**Context:** Making zsh-configuration independently installable while leveraging existing dev-tools
**Challenge:** Balance between integration benefits and package independence

---

## The Dependency Dilemma

### Current Situation

**Our plan relies on:**
- **zsh-claude-workflow** - Project detection (CRITICAL)
- **aiterm** - Terminal context switching (nice-to-have)
- **apple-notes-sync** - Dashboard patterns (logic only, not tool itself)

**The problem:**
- Can't assume these tools are installed
- Want to be independently installable via npm/brew/pipx
- Don't want to duplicate functionality
- Need graceful degradation if dependencies missing

---

## Option 1: Soft Dependencies + Graceful Degradation ⭐ RECOMMENDED

### Strategy

Make all external tools **optional** with built-in fallbacks.

### Implementation

```javascript
// cli/lib/project-detector-bridge.js

import { exec } from 'child_process';
import { promisify } from 'util';
import fs from 'fs';
import path from 'path';

const execAsync = promisify(exec);

// Try external tool first, fall back to built-in
export async function detectProjectType(projectPath) {
  // Level 1: Try zsh-claude-workflow (best detection)
  const externalDetector = await tryExternalDetector(projectPath);
  if (externalDetector) return externalDetector;

  // Level 2: Built-in detection (good enough)
  return builtInDetection(projectPath);
}

async function tryExternalDetector(projectPath) {
  try {
    // Check if zsh-claude-workflow exists
    const workflowPath = path.join(
      process.env.HOME,
      'projects/dev-tools/zsh-claude-workflow/commands/proj-type'
    );

    if (!fs.existsSync(workflowPath)) {
      return null; // Not installed, use fallback
    }

    // Use external detector
    const { stdout } = await execAsync(
      `cd "${projectPath}" && proj-type`,
      { shell: '/bin/zsh' }
    );
    return stdout.trim();
  } catch (error) {
    // Silent fallback on error
    return null;
  }
}

function builtInDetection(projectPath) {
  // Simple but effective detection
  if (fs.existsSync(path.join(projectPath, 'DESCRIPTION'))) {
    return 'r-package';
  }
  if (fs.existsSync(path.join(projectPath, '_quarto.yml'))) {
    return 'quarto';
  }
  if (fs.existsSync(path.join(projectPath, 'package.json'))) {
    return 'node';
  }
  if (fs.existsSync(path.join(projectPath, 'pyproject.toml'))) {
    return 'python';
  }
  if (fs.existsSync(path.join(projectPath, 'Cargo.toml'))) {
    return 'rust';
  }
  if (fs.existsSync(path.join(projectPath, '.spacemacs'))) {
    return 'spacemacs';
  }
  return 'generic';
}
```

### Pros

✅ **Independent installation** - Works out of the box
✅ **Enhanced when available** - Better detection if zsh-claude-workflow installed
✅ **No hard dependencies** - Users can install without other tools
✅ **Graceful degradation** - Silent fallback if external tool missing
✅ **User choice** - Install external tools for better features

### Cons

❌ **Some code duplication** - Basic detection logic duplicated
❌ **Two codepaths** - More testing needed
❌ **Less powerful alone** - Built-in detection is simpler than external

### Installation Experience

```bash
# Minimal install (works but basic)
npm install -g zsh-configuration

# Enhanced install (recommended)
npm install -g zsh-configuration
git clone https://github.com/Data-Wise/zsh-claude-workflow ~/projects/dev-tools/zsh-claude-workflow
cd ~/projects/dev-tools/zsh-claude-workflow && ./install.sh

# zsh-configuration now uses enhanced project detection
```

### Detection Strategy Status

```javascript
// cli/core/feature-status.js

export function getFeatureStatus() {
  return {
    projectDetection: {
      level: hasExternalDetector() ? 'enhanced' : 'built-in',
      features: hasExternalDetector()
        ? ['8 project types', 'smart detection', 'templates']
        : ['6 project types', 'basic detection']
    },
    terminalContext: {
      level: hasAiterm() ? 'enhanced' : 'none',
      features: hasAiterm()
        ? ['auto-switch profiles', 'context-aware colors']
        : ['manual terminal management']
    },
    dashboard: {
      level: hasAppleNotes() ? 'enhanced' : 'built-in',
      features: hasAppleNotes()
        ? ['terminal dashboard', 'Apple Notes export']
        : ['terminal dashboard only']
    }
  };
}

// Show on first run
> zsh-config doctor

✓ Core features: All available
✓ Project detection: Built-in (6 types)
ℹ Enhanced detection available: Install zsh-claude-workflow for 8+ types
ℹ Terminal context: Install aiterm for auto-switching profiles
```

---

## Option 2: Plugin System (Extensible)

### Strategy

Build a plugin architecture where external tools are plugins.

### Implementation

```javascript
// cli/core/plugin-manager.js

class PluginManager {
  constructor() {
    this.plugins = new Map();
    this.loadPlugins();
  }

  loadPlugins() {
    // Auto-discover plugins
    this.tryRegisterPlugin('project-detector', [
      '~/projects/dev-tools/zsh-claude-workflow',
      '~/.zsh-config/plugins/project-detector'
    ]);

    this.tryRegisterPlugin('terminal-context', [
      '~/projects/dev-tools/aiterm',
      '~/.zsh-config/plugins/aiterm'
    ]);
  }

  tryRegisterPlugin(name, searchPaths) {
    for (const searchPath of searchPaths) {
      const pluginPath = path.expanduser(searchPath);
      if (fs.existsSync(pluginPath)) {
        this.plugins.set(name, require(pluginPath));
        return true;
      }
    }
    // Register built-in fallback
    this.plugins.set(name, require(`./plugins/${name}-builtin`));
    return false;
  }

  use(pluginName) {
    return this.plugins.get(pluginName);
  }
}

// Usage
const plugins = new PluginManager();
const detector = plugins.use('project-detector');
const projectType = detector.detect('/path/to/project');
```

### Plugin Interface

```javascript
// Plugin interface that both external and built-in must implement

export interface ProjectDetectorPlugin {
  detect(projectPath: string): string;
  getCapabilities(): string[];
  getTemplates?(): Map<string, string>;
}

// External plugin adapter
// Wraps zsh-claude-workflow to match interface
class ZshClaudeWorkflowAdapter implements ProjectDetectorPlugin {
  detect(projectPath) {
    // Call external command
  }

  getCapabilities() {
    return ['r-package', 'quarto', 'research', 'dev-tool', 'node', 'python', 'spacemacs', 'generic'];
  }
}

// Built-in plugin
class BuiltInDetector implements ProjectDetectorPlugin {
  detect(projectPath) {
    // Simple file-based detection
  }

  getCapabilities() {
    return ['r-package', 'quarto', 'node', 'python', 'rust', 'generic'];
  }
}
```

### Pros

✅ **Very extensible** - Easy to add new plugins
✅ **Clean abstraction** - Plugins implement standard interface
✅ **User can add custom plugins** - Drop files in ~/.zsh-config/plugins/
✅ **Version independent** - Plugins can update independently

### Cons

❌ **More complex** - Plugin system adds overhead
❌ **Harder to debug** - Multiple plugin versions/sources
❌ **Over-engineering?** - May be too complex for 3-4 integrations

---

## Option 3: npm Peer Dependencies

### Strategy

Publish external tools as npm packages and use peer dependencies.

### Implementation

```json
// package.json

{
  "name": "zsh-configuration",
  "peerDependencies": {
    "@data-wise/zsh-claude-workflow": "^1.0.0"
  },
  "peerDependenciesMeta": {
    "@data-wise/zsh-claude-workflow": {
      "optional": true
    }
  }
}
```

### Required Changes

1. **Publish zsh-claude-workflow to npm**
   - Convert to npm package
   - Add package.json with proper exports
   - Publish to @data-wise scope

2. **Import as module**
   ```javascript
   // Instead of shell exec
   import { detectProject } from '@data-wise/zsh-claude-workflow';

   const projectType = detectProject('/path/to/project');
   ```

### Pros

✅ **npm standard** - Uses established npm patterns
✅ **Version management** - npm handles compatibility
✅ **Clean imports** - Use as JavaScript module
✅ **Auto-install** - npm can prompt to install peer deps

### Cons

❌ **Requires refactoring external tools** - zsh-claude-workflow needs npm package structure
❌ **Maintenance burden** - Need to maintain npm packages for all tools
❌ **Breaking change** - Existing zsh-claude-workflow users affected
❌ **Not ZSH-first** - Moves away from shell-based approach

---

## Option 4: Vendoring (Bundle Code)

### Strategy

Copy the essential code from external tools into our package.

### Implementation

```
zsh-configuration/
├── cli/
│   └── vendor/
│       ├── project-detector.sh    # Copied from zsh-claude-workflow
│       └── README.md              # Attribution and license info
```

### Pros

✅ **Zero dependencies** - Completely self-contained
✅ **Fast** - No external calls
✅ **Guaranteed availability** - Always works

### Cons

❌ **Code duplication** - Duplicates zsh-claude-workflow
❌ **Maintenance burden** - Must update vendored code manually
❌ **License complexity** - Need to include licenses
❌ **Divergence** - Vendored code gets out of sync with original
❌ **Goes against our principle** - We wanted to integrate, not duplicate!

---

## Option 5: Hybrid Approach (Best of Both Worlds) ⭐ ALTERNATIVE RECOMMENDATION

### Strategy

Combine soft dependencies + plugin system.

### Implementation

1. **Built-in fallbacks** for core features (always works)
2. **Plugin discovery** for enhanced features (auto-detect if available)
3. **Easy plugin installation** via helper command

```bash
# Works out of box with built-in features
npm install -g zsh-configuration

# Check status
zsh-config doctor
✓ Core features: Available
ℹ Enhanced features: 2 available

# Install enhanced features with one command
zsh-config install-enhancements

Installing enhanced project detection...
  → zsh-claude-workflow (8+ project types, templates)
Installing terminal context switching...
  → aiterm (auto-switching profiles, colors)

✓ All enhancements installed
```

### Plugin Discovery

```javascript
// cli/core/enhancement-manager.js

const ENHANCEMENTS = {
  'project-detection': {
    name: 'Enhanced Project Detection',
    provider: 'zsh-claude-workflow',
    install: 'git clone https://github.com/Data-Wise/zsh-claude-workflow ~/projects/dev-tools/zsh-claude-workflow && cd ~/projects/dev-tools/zsh-claude-workflow && ./install.sh',
    detect: () => fs.existsSync(path.join(process.env.HOME, 'projects/dev-tools/zsh-claude-workflow')),
    benefits: ['8+ project types', 'Smart templates', 'Storage awareness']
  },
  'terminal-context': {
    name: 'Terminal Context Switching',
    provider: 'aiterm',
    install: 'pipx install git+https://github.com/Data-Wise/aiterm',
    detect: () => commandExists('ait'),
    benefits: ['Auto-switch profiles', 'Context-aware colors', 'Session tracking']
  }
};

export function checkEnhancements() {
  return Object.entries(ENHANCEMENTS).map(([key, config]) => ({
    key,
    ...config,
    installed: config.detect()
  }));
}

export async function installEnhancement(key) {
  const config = ENHANCEMENTS[key];
  if (!config) throw new Error(`Unknown enhancement: ${key}`);

  console.log(`Installing ${config.name}...`);
  await execAsync(config.install, { stdio: 'inherit' });

  if (config.detect()) {
    console.log(`✓ ${config.name} installed successfully`);
  } else {
    console.log(`⚠ Installation may have failed, please check manually`);
  }
}
```

### Commands

```bash
# Check what's available
zsh-config doctor

# Install all enhancements
zsh-config install-enhancements

# Install specific enhancement
zsh-config install-enhancement project-detection

# List available enhancements
zsh-config enhancements list
```

### Pros

✅ **Best user experience** - Works immediately, easy to enhance
✅ **Independent** - Core features require no dependencies
✅ **Discoverable** - User knows what enhancements exist
✅ **One-command install** - Easy to get full features
✅ **Graceful degradation** - Falls back if enhancements removed

### Cons

❌ **More code** - Enhancement manager adds complexity
❌ **Still some duplication** - Built-in fallbacks duplicate some logic

---

## Option 6: Git Submodules

### Strategy

Use git submodules to include external tools as part of the repo.

### Implementation

```bash
# Add external tools as submodules
git submodule add https://github.com/Data-Wise/zsh-claude-workflow vendor/zsh-claude-workflow
git submodule add https://github.com/Data-Wise/aiterm vendor/aiterm

# Users clone with --recursive
git clone --recursive https://github.com/Data-Wise/zsh-configuration
```

### Pros

✅ **Version pinning** - Exact versions of dependencies
✅ **Single repo** - Everything in one place
✅ **Git-native** - Uses standard git features

### Cons

❌ **Git complexity** - Submodules are notoriously tricky
❌ **Clone complexity** - Must remember --recursive
❌ **Update friction** - Updating submodules is manual
❌ **Size bloat** - Includes entire external repos
❌ **Not npm-friendly** - Doesn't work with npm install

---

## Comparison Matrix

| Approach | Independence | User Experience | Maintenance | Best Features |
|----------|--------------|-----------------|-------------|---------------|
| **Soft Dependencies** ⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Auto-fallback |
| **Plugin System** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | Extensibility |
| **npm Peer Deps** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | npm standards |
| **Vendoring** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐ | Zero deps |
| **Hybrid** ⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | Best of both |
| **Git Submodules** | ⭐⭐ | ⭐⭐ | ⭐⭐ | Version pinning |

---

## Recommended Approach: Hybrid (Option 5)

### Why This Wins

1. **Works immediately** - Built-in features for core functionality
2. **Easy to enhance** - One command to install all enhancements
3. **User-friendly** - Clear messaging about what's available
4. **Independent** - No hard dependencies on external tools
5. **Leverages existing tools** - Uses them when available
6. **Discoverable** - `doctor` command shows what can be installed

### Implementation Plan

#### Phase 1: Built-in Fallbacks (Week 1)

```javascript
// cli/core/detectors/built-in.js

export function detectProjectType(projectPath) {
  // Simple but effective detection
  const files = fs.readdirSync(projectPath);

  if (files.includes('DESCRIPTION')) return 'r-package';
  if (files.includes('_quarto.yml')) return 'quarto';
  if (files.includes('package.json')) return 'node';
  if (files.includes('pyproject.toml')) return 'python';
  if (files.includes('Cargo.toml')) return 'rust';

  return 'generic';
}

export const SUPPORTED_TYPES = [
  'r-package', 'quarto', 'node', 'python', 'rust', 'generic'
];
```

#### Phase 2: Enhancement Discovery (Week 1)

```javascript
// cli/core/enhancements/index.js

export const ENHANCEMENTS = {
  'zsh-claude-workflow': {
    name: 'Enhanced Project Detection',
    description: '8+ project types with smart templates',
    detectPath: '~/projects/dev-tools/zsh-claude-workflow',
    installCmd: 'git clone https://github.com/Data-Wise/zsh-claude-workflow ~/projects/dev-tools/zsh-claude-workflow && cd ~/projects/dev-tools/zsh-claude-workflow && ./install.sh',
    checkInstalled: () => {
      const workflowPath = path.join(
        process.env.HOME,
        'projects/dev-tools/zsh-claude-workflow'
      );
      return fs.existsSync(workflowPath);
    }
  },
  'aiterm': {
    name: 'Terminal Context Switching',
    description: 'Auto-switch terminal profiles based on project type',
    detectPath: null, // Installed globally via pipx
    installCmd: 'pipx install git+https://github.com/Data-Wise/aiterm',
    checkInstalled: () => {
      try {
        execSync('which ait', { stdio: 'ignore' });
        return true;
      } catch {
        return false;
      }
    }
  }
};
```

#### Phase 3: Doctor Command (Week 1)

```bash
> zsh-config doctor

═══════════════════════════════════════════════
ZSH Configuration - System Check
═══════════════════════════════════════════════

Core Features:
  ✓ Project detection (built-in)
  ✓ Session management
  ✓ Dashboard generation
  ✓ Task aggregation

Supported Project Types (Built-in):
  ✓ r-package, quarto, node, python, rust, generic

Available Enhancements:
  ⚬ Enhanced Project Detection (not installed)
    Benefits: 8+ types, smart templates, storage awareness
    Install: zsh-config install-enhancement zsh-claude-workflow

  ⚬ Terminal Context Switching (not installed)
    Benefits: Auto-switch profiles, context-aware colors
    Install: zsh-config install-enhancement aiterm

Quick Install All:
  zsh-config install-enhancements
```

#### Phase 4: Smart Bridge (Week 1)

```javascript
// cli/lib/project-detector-bridge.js

import { detectProjectType as builtIn } from '../core/detectors/built-in.js';
import { checkEnhancement } from '../core/enhancements/index.js';

export async function detectProjectType(projectPath) {
  // Try enhanced detector if available
  if (checkEnhancement('zsh-claude-workflow')) {
    try {
      return await enhancedDetection(projectPath);
    } catch (error) {
      console.warn('Enhanced detection failed, falling back to built-in');
    }
  }

  // Fall back to built-in
  return builtIn(projectPath);
}

async function enhancedDetection(projectPath) {
  const { stdout } = await execAsync(
    `cd "${projectPath}" && proj-type`,
    { shell: '/bin/zsh' }
  );
  return stdout.trim();
}
```

### User Journey

**First Install:**
```bash
npm install -g zsh-configuration

zsh-config doctor
# Shows core features working, enhancements available

zsh-config install-enhancements
# One command installs zsh-claude-workflow and aiterm

zsh-config doctor
# Now shows all enhancements installed
```

**Daily Use:**
```bash
# Works with or without enhancements
work rmediation
finish
dashboard
pp
```

---

## Package Distribution Strategies

### Option A: npm Global Package ⭐ RECOMMENDED

```bash
# Publish to npm
npm publish

# Users install globally
npm install -g zsh-configuration

# Commands available system-wide
zsh-config doctor
work rmediation
dashboard
```

**Pros:**
- Standard JavaScript package distribution
- Easy to update (`npm update -g zsh-configuration`)
- Version management built-in
- Works on all platforms

### Option B: Homebrew Formula

```ruby
# Formula: zsh-configuration.rb

class ZshConfiguration < Formula
  desc "Personal productivity & project management for ZSH"
  homepage "https://github.com/Data-Wise/zsh-configuration"
  url "https://github.com/Data-Wise/zsh-configuration/archive/v1.0.0.tar.gz"

  depends_on "node"

  def install
    system "npm", "install", "--production"
    prefix.install Dir["*"]
    bin.install_symlink prefix/"cli/bin/zsh-config"
  end
end

# Users install via brew
brew install data-wise/tap/zsh-configuration
```

**Pros:**
- Native macOS experience
- Handles dependencies automatically
- Easy updates via `brew upgrade`

### Option C: Installation Script

```bash
# install.sh

#!/bin/bash

set -e

echo "Installing zsh-configuration..."

# Clone repo
git clone https://github.com/Data-Wise/zsh-configuration ~/projects/dev-tools/zsh-configuration
cd ~/projects/dev-tools/zsh-configuration

# Install Node.js dependencies (none for core)
npm install --production

# Create symlinks to PATH
ln -sf $(pwd)/cli/bin/zsh-config /usr/local/bin/zsh-config

# Source ZSH functions
echo "source $(pwd)/config/zsh/functions/session-commands.zsh" >> ~/.zshrc

echo "✓ Installation complete"
echo ""
echo "Run 'zsh-config doctor' to check status"
```

**Users install:**
```bash
curl -fsSL https://raw.githubusercontent.com/Data-Wise/zsh-configuration/main/install.sh | bash
```

### Option D: pipx (Python Package)

**If we want Python distribution:**

```bash
# Publish to PyPI as Python package
pipx install zsh-configuration

# Commands available
zsh-config doctor
```

**Requires:**
- Wrapping Node.js code in Python CLI
- More complex build process
- Benefits: Python ecosystem distribution

---

## Dependency Declaration

### In package.json

```json
{
  "name": "zsh-configuration",
  "version": "1.0.0",
  "description": "Personal productivity & project management system",

  "bin": {
    "zsh-config": "./cli/bin/zsh-config.js"
  },

  "scripts": {
    "setup": "./scripts/setup.sh",
    "test": "node --test",
    "doctor": "node cli/bin/zsh-config.js doctor",
    "install-enhancements": "node cli/bin/zsh-config.js install-enhancements"
  },

  "dependencies": {},

  "optionalDependencies": {},

  "peerDependencies": {},

  "peerDependenciesMeta": {},

  "engines": {
    "node": ">=18.0.0",
    "npm": ">=9.0.0"
  },

  "os": ["darwin", "linux"],

  "enhancedBy": {
    "zsh-claude-workflow": {
      "optional": true,
      "repository": "https://github.com/Data-Wise/zsh-claude-workflow",
      "benefits": "Enhanced project detection (8+ types)"
    },
    "aiterm": {
      "optional": true,
      "repository": "https://github.com/Data-Wise/aiterm",
      "benefits": "Terminal context switching"
    }
  }
}
```

**Custom field `enhancedBy`:**
- Documents optional enhancements
- Used by `doctor` command to show available features
- Can be checked by installation scripts

---

## Final Recommendation

### Primary: Hybrid Approach (Option 5)

**Implementation:**
1. **Core features** - Built-in, zero dependencies, always work
2. **Enhancement discovery** - Auto-detect if enhanced tools available
3. **One-command install** - `zsh-config install-enhancements`
4. **Clear messaging** - `doctor` command shows what's available/installed

### Distribution: npm Global Package (Option A)

**Why:**
- Standard JavaScript distribution
- Easy updates
- Works everywhere Node.js works
- Can add Homebrew later if desired

### Timeline

**Week 1:**
- [x] Built-in project detection (6 types)
- [ ] Enhancement discovery system
- [ ] Doctor command
- [ ] Install-enhancements command
- [ ] Smart bridge with fallbacks

**Week 2:**
- [ ] Test with/without enhancements
- [ ] Documentation for installation
- [ ] npm package preparation

**Week 3:**
- [ ] Publish to npm
- [ ] Create Homebrew formula (optional)
- [ ] Installation guides

---

## Example Code Structure

```
zsh-configuration/
├── package.json                          # npm package config
├── cli/
│   ├── bin/
│   │   └── zsh-config.js                 # Main CLI entry point
│   ├── core/
│   │   ├── detectors/
│   │   │   ├── built-in.js               # Built-in project detection
│   │   │   └── index.js                  # Exports detector interface
│   │   ├── enhancements/
│   │   │   ├── registry.js               # Available enhancements
│   │   │   ├── installer.js              # Install enhancements
│   │   │   └── index.js
│   │   ├── session-manager.js
│   │   ├── dashboard-generator.js
│   │   └── project-scanner.js
│   ├── lib/
│   │   ├── project-detector-bridge.js    # Smart bridge (enhanced → built-in)
│   │   └── aiterm-bridge.js              # Optional aiterm integration
│   └── commands/
│       ├── doctor.js                     # System check
│       ├── install-enhancements.js       # Install helpers
│       ├── work.js
│       ├── finish.js
│       └── dashboard.js
└── config/
    └── zsh/
        └── functions/
            ├── session-commands.zsh
            └── dashboard-commands.zsh
```

---

## Open Questions

1. **Should we vendor a minimal fallback for project detection?**
   - Pro: Truly zero dependencies
   - Con: Some code duplication
   - Recommendation: Yes, but keep it minimal (6 types)

2. **npm scope: @data-wise or no scope?**
   - `zsh-configuration` (no scope, easier to type)
   - `@data-wise/zsh-configuration` (namespaced, professional)
   - Recommendation: No scope for simplicity

3. **Should enhancements auto-install on first run?**
   - Pro: Better out-of-box experience
   - Con: Surprising behavior, slow first run
   - Recommendation: No, prompt user instead

4. **How to handle enhancement updates?**
   - User updates manually (cd ~/projects/dev-tools/zsh-claude-workflow && git pull)
   - `zsh-config update-enhancements` command
   - Recommendation: Provide update command

---

**Status:** ✅ Dependency strategy defined
**Recommendation:** Hybrid approach with npm distribution
**Key Insight:** Independence with optional enhancements gives best UX
**Next Action:** Implement built-in detection and enhancement discovery

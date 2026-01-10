# Plugin Management Workflow

**Quick Answer:** `flow plugin` manages flow-cli extensions. List, create, install, enable/disable plugins to customize your workflow.

---

## Overview

The plugin system allows you to extend flow-cli with custom commands, hooks, and workflows without modifying the core codebase.

**Common workflows:**
- Browse and enable bundled plugins
- Create your own custom plugins
- Install community plugins from GitHub
- Share plugins across teams/projects

---

## Quick Start

### List Available Plugins

```bash
# Show enabled plugins
flow plugin list

# Show all discovered plugins (enabled + disabled)
flow plugin list --all
flow plugin list -a
```

**Output example:**
```
✓ example-plugin   v1.0.0  Enabled
○ my-custom        v0.1.0  Disabled
```

---

### Enable/Disable Plugins

```bash
# Enable a plugin
flow plugin enable my-custom

# Disable a plugin
flow plugin disable my-custom

# Reload shell to apply changes
exec zsh
```

**Note:** Reload required after enable/disable.

---

## Creating Plugins

### Wizard Creation

The easiest way to create a plugin:

```bash
flow plugin create my-workflow
```

**Prompts:**
```
Plugin name: my-workflow
Created: ~/.config/flow/plugins/my-workflow/
  ├── main.zsh
  ├── plugin.json
  └── README.md
```

---

### Manual Creation

Create plugin structure:

```bash
mkdir -p ~/.config/flow/plugins/my-plugin
cd ~/.config/flow/plugins/my-plugin

# Create main file
cat > main.zsh << 'EOF'
# My custom plugin

# Register command
my_command() {
  echo "Hello from my plugin!"
}

# Register hook (optional)
flow_hook_register "PreWork" "_my_plugin_pre_work"

_my_plugin_pre_work() {
  local project="$1"
  echo "Starting work on: $project"
}
EOF

# Create metadata
cat > plugin.json << 'EOF'
{
  "name": "my-plugin",
  "version": "0.1.0",
  "description": "My custom flow-cli plugin",
  "author": "Your Name",
  "commands": ["my_command"],
  "hooks": ["PreWork"]
}
EOF
```

**Reload shell:**
```bash
exec zsh
flow plugin list  # Should show your plugin
```

---

## Installing Plugins

### From GitHub

```bash
# Install from GitHub repo
flow plugin install gh:username/flow-plugin-docker

# Example: Install a workflow plugin
flow plugin install gh:data-wise/flow-plugin-deploy
```

**What happens:**
1. Clones repo to `~/.config/flow/plugins/`
2. Auto-loads on next shell reload
3. Commands/hooks become available

---

### From Local Directory

```bash
# Copy from local path
flow plugin install /path/to/my-plugin

# Example: Install from Downloads
flow plugin install ~/Downloads/team-workflow-plugin
```

---

### Development Mode (Symlink)

For active development, symlink instead of copying:

```bash
cd ~/projects/dev-tools/my-flow-plugin
flow plugin install --dev .
```

**Benefits:**
- Changes reflect immediately (no reinstall)
- Edit code in original location
- Perfect for testing

---

## Plugin Development Workflow

### 1. Create Plugin Structure

```bash
flow plugin create my-awesome-tool
cd ~/.config/flow/plugins/my-awesome-tool
```

---

### 2. Implement Your Command

Edit `main.zsh`:

```bash
# Add custom command
my_deploy() {
  local env="${1:-staging}"

  echo "🚀 Deploying to $env..."

  # Your deployment logic
  if [[ "$env" == "production" ]]; then
    if ! _flow_confirm "Deploy to PRODUCTION?"; then
      echo "Cancelled"
      return 1
    fi
  fi

  # Run deployment
  git push origin main
  ssh deploy@server "cd app && git pull && systemctl restart app"

  echo "✅ Deployed to $env"
}
```

---

### 3. Register Hooks (Optional)

Add hook to run before/after flow-cli events:

```bash
# Register hook in main.zsh
flow_hook_register "PostFinish" "_my_plugin_post_finish"

_my_plugin_post_finish() {
  local session_note="$1"

  # Send Slack notification
  if command -v slack-cli >/dev/null 2>&1; then
    slack-cli send "#dev" "Session complete: $session_note"
  fi
}
```

**Available hooks:**
- `PreWork` - Before starting work session
- `PostWork` - After work session starts
- `PreFinish` - Before finishing session
- `PostFinish` - After finishing session
- `PreCommand` - Before any command
- `PostCommand` - After any command

---

### 4. Update Metadata

Edit `plugin.json`:

```json
{
  "name": "my-awesome-tool",
  "version": "0.2.0",
  "description": "Automated deployment workflows",
  "author": "Your Name <you@example.com>",
  "commands": ["my_deploy"],
  "hooks": ["PostFinish"],
  "dependencies": {
    "tools": ["git", "ssh"],
    "plugins": []
  },
  "config": {
    "default_env": "staging",
    "notify_slack": true
  }
}
```

---

### 5. Test Your Plugin

```bash
# Reload shell
exec zsh

# Test command
my_deploy staging

# Check plugin info
flow plugin info my-awesome-tool

# View hooks
flow plugin hooks
```

---

### 6. Share Your Plugin

**Option A: GitHub Repository**

```bash
cd ~/.config/flow/plugins/my-awesome-tool
git init
git add .
git commit -m "Initial commit"
gh repo create flow-plugin-my-awesome-tool --public --source=. --push
```

**Now others can install:**
```bash
flow plugin install gh:yourusername/flow-plugin-my-awesome-tool
```

---

**Option B: Local Distribution**

```bash
# Package as tarball
cd ~/.config/flow/plugins
tar -czf my-awesome-tool.tar.gz my-awesome-tool/

# Share tarball
# Others extract and install:
tar -xzf my-awesome-tool.tar.gz
flow plugin install ./my-awesome-tool
```

---

## Common Plugin Patterns

### Pattern 1: Project-Type Dispatcher

Add custom dispatcher for your project type:

```bash
# main.zsh
py() {
  local cmd="${1:-help}"
  shift 2>/dev/null

  case "$cmd" in
    test)
      pytest tests/ "$@"
      ;;
    run)
      python main.py "$@"
      ;;
    lint)
      ruff check . && mypy .
      ;;
    help)
      echo "py - Python Project Dispatcher"
      echo "  py test   Run pytest"
      echo "  py run    Run main.py"
      echo "  py lint   Run linters"
      ;;
    *)
      echo "Unknown: $cmd"
      return 1
      ;;
  esac
}
```

---

### Pattern 2: Workflow Automation

Automate repetitive workflows:

```bash
# main.zsh
flow_plugin_register_command "deploy-all"

deploy-all() {
  echo "🚀 Full deployment workflow..."

  # 1. Run tests
  echo "1/5 Running tests..."
  flow test || return 1

  # 2. Build
  echo "2/5 Building..."
  flow build || return 1

  # 3. Commit
  echo "3/5 Committing..."
  git add . && git commit -m "Deploy: $(date +%Y-%m-%d)"

  # 4. Push
  echo "4/5 Pushing..."
  git push origin main

  # 5. Deploy
  echo "5/5 Deploying..."
  ssh deploy@server "cd app && git pull && ./deploy.sh"

  echo "✅ Deployment complete!"
}
```

---

### Pattern 3: Integration Hooks

Integrate with external services:

```bash
# main.zsh
flow_hook_register "PostFinish" "_notify_jira"

_notify_jira() {
  local note="$1"

  # Extract JIRA ticket from note (e.g., "PROJ-123 fix bug")
  local ticket=$(echo "$note" | grep -oE "[A-Z]+-[0-9]+")

  if [[ -n "$ticket" ]]; then
    # Add comment to JIRA ticket
    jira issue comment "$ticket" \
      "Completed work: $note" \
      --comment-format="plain"

    echo "📝 Updated JIRA ticket: $ticket"
  fi
}
```

---

### Pattern 4: Custom Config

Add plugin-specific configuration:

```bash
# main.zsh
# Load plugin config from ~/.config/flow/my-plugin.conf
if [[ -f ~/.config/flow/my-plugin.conf ]]; then
  source ~/.config/flow/my-plugin.conf
fi

# Use config
my_deploy() {
  local env="${MY_PLUGIN_DEFAULT_ENV:-staging}"
  local region="${MY_PLUGIN_AWS_REGION:-us-east-1}"

  echo "Deploying to $env in $region..."
}

# Config file example (~/.config/flow/my-plugin.conf):
# MY_PLUGIN_DEFAULT_ENV="production"
# MY_PLUGIN_AWS_REGION="eu-west-1"
# MY_PLUGIN_SLACK_WEBHOOK="https://hooks.slack.com/..."
```

---

## Plugin Management Commands

### Information Commands

```bash
# Show all plugin info
flow plugin info my-plugin

# Show registered hooks
flow plugin hooks

# Show plugin search paths
flow plugin path
```

---

### Removal

```bash
# Remove plugin (with confirmation)
flow plugin remove my-plugin

# Force remove without confirmation
flow plugin remove -f my-plugin

# Note: Cannot remove bundled plugins, only disable them
flow plugin disable bundled-plugin
```

---

## Plugin Locations

### Search Paths (Priority Order)

1. **User plugins:** `~/.config/flow/plugins/`
2. **Bundled plugins:** `$FLOW_PLUGIN_DIR/plugins/` (flow-cli installation)

---

### Directory Structure

```
~/.config/flow/plugins/
├── my-workflow/
│   ├── main.zsh          # Entry point (required)
│   ├── plugin.json       # Metadata (required)
│   ├── README.md         # Documentation
│   ├── lib/              # Library code
│   │   └── helpers.zsh
│   └── completions/      # ZSH completions
│       └── _my_command
```

---

## Troubleshooting

### Issue: Plugin not loaded

**Symptoms:** `command not found: my_command`

**Causes:**
1. Plugin not enabled
2. Shell not reloaded
3. Syntax error in main.zsh

**Solutions:**
```bash
# Check plugin status
flow plugin list -a

# Enable if disabled
flow plugin enable my-plugin

# Reload shell
exec zsh

# Check for errors
zsh -x ~/.config/flow/plugins/my-plugin/main.zsh
```

---

### Issue: Hook not firing

**Symptoms:** Hook function not called

**Cause:** Hook not registered or wrong event name

**Solution:**
```bash
# View registered hooks
flow plugin hooks

# Verify registration in main.zsh
grep "flow_hook_register" ~/.config/flow/plugins/my-plugin/main.zsh

# Correct event names: PreWork, PostWork, PreFinish, PostFinish
```

---

### Issue: Command conflicts

**Symptoms:** Wrong command runs (another plugin/builtin)

**Cause:** Function name collision

**Solution:**
```bash
# Use plugin prefix in function names
# Bad:  deploy()
# Good: myplugin_deploy()

# Or namespace with underscore
# Good: _my_plugin_deploy()
```

---

## Best Practices

### DO ✅

**1. Prefix function names**
```bash
# Avoid conflicts
_myplugin_helper() { ... }
myplugin_command() { ... }
```

**2. Clean up on disable**
```bash
# Add cleanup function
_myplugin_cleanup() {
  unset -f myplugin_command
  unset MY_PLUGIN_VAR
}
```

**3. Document your plugin**
```bash
# Clear README.md with:
# - What it does
# - How to use it
# - Configuration options
# - Examples
```

**4. Version your plugin**
```json
{
  "version": "1.2.0",  // Semantic versioning
  "changelog": {
    "1.2.0": "Added feature X",
    "1.1.0": "Improved performance"
  }
}
```

---

### DON'T ❌

**1. Don't modify flow-cli core**
```bash
# ❌ Bad: Override core functions
work() { ... }  # Don't do this!

# ✅ Good: Add new commands or hooks
my_work_wrapper() {
  # Custom pre-work logic
  work "$@"
  # Custom post-work logic
}
```

**2. Don't block the shell**
```bash
# ❌ Bad: Long-running operations
while true; do
  check_status
  sleep 60
done

# ✅ Good: Background processes or one-shot
(check_status &)
```

**3. Don't assume dependencies**
```bash
# ❌ Bad: Direct usage
docker ps

# ✅ Good: Check first
if command -v docker >/dev/null 2>&1; then
  docker ps
else
  echo "Docker not installed"
fi
```

---

## Real-World Examples

### Example 1: AWS Deployment Plugin

```bash
# ~/.config/flow/plugins/aws-deploy/main.zsh
aws_deploy() {
  local env="${1:-staging}"
  local region="${AWS_REGION:-us-east-1}"

  echo "🚀 Deploying to AWS ($env, $region)..."

  # Build
  npm run build || return 1

  # Deploy to S3
  aws s3 sync ./dist/ "s3://my-app-$env/" \
    --region "$region" \
    --delete

  # Invalidate CloudFront
  local dist_id=$(aws cloudfront list-distributions \
    --query "DistributionList.Items[?Aliases.Items[?@=='my-app-$env.example.com']].Id | [0]" \
    --output text)

  aws cloudfront create-invalidation \
    --distribution-id "$dist_id" \
    --paths "/*"

  echo "✅ Deployed! https://my-app-$env.example.com"
}
```

---

### Example 2: Slack Notifier Plugin

```bash
# ~/.config/flow/plugins/slack-notify/main.zsh
flow_hook_register "PostFinish" "_slack_notify_finish"

_slack_notify_finish() {
  local note="$1"
  local webhook="${SLACK_WEBHOOK:-}"

  [[ -z "$webhook" ]] && return 0

  local project=$(basename "$PWD")
  local user=$(git config user.name || echo "$USER")

  curl -X POST "$webhook" \
    -H "Content-Type: application/json" \
    -d "{
      \"text\": \":white_check_mark: *$user* completed work on *$project*\",
      \"blocks\": [{
        \"type\": \"section\",
        \"text\": {
          \"type\": \"mrkdwn\",
          \"text\": \"$note\"
        }
      }]
    }" \
    --silent --output /dev/null
}

# Config: export SLACK_WEBHOOK="https://hooks.slack.com/..."
```

---

## Summary

**Key Points:**

1. ✅ `flow plugin list` - See available plugins
2. ✅ `flow plugin create` - Create new plugin
3. ✅ `flow plugin install` - Install from GitHub/local
4. ✅ Hooks extend flow-cli behavior without core mods
5. ✅ Prefix function names to avoid conflicts

**Quick workflow:**

```bash
# Create
flow plugin create my-tool

# Develop
cd ~/.config/flow/plugins/my-tool
vim main.zsh

# Test
exec zsh
my_tool_command

# Share
git init && gh repo create --push
```

---

**Last Updated:** 2026-01-10
**Version:** v5.0.0
**Related:** [flow.md](../commands/flow.md), [config guide](./CONFIG-MANAGEMENT-WORKFLOW.md)

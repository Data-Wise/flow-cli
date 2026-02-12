# Himalaya Email Setup

**Required for:** `em` email dispatcher
**Time:** 15-20 minutes
**Last Updated:** 2026-02-10

---

## Overview

The `em` dispatcher uses [himalaya](https://github.com/pimalaya/himalaya) as its email backend. Himalaya is a CLI email client that talks IMAP/SMTP, supports OAuth2 (via proxy), and outputs JSON for scripting.

### Architecture

```
em (flow-cli dispatcher)
  |
  v
himalaya (CLI email client)
  |
  v
email-oauth2-proxy (localhost)     <-- Only needed for OAuth2 providers
  IMAP: 127.0.0.1:1993 --> outlook.office365.com:993 (OAuth2/TLS)
  SMTP: 127.0.0.1:1587 --> smtp.office365.com:587  (OAuth2/STARTTLS)
```

**For app-password providers** (Gmail with app passwords, Fastmail, etc.), you connect himalaya directly — no proxy needed.

---

## Step 1: Install Himalaya

=== "Homebrew (macOS)"

    ```bash
    brew install himalaya
    ```

    Tracks stable releases. Easy upgrades via `brew upgrade himalaya`.

=== "Cargo (stable)"

    ```bash
    cargo install himalaya
    ```

    Same stable release as Homebrew. Cross-platform.

=== "Cargo (latest dev)"

    ```bash
    cargo install --git https://github.com/pimalaya/himalaya.git
    ```

    Bleeding-edge from git. May have newer features but less tested.

**Minimum version:** v1.0.0 (required for JSON output and template subsystem). Run `em doctor` to check.

Verify:

```bash
himalaya --version
```

---

## Step 2: Install Supporting Tools

| Tool | Purpose | Install |
|------|---------|---------|
| **jq** | JSON parsing (required) | `brew install jq` |
| **fzf** | Interactive picker (`em pick`) | `brew install fzf` |
| **bat** | Syntax highlighting | `brew install bat` |
| **w3m** | HTML email rendering | `brew install w3m` |

---

## Step 3: Configure Himalaya

Create `~/.config/himalaya/config.toml`:

### Option A: App Password (Simple)

For providers supporting app passwords (Gmail, Fastmail, etc.):

```toml
display-name = "Your Name"
downloads-dir = "~/Downloads"

[accounts.main]
default = true
email = "you@example.com"
display-name = "Your Name"

# Folder aliases
folder.aliases.inbox = "INBOX"
folder.aliases.sent = "Sent"
folder.aliases.drafts = "Drafts"
folder.aliases.trash = "Trash"

# Display
envelope.list.page-size = 25
envelope.list.datetime-fmt = "%F %R"
envelope.list.datetime-local-tz = true

# Message settings
message.read.headers = ["From", "To", "Cc", "Subject", "Date"]
message.write.headers = ["From", "To", "Cc", "Subject"]
message.send.save-copy = true
message.delete.style = "folder"

# IMAP
backend.type = "imap"
backend.host = "imap.example.com"
backend.port = 993
backend.encryption.type = "tls"
backend.login = "you@example.com"
backend.auth.type = "password"
backend.auth.cmd = "security find-generic-password -a you@example.com -s himalaya -w"

# SMTP
message.send.backend.type = "smtp"
message.send.backend.host = "smtp.example.com"
message.send.backend.port = 465
message.send.backend.encryption.type = "tls"
message.send.backend.login = "you@example.com"
message.send.backend.auth.type = "password"
message.send.backend.auth.cmd = "security find-generic-password -a you@example.com -s himalaya -w"
```

Store your app password in macOS Keychain:

```bash
security add-generic-password -a you@example.com -s himalaya -w "your-app-password"
```

### Option B: OAuth2 via Proxy (Microsoft 365, Google Workspace)

For providers requiring OAuth2, use [email-oauth2-proxy](https://github.com/simonrob/email-oauth2-proxy):

**1. Install the proxy:**

```bash
pip install emailproxy
```

**2. Configure the proxy** at `~/.config/email-oauth2-proxy/emailproxy.config`:

```ini
[Server setup]
local_address = 127.0.0.1

[you@example.com]
permission_url = https://login.microsoftonline.com/common/oauth2/v2.0/authorize
token_url = https://login.microsoftonline.com/common/oauth2/v2.0/token
oauth2_scope = https://outlook.office365.com/IMAP.AccessAsUser.All https://outlook.office365.com/SMTP.Send offline_access
redirect_uri = http://localhost:11434/redirect
client_id = 08162f7c-0fd2-4200-a84a-f25a4db0b584
client_secret =

server_address = outlook.office365.com
server_port = 993
local_address = 127.0.0.1:1993

[you@example.com - SMTP]
permission_url = https://login.microsoftonline.com/common/oauth2/v2.0/authorize
token_url = https://login.microsoftonline.com/common/oauth2/v2.0/token
oauth2_scope = https://outlook.office365.com/SMTP.Send offline_access
redirect_uri = http://localhost:11434/redirect
client_id = 08162f7c-0fd2-4200-a84a-f25a4db0b584
client_secret =

server_address = smtp.office365.com
server_port = 587
local_address = 127.0.0.1:1587
```

**3. Configure himalaya** to connect through the proxy (no TLS — proxy handles it):

```toml
# IMAP via proxy
backend.type = "imap"
backend.host = "127.0.0.1"
backend.port = 1993
backend.encryption.type = "none"
backend.login = "you@example.com"
backend.auth.type = "password"
backend.auth.cmd = "echo you@example.com"

# SMTP via proxy
message.send.backend.type = "smtp"
message.send.backend.host = "127.0.0.1"
message.send.backend.port = 1587
message.send.backend.encryption.type = "none"
message.send.backend.login = "you@example.com"
message.send.backend.auth.type = "password"
message.send.backend.auth.cmd = "echo you@example.com"
```

**4. Set up the proxy as a LaunchAgent** (starts on login):

```bash
cat > ~/Library/LaunchAgents/com.emailproxy.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.emailproxy</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>-m</string>
        <string>emailproxy</string>
        <string>--config-file</string>
        <string>/Users/YOU/.config/email-oauth2-proxy/emailproxy.config</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/YOU/.local/share/email-oauth2-proxy/proxy.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/YOU/.local/share/email-oauth2-proxy/proxy.log</string>
</dict>
</plist>
EOF

# Load it
launchctl load ~/Library/LaunchAgents/com.emailproxy.plist
```

**5. Initial OAuth2 authentication:**

```bash
# Trigger first auth
himalaya envelope list

# Watch proxy log for device code
tail -f ~/.local/share/email-oauth2-proxy/proxy.log
# You'll see: "Visit https://microsoft.com/devicelogin and use code XXXXXXXX"
# Open that URL and enter the code
```

---

## Step 4: Verify

```bash
# Check himalaya can connect
himalaya account doctor

# List inbox
himalaya envelope list

# Check em dispatcher
em doctor
```

You should see your inbox. If everything works, `em` commands are ready.

---

## Troubleshooting

### OAuth2 Token Expired

If you see auth errors after a long period:

```bash
# Check proxy log
tail -20 ~/.local/share/email-oauth2-proxy/proxy.log

# Trigger re-auth
himalaya envelope list
# Follow the device code instructions in the log
```

### Restart the Proxy

```bash
launchctl unload ~/Library/LaunchAgents/com.emailproxy.plist
launchctl load ~/Library/LaunchAgents/com.emailproxy.plist
```

### Check Proxy Status

```bash
ps aux | grep emailproxy | grep -v grep
tail -20 ~/.local/share/email-oauth2-proxy/proxy.log
```

### Common Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| Connection refused | Proxy not running | `launchctl load` the plist |
| Auth error | Token expired | Follow device code flow |
| Timeout on send | SMTP port blocked | Check proxy SMTP config |
| Empty inbox | Wrong folder name | Check `folder.aliases` in config |
| `em` says "himalaya not found" | Not in PATH | `brew install himalaya` or check PATH |

---

## Optional: Display Enhancements

### HTML Email Rendering

Install a terminal HTML renderer for rich email display:

```bash
brew install w3m    # Best table rendering
# or
brew install lynx   # Fastest, good charset support
```

The `em read` command automatically detects and uses these for HTML emails.

### Neovim Integration

For in-editor email with AI-powered actions (summarize, draft reply, extract todos), see the dedicated [Neovim Himalaya Setup](HIMALAYA-NVIM-SETUP.md) guide.

---

## Next Steps

- [Email Dispatcher Guide](EMAIL-DISPATCHER-GUIDE.md) - Full `em` command reference
- [Email Tutorial](EMAIL-TUTORIAL.md) - 60-minute hands-on walkthrough
- [Email Refcard](../reference/REFCARD-EMAIL-DISPATCHER.md) - Quick reference card
- [Neovim Setup](HIMALAYA-NVIM-SETUP.md) - Neovim + AI email integration

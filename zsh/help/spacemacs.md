# Spacemacs Integration - Detailed Guide

**Your Editor Setup - Optimized**

---

## 🎯 SETUP DETECTED

✅ Spacemacs installed  
✅ Emacsclient available  
✅ Daemon support ready

---

## 🚀 LAUNCH ALIASES (4)

### Primary Launch
```bash
e              # emacsclient -c -a ""
               # Connect to daemon OR start new
               # USE THIS MOST OF THE TIME
```

**What it does:**
1. Checks if daemon running
2. If yes: Opens new frame (instant!)
3. If no: Starts Emacs normally

**When to use:**
- Opening files
- Daily editing
- Quick edits

### Terminal Mode
```bash
et             # emacsclient -t
               # Terminal Emacs (no GUI)
```

**When to use:**
- SSH sessions
- Quick edits in terminal
- GUI not available

### GUI Client
```bash
ec             # emacsclient -c
               # GUI client (assumes daemon running)
```

**When to use:**
- Daemon definitely running
- Want new frame
- Explicit GUI request

### Open Directory
```bash
edir           # emacsclient -c -a "" .
               # Open current directory in dired
```

**When to use:**
- File management
- Project exploration
- Bulk operations

---

## ⚙️ SERVER MANAGEMENT (3)

### Start Server
```bash
estart         # emacs --daemon
               # Start Emacs daemon in background
```

**Run this ONCE per session (optional):**
```bash
# At login or first use:
$ estart
```

**Benefits:**
- Instant subsequent launches
- Shared buffers across frames
- Persistent state

### Stop Server
```bash
estop          # emacsclient -e "(kill-emacs)"
               # Gracefully stop daemon
```

**When to use:**
- End of day
- Updating Spacemacs
- Something went wrong

### Restart Server
```bash
erestart       # estop && sleep 1 && estart
               # Full restart
```

**When to use:**
- Config changes not taking effect
- Weird behavior
- Fresh start needed

---

## 📝 QUICK EDITS (3)

### Edit Zsh Config
```bash
ezsh           # Open ~/.config/zsh/.zshrc
```

**Workflow:**
```bash
$ ezsh              # Edit config
# Make changes
# Save: SPC f s (Spacemacs) or C-x C-s
$ reload            # Reload zsh
```

### Edit Project Status
```bash
estat          # Open .STATUS in current dir
```

**Workflow:**
```bash
$ @medfit           # Jump to project
$ estat             # Edit status
# Update completed/next/progress
# Save
```

### Edit Project Hub
```bash
ehub           # Open PROJECT-HUB.md
```

**For strategic planning updates**

---

## 🔧 CONFIG MANAGEMENT (2)

### Edit Spacemacs Config
```bash
econfig        # Open ~/.spacemacs
```

**What to edit:**
- Layer configuration
- Package additions
- Key bindings
- Theme/appearance

### Reload Config
```bash
ereload        # Spacemacs/reload-dotfile
               # Reload WITHOUT restarting
```

**After editing .spacemacs:**
```bash
$ econfig           # Edit .spacemacs
# Make changes
# Save
$ ereload           # Reload config
# No restart needed!
```

---

## 💡 COMMON WORKFLOWS

### First Time Each Day
```bash
# Option 1: Just use e (auto-starts if needed)
$ e

# Option 2: Explicit daemon start
$ estart            # Start daemon
$ e file.R          # Open file (instant!)
```

### Edit Zsh Config
```bash
$ ezsh              # Open .zshrc
# Edit in Spacemacs
# SPC f s to save
$ reload            # Back in terminal, reload
```

### Update Project Status
```bash
$ @medfit           # Jump to project
$ estat             # Edit .STATUS
# Update sections
# SPC f s to save
$ status            # Verify changes
```

### Work on R Package
```bash
$ @medfit
$ e R/fit.R         # Open R file
# Edit in Spacemacs
# SPC f s to save
$ rload             # Back in terminal, reload package
$ rtest             # Run tests
```

### Multiple Files
```bash
$ @medfit
$ e R/*.R           # Open all R files
# Spacemacs opens them all
# Switch between buffers: SPC b b
```

---

## 🎯 SPACEMACS QUICK KEYS

**While in Spacemacs:**

```
SPC f s         # Save file
SPC f f         # Find file
SPC b b         # Switch buffer
SPC w /         # Split vertically
SPC w -         # Split horizontally
SPC q q         # Quit Spacemacs
SPC f t         # Toggle file tree
SPC p f         # Find file in project
```

---

## 🔄 INTEGRATION WITH OTHER ALIASES

### Spacemacs + Navigation
```bash
$ @medfit && estat     # Jump and edit status
$ @zsh && ezsh         # Jump and edit config
```

### Spacemacs + Status
```bash
$ estat                # Edit status
# Make changes in Spacemacs
$ status               # View in terminal
```

### Spacemacs + R
```bash
$ e R/fit.R            # Edit in Spacemacs
# Write code
$ rload                # Load in terminal
$ rtest                # Test in terminal
```

---

## ⚡ PERFORMANCE TIPS

### Daemon vs No Daemon

**With daemon:**
- First launch: ~2-3 seconds (estart)
- Subsequent: <0.5 seconds (e)
- Shared state

**Without daemon:**
- Every launch: ~2-3 seconds
- Isolated instances

**Recommendation:** Run estart once per day

### When Daemon Gets Weird
```bash
$ estop             # Stop daemon
$ estart            # Restart fresh
# Or
$ erestart          # Do both
```

---

## 🐛 TROUBLESHOOTING

### "Can't connect to daemon"
```bash
# Check if running:
$ ps aux | grep emacs

# Restart:
$ erestart
```

### "Config changes not taking"
```bash
# After editing .spacemacs:
$ ereload

# If that doesn't work:
$ erestart
```

### "Spacemacs won't start"
```bash
# Check logs:
$ tail -f ~/.emacs.d/server/server.log

# Or start without daemon:
$ emacs
```

### "Want fresh start"
```bash
$ estop
# Close all Emacs windows
$ estart
```

---

## 📊 ALIAS SUMMARY

| Alias | Purpose | Frequency |
|-------|---------|-----------|
| e | Launch/connect | Daily |
| estat | Edit status | Daily |
| ezsh | Edit zsh config | Weekly |
| econfig | Edit Spacemacs config | As needed |
| ereload | Reload config | As needed |
| estart | Start daemon | Once/day |
| et | Terminal mode | Rare |
| ec | GUI client | Rare |
| edir | Open directory | As needed |
| estop | Stop daemon | End of day |

---

## 🎯 QUICK REFERENCE

**Most used:**
```bash
e              # Launch
estat          # Edit status
ezsh           # Edit zsh config
ereload        # Reload Spacemacs config
```

**Daily workflow:**
```bash
# Morning:
estart         # Optional, or let e auto-start

# During work:
e file         # Edit files
estat          # Update status
ezsh           # Tweak config

# End of day:
estop          # Optional shutdown
```

---

**See also:** help, helpnav, helpr

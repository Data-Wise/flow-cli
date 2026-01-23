# Automatic Token Health Checks

## Weekly Health Check (Recommended)

Add to your `~/.config/zsh/.zshrc`:

```bash
# Weekly token health check (runs once per week max)
_flow_weekly_token_check() {
  local last_check_file="$HOME/.cache/flow-cli/last-token-check"
  local last_check_date=$(cat "$last_check_file" 2>/dev/null || echo "0")
  local current_date=$(date +%Y%m%d)
  local days_since=$((current_date - last_check_date))

  if [[ $days_since -ge 7 ]]; then
    # Check token status (silent)
    local token_status=$(dot token expiring 2>&1)
    echo "$current_date" > "$last_check_file"

    # Only notify if issues found
    if echo "$token_status" | grep -q "EXPIRED\|EXPIRING"; then
      # macOS Notification
      osascript -e 'display notification "GitHub tokens need rotation" with title "flow-cli" sound name "default"' &>/dev/null

      # Shell prompt
      echo ""
      echo "${FLOW_COLORS[warning]}⚠ flow-cli: GitHub tokens need rotation${FLOW_COLORS[reset]}"
      echo "Run: ${FLOW_COLORS[cmd]}dot token rotate${FLOW_COLORS[reset]}"
      echo ""
    fi
  fi
}

# Run async on shell startup (non-blocking)
_flow_weekly_token_check &!
```

## Manual Health Check

Run anytime:

```bash
dot token expiring
```

## Integration with flow doctor

Coming in Phase 2: `flow doctor` will include token health checks.

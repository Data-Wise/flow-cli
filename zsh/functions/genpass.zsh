# ------------------------------------------------------------------------------
# SECURITY UTILITIES
# ------------------------------------------------------------------------------

# usage: genpass [length]
# default: 32 characters
genpass() {
    local length="${1:-32}"
    
    # Logic:
    # 1. Generate excess random bytes (length * 2 ensures enough raw data)
    # 2. Base64 encode it
    # 3. Clean it: remove newlines, '+', '/', and '=' for maximum url/system compatibility
    # 4. Cut to the exact requested length
    # 5. Pipe strictly to clipboard (pbcopy) to avoid history logs
    openssl rand -base64 "$((length * 2))" | tr -d '\n+/=' | cut -c1-"$length" | pbcopy

    # Feedback: Use Zsh colors to confirm without revealing the secret
    print -P "%F{green}✔%f Generated %B${length}-character%b secret and copied to clipboard."
}
#!/bin/bash
# auth.sh <gmail|drive|calendar> <label>
set -e
SVC="$1"; L="$2"
[ -n "$SVC" ] && [ -n "$L" ] || { echo "usage: auth.sh <gmail|drive|calendar> <label>" >&2; exit 1; }

echo
echo "Watch for the Google account picker. If your browser is already signed in,"
echo "Google may skip it and authorize the WRONG account. Use a private window if"
echo "no picker appears. Run verify.sh afterwards to confirm."
echo

case "$SVC" in
  gmail)
    export GMAIL_OAUTH_PATH="$HOME/.gmail-mcp/gcp-oauth.keys.json"
    export GMAIL_CREDENTIALS_PATH="$HOME/.gmail-mcp/creds-$L.json"
    npx -y @gongrzhe/server-gmail-autoauth-mcp auth
    [ -f "$GMAIL_CREDENTIALS_PATH" ] && chmod 600 "$GMAIL_CREDENTIALS_PATH" \
      && echo "SUCCESS — $GMAIL_CREDENTIALS_PATH" || { echo "FAILED — no token written." >&2; exit 1; }
    ;;
  drive)
    node "$HOME/.gdrive-mcp/drive-auth.mjs" "$L"
    ;;
  calendar)
    export GOOGLE_OAUTH_CREDENTIALS="$HOME/.gcal-mcp/gcp-oauth.keys.json"
    export GOOGLE_CALENDAR_MCP_TOKEN_PATH="$HOME/.gcal-mcp/token-$L.json"
    npx -y @cocal/google-calendar-mcp auth
    [ -f "$GOOGLE_CALENDAR_MCP_TOKEN_PATH" ] && chmod 600 "$GOOGLE_CALENDAR_MCP_TOKEN_PATH" \
      && echo "SUCCESS — $GOOGLE_CALENDAR_MCP_TOKEN_PATH" || { echo "FAILED — no token written." >&2; exit 1; }
    ;;
  *) echo "Unknown service: $SVC (use gmail, drive or calendar)" >&2; exit 1;;
esac

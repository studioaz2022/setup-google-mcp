#!/bin/bash
# bootstrap.sh <path-to-oauth-keys.json> <label1> [label2 ...]
# Creates credential directories for each account label and installs helpers.
set -e
KEYS_SRC="$1"; shift || true
[ -n "$KEYS_SRC" ] && [ "$#" -ge 1 ] || { echo "usage: bootstrap.sh <keys.json> <label> [label...]" >&2; exit 1; }
[ -f "$KEYS_SRC" ] || { echo "No such file: $KEYS_SRC" >&2; exit 1; }

python3 - "$KEYS_SRC" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
k = list(d.keys())
if "installed" not in d:
    print(f"ERROR: this is a '{k[0]}' OAuth client, not a Desktop app.", file=sys.stderr)
    print("Create a new client of type 'Desktop app' and download that JSON.", file=sys.stderr)
    sys.exit(1)
i = d["installed"]
for f in ("client_id", "client_secret"):
    if not i.get(f):
        print(f"ERROR: keys file is missing {f}", file=sys.stderr); sys.exit(1)
print(f"OK: Desktop app client for project {i.get('project_id','(unknown)')}")
PY

mkdir -p "$HOME/.gmail-mcp" "$HOME/.gcal-mcp"; chmod 700 "$HOME/.gmail-mcp" "$HOME/.gcal-mcp"
cp "$KEYS_SRC" "$HOME/.gmail-mcp/gcp-oauth.keys.json"
cp "$KEYS_SRC" "$HOME/.gcal-mcp/gcp-oauth.keys.json"
chmod 600 "$HOME/.gmail-mcp/gcp-oauth.keys.json" "$HOME/.gcal-mcp/gcp-oauth.keys.json"

for L in "$@"; do
  case "$L" in *[!a-z0-9-]*) echo "Label '$L' must be lowercase letters, digits or hyphens." >&2; exit 1;; esac
  mkdir -p "$HOME/.gdrive-mcp/$L"; chmod 700 "$HOME/.gdrive-mcp" "$HOME/.gdrive-mcp/$L"
  cp "$KEYS_SRC" "$HOME/.gdrive-mcp/$L/gcp-oauth.keys.json"
  chmod 600 "$HOME/.gdrive-mcp/$L/gcp-oauth.keys.json"
  echo "  prepared: $L"
done

# Drive's server authorizes lazily on first tool call and times out after 30s,
# so a bare server start never completes the flow. This forces it directly.
cp "$(dirname "$0")/drive-auth.mjs" "$HOME/.gdrive-mcp/drive-auth.mjs"
chmod 700 "$HOME/.gdrive-mcp/drive-auth.mjs"
( cd "$HOME/.gdrive-mcp" && npm install --silent --no-fund --no-audit @isaacphi/mcp-gdrive >/dev/null 2>&1 ) \
  && echo "  Drive auth helper installed" || echo "  WARNING: Drive helper install failed — 'auth.sh drive' may not work"

echo
echo "Done. Drive server env values (needed for client config):"
python3 -c "
import json,os
i=json.load(open(os.path.expanduser('~/.gmail-mcp/gcp-oauth.keys.json')))['installed']
print('  CLIENT_ID     =', i['client_id'])
print('  CLIENT_SECRET = (in ~/.gmail-mcp/gcp-oauth.keys.json — do not paste into chat)')
"

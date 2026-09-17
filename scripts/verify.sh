#!/bin/bash
# verify.sh <label1> [label2 ...]
# Calls each Google API with each stored token and prints the account it really
# belongs to. Compare every line against what the user intended.
[ "$#" -ge 1 ] || { echo "usage: verify.sh <label> [label...]" >&2; exit 1; }
echo
printf "%-10s %-10s %-34s %s\n" LABEL SERVICE "ACCOUNT THE TOKEN BELONGS TO" REFRESH
printf "%-10s %-10s %-34s %s\n" "------" "-------" "----------------------------------" "-------"

check() { # label service tokenfile jsonpath url jqfield
  local L="$1" S="$2" F="$3" P="$4" URL="$5" FIELD="$6"
  [ -f "$F" ] || { printf "%-10s %-10s %-34s %s\n" "$L" "$S" "(not authorized)" "-"; return; }
  local TOKEN REFRESH
  TOKEN=$(python3 -c "
import json,sys
d=json.load(open('$F'))
for k in '$P'.split('.'):
    if k: d=d.get(k,{})
print(d.get('access_token',''))
" 2>/dev/null)
  REFRESH=$(python3 -c "
import json
d=json.load(open('$F'))
for k in '$P'.split('.'):
    if k: d=d.get(k,{})
print('yes' if d.get('refresh_token') else 'NO')
" 2>/dev/null)
  local WHO
  WHO=$(curl -s --max-time 20 -H "Authorization: Bearer $TOKEN" "$URL" \
        | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
except Exception:
    print('(unreadable response)'); raise SystemExit
v=d
for k in '$FIELD'.split('.'):
    v=v.get(k,{}) if isinstance(v,dict) else {}
print(v if isinstance(v,str) and v else '(ERROR: '+json.dumps(d)[:60]+')')
")
  printf "%-10s %-10s %-34s %s\n" "$L" "$S" "$WHO" "$REFRESH"
}

for L in "$@"; do
  check "$L" gmail    "$HOME/.gmail-mcp/creds-$L.json" "" \
        "https://gmail.googleapis.com/gmail/v1/users/me/profile" "emailAddress"
  check "$L" drive    "$HOME/.gdrive-mcp/$L/.gdrive-server-credentials.json" "" \
        "https://www.googleapis.com/drive/v3/about?fields=user(emailAddress)" "user.emailAddress"
  check "$L" calendar "$HOME/.gcal-mcp/token-$L.json" "normal" \
        "https://www.googleapis.com/calendar/v3/calendars/primary" "id"
done
echo
echo "Every address must match the account you intended for that label."
echo "A mismatch means that service was authorized with the wrong Google account —"
echo "re-run:  bash scripts/auth.sh <service> <label>"

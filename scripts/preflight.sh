#!/bin/bash
# preflight.sh — confirm this machine has what the setup needs.
# Safe to run repeatedly; changes nothing.
MISSING=0
ok()   { printf "  \033[32m✓\033[0m %-12s %s\n" "$1" "$2"; }
bad()  { printf "  \033[31m✗\033[0m %-12s %s\n" "$1" "$2"; MISSING=1; }

echo
echo "Checking prerequisites..."
echo

if command -v node >/dev/null 2>&1; then
  V=$(node --version); MAJOR=${V#v}; MAJOR=${MAJOR%%.*}
  if [ "$MAJOR" -ge 18 ] 2>/dev/null; then ok node "$V"
  else bad node "$V — too old, need 18 or newer"; fi
else
  bad node "not installed"
fi

command -v npx >/dev/null 2>&1 && ok npx "$(npx --version 2>/dev/null)" || bad npx "not installed (ships with Node)"
command -v python3 >/dev/null 2>&1 && ok python3 "$(python3 --version 2>&1 | cut -d' ' -f2)" || bad python3 "not installed"
command -v curl >/dev/null 2>&1 && ok curl "present" || bad curl "not installed"
command -v claude >/dev/null 2>&1 && ok claude "$(claude --version 2>/dev/null | head -1)" || \
  printf "  \033[33m!\033[0m %-12s %s\n" claude "not on PATH — fine if you use the desktop app"

echo
if [ "$MISSING" = "0" ]; then
  echo "All set. Next: /setup-google-mcp in Claude Code."
else
  echo "Install what's missing, then re-run this."
  echo
  echo "  macOS, with Homebrew:   brew install node python3"
  echo "  macOS, without:         https://nodejs.org (LTS installer — includes npx)"
  echo "                          python3 comes with Xcode Command Line Tools:"
  echo "                          xcode-select --install"
  echo "  Linux:                  use your package manager (nodejs, npm, python3)"
  exit 1
fi

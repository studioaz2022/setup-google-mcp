# Claude Code registration

Replace `LABEL` with each account label. `-s user` makes the servers available
in every project, not just the current one.

## Gmail
```bash
claude mcp add -s user gmail-LABEL \
  -e GMAIL_OAUTH_PATH="$HOME/.gmail-mcp/gcp-oauth.keys.json" \
  -e GMAIL_CREDENTIALS_PATH="$HOME/.gmail-mcp/creds-LABEL.json" \
  -- npx -y @gongrzhe/server-gmail-autoauth-mcp
```

## Drive
`CLIENT_ID` / `CLIENT_SECRET` come from the keys file; the command reads them
directly so neither is typed into a terminal or a chat.
```bash
claude mcp add -s user gdrive-LABEL \
  -e CLIENT_ID="$(python3 -c "import json,os;print(json.load(open(os.path.expanduser('~/.gmail-mcp/gcp-oauth.keys.json')))['installed']['client_id'])")" \
  -e CLIENT_SECRET="$(python3 -c "import json,os;print(json.load(open(os.path.expanduser('~/.gmail-mcp/gcp-oauth.keys.json')))['installed']['client_secret'])")" \
  -e GDRIVE_CREDS_DIR="$HOME/.gdrive-mcp/LABEL" \
  -- npx -y @isaacphi/mcp-gdrive
```

## Calendar
```bash
claude mcp add -s user gcal-LABEL \
  -e GOOGLE_OAUTH_CREDENTIALS="$HOME/.gcal-mcp/gcp-oauth.keys.json" \
  -e GOOGLE_CALENDAR_MCP_TOKEN_PATH="$HOME/.gcal-mcp/token-LABEL.json" \
  -- npx -y @cocal/google-calendar-mcp
```

## Optional — fewer permission prompts

Allowlist read-only tools in `~/.claude/settings.json` so searching and reading
run without prompting, while every write still asks. Merge into
`permissions.allow`, preserving anything already there:

```json
"mcp__gmail-LABEL__read_email",
"mcp__gmail-LABEL__search_emails",
"mcp__gmail-LABEL__list_email_labels",
"mcp__gdrive-LABEL__gdrive_search",
"mcp__gdrive-LABEL__gdrive_read_file",
"mcp__gdrive-LABEL__gsheets_read",
"mcp__gcal-LABEL__list-events",
"mcp__gcal-LABEL__search-events",
"mcp__gcal-LABEL__get-event",
"mcp__gcal-LABEL__list-calendars",
"mcp__gcal-LABEL__get-freebusy"
```

Do NOT allowlist: `send_email`, `draft_email`, `modify_email`, `delete_email`,
`gsheets_update_cell`, `create-event`, `update-event`, `delete-event`,
`respond-to-event`.

Verify: `claude mcp list`

---
name: setup-google-mcp
description: Set up local MCP servers for one or more Google accounts (Gmail, Drive, Calendar) so Claude can search and read them, with each account kept strictly separate. Use when the user wants Claude connected to their Gmail, Google Drive, or Google Calendar, especially across multiple accounts, or says the built-in connector only handles one account.
---

# Set up Google MCP servers (multi-account)

Wire up local MCP servers giving Claude access to the user's Google accounts.
Each account gets its own servers and its own credentials, so two accounts can
never be confused.

The software is three public npm packages, fetched by `npx` on first run:

| Service | Package | Scope granted |
|---|---|---|
| Gmail | `@gongrzhe/server-gmail-autoauth-mcp` | `gmail.modify` — read, send, label, trash. **No permanent delete.** |
| Drive | `@isaacphi/mcp-gdrive` | `drive.readonly` + `spreadsheets` — read files/sheets, update single cells |
| Calendar | `@cocal/google-calendar-mcp` | `calendar` — **full read/write, including irreversible deletes** |

## Before you start

Tell the user, in your own words:

- These are **third-party packages**, not written or audited by Anthropic. They
  get real access to their mail and calendar. They should decide that's
  acceptable — point them at the npm pages if they want to look first.
- **Calendar is full read/write.** `delete-event` is irreversible; a deleted
  event is gone. Gmail deletes go to Trash and Drive is read-only, so Calendar
  is the only place an accident can't be undone.
- Nothing leaves their machine except traffic to Google. Credentials are stored
  in their home directory.

## Step 0 — Preflight

Run this first. It changes nothing and takes a second:

```bash
bash scripts/preflight.sh
```

It checks Node 18+, npx, python3 and curl. If anything is missing, stop and help
the user install it — every later step depends on these. **Node is not
preinstalled on macOS**, so a fresh machine usually needs it.

## Step 0.5 — Gather requirements

Ask, and do not assume:

1. **How many Google accounts**, and a short lowercase label for each
   (`personal`, `work`, `school`). Labels become server names, so keep them
   short and meaningful.
2. **The email address for each label.** You need these to verify later that
   each token actually points where it should.
3. **Which services** they want per account: Gmail, Drive, Calendar, or a subset.
   Fewer servers means less clutter; they can add more later.
4. **Which clients** to configure: Claude Code, Cursor, Codex, or several.

Record the answers before proceeding — every later step depends on them.

## Step 1 — Google Cloud project (the user does this)

You cannot do this part. Give them these steps and wait for confirmation.

1. Go to https://console.cloud.google.com and **create a new project**.
2. **APIs & Services → Library** — enable one API per service they chose:
   **Gmail API**, **Google Drive API**, **Google Calendar API**.
3. **APIs & Services → OAuth consent screen** (may be called **Branding**):
   choose **External**.
4. **Publish the app to production.** A warning appears saying the app requires
   verification — that is expected. Publishing anyway is correct and safe for
   personal use: they get an "unverified app" screen at sign-in that they click
   through via *Advanced → Go to (app)*, and a 100-user cap that does not matter.
5. **Credentials → Create Credentials → OAuth client ID → Desktop app.**
   Download the JSON.

### Two traps — state both explicitly

- **Leaving the app in "Testing" expires refresh tokens after 7 days.** They
  would re-authorize every week. Publishing to production is what prevents this.
  If they skip step 4, everything works for a week and then breaks; flag it now.
- **Enabling an API and adding a scope are different switches.** Skipping the
  API enable produces a successful authorization followed by `SERVICE_DISABLED`
  on every call — a failure that surfaces much later and looks unrelated.

## Step 2 — Bootstrap

Ask for the path to the downloaded JSON, then run:

```bash
bash scripts/bootstrap.sh <path-to-downloaded.json> <label1> [label2 ...]
```

It validates the file is a **Desktop app** client (`installed` key — a `web`
client will not work), creates `~/.gmail-mcp/`, `~/.gdrive-mcp/<label>/`, and
`~/.gcal-mcp/` with `700`/`600` permissions, and installs the Drive auth helper.

If it reports the file is a `web` client, they picked the wrong application type
in step 1.5 — send them back to create a Desktop app client.

## Step 3 — Authorize each account

One command per account per service:

```bash
bash scripts/auth.sh gmail <label>
bash scripts/auth.sh drive <label>
bash scripts/auth.sh calendar <label>
```

**Before the first run, warn them about the account picker.** If their browser is
already signed into a Google account, Google may skip the chooser and silently
authorize the wrong one. Tell them to watch for the picker, and to use a private
window if it does not appear. A silently wrong authorization is the single most
likely failure, and it is invisible until you verify.

Run these one at a time and confirm each before moving on. Drive's flow has a
**30-second timeout** — they should not linger on the account picker.

## Step 4 — Verify (do not skip)

```bash
bash scripts/verify.sh <label1> [label2 ...]
```

This calls each Google API with each stored token and prints the email address
that token actually belongs to.

**Compare every line against what the user told you in Step 0.** If any row shows
the wrong address, that account was authorized with the wrong Google account.
Re-run the matching `auth.sh` command for it — do not continue until every row
matches. This check is the whole reason the setup is trustworthy.

Also confirm each row shows a refresh token. Without one they will be
re-authorizing constantly.

## Step 5 — Register the servers

Use `templates/` for the client(s) they chose. Server naming is
`<service>-<label>` — `gmail-work`, `gdrive-personal`, `gcal-school`.

- **Claude Code** — `templates/claude-code.md` has the `claude mcp add` commands.
  Use `-s user` so the servers work in every project.
- **Cursor** — merge `templates/cursor.json` into `~/.cursor/mcp.json`. Preserve
  any existing servers; do not overwrite the file.
- **Codex** — append `templates/codex.toml` to `~/.codex/config.toml`. Note that
  the ChatGPT desktop app rewrites this file, so verify the block survives a
  restart.

Substitute real labels and paths. The Drive server needs `CLIENT_ID` and
`CLIENT_SECRET` read from their keys file — `bootstrap.sh` prints them.

## Step 6 — Write the routing rule

**This is what keeps the accounts straight, and it matters more than anything
else here.** Multiple accounts expose identical tool sets; the server name is the
only thing distinguishing them.

Fill in `templates/ROUTING_RULE.md` with their real labels and addresses, then
install it where their client reads standing instructions:

- **Claude Code** → append to `~/.claude/CLAUDE.md` (applies to every project)
- **Codex** → `~/.codex/AGENTS.md`, and `~/AGENTS.md` as a belt-and-braces copy
- **Cursor** → Settings → Rules is UI-stored, so hand them the text to paste;
  a project-scoped copy can go in `.cursor/rules/google-routing.mdc`

Without this, a client with several identical-looking Google servers has nothing
telling it which is which — exactly the confusion this setup exists to prevent.

## Step 7 — Confirm it works

Servers load at client startup, so have them restart and **start a fresh chat**.

Then have them try a request naming an account explicitly — "search my work email
for anything from my landlord." A correct setup names the mailbox it used. If it
asks which account they mean, or reaches for a tool that is not there, the
routing rule or the server registration did not load.

## Troubleshooting

| Symptom | Cause |
|---|---|
| `SERVICE_DISABLED` | That API was never enabled (Step 1.2) |
| Auth works, breaks ~7 days later | Consent screen left in "Testing" (Step 1.4) |
| Drive auth appears to do nothing | Its flow is lazy and times out in 30s — use `auth.sh drive`, not a bare server start |
| `verify.sh` shows the wrong address | Wrong Google account chosen at sign-in; re-run that `auth.sh` |
| "invalid_client" | `web` client instead of Desktop app |
| Tools missing after setup | Client not restarted, or config went to the wrong scope |
| Everything stops at once, all accounts | Google password change revokes tokens carrying Gmail scopes — re-run the auth steps |

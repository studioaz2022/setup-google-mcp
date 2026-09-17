# Google MCP setup (multi-account)

Connect Claude to one or more Google accounts — Gmail, Drive, Calendar — with
each account kept strictly separate, so it can never act on the wrong one.

Built because the built-in Google connectors generally handle a single account,
and juggling a personal and a work inbox means constantly switching.

## Install

**1. Get the files into your skills folder:**

```bash
mkdir -p ~/.claude/skills
git clone https://github.com/studioaz2022/setup-google-mcp.git ~/.claude/skills/setup-google-mcp
```

(Downloaded a zip instead? Unzip it and move the folder to
`~/.claude/skills/setup-google-mcp`.)

**2. Check your machine has what it needs:**

```bash
bash ~/.claude/skills/setup-google-mcp/scripts/preflight.sh
```

Needs Node 18+, npx, python3 and curl. The script tells you how to install
anything missing. **Node is not preinstalled on macOS**, so this often has
something to do on a fresh machine.

**3. In Claude Code, run:**

```
/setup-google-mcp
```

Claude reads the skill and walks you through it — asking which accounts and
services you want, telling you exactly what to click in Google Cloud Console,
running the scripts, and verifying each token landed on the right account.

Prefer to drive it yourself? `SKILL.md` is a readable runbook; the steps are the
same by hand.

## What it sets up

| Service | Package | Access |
|---|---|---|
| Gmail | `@gongrzhe/server-gmail-autoauth-mcp` | read, send, label, trash — **no permanent delete** |
| Drive | `@isaacphi/mcp-gdrive` | read files and sheets, update single cells — **read-only otherwise** |
| Calendar | `@cocal/google-calendar-mcp` | **full read/write, including irreversible deletes** |

Servers are named `<service>-<label>` — `gmail-work`, `gdrive-personal` — and
the label is in every tool name, which is what keeps accounts from blurring.

## Read this before you start

- **These are third-party packages**, not written or audited by Anthropic or by
  whoever sent you this. They get real access to your mail and calendar. Look at
  them on npm first if you want to.
- **Calendar is the one irreversible thing.** A deleted event is gone. Gmail
  deletes go to Trash; Drive is read-only. The routing rule the skill installs
  puts every write behind explicit approval, but that's an instruction, not a
  hard boundary. If you want a hard boundary, authorize Calendar with a
  read-only scope instead.
- **Everything stays on your machine.** Credentials live in `~/.gmail-mcp/`,
  `~/.gdrive-mcp/`, `~/.gcal-mcp/` at `700`/`600`. Nothing is uploaded anywhere;
  traffic goes only to Google.
- **You need your own Google Cloud project.** Never use someone else's OAuth
  client — their quotas, their audit logs, their ability to revoke you.

## Time

About 15 minutes for one account, 25 for two. Most of it is clicking through
Google Cloud Console and signing in once per account per service.

## Files

```
SKILL.md                    the runbook Claude follows
scripts/preflight.sh        checks Node / python3 / curl are present
scripts/bootstrap.sh        validates your keys file, creates credential dirs
scripts/auth.sh             authorizes one service for one account
scripts/drive-auth.mjs      forces Drive's lazy OAuth flow (it needs the nudge)
scripts/verify.sh           proves each token belongs to the account you meant
templates/                  config for Claude Code, Cursor, Codex + routing rule
```

## The step people skip

`verify.sh` calls each API and prints the address each token actually belongs to.
Run it. If your browser was already signed into Google, it may have silently
authorized the wrong account — and you would not find out until Claude read the
wrong inbox. It is the only check that catches this.

## Known traps

| Symptom | Cause |
|---|---|
| Works, then breaks ~7 days later | OAuth consent screen left in "Testing" — publish to production |
| `SERVICE_DISABLED` on every call | That API was never enabled (separate switch from adding the scope) |
| Drive auth seems to do nothing | Its flow is lazy with a 30s timeout — use `auth.sh drive` |
| "invalid_client" | You made a `web` OAuth client; it must be **Desktop app** |
| Tools missing after setup | Restart the client and start a fresh chat |
| All accounts break at once | A Google password change revokes tokens with Gmail scopes |

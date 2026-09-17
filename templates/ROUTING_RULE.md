<!-- Fill in the real labels and addresses, then install where the client reads
     standing instructions:
       Claude Code → append to ~/.claude/CLAUDE.md
       Codex       → ~/.codex/AGENTS.md  (and ~/AGENTS.md as a backup copy)
       Cursor      → Settings → Rules (paste), or .cursor/rules/*.mdc per project
-->

## Google accounts — routing

Each Google account has its own MCP servers. **Always route Google work through
these**, in preference to any built-in connector.

| Server | Account | Covers |
|---|---|---|
| `gmail-LABEL1` | you@example.com | LABEL1 email |
| `gdrive-LABEL1` | you@example.com | LABEL1 Drive + Sheets |
| `gcal-LABEL1` | you@example.com | LABEL1 calendar |
| `gmail-LABEL2` | other@example.com | LABEL2 email |
| `gdrive-LABEL2` | other@example.com | LABEL2 Drive + Sheets |
| `gcal-LABEL2` | other@example.com | LABEL2 calendar |

The accounts expose identical tool sets. **The server name is the only thing
distinguishing them** — read the name, don't infer from content.

### Routing

- Phrases meaning LABEL1 → the `*-LABEL1` servers; LABEL2 → the `*-LABEL2` servers.
- A named address resolves directly to that account's servers.
- "check both" / "all my email" → query both and label every result by account.
- **If the intended account is genuinely unclear, ask.** Do not guess. Acting on
  the wrong account is the specific failure this setup exists to prevent.
- Once an account is established in a task, stay on it. If a follow-up appears to
  cross over, say so rather than silently switching.

**Always state which account you acted on**, e.g. "in your LABEL2 inbox
(other@example.com), 3 threads matched".

### Approval

Reading and searching need no confirmation.

**Anything that writes requires an explicit go-ahead in chat, per account** —
approval for one account never carries to another. That covers sending,
replying, forwarding, trashing, label changes, `gsheets_update_cell`, and every
calendar mutation.

**`delete-event` is the one irreversible action here.** Gmail deletes go to
Trash; Drive is read-only; a deleted calendar event is gone. Only call it when
deleting that specific event is what was explicitly asked for, and confirm which
calendar first.

### Limits

- Gmail `gmail.modify` — read, send, label, trash. **No permanent delete.**
- Drive `drive.readonly` + `spreadsheets` — read files and sheets, update single
  cells. **No creating, uploading, moving or deleting.** If asked to write to
  Drive, say plainly the scope doesn't allow it rather than working around it.
- Calendar `calendar` — full read/write including deletion.

# Using your vault from your phone

Optional, and not part of the guard. This documents how to reach a vault from a messaging app, because a vault you can only reach at your desk captures a fraction of what you would actually put in it — most of what is worth capturing happens while you are somewhere else.

**Channels** is Anthropic's mechanism for pushing messages into a running Claude Code session. You message a bot; the session on your machine reads it, works against your real files, and replies in the same chat. The work happens locally — only the chat messages travel.

> Channels is a **research preview**. The `--channels` flag does not appear in `claude --help`, and the docs warn the syntax may change. It is genuinely useful today; do not build anything load-bearing on the flag staying identical.

## Requirements

[Bun](https://bun.sh) — the channel plugins are Bun scripts.

```bash
curl -fsSL https://bun.sh/install | bash
bun --version
```

## Which channel

| | Telegram | Discord | iMessage |
|---|---|---|---|
| Setup | Bot via BotFather | Bot via Developer Portal | None — no token at all |
| Works on | Everything | Everything | Apple devices only |
| Needs an account | Telegram | Discord | Already have it |
| Attachments in | Photos auto-download | Yes | Yes |
| Fiddliest part | Copying a token | Bot invite permissions | Granting Full Disk Access |

**Telegram is the usual pick** — quickest setup, works on every device, and the bot is private to you.

**iMessage is the least setup by a distance** if you are on Apple hardware: no bot, no token, no third-party account. Text yourself and it works. The catch is that it reads your Messages database directly, which requires Full Disk Access for your terminal — a real permission to think about before granting.

**Discord** makes sense if you already live there.

## Try it first with no accounts

Before touching a real platform:

```
/plugin install fakechat@claude-plugins-official
```
```bash
claude --channels plugin:fakechat@claude-plugins-official
```

Open `http://localhost:8787` and type. The message lands in your session; the reply comes back in the browser. **This proves the mechanism works before you debug a bot token.**

---

## Telegram

**1. Create the bot.** Message [@BotFather](https://t.me/BotFather), send `/newbot`, give it a display name and a username ending in `bot`. Copy the token it returns.

**2. Install and configure.**
```
/plugin install telegram@claude-plugins-official
```
```
/telegram:configure <paste-your-token>
```
Saved to `~/.claude/channels/telegram/.env`.

**3. Restart with the channel on.**
```bash
claude --channels plugin:telegram@claude-plugins-official
```

**4. Pair.** Message your bot anything. It replies with a six-character code. Back in Claude Code:
```
/telegram:access pair <code>
```
```
/telegram:access policy allowlist
```

**Do not skip the allowlist.** Until you set it, the access policy is wider than you want for something that can read and write your notes.

**Verify:** message the bot "what files are in my vault root?" and get a real answer.

## Discord

**1. Create the bot.** [Developer Portal](https://discord.com/developers/applications) → New Application → Bot → Reset Token, copy it.

**2. Enable Message Content Intent** under Privileged Gateway Intents. Without it the bot receives empty messages and the failure looks like the bot ignoring you.

**3. Invite it.** OAuth2 → URL Generator → scope `bot`, permissions: View Channels, Send Messages, Send Messages in Threads, Read Message History, Attach Files, Add Reactions.

**4. Install, configure, restart, pair** — same shape as Telegram:
```
/plugin install discord@claude-plugins-official
```
```
/discord:configure <token>
```
```bash
claude --channels plugin:discord@claude-plugins-official
```
DM the bot, then `/discord:access pair <code>` and `/discord:access policy allowlist`.

## iMessage

macOS only. No bot, no token.

**1. Grant Full Disk Access.** The plugin reads `~/Library/Messages/chat.db`, which macOS protects. The first read triggers a prompt naming whichever app launched Bun — your terminal. If you miss it: System Settings → Privacy & Security → Full Disk Access, add your terminal. **Without this the server exits immediately with `authorization denied`.**

**2. Install and restart.**
```
/plugin install imessage@claude-plugins-official
```
```bash
claude --channels plugin:imessage@claude-plugins-official
```

**3. Text yourself.** Messaging your own Apple ID bypasses access control with no pairing. The first reply triggers a macOS Automation prompt — click OK.

To let someone else through: `/imessage:access allow +15551234567`.

---

## How many conversations at once

**One running session per channel.** Messages arrive in the session that is already open; there is no session-per-thread.

To hold genuinely separate contexts — a work thread and a health thread, each remembering its own state — create a second bot and point it at its own state directory:

```bash
TELEGRAM_STATE_DIR=~/.claude/channels/telegram-work \
  claude --channels plugin:telegram@claude-plugins-official
```

Fine at two or three. If you want many parallel topics inside one chat, Channels is the wrong tool and a tmux-based bridge is the right one.

## Keeping it running

Events only arrive while the session is open, so an always-on setup means running Claude in a persistent terminal:

```bash
tmux new -s vault -c ~/your-vault
claude --channels plugin:telegram@claude-plugins-official
```

Detach with `Ctrl-b d`; reattach with `tmux attach -t vault`. It survives a closed terminal, **not** a reboot.

## Running one always-on — the part that bites

Everything below was found on a real always-on install. None of it is in the official docs.

### Disable the channel plugin at user scope, enable it only in the bot session

**A channel plugin enabled at user scope starts its server in every session you open** — including an ordinary `claude` in some unrelated folder. For Telegram that is actively destructive: the plugin SIGTERMs any previous poller on start, because Telegram permits exactly one `getUpdates` consumer per token. **A casual session in another directory silently steals the bot from your always-on one**, and nothing tells you.

Install the plugin, then disable it at user scope and enable it only where you want it:

```bash
claude plugin disable telegram@claude-plugins-official
```

```bash
claude --settings '{"enabledPlugins":{"telegram@claude-plugins-official":true}}'        --channels plugin:telegram@claude-plugins-official
```

Verified: `--channels` alone does **not** load a user-disabled plugin — no server spawns. With `--settings` it does. Ordinary sessions then never start it.

### A failed channel server is cached and never retried

If a channel server fails to start — port already bound, token missing — the failure is recorded in `~/.claude/mcp-needs-auth-cache.json` and **every later session skips starting it entirely**, with no new log and no attempt. It looks like the plugin is broken.

```bash
mv ~/.claude/mcp-needs-auth-cache.json ~/.claude/mcp-needs-auth-cache.json.bak
```

This is also why "give each bot its own state directory so other sessions fail fast" is the wrong fix: those deliberate failures poison the cache and then block the session you actually wanted.

### Slash commands do not reach Claude Code

The plugin intercepts its own `/start`, `/help` and `/status`; **everything else is forwarded as ordinary chat text.** `/clear`, `/compact` and the rest never execute — and the model may cheerfully *say* it cleared the session. If you need a fresh session from your phone, restart the process, do not trust a slash command.

Skills still work when asked for in plain words.

### Tell the agent to use the `reply` tool

The model sometimes answers into the terminal instead of calling the channel's `reply` tool, and the answer never reaches your phone. Put the rule in the vault's `CLAUDE.md` explicitly: **every answer to a channel message goes through `reply`, with the inbound message's chat id.** That fixed it; without it the behaviour was intermittent.

### Question menus hang the session with nothing on your phone

*Found and verified with the official Telegram plugin. Discord and iMessage use the same channel mechanism but were not tested. Tmux bridges such as ccbot already carry the question into the chat and do not need this.*

When the model asks a multiple-choice follow-up (the `AskUserQuestion` tool) or enters plan mode, the menu renders **only in the terminal**. The channel does not forward it, the chat shows nothing, and the session waits indefinitely. On the install this was found on, one question sat unanswered for 75 minutes until someone reached the terminal, and `--dangerously-skip-permissions` did not prevent it. Permission relay is documented for tool-use approvals such as `Bash`, `Write` and `Edit`, not for these menus. Claude Code's docs say `-p` mode disables them; an interactive always-on session has to do it explicitly ([anthropics/claude-code#70294](https://github.com/anthropics/claude-code/issues/70294)).

Take the tools away from the always-on session, keeping whatever permission choice you made below:

```bash
claude --settings '{"enabledPlugins":{"telegram@claude-plugins-official":true}}' \
  --channels plugin:telegram@claude-plugins-official \
  --disallowedTools AskUserQuestion EnterPlanMode ExitPlanMode
```

Keep `--disallowedTools` last: it takes a list, so an option placed after its tool names is read as another tool name.

Verified on Claude Code 2.1.274: with the flag, the three tools are absent from the session's tool list; without it, all three are present. **Do not combine this with a session that starts in plan mode** (`defaultMode: "plan"`): with `ExitPlanMode` removed it can never leave.

Then tell the model how to ask instead, next to the `reply` rule in the vault's `CLAUDE.md`: **when you need a choice or clarification, send the question as an ordinary message with the `reply` tool (numbered options are fine), then stop and wait for the next message.** This gives the model somewhere to put the question once the menu tool is gone.

**If you wrap `claude` in a restart loop, restarting `claude` does not pick up an edited command.** Bash has already read the loop, so it keeps starting the old command line. Stop the loop itself (end its tmux session, or Ctrl-C it in its pane) and start the script again. Confirm with `ps -eo args | grep -- '--disallowedTools'`, which shows the running command line on both macOS and Linux.

## Permissions — there is a middle option

Three choices, not two.

1. **Permission prompts on, no relay.** The session **stalls** waiting for an answer you cannot give from your phone.
2. **Permission relay** *(Telegram plugin 0.0.7 and later)*. The prompt is forwarded to your allowlisted chat with Allow / Deny buttons. **This is the right default for most people** — unattended use works, and you still approve anything consequential.
3. **`--dangerously-skip-permissions`.** Nothing asks. An inbound message drives an agent with unsupervised access to your filesystem. Defensible on your own machine for your own vault; it should be a decision you make deliberately, not a flag copied from a setup guide.

Check your plugin version before assuming option 1 is your lot — relay landed quietly.

**Anyone who can message through the channel can approve tool use in your session.** Allowlist only yourself unless you mean otherwise.

This is also where the guard earns its place: with prompts off or relayed, the `PreToolUse` hook is the only thing still saying no without asking.

## When it does not work

| Symptom | Cause |
|---|---|
| Bot never replies | The session is not running with `--channels`. The bot can only reply while the channel is active |
| Messages arrive, replies stop coming | Usually Claude auth expiry, not the channel. Run `claude auth status` first |
| Bot receives empty messages (Discord) | Message Content Intent not enabled |
| `authorization denied` (iMessage) | Full Disk Access not granted to the terminal |
| Channel silently does not register | Plugin not on the approved allowlist, or your org has channels disabled |
| Bot stops responding after you opened Claude elsewhere | Another session stole the poller — see the user-scope section above |
| Plugin shows `failed` forever, no new logs | Cached failure in `mcp-needs-auth-cache.json` |
| Answers appear in the terminal, not your phone | Model skipped the `reply` tool |
| Bot goes silent mid-task and never answers | Often a question or plan menu waiting in the terminal, which is not forwarded; see the question-menu section above |
| `/clear` seems to do nothing | Slash commands are not forwarded |

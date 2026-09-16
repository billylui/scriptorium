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

## Permissions, honestly

If Claude hits a permission prompt while you are away, the session **pauses until you answer**. Channels that support permission relay can forward the prompt to your chat.

The alternative is `--dangerously-skip-permissions`, which makes unattended use work and means **an inbound message drives an agent with unsupervised access to your filesystem**. On your own machine, for your own vault, that is defensible. It should be a decision you make deliberately, not a flag you copy from a setup guide.

This is also where the guard earns its place: with permission prompts off, the `PreToolUse` hook is the only thing still saying no.

## When it does not work

| Symptom | Cause |
|---|---|
| Bot never replies | The session is not running with `--channels`. The bot can only reply while the channel is active |
| Messages arrive, replies stop coming | Usually Claude auth expiry, not the channel. Run `claude auth status` first |
| Bot receives empty messages (Discord) | Message Content Intent not enabled |
| `authorization denied` (iMessage) | Full Disk Access not granted to the terminal |
| Channel silently does not register | Plugin not on the approved allowlist, or your org has channels disabled |

**Anyone who can message through the channel can approve tool use in your session** if permission relay is on. Allowlist only yourself unless you mean otherwise.

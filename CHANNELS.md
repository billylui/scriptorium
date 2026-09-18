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

Keep `--disallowedTools` last: it takes a list, so an option placed after its tool names is read as another tool name. The sections below add more tools to it.

Verified on Claude Code 2.1.274: with the flag, the three tools are absent from the session's tool list; without it, all three are present. **Do not combine this with a session that starts in plan mode** (`defaultMode: "plan"`): with `ExitPlanMode` removed it can never leave.

Then tell the model how to ask instead, next to the `reply` rule in the vault's `CLAUDE.md`: **when you need a choice or clarification, send the question as an ordinary message with the `reply` tool (numbered options are fine), then stop and wait for the next message.** This gives the model somewhere to put the question once the menu tool is gone.

**If you wrap `claude` in a restart loop, restarting `claude` does not pick up an edited command.** Bash has already read the loop, so it keeps starting the old command line. Stop the loop itself (end its tmux session, or Ctrl-C it in its pane) and start the script again. Confirm with `ps -eo args | grep -- '--disallowedTools'`, which shows the running command line on both macOS and Linux. To avoid this next time, have the loop call its own script for each start (`"$0" run`, with the `claude` command in a `run` branch), so every restart reads the file afresh.

### The chat goes quiet while it works

*Found with the official Telegram plugin 0.0.7. A tmux bridge such as ccbot streams the whole session and does not have this problem.*

The plugin sends Telegram's "typing…" indicator once, when a message arrives, and Telegram clears it after about five seconds. After that the chat shows nothing until the model sends something, so a task that takes three minutes looks exactly like a session that has died. Three layers, cheapest first. None of them costs accuracy.

**1. Acknowledge on receipt.** The plugin can react to each message the moment it receives it:

```
/telegram:access set ackReaction 👀
```

The plugin re-reads its access file on every message, so this applies without a restart. If you edit `access.json` by hand instead, write it atomically: a file the plugin cannot parse is moved aside and replaced with defaults, which puts the bot back into pairing mode.

**2. Ask for progress messages.** The plugin has an `edit_message` tool for interim updates, but the model uses it only when told to, and a general "acknowledge long work first" line was not enough: on the install this was found on, the model made 47 tool calls before its first reply. Make the rule concrete, next to the `reply` rule in the vault's `CLAUDE.md`: **for anything bigger than a quick lookup, send a one-line `reply` saying what you are about to do before the first tool call, update that same message with `edit_message` at milestones, and send the final answer as a new `reply`, because edits do not notify the phone.**

**3. Keep "typing…" alive.** [`channels/telegram/vault-bot-typing`](channels/telegram/vault-bot-typing) is a hook on six events. A turn starting (`UserPromptSubmit`) or a tool call (`PreToolUse`) keeps a small detached loop running that renews the indicator every four seconds. Anything that means the bot is no longer working stops it: a `reply`, the end of the turn (`Stop`, or `StopFailure` when an API error such as a usage limit ended it), a `Notification` (a permission prompt, or waiting idle for you), or a new session (`SessionStart`). A `reply` may be an interim note rather than the answer; the next tool call starts the loop again. Renewing it only on tool calls is not enough: measured on real turns, the model spends long stretches thinking or writing between tools, and a per-tool-call renewal left "typing…" visible for only 12 to 75 percent of the turn. If nothing refreshes the loop for ten minutes it stops itself. The loop holds a lock for its whole life, which the system releases however it dies, so there is never more than one per bot and a crash leaves nothing stale. The hook always exits 0 at once and the loop runs detached, so it never slows or blocks a tool, and it costs no tokens because the model is not involved. It reads the token from the plugin's `.env` and sends to every chat in the allowlist, normally just you; it uses macOS `plutil` to read the allowlist.

Register it on all six events in the bot session's `--settings`, **not** in the vault's `.claude/settings.json`, and restart the bot after changing the list: the events are read when the session starts, and a loop that never hears the end of a turn keeps typing until its ten-minute limit. There it would run in every session opened in the vault, and your phone would show the bot typing while you work at your desk:

```bash
claude --settings '{"enabledPlugins":{"telegram@claude-plugins-official":true},"hooks":{"UserPromptSubmit":[{"hooks":[{"type":"command","command":"$HOME/.local/bin/vault-bot-typing"}]}],"PreToolUse":[{"hooks":[{"type":"command","command":"$HOME/.local/bin/vault-bot-typing"}]}],"Stop":[{"hooks":[{"type":"command","command":"$HOME/.local/bin/vault-bot-typing"}]}],"StopFailure":[{"hooks":[{"type":"command","command":"$HOME/.local/bin/vault-bot-typing"}]}],"Notification":[{"hooks":[{"type":"command","command":"$HOME/.local/bin/vault-bot-typing"}]}],"SessionStart":[{"hooks":[{"type":"command","command":"$HOME/.local/bin/vault-bot-typing"}]}]}}' \
  --channels plugin:telegram@claude-plugins-official \
  --disallowedTools AskUserQuestion EnterPlanMode ExitPlanMode
```

### A slow reply is not always a slow model

A reply reported as taking fourteen minutes turned out to have taken three and a half. The messages had waited at Telegram for 11 to 35 minutes while the session sat idle and the machine was awake, then reached the plugin together in one batch. The window coincided with a network change on the machine's VPN. Nothing errored and nothing recovered on its own: the plugin's long poll had quietly stopped receiving.

**Tell delivery from thinking before tuning anything.** Each inbound `<channel>` tag carries a `ts` attribute, the time Telegram received the message. The plugin's MCP log records the moment it handed the message to the session, as a `notifications/claude/channel` line; on macOS the log is under `~/Library/Caches/claude-cli-nodejs/<project>/mcp-logs-plugin-telegram-telegram/`. A gap between the two is delivery; a gap after the log line is the model. Lowering the effort or switching to a smaller model does nothing for the first.

[`channels/telegram/vault-bot-watchdog`](channels/telegram/vault-bot-watchdog) restarts the bot when Telegram is holding messages the plugin has stopped fetching. Run it every minute with `VAULT_WATCHDOG_RESTART` set to the shell command that restarts your bot session. Under a restart loop, ending that one `claude` process is enough; match it by its own arguments, never a bare `pkill claude`, which would end your other sessions too. With a single bot, `pkill -TERM -f -- '--channels plugin:telegram'` does it. With several bots that pattern matches all of them, and one stalled bot would take the others down with it, so give each bot's command line something of its own to match, such as its own `--settings` file, and match that. launchd runs jobs with a minimal `PATH` that has no Homebrew, so give tools such as `tmux` by absolute path. The command should end the old session and return; leave starting the new one to your restart loop, because launchd may kill whatever a finished job left running. Set `TELEGRAM_STATE_DIR` in the job's environment if the bot does not use the default state directory, and run one job per bot. It asks Telegram's `getWebhookInfo` for `pending_update_count`. A healthy poller drains that within seconds, even while the model is busy with a long task, so updates still pending across two minutes of checks mean the poll has stalled. A failed check does not reset that count, but a longer silence between good checks does, so the machine waking from sleep with messages waiting is given the same two minutes to catch up. It then restarts the bot and waits ten minutes before it may restart again; the cooldown is saved before the restart runs, and a restart command that fails or runs past 60 seconds is logged as such. Messages still waiting at Telegram are kept and reach the new session, but the old session's chat context goes with it, as at any restart, along with any task it was in the middle of. If Telegram cannot be reached at all it does nothing, because a restart cannot fix the network and it cannot tell an outage from a stall. It logs only changes, not every check. `getWebhookInfo` does not compete with the plugin: Telegram allows one `getUpdates` consumer per token, and this is not one.

### Reminders set from chat are lost on every restart

Ask the bot to remind you of something and the model reaches for Claude Code's own scheduler, `CronCreate`. Its tool description says the jobs live only in the session: the `durable` flag "has no effect", recurring jobs expire after seven days, and jobs fire only while the session is idle. An always-on bot restarts — on a schedule, after a crash, whenever you ask for a fresh session — and every reminder it set is gone without a word.

[`channels/telegram/vault-remind`](channels/telegram/vault-remind) keeps reminders in a file and sends them straight to Telegram with the bot's own token. No Claude session is involved when they fire. Each reminder goes to one chat, through the bot that set it: the one given with `--chat`, a person or group on that bot's allowlist, or else the first person on it. On a bot only you use that default is you. On a bot shared by several people, have the model pass `--chat` with the `chat_id` of the message that asked, as in the rule below, or every reminder goes to the first person on the list. With two bots a reminder never goes out through the other one, whichever bot's environment the scheduled job runs with. An `--until` date that leaves nothing to send is refused.

```bash
vault-remind add --in 13h --text "Take your evening pill"
vault-remind add --at "2026-10-01 09:00" --text "Call the dentist"
vault-remind add --daily 08:00,20:00 --until 2026-10-31 --text "Stretch"
vault-remind list
vault-remind cancel <id>
```

Run `vault-remind send-due` every minute: a LaunchAgent with `StartInterval` 60 on macOS, or cron. A network error, a rate limit, or a token Telegram does not recognise leaves the reminder to be retried the next minute, so an outage or a mistyped token delays it rather than losing it; so does a missing token or allowlist on this machine, logged each minute until fixed. Any other refusal, such as a chat that has blocked the bot, is logged and the reminder dropped rather than retried forever. Only one `send-due` runs at a time, and each due reminder is claimed in the file before it is sent, so it goes out once: a file that cannot be written stops reminders instead of repeating them, a run killed mid-send can lose that one reminder but never repeats it, and a corrupt file stops them with an error naming it. The one duplicate left is a message Telegram accepted whose confirmation never arrived; that is retried, because a second copy is better than none. One job covers every bot, since each reminder records its own. One that goes out more than ten minutes late says when it was due, and a daily reminder that missed several days sends one catch-up, not a backlog. Times are the machine's local time, and `--in` counts real hours, so a clock change in between does not move it. It needs Python 3.9 and nothing outside the standard library. It still depends on the machine being on and online, so anything you cannot afford to miss belongs in your phone's own alarms too.

Then take the scheduler away from the bot, and tell it where reminders go:

- Add `CronCreate CronDelete CronList` to the bot's `--disallowedTools`.
- In the vault's `CLAUDE.md`: **reminders go through `vault-remind` with the Bash tool, never Claude's scheduler. Pass `--chat` with the `chat_id` from the message that asked. Write the text as the message to receive. When the timing is relative to something already done ("13 hours after the dose I took at 07:51"), count from that moment, not from when the message arrived. Reply with the exact time the command printed.**

Verified on the install this was found on: asked from Telegram for a reminder in two minutes, the model called `vault-remind add --in 2m`, replied with the time it printed, and the reminder arrived from the scheduled job.

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
| Chat shows nothing for minutes, then the answer | Only one "typing…" is sent per message; see the section on the chat going quiet |
| Answer arrives many minutes late, though the session was idle | Messages held at Telegram, not a slow model; see the section on slow replies |
| A reminder the bot confirmed never arrived | Set with Claude's session-only scheduler and lost at a restart; see the reminders section |
| `/clear` seems to do nothing | Slash commands are not forwarded |

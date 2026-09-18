# Channels: Telegram script follow-ups

**Status:** OPEN · **Opened:** 2026-09-18 · **Owner:** unassigned

The three optional scripts in `channels/telegram/` (`vault-bot-typing`, `vault-remind`, `vault-bot-watchdog`) and the `CHANNELS.md` sections that explain them. Three independent items; each can ship as its own PR.

## What already shipped (LIVE — do not redo)

- **PR #4 (version 0.6.0).** The three scripts plus the `CHANNELS.md` sections on the chat going quiet, slow replies that are delivery stalls, and reminders lost at restart. Two review rounds found defects, none critical, all fixed on the PR branch before merge: reminders claimed in the file before sending, one chat per reminder through the bot that set it, no retry on permanent refusals, watchdog cooldown saved before restarting with a timeout and exit-status check, token kept out of `ps`, stamp validated as digits, only one `send-due` at a time so a reminder is never sent twice by overlapping runs.
- Verified on a real always-on install: a reminder requested from Telegram was set with `vault-remind add --in 2m` and sent by the scheduled job at that minute; the typing hook's stamp was written during the turn; the watchdog runs every minute and reads `pending_update_count` from the live bot.

## 1. The scripts' tests are not in the repository

**Problem:** each script was written test-first, with a fake Telegram server (26 tests for `vault-remind`, 16 for `vault-bot-watchdog`, 10 for `vault-bot-typing`), but the repo keeps no test suite, so the tests were not committed. The next change to any of these scripts has no regression net.

**Why it matters:** the review found its defects exactly where the tests were thin (one chat, one bot, unbroken checks). Without the suites, those cases regress silently.

**Fix:** decide whether `channels/telegram/tests/` belongs in the repo. If yes, commit the three suites (standard library only, Python 3.9, no network) and say how to run them in `CONTRIBUTING.md`. If no, record why here and close the item.

**Files:** `channels/telegram/`, `CONTRIBUTING.md`.

## 2. A watchdog restart loses the conversation

**Problem:** the watchdog restarts the bot by ending its `claude` process; the restart loop starts a fresh session. Messages still waiting at Telegram arrive, but the chat context and any task in progress are gone, so a follow-up such as "yes, do the second one" arrives with no referent.

**Why it matters:** a watchdog restart happens exactly when the person has been waiting on the bot, which is when losing the thread is most noticeable.

**Fix:** for watchdog restarts only, resume the bot's last session: the restart command leaves a marker, and the loop starts `claude --resume <id>` with the id of the bot's newest transcript (not `--continue`, which picks the newest session in the directory and may be one the person opened themselves). Scheduled daily restarts should stay fresh. **Unverified:** that `--resume` works together with `--channels`; test that first, on a bot whose owner can be interrupted.

**Files:** `channels/telegram/vault-bot-watchdog`, the restart-loop example in `CHANNELS.md`.

## 3. The watchdog has not yet been seen to fire on a real stall

**Problem:** its stall detection rests on Telegram's `getWebhookInfo` reporting `pending_update_count` for a bot that long-polls (the field is present and 0 on a healthy polling bot). It has been tested against a fake server only.

**Fix:** the next time a stall happens on a watched install, confirm from `vault-bot.log` that the watchdog logged `update(s) undelivered … restarting the bot` and that the held messages arrived after the restart. Record the result here, then close the item.

## Re-verify ground truth before acting

```bash
git log --oneline -5 -- channels/telegram CHANNELS.md
ls channels/telegram
grep -n "restarts the bot when Telegram is holding" CHANNELS.md
```

# Authorship and trust

Three laws that only exist once an agent writes most of your knowledge base. They are separated from `LAWS.md` because they govern *reading* rather than writing: the other laws stop a vault from being corrupted, these stop it from being **misread**.

They share one insight. A file-based vault gives no visual signal of who wrote what. Human sentences and agent sentences sit in the same folders, in the same format, in the same voice — and after a few months you cannot tell them apart by looking. Everything below follows from that.

## Law 1 — Protected surfaces

**Some surfaces are human-authored. The agent appends to them and never edits them in place.**

List them in `protected_surfaces` in `.scriptorium.json`. Typical members are a daily note's reflection section, any journal kept in the person's own words, first-person observations about other people, and answers to questions the person worked through themselves.

Everything else is default-allowed: activity logs, indexes, synthesis, working files, frontmatter, backlinks.

**Why it is a hard rule rather than a preference.** An agent improving prose is doing its job. Applied to a sentence someone wrote about their own life, "improving" it destroys the only copy of how they actually put it — and because the vault shows no authorship, nobody notices the substitution later. The loss is silent and permanent.

When unsure, append a clearly marked block with a date rather than editing the existing text. An appended block is reversible; a rewritten paragraph is not.

## Law 2 — Provenance

**Never cite agent-written prose as evidence of how the human thinks.**

In a mature agent-written vault, the overwhelming majority of the words are the agent's: synthesis notes, landing pages, activity logs, research briefs, decision write-ups. Reading that corpus back to learn about its owner measures the agent and reports it as the person.

This is easy to do by accident and hard to notice, because the conclusion looks well-evidenced. It cites real notes. The notes are in the person's vault, in folders they organised, about topics they chose. Every part of the chain looks sound except the part that matters: **they did not write the sentences.**

**The admissible basis for any claim about how someone thinks is exactly the `protected_surfaces` list from Law 1, plus their own messages, plus their actions.** Those two lists being identical is not a coincidence. The surfaces worth protecting from the agent's pen are the same surfaces that are admissible as evidence about the person — a file is either their voice or it is not, and that single fact decides both questions.

**Actions count as first-party even when the narration is the agent's.** A decision taken, a project abandoned, a window left to close. Separate the deed from the prose about the deed; the deed is theirs.

### The corrective-apparatus trap

**The sharpest version of this error involves the agent's own memory files, and it inverts the person completely.**

Any long-running agent setup accumulates corrections — notes recording where the agent went wrong and what to do instead. They read like a description of the person's preferences. They are not. They are **brakes fitted to a specific vehicle**, and every one of them exists because the agent did something the person had to stop.

Reading the brakes and inferring a slow driver is the canonical failure. A file saying "stop over-asserting" describes an agent that over-asserts. A file saying "verify before concluding" describes an agent that concluded too early. Read as a portrait of the human, this corrective apparatus produces a confident, detailed, and precisely inverted picture — cautious where they are decisive, hesitant where they are fast.

### The condition — and it matters as much as the law

**This law restricts exactly one kind of inference: claims about someone's psychology, reasoning style, character, or patterns of mind. It restricts nothing else, and must never be stretched.**

The vault remains ground truth for facts, decisions, records, history and state, and must still be read before answering. This is not a licence to hedge a factual answer, to skip research, or to refuse to summarise what the notes say. A law that starts as "be careful about inferring personality" and drifts into "be uncertain about everything" has failed in the opposite direction, and that drift is the most likely way this rule goes wrong.

**The test:** if a sentence about the person would need an agent-written note as its footnote, it is not supported. If it would need a *fact* from an agent-written note, it is fine.

**When the first-party record is too thin to answer, say so and switch to asking.** Capture what they actually say, verbatim. Do not synthesise another reading from the same unsuitable material — a wrong conclusion here propagates into landing notes and summaries and is then cited as settled.

### Measure it, do not assume it

Run `scripts/first-party-inventory.sh` to count how much of your vault is actually first-party. The number is usually far smaller than it feels, and it moves as the vault grows.

**Do not read the vault's staleness as the corpus's staleness.** Durable first-party surfaces are often old while the largest first-party corpus — the person's own messages in session — is current and renews daily. Those are different things, and in most setups the message corpus lives outside the vault, is never persisted in full, and expires on a rolling window instead of accumulating. If a question needs their actual voice, read it directly rather than assuming the vault preserved it.

## Law 3 — Truth hierarchy

When sources conflict, resolve in this order:

1. **Vault files** — ground truth for facts, decisions, records and state. Read before answering. Subject to Law 2: ground truth about *the world*, not about *the person's mind*.
2. **What the person says now** — may update or override the vault. The vault is a record, not an authority over its owner.
3. **Agent memory** — useful, may be stale, and subject to the corrective-apparatus trap above. Verify against the vault before relying on it.
4. **General knowledge** — only when the vault has nothing, and say so plainly: *"I don't see prior thinking on this here."*

**Memory ranks below the vault deliberately.** It is written from a single session's vantage point, it is rarely revisited, and it goes stale without any signal that it has. If a memory names a file, a function, or a setting, confirm that it still exists before acting on it.

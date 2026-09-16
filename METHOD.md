# The method

The laws say how a note must be *shaped*. This says how the vault is *run* — what the folders are, where a new note goes, and what you do daily, weekly and monthly. It is one opinionated system that has been run continuously against a real vault; the laws exist because this is the system that produced them.

You can ignore all of it and use the guard with your own structure. If you want the whole thing, start here.

## The structure

```
your-vault/
├── index.md          global table of contents
├── 00-Inbox/         the ONLY entry point — everything lands here first
├── 01-Daily/         one note per day, YYYY-MM-DD.md
├── 02-People/        one dossier per person, Firstname-Lastname.md
├── 03-Projects/      time-bound initiatives — things that can finish
├── 04-Areas/         ongoing life domains — things that never finish
├── 05-Knowledge/     synthesised understanding: patterns, frameworks, conclusions
├── 06-Resources/     external material — clips, articles, PDFs you did not write
├── 07-Archive/       finished projects and dead threads
├── 08-Templates/     note templates
└── 09-Attachments/   images, PDFs, media
```

**The numeric prefixes are not decoration.** They force lexical sort to match the order you actually touch things — inbox first, archive last — so the sidebar stops being an alphabet and starts being a workflow.

**`00-Inbox/` being the only entry point is the load-bearing rule.** Anything captured anywhere else has to be found later by remembering where you put it, which is the failure this whole structure exists to prevent. Capture into the inbox, file from the inbox, and the question "where did I put that" never gets asked.

**`06-Resources/` is different from every other folder: it is untrusted data.** It holds material other people wrote, which can contain text aimed at your agent. Nothing in it is ever treated as an instruction. Configure it under `untrusted_folders` and see the trust-boundary law in [`LAWS.md`](LAWS.md).

## Projects and Areas — classify by completion criterion

This is the decision people get wrong most often, and the rule is not about subject matter.

**Ask: can this finish? Is there a state where it is done and you stop?**

- **Yes → Project.** "Ship the new pricing page." "Pass the exam in December." "Plan the October trip." It has a finish line, and when it crosses it, move it to `07-Archive/`.
- **No → Area.** "Health." "Finances." "Japanese." "My team." These have no done state. They have a *current state* that you maintain, and they are living documents you revise rather than complete.

**The trap is mis-shelving in both directions at once.** A subject that accumulates plans, ranked options and real decisions *feels* like a project — it has all the machinery of one. But if there is no state at which you stop, it is an Area with a `decisions/` folder, not a Project that never ends. A Project that never ends is a Project you will feel permanently behind on, and that feeling is a filing error rather than a personal failing.

The same subject can hold both. "Japanese" is an Area; "Pass JLPT N4 in December" is a Project inside that life domain. The Area survives the Project.

## Every folder gets a landing note

A folder under `03-Projects/` or `04-Areas/` must contain a note named exactly after it: `Apollo/Apollo.md`, `Health/Health.md`.

This is not a style preference. A `[[Folder]]` link resolves only to `Folder.md` — never to `Folder/index.md`. Without the landing note, every reference to that subject is an unresolved link, and clicking one creates an empty file at your vault root. The landing note is what makes a subject linkable.

Create it in the same operation that creates the folder, from `templates/project-landing.md` or `templates/area-landing.md`. Turn on `folder_landing` in `.scriptorium.json` once your structure is settled and the guard will refuse writes into a folder that lacks one.

## The loop: capture → classify → file → link → log

This is the whole daily mechanic.

1. **Capture** into `00-Inbox/`. Unstructured, unsorted, no thinking required. A voice note, a paragraph, a link.
2. **Classify.** Which project, area, or person does this belong to? A dump covering three subjects splits into three notes.
3. **File** into the right folder, shaped per the conventions.
4. **Link.** Add `[[wikilinks]]` to related notes, and verify the targets exist. **Every person named gets a link to their dossier.**
5. **Log** a line in today's daily note.
6. **Remove** the item from the inbox. The inbox returning to zero is what makes it trustworthy.

Steps 2–6 are what the agent does for you. Your job is step 1.

## People

One file per person, `Firstname-Lastname.md`, in `02-People/`. Flat, no sub-folders.

**The rule that makes this work: every mention of a person, anywhere in the vault, links to their dossier.** Do that consistently and the backlinks pane on a person's file becomes a complete interaction history you never had to write — every meeting, decision and passing mention, in date order, assembled for free.

Skip the links and the dossier is just a contact card. The history exists only in the notes that recorded it, and you are back to remembering where you put things.

Dossiers hold objective facts and interaction logs. Your own first-person impressions of someone are yours — list them under `protected_surfaces` so the agent appends rather than rewrites. See [`AUTHORSHIP.md`](AUTHORSHIP.md).

## Daily notes

One per day, `YYYY-MM-DD.md`. Three jobs:

- **Activity log** — what happened, appended through the day. The agent writes most of this.
- **Reflections** — your own words. This is a protected surface; the agent formats and appends what you give it and never invents it.
- **Daily summary** — written at the end, synthesising the log.

Daily notes are the raw material for weekly review. They are deliberately low-effort: a log nobody dreads writing is a log that gets written.

**The day boundary is configurable** (`day_boundary_hour`, default 05:00). Work done at 01:00 belongs to the day it started, not the calendar date — otherwise late sessions scatter across two files.

## Review cadence

**Weekly.** Read the week's daily notes. Look for what repeated, what stalled, and what you keep circling. Write conclusions into `05-Knowledge/` as synthesis notes. Daily notes record what happened; nothing records what *kept* happening, because the pattern only exists across files.

**Monthly.** Consolidate knowledge notes, update Area landing notes to current state, and check every Project's `status:`. A project left `active` after it ended shows up in every enumeration and every "what is open" answer forever — one stale word taxes every future review.

## Your first month

**Day one.** Create the folders. Copy the templates. Create today's daily note. Create *one* Area for something genuinely ongoing in your life, with its landing note. Do not build a taxonomy for a vault you do not have yet — the structure is a place to put things, not a thing to design.

**Week one.** Capture into `00-Inbox/` without filing. Let it accumulate, then process it with the agent and watch where things land. You are learning your own categories, and they are not the ones you would have guessed.

**Month one.** You will have three to five Areas and a couple of Projects. Now turn on `folder_landing`, run your first weekly review, and add the people you actually write about. The structure earns its keep at roughly a hundred notes, not at ten.

**What not to do:** do not port an existing note collection in on day one. Start with today, let the vault fill forward, and pull old notes in only when you reach for one. Most of them you never reach for.

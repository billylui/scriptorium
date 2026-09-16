---
type: decision
status: proposed
date: {{date}}
project: "[[{{topic_node}}]]"
supersedes: ~
superseded-by: ~
review-date: ~
tags:
  - decision
---

# {{NNNN}} — {{imperative-title}}

<NNNN is the sequential number (0001, 0002, ...). Never reuse a number even after a decision is rejected or superseded. Title is imperative-mood ("use-postgres", "adopt-X", "reject-Y").>

## Context

<The situation that called for a decision. What constraints? What forced the choice now?>

## Options considered

### Option A — <name>
<Description in 2-4 sentences.>

**Why-not:** <Reason rejected, or "accepted" if this is the chosen option.>

### Option B — <name>
<Description.>

**Why-not:** <Reason rejected.>

### Option C — <name> (optional)
<Description.>

**Why-not:** <Reason rejected.>

## Decision

<Which option, and the load-bearing reasons. Include any conditions or scope limits ("this applies for v1 only").>

## Expected outcome

<What we expect to be true in 30 / 90 / 180 days if this decision holds. This is the prediction future-self compares against.>

- **30 days:** <what should be observable>
- **90 days:** <what should be observable>
- **180 days:** <what should be observable>

## Review date

<When to revisit. Could be a date, an event ("after the next quarterly review"), or a metric trigger ("if MRR < X").>

## Related

- **Supersedes:** <if this decision replaces an earlier one, link it here AND update `superseded-by:` on the old decision's frontmatter>
- **Linked notes:** [[<note>]], [[<note>]]

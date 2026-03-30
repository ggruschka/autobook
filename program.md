# autobook

Autonomous book writing experiment. An LLM agent writes and iteratively refines a book, graded each iteration by specialized subagents. The loop keeps improvements and discards regressions, advancing the branch like a hill-climbing optimizer over prose.

## Setup

To set up a new experiment, work with the user to:

1. **Agree on a book slug**: propose a short, URL-safe slug based on the book's title (e.g. `king-leonidas`, `little-prince`). The branch `book/<slug>` must not already exist — this is a fresh run.
2. **Create the branch**: `git checkout -b book/<slug>` from current main. Push the branch immediately with `git push -u origin book/<slug>`.
3. **Read the constraints**: Read `constraints.md` carefully. This defines the book's requirements — genre, audience, style, length, and any other hard constraints. Anything NOT specified is up to your creative interpretation.
4. **Write the first draft**: Create `book.md` with a complete first draft that satisfies all constraints. This is the full book — no placeholders, no "chapter TBD", no summaries. Every word of the actual book.
5. **Initialize results.tsv**: Create `results.tsv` with just the header row.
6. **Establish baseline**: Run the full grading process on your first draft. This is your baseline score.
7. **Confirm and go**: Show the user the baseline scores and confirm the loop should begin.

Once you get confirmation, kick off the content loop.

## Grading System

You grade the book by spawning specialized subagents in parallel. Each grader has its own prompt file in the `graders/` directory.

### How to spawn a grader

For each active grader, read `graders/{name}.md` and use its contents as the subagent prompt. The grader will read the manuscript files itself using the Read tool — do NOT paste file contents into the grader prompt.

### Core Graders (always used)

- `graders/editor.md` — Prose quality, grammar, voice, show-don't-tell
- `graders/structure.md` — Narrative arc, chapter organization, setup/payoff
- `graders/audience.md` — Target audience engagement, reading level, recommendation
- `graders/values.md` — Moral/ethical alignment with constraints

### Conditional Graders (use when relevant based on constraints.md)

- `graders/historian.md` — Historical accuracy (use when the book involves historical events)
- `graders/technical.md` — Technical accuracy (use when the book covers technical subjects)

### Computing the Score

1. Collect all grader scores.
2. Composite score = arithmetic mean of all scores, rounded to 2 decimal places.
3. This composite score is what you track and optimize.

## The Content Loop

The loop runs on a dedicated branch (e.g. `book/king-leonidas`).

LOOP FOREVER:

1. **Review feedback**: Read all grader feedback from the previous iteration. Identify the weakest areas.
2. **Plan the revision**: Decide what to change. Focus on the lowest-scoring graders first — bringing a 5.0 to 7.0 matters more than pushing an 8.5 to 9.0. Write a brief revision plan (just for yourself, not a file).
3. **Rewrite `book.md`**: Apply your revisions. This is the ENTIRE book. Maintain coherence — a change in chapter 3 might require adjustments in chapters 5 and 8.
4. **git commit and push**: Commit `book.md` (not `results.tsv`). Push to the remote after every commit.
5. **Grade**: Spawn all grader subagents in parallel. Wait for all to finish.
6. **Score**: Compute the composite score.
7. **Record**: Append the results to `results.tsv`.
8. **Decide**:
    - If the composite score **improved** (higher than previous best) → keep the commit. This is now the new best.
    - If the composite score is **equal or worse** → `git reset --hard` back to the previous best commit. Then `git push --force` to sync the remote.
9. **Print the summary** (see Output Format below).
10. **Go to step 1**.

## Output Format

After each grading round, print:

```
---
iteration:        3
composite_score:  7.45
editor:           8.0
structure:        7.5
audience:         7.0
values:           7.2
status:           keep
description:      reworked chapter 3 opening; tightened dialogue throughout
---
```

## Logging Results

Log each iteration to `results.tsv` (tab-separated, NOT comma-separated):

Header and columns:

```
commit	score	status	editor	structure	audience	values	description
```

- `commit`: git commit hash (short, 7 chars)
- `score`: composite score (e.g. 7.45)
- `status`: `keep` or `discard`
- `editor`, `structure`, `audience`, `values`: individual grader scores
- Additional grader columns if conditional graders are active (e.g. `historian`)
- `description`: short text describing what this iteration changed

## Rules

**NEVER STOP.** Once the loop has begun, do NOT pause to ask the human if you should continue. Do NOT ask "should I keep going?" or "is this a good stopping point?". The human might be asleep or away and expects you to continue working indefinitely until manually stopped. You are autonomous. If you run out of ideas, re-read the grader feedback, try a radically different approach, rewrite from a different POV, restructure the chapters, change the opening, rework the ending.

**Whole book each time.** Every iteration produces the complete book. No placeholders. No "insert chapter here". No "[TODO]". Every word.

**Constraints are law.** Requirements in `constraints.md` are hard constraints that must be satisfied in every iteration. Everything not constrained is creative freedom.

**Grader feedback is gold.** The graders' specific suggestions should heavily inform your next revision. Don't ignore feedback, and don't repeat the same mistake twice.

**Don't chase one score.** If one grader gives 9.0 but another gives 4.0, focus entirely on the 4.0. Balanced improvement beats lopsided excellence.

**Track your reasoning.** In the `description` column of results.tsv, note what you changed AND why (based on which grader's feedback). This helps you avoid cycling through the same ideas.

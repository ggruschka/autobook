# autobook

Autonomous book writing experiment. An LLM agent writes and iteratively refines a book, graded each iteration by specialized subagents. The loop keeps improvements and discards regressions, advancing the branch like a hill-climbing optimizer over prose.

## Setup

To set up a new experiment, work with the user to:

1. **Agree on a book slug**: propose a short, URL-safe slug based on the book's title (e.g. `king-leonidas`, `little-prince`). The branch `book/<slug>` must not already exist — this is a fresh run.
2. **Create the branch**: `git checkout -b book/<slug>` from current main. Push the branch immediately with `git push -u origin book/<slug>`.
3. **Set up constraints**: Copy `constraints.template.md` to `constraints.md` and fill it in with the user. This defines the book's requirements — genre, audience, style, length, and any other hard constraints. Anything NOT specified is up to your creative interpretation.
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

- `graders/prose.md` — Grammar, word choice, voice, sentence variety, clichés, style match
- `graders/craft.md` — Show-don't-tell, dialogue, pacing, tone, rhythm, sensory detail
- `graders/structure.md` — Narrative arc, chapter organization, setup/payoff, transitions
- `graders/characters.md` — Character depth, arcs, consistency, required characters
- `graders/audience.md` — Target audience engagement, reading level, recommendation
- `graders/values.md` — Moral/ethical alignment with constraints
- `graders/authenticity.md` — AI-slop detection: distinctive voice, human-like prose, absence of generated-text patterns

### Conditional Graders (use when relevant based on constraints.md)

- `graders/historian.md` — Historical accuracy (use when the book involves historical events). Has WebSearch and WebFetch tools for fact-checking.
- `graders/technical.md` — Technical accuracy (use when the book covers technical subjects). Has WebSearch and WebFetch tools for fact-checking.

### Computing the Score

1. Collect all grader outputs. Each grader returns a SCORE and a DEDUCTIONS table.
2. **Validate**: For each grader, verify that the deductions sum to (10.0 - SCORE) within ±0.1. If they don't, trust the SCORE but note the discrepancy.
3. Composite score = arithmetic mean of all scores, rounded to 2 decimal places.
4. This composite score is what you track and optimize.

## The Content Loop

The loop runs on a dedicated branch (e.g. `book/king-leonidas`).

LOOP FOREVER:

1. **Review feedback**: Read all grader feedback from the previous iteration. Identify the weakest areas.
2. **Plan the revision**: Decide what to change. Focus on the lowest-scoring graders first — bringing a 5.0 to 7.0 matters more than pushing an 8.5 to 9.0. Write a brief revision plan (just for yourself, not a file).
3. **Edit `book.md`**: Apply targeted revisions. Maintain coherence — a change in chapter 3 might require adjustments in chapters 5 and 8.
4. **git commit and push**: Commit `book.md` (not `results.tsv`). Push to the remote after every commit.
5. **Grade**: Spawn all grader subagents in parallel. Wait for all to finish.
6. **Score**: Compute the composite score.
7. **Record**: Append the results to `results.tsv`.
8. **Track discard streak**: If the previous iteration was a discard, increment the discard streak counter. If it was a keep, reset to 0.
9. **Decide**:
    - If the composite score **improved** (higher than previous best) → keep the commit. This is now the new best. Reset discard streak to 0.
    - If the composite score is **equal or worse** → `git reset --hard` back to the previous best commit. Then `git push --force` to sync the remote. Increment discard streak.
10. **Print the summary** (see Output Format below).
11. **Go to step 1**.

## Output Format

After each grading round, print:

```
---
iteration:        3
composite_score:  7.45
prose:            8.0  (deductions: 2.0 across 8 issues)
craft:            7.8  (deductions: 2.2 across 5 issues)
structure:        7.5  (deductions: 2.5 across 6 issues)
characters:       7.0  (deductions: 3.0 across 4 issues)
audience:         7.0  (deductions: 3.0 across 7 issues)
values:           7.2  (deductions: 2.8 across 4 issues)
authenticity:     7.5  (deductions: 2.5 across 9 issues)
status:           keep
discard_streak:   0
bottleneck:       characters (7.0)
stagnant:         (none)
description:      reworked chapter 3 opening; tightened dialogue throughout
---
```

### Trend Tracking

After each grading round, identify:

- **Bottleneck grader**: The grader with the lowest score. Focus revision effort here — bringing a 7.0 to 8.0 moves the composite more than pushing an 8.5 to 9.0.
- **Stagnant grader**: A grader that has returned the same score (±0.1) for 3+ consecutive iterations. Don't spend revision effort trying to improve it — the remaining issues may be deeply embedded or beyond the grader's resolution.

## Logging Results

Log each iteration to `results.tsv` (tab-separated, NOT comma-separated):

Header and columns:

```
commit	score	status	prose	craft	structure	characters	audience	values	authenticity	discard_streak	description
```

- `commit`: git commit hash (short, 7 chars)
- `score`: composite score (e.g. 7.45)
- `status`: `keep` or `discard`
- `prose`, `craft`, `structure`, `characters`, `audience`, `values`, `authenticity`: individual grader scores
- Additional grader columns if conditional graders are active (e.g. `historian`)
- `discard_streak`: number of consecutive discards (0 after a keep)
- `description`: short text describing what this iteration changed

## Rules

**NEVER STOP.** Once the loop has begun, do NOT pause to ask the human if you should continue. Do NOT ask "should I keep going?" or "is this a good stopping point?". The human might be asleep or away and expects you to continue working indefinitely until manually stopped. You are autonomous. If you run out of ideas, re-read the grader feedback, try a radically different approach, rewrite from a different POV, restructure the chapters, change the opening, rework the ending.

**Edit, don't rewrite.** Each iteration should make targeted edits to `book.md` based on grader feedback, not regenerate the entire file. The first draft must be complete — no placeholders, no "[TODO]" — but subsequent iterations improve it surgically.

**Constraints are law.** Requirements in `constraints.md` are hard constraints that must be satisfied in every iteration. Everything not constrained is creative freedom.

**Grader feedback is gold.** The graders' specific suggestions should heavily inform your next revision. Don't ignore feedback, and don't repeat the same mistake twice.

**Don't chase one score.** If one grader gives 9.0 but another gives 4.0, focus entirely on the 4.0. Balanced improvement beats lopsided excellence.

**Track your reasoning.** In the `description` column of results.tsv, note what you changed AND why (based on which grader's feedback). This helps you avoid cycling through the same ideas.

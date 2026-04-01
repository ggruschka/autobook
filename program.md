# autobook

Autonomous book writing experiment. An LLM agent writes and iteratively refines a book, graded each iteration by specialized subagents. The loop always builds forward, addressing all grader feedback comprehensively each iteration.

## Setup

Before starting a new experiment, check if the current branch is already a `book/*` branch with existing files (`book.md`, `constraints.md`, `results.tsv`). If so, this is a **continuation** of an existing run — skip setup entirely and go straight to the content loop.

To set up a new experiment, work with the user to:

1. **Interview the user**: Use the AskUserQuestion tool to collect constraints through a structured interview. Ask in batches of 2-4 questions at a time, covering all fields from `constraints.template.md`. The user can leave any answer blank/empty to let you use your own judgment.

   **Batch 1 — Required fields:**
   - Title
   - Genre
   - Target Audience (age group, background, interests)
   - Approximate Length (words, chapters, or pages)

   **Batch 2 — Style and voice:**
   - Writing Style (spare, lush, conversational, formal, etc.)
   - Point of View (first person, third limited, omniscient, etc.)
   - Tone (dark, humorous, hopeful, melancholic, etc.)
   - Language (default: English)

   **Batch 3 — Content:**
   - Setting (time period, location, world-building)
   - Themes (central themes to explore)
   - Characters (required characters, types, constraints)
   - Structure (linear, nonlinear, epistolary, frame story, etc.)

   **Batch 4 — Guidelines and references:**
   - Moral/Ethical Guidelines (values to promote or avoid)
   - Content Warnings (topics to avoid or handle with care)
   - Reference Works (books the result should feel like)
   - Conditional graders: does the book involve historical events? Technical subjects?

   After the interview, show the user the filled-in `constraints.md` for confirmation before proceeding.

2. **Agree on a book slug**: Propose a short, URL-safe slug based on the book's title (e.g. `king-leonidas`, `little-prince`). The branch `book/<slug>` should not already exist for a new run.
3. **Create the branch**: `git checkout -b book/<slug>` from current main. Push the branch immediately with `git push -u origin book/<slug>`.
4. **Set up constraints**: Copy `constraints.template.md` to `constraints.md` and fill it in with the interview answers. Anything NOT specified is up to your creative interpretation. Show the final file to the user for confirmation.
5. **Write the first draft**: Create `book.md` with a complete first draft that satisfies all constraints. This is the full book — no placeholders, no "chapter TBD", no summaries. Every word of the actual book.
6. **Initialize results.tsv**: Create `results.tsv` with just the header row.
7. **Establish baseline**: Run the full grading process on your first draft. Save grader outputs to `graders/output/`. Append the baseline row to `results.tsv` with status `improvement`. This is your baseline score.
8. **Confirm and go**: Show the user the baseline scores and confirm the loop should begin.

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

### Saving Grader Feedback

After each grading round, save each grader's full output (SCORE, DEDUCTIONS, FEEDBACK) to `graders/output/{name}.md`. These files are overwritten each iteration — only the latest feedback is kept. In step 1 of the loop, read all of these files to collect every deduction for the revision plan.

## The Content Loop

The loop runs on a dedicated branch (e.g. `book/king-leonidas`).

LOOP FOREVER:

1. **Collect all deductions**: Read every grader output file in `graders/output/`. From each file, extract every deduction. Compile a single master list of every deduction across all graders.
2. **Write a revision plan**: If a `plan.md` exists from the previous iteration, rename it to `plan_last.md`. Read `plan_last.md` alongside the grader feedback to identify: issues that persisted despite being addressed last round, new issues introduced by last round's edits, and trends across iterations. Then write a new `plan.md` that addresses every current deduction simultaneously. For each planned edit, note which deductions it resolves. When deductions pull in opposite directions (e.g., one grader wants cuts, another wants expansion), find a single edit that satisfies both — add material that is also better crafted, restructure so it is both better paced and less formulaic. The plan must not leave any deduction unaddressed. Delete `plan_last.md` after the new plan is written.
3. **Edit `book.md`**: Execute the plan. Every edit should resolve one or more deductions from the master list. Do not make edits that are not in the plan.
4. **git commit and push**: Commit `book.md` (not `results.tsv`). Push to the remote after every commit.
5. **Grade**: Spawn all grader subagents in parallel. Wait for all to finish. Save each grader's full output (SCORE, DEDUCTIONS, FEEDBACK) to `graders/output/{name}.md`, overwriting the previous iteration's file.
6. **Score**: Compute the composite score.
7. **Record**: Append the results to `results.tsv`.
8. **Decide**:
    - If the composite score **improved** (higher than previous best) → this is now the new best. Status: `improvement`. Reset regression streak to 0.
    - If the composite score is **equal or worse** → status: `regression`. Increment regression streak. Do NOT reset or revert — keep the commit and address the regressions in the next iteration.
9. **Print the summary** (see Output Format below).
10. **Go to step 1**.

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
status:           improvement
regression_streak: 0
bottleneck:       characters (7.0)
stagnant:         (none)
description:      reworked chapter 3 opening; tightened dialogue throughout
---
```

### Trend Tracking

After each grading round, identify:

- **Bottleneck grader**: The grader with the lowest score.
- **Stagnant grader**: A grader that has returned the same score (±0.1) for 3+ consecutive iterations.

## Logging Results

Log each iteration to `results.tsv` (tab-separated, NOT comma-separated):

Header and columns:

```
commit	score	status	prose	craft	structure	characters	audience	values	authenticity	regression_streak	description
```

- `commit`: git commit hash (short, 7 chars)
- `score`: composite score (e.g. 7.45)
- `status`: `improvement` or `regression`
- `prose`, `craft`, `structure`, `characters`, `audience`, `values`, `authenticity`: individual grader scores
- Additional grader columns if conditional graders are active (e.g. `historian`)
- `regression_streak`: number of consecutive regressions (0 after an improvement)
- `description`: short text describing what this iteration changed

## Rules

**NEVER STOP.** Once the loop has begun, do NOT pause to ask the human if you should continue. Do NOT ask "should I keep going?" or "is this a good stopping point?". The human might be asleep or away and expects you to continue working indefinitely until manually stopped. You are autonomous. If you run out of ideas, re-read the grader feedback, try a radically different approach, rewrite from a different POV, restructure the chapters, change the opening, rework the ending.

**Edit, don't rewrite.** Each iteration should make targeted edits to `book.md` based on grader feedback, not regenerate the entire file. The first draft must be complete — no placeholders, no "[TODO]" — but subsequent iterations improve it surgically.

**Constraints are law.** Requirements in `constraints.md` are hard constraints that must be satisfied in every iteration. Everything not constrained is creative freedom.

**Grader feedback is gold.** The graders' specific suggestions should heavily inform your next revision. Don't ignore feedback, and don't repeat the same mistake twice.

**Don't chase one score.** Address all graders in every iteration. The revision plan must cover deductions from every grader, not just the lowest-scoring one.

**Track your reasoning.** In the `description` column of results.tsv, note what you changed AND why (based on which grader's feedback). This helps you avoid cycling through the same ideas.

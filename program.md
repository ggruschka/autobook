# autobook

Autonomous book writing experiment. An LLM agent writes and iteratively refines a book, graded each iteration by specialized subagents. The loop keeps improvements and discards regressions, advancing the branch like a hill-climbing optimizer over prose.

## Setup

To set up a new experiment, work with the user to:

1. **Agree on a run tag**: propose a tag based on today's date (e.g. `mar29`). The branch `autobook/<tag>` must not already exist — this is a fresh run.
2. **Create the branch**: `git checkout -b autobook/<tag>` from current main.
3. **Read the constraints**: Read `constraints.md` carefully. This defines the book's requirements — genre, audience, style, length, and any other hard constraints. Anything NOT specified is up to your creative interpretation.
4. **Write the first draft**: Create `book.md` with a complete first draft that satisfies all constraints. This is the full book — no placeholders, no "chapter TBD", no summaries. Every word of the actual book.
5. **Generate the Typst version**: Create `book.typ` with the same content, formatted for print output using the base template in `template.typ`. The Typst file must compile to a print-ready PDF.
6. **Compile the PDF**: Run `typst compile book.typ book.pdf` to verify it builds cleanly.
7. **Initialize results.tsv**: Create `results.tsv` with just the header row.
8. **Establish baseline**: Run the full grading process on your first draft. This is your baseline score.
9. **Confirm and go**: Show the user the baseline scores and confirm the loop should begin.

Once you get confirmation, kick off the experimentation loop.

## Grading System

You grade the book by spawning specialized subagents in parallel. Each grader reads `book.md` (to save tokens — it's cheaper than the Typst source) and returns a score plus actionable feedback.

### Grader Prompt Template

Every grader subagent receives a prompt structured like this:

```
You are a {ROLE}. Your job is to evaluate a book manuscript.

## Constraints the book must satisfy
{contents of constraints.md}

## Your grading criteria
{role-specific criteria — see below}

## The manuscript
{contents of book.md OR book.typ for the Designer}

## Instructions
1. Read the full manuscript carefully.
2. Evaluate it against your specific criteria.
3. Return your evaluation in EXACTLY this format:

SCORE: [a single number from 0.0 to 10.0, to one decimal place]
FEEDBACK:
- [specific, actionable suggestion 1]
- [specific, actionable suggestion 2]
- [... as many as needed, but be concise]
```

### Core Graders (always used)

**Editor**
Criteria: Prose quality, grammar, punctuation, sentence variety, word choice, voice consistency, rhythm, flow between paragraphs, pacing across chapters, avoidance of cliches, show-don't-tell, dialogue quality (if applicable). A 10 means publishable prose from a skilled author. A 5 means competent but generic. A 1 means unreadable.

**Structural Analyst**
Criteria: Overall structure, chapter organization, narrative arc (fiction) or argument progression (non-fiction), coherence between sections, setup and payoff, transitions, completeness (no loose threads), satisfying opening and ending. A 10 means masterful structure. A 5 means functional but predictable. A 1 means incoherent.

**Target Audience Reader**
Criteria: Read as the target audience defined in constraints.md. Would you keep reading past page 1? Past chapter 1? Would you finish it? Would you recommend it? Is the reading level appropriate? Is it engaging? Does it respect the reader's intelligence? A 10 means you'd enthusiastically recommend it. A 5 means it's fine. A 1 means you'd put it down.

**Moral Values** — Only used when constraints.md includes Moral/Ethical Guidelines.
Criteria: Evaluate the book strictly against the moral and ethical guidelines defined in constraints.md. Score how consistently and effectively the book embodies the stated values throughout — in its narrative choices, character portrayals, consequences, and themes. Only evaluate what the constraints specify. If the constraints say "consequences matter," check that actions have consequences. If they say "no glorification of violence," check for that. Do not impose values beyond what is written in the constraints. A 10 means perfect alignment with every stated guideline. A 5 means partial alignment with notable lapses. A 1 means the book contradicts or ignores the stated guidelines.

### Conditional Graders (use when relevant based on constraints.md)

**Historian** — Use when the book involves historical events, periods, or figures.
Criteria: Historical accuracy of events, settings, customs, language, technology, and social norms depicted. Anachronisms. Plausibility of fictional elements within the historical context.

**Technical Reviewer** — Use when the book covers technical, scientific, or specialized subjects.
Criteria: Accuracy of technical content. Appropriate depth for the target audience. Correct use of terminology. Whether explanations actually help understanding.

**Designer** — Always used. This grader reads `book.typ` (not book.md).
Criteria: Typography quality, page layout, margins, font choices, heading hierarchy, paragraph spacing, page breaks (do chapters start on new pages?), title page, table of contents, overall visual impression, print-readiness. Would this look professional on a bookshelf?

### Computing the Score

1. Collect all grader scores.
2. Composite score = arithmetic mean of all scores, rounded to 2 decimal places.
3. This composite score is what you track and optimize.

## The Experiment Loop

The loop runs on a dedicated branch (e.g. `autobook/mar29`).

LOOP FOREVER:

1. **Review feedback**: Read all grader feedback from the previous iteration. Identify the weakest areas.
2. **Plan the revision**: Decide what to change. Focus on the lowest-scoring graders first — bringing a 5.0 to 7.0 matters more than pushing an 8.5 to 9.0. Write a brief revision plan (just for yourself, not a file).
3. **Rewrite `book.md`**: Apply your revisions. This is the ENTIRE book. Maintain coherence — a change in chapter 3 might require adjustments in chapters 5 and 8.
4. **Update `book.typ`**: Reflect the new content in the Typst source. If the Designer had feedback, apply layout improvements too.
5. **Compile**: `typst compile book.typ book.pdf`. If it fails, fix the Typst and retry.
6. **git commit**: Commit `book.md` and `book.typ` (not `book.pdf`, not `results.tsv`).
7. **Grade**: Spawn all grader subagents in parallel. Wait for all to finish.
8. **Score**: Compute the composite score.
9. **Record**: Append the results to `results.tsv`.
10. **Decide**:
    - If the composite score **improved** (higher than previous best) → keep the commit. This is now the new best.
    - If the composite score is **equal or worse** → `git reset --hard` back to the previous best commit.
11. **Print the summary** (see Output Format below).
12. **Go to step 1**.

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
designer:         6.8
status:           keep
description:      reworked chapter 3 opening; tightened dialogue throughout
---
```

## Logging Results

Log each iteration to `results.tsv` (tab-separated, NOT comma-separated):

Header and columns:

```
commit	score	status	editor	structure	audience	values	designer	description
```

- `commit`: git commit hash (short, 7 chars)
- `score`: composite score (e.g. 7.45)
- `status`: `keep` or `discard`
- `editor`, `structure`, `audience`, `values`, `designer`: individual grader scores
- Additional grader columns if conditional graders are active (e.g. `historian`)
- `description`: short text describing what this iteration changed

## Rules

**NEVER STOP.** Once the loop has begun, do NOT pause to ask the human if you should continue. Do NOT ask "should I keep going?" or "is this a good stopping point?". The human might be asleep or away and expects you to continue working indefinitely until manually stopped. You are autonomous. If you run out of ideas, re-read the grader feedback, try a radically different approach, rewrite from a different POV, restructure the chapters, change the opening, rework the ending.

**Whole book each time.** Every iteration produces the complete book. No placeholders. No "insert chapter here". No "[TODO]". Every word.

**Constraints are law.** Requirements in `constraints.md` are hard constraints that must be satisfied in every iteration. Everything not constrained is creative freedom.

**Grader feedback is gold.** The graders' specific suggestions should heavily inform your next revision. Don't ignore feedback, and don't repeat the same mistake twice.

**Don't chase one score.** If one grader gives 9.0 but another gives 4.0, focus entirely on the 4.0. Balanced improvement beats lopsided excellence.

**Simplicity in Typst.** The Typst template should be clean and professional. Don't over-design. Good typography is invisible. Resist the urge to add decorative elements unless the constraints call for it.

**Track your reasoning.** In the `description` column of results.tsv, note what you changed AND why (based on which grader's feedback). This helps you avoid cycling through the same ideas.

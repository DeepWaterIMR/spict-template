# AGENTS.md — contract for AI agents working in this repository

This file is the single source of truth for any LLM-based agent (Claude Code,
Cursor, Windsurf, ChatGPT, Copilot, custom agents) working on this repo,
alongside human collaborators. **Read this file before doing anything else.**

If a tool-specific file (`CLAUDE.md`, `.cursorrules`, etc.) contradicts this
file, fix the tool-specific file rather than ignoring `AGENTS.md`.

---

## 1. What this repo is

A SPiCT (Surplus Production model in Continuous Time) stock assessment project
for the Deep-water species and cartilaginous fish group at the Institute of
Marine Research (Havforskningsinstituttet, Norway), scaffolded from
`DeepWaterIMR/spict-template`.

If you are reading this in the template itself (path ends `…/spict-template`),
do not render the qmd documents — they contain `{{STOCK_NAME}}` and other
unfilled placeholders.

## 1a. New-stock onboarding (read this if scaffolding is incomplete)

**Before anything else**, check whether this is a freshly scaffolded repo by
running:

```bash
grep -r '{{[A-Z_]*}}' . --include='*.qmd' --include='*.R' --include='*.md' 2>/dev/null | head
```

If that returns any hits, the scaffolder has not been run yet and the repo is
not assessment-ready. **Drive the analyst through the onboarding interview in
`memory/template_scaffold_interview.md`** — ask them the questions listed
there (stock identity, catch data sources, survey index producer repo,
working-group conventions), fill `stock_config.yaml`, run
`source("scaffold.R"); scaffold("stock_config.yaml")`, then proceed to
`memory/template_open_items.md`. Record every non-trivial decision as a new
file in `memory/` and sign it (see § 2).

Do **not** try to render the qmd documents or "guess" plausible values for the
analyst — onboarding is interactive by design. If the analyst doesn't know a
value, write a memory file describing what's still open and ask them to
follow up.

## 2. Project memory: `memory/`

This folder is the **shared, committed, multi-agent project memory** for this
repo. Every collaborator and every agent reads and writes here.

### Read first

At the start of any non-trivial task, read `memory/MEMORY.md` (the index) and
load the entries relevant to your task. The index is short by design — scan it.

### Write when you learn something non-obvious

When you make a decision, calibrate a value, learn how a data source is
shaped, or discover a non-obvious constraint, save it as a new file in
`memory/`:

```markdown
---
name: <kebab-case-slug>
description: <one-line summary>
metadata:
  type: project | reference | feedback | decision
  author: <agent or person name>
  created: YYYY-MM-DD
---

<the fact, in markdown>

**Why**: <reasoning>
**How to apply**: <when this matters for future work>

Related: [[other-memory-slug]]
```

Then add a one-line pointer to `memory/MEMORY.md` (newest at the bottom).

### What belongs in project memory (commit it)

- Calibration decisions (priors chosen, breakpoints set, why)
- Data provenance (where each file came from, format quirks)
- Constraints discovered the hard way
- Cross-cutting style decisions specific to this stock
- Open items still needing work

### What does NOT belong in project memory

- Personal preferences (those go to your user-level memory: `~/.claude/projects/.../memory/` for Claude Code, equivalent for other tools)
- Code structure (already visible in the repo)
- Information already in git history
- Anything truly transient to a single session

### Multi-agent rules

- **Sign your work**: set `metadata.author` to a stable identifier (e.g.
  `claude-code-mikko`, `cursor-anna`, `human-mikko`). This is the audit
  trail; preserve it on edits.
- **Don't silently delete other agents' memories**: if a memory looks wrong,
  add a correction memory linking back to it (`Supersedes: [[old-slug]]`)
  rather than removing it. Wholesale deletion needs human sign-off in a PR.
- **Don't duplicate**: before writing a new memory, grep `memory/` for the
  topic — if a relevant file exists, update it instead.

## 3. Hard constraints

### 3.1 Byte-identical output on `2 advice sheet.qmd`

Once this repo is producing official-track advice, **`2 advice sheet.qmd` must
render byte-for-byte identical numeric output before and after any change**.
Only cosmetic or provably functionally-equivalent edits. Before editing, verify
the replacement evaluates to the same value for the current `assessment_year`
and `advice_year`.

This is inherited from `reg-spict`. See `memory/template_constraints.md`.

### 3.2 Exploratory-status callouts

Both production qmds carry a prominent callout stating they are exploratory
SPiCT supplements (where applicable to the working group's gadget-based
official assessment). Do not remove or soften these notices without explicit
human authorisation recorded in `memory/`.

## 4. Workflow conventions

- **Units**: catches in tonnes throughout.
- **Survey timing**: `year + 6/12` (June) for SPiCT.
- **Index scaling**: survey estimates divided by their mean.
- **`stdevfac` vectors** must average to 1.
- **`logn` fixed** (Schaefer): `phases$logn <- -1`, `ini$logn <- log(2)`.
- **`logalpha` / `logbeta` priors deactivated** (`c(0, 0, 0)`).
- Use the **tidyverse pipe** `|>`, not `%>%`, in new code.
- Format R code with `air` (config in `air.toml`).
- For inline list enumerations in qmd narrative text, use `list_values()` from
  `src/0_setup.R` (handles 1 / 2 / ≥3 element cases correctly).

## 5. Running things

```r
# Production: renders 1 → 2 and copies outputs to docs/assessment/<year>/
source("run_assessment.R")
run_assessment()                            # default years
run_assessment(assessment_year = 2027)      # next year's run

# Exploration: single-model diagnostic report
source("src/exploration/1 fit model.R")

# Exploration: interactive Shiny explorer
shiny::runApp("src/exploration/spict_explorer")
```

Outputs land in `docs/assessment/<assessment_year>/`. Saved model objects are
git-ignored under `data/model_output/saved_models/`.

## 6. When unsure

Ask a human in the PR/commit thread before:

- Removing or softening exploratory-status callouts
- Editing `2 advice sheet.qmd` once it's producing official-track output
- Deleting or overwriting another agent's memory file
- Adding new stock-level dependencies
- Changing the canonical year-parameter names (`assessment_year`,
  `advice_year`, `prev_advice_year`, etc.) — these are matched in
  `run_assessment.R`, the qmd YAML `params:` blocks, and the exploration scripts.

When in doubt, write a memory file describing the question and the chosen
path. Future agents (and your future self) will thank you.

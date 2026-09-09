# AGENTS.md — {{PROJECT_TITLE}}

You are helping with a **SPiCT stock assessment** of {{STOCK_NAME}} (*{{STOCK_LATIN}}*) in ICES
subareas {{ICES_AREAS}}, for the {{WORKING_GROUP_LONG}} ({{WORKING_GROUP}}). The documents are
Quarto, the analyses are R, the references are BibTeX. The humans in `config.yaml` are the
authors and are accountable for every word and every number; you are a supervised collaborator.

> This is the entry point for **Codex, Cursor, Gemini CLI, Mistral, local models, and other
> agents**. Claude Code reads [`CLAUDE.md`](CLAUDE.md).

This project was scaffolded from
[spict-template](https://github.com/DeepWaterIMR/spict-template), which sits on top of
[academic-writing](https://github.com/DeepWaterIMR/academic-writing). The rules live in their
skills; read them rather than guessing:

| Skill | Read it before |
|---|---|
| `academic-style` | Writing or editing any prose |
| `academic-conventions` | Any Quarto work |
| `academic-data-report` | Touching `docs/data-report/` |
| `academic-assessment-report` | Touching `docs/assessment-report/` |
| `academic-advice-sheet` | Touching `docs/advice-sheet/` |
| `spict-compile-data`, `spict-fit-model`, `spict-explore`, `spict-advice-sheet` | The corresponding workflow step |
| `scientific-quarto-review` | A long render, and any audit |

## ⛔ Non-negotiable

1. **The exploratory-status callouts stay.** The data report and the advice sheet each carry a
   callout saying this assessment supplements, and does not replace, the official
   {{WORKING_GROUP}} assessment. Removing or softening one needs explicit human authorisation
   recorded in `ai/memory/`. A tidying pass is exactly how one gets dropped.
2. **Once the advice sheet is on the official track, its numeric output must not change** under
   a cosmetic edit. Verify equivalence before editing; render and compare when unsure. The
   memory entry recording benchmark sign-off is what activates this rule.
3. **The advice-history table is extended, never fitted.** When the assessment year advances
   past the last recorded row, add that year's actual advice text. Never pad, recycle, or
   shorten the year range to make lengths match.
4. **The authors are accountable for everything, including what you wrote.** Never present your
   output as finished. Say what you changed and what still needs checking.
5. **Never list a language model as an author**, and disclose AI use in the methods, appending
   to any existing model list rather than replacing it.
6. **Never invent.** No fabricated numbers, citations, package behaviour, or SPiCT arguments.
   Flag `[VERIFY]` rather than guess.
7. **Never commit data or private paths.** `data/`, `logs/`, `figures/`, and `ai/review/` are
   git-ignored for a reason. Do not loosen `.gitignore` to make one file commit.

## SPiCT conventions

These are the project's conventions, not preferences. Departing from one is a decision to
record in `ai/memory/`.

- **Catches in tonnes throughout.**
- **Index timing is `INDEX_TIMING` from `config.yaml`**, a fraction of the year, matching when
  the survey runs.
- **The index is scaled by its own mean**; only its shape carries information.
- **`stdevfac` vectors must average to 1.** They multiply an estimated observation standard
  deviation, so a vector that does not average to 1 silently rescales it.
- **`logn` is fixed at the Schaefer value.** Freeing it is a benchmark decision.
- **`logalpha` and `logbeta` priors are deactivated.**
- **Priors carried over from another stock are placeholders, not defaults.**
- **Reference points from SPiCT are relative.** B~lim~ and MSY B~trigger~ are conventions from
  the advice framework, in `config.yaml`.

## How this project is laid out

| Path | Contents |
|---|---|
| `config.yaml` | Stock identity, years, priors, model settings. The single source of truth |
| `R/` | Pipeline scripts numbered by run order; helper libraries un-numbered |
| `docs/data-report/spict-assessment/` | The assessment. Fits the model, saves the summary |
| `docs/data-report/exploration/` | Candidate fits and comparisons |
| `docs/assessment-report/` | The working-group chapter |
| `docs/advice-sheet/` | The catch advice |
| `docs/assets/` | Bibliography, CSL, Word templates, advice CSS |
| `docs/render.R` | Renders the non-HTML formats and post-processes them |
| `shiny/spict-explorer/` | Interactive prior and setting explorer |
| `data/`, `figures/`, `logs/` | Not committed |
| `ai/` | Your space: `memory/`, `tests/`, `review/` |

## Rules for working here

1. **The assessment data report fits; nothing else does.** The chapter and the advice sheet
   read `data/output/{{STOCK_SLUG}}_spict_summary_<year>.rds`. When the advice sheet needs a
   value it does not have, add a field to the summary object — do not load the fit there.
2. **Settings live in `config.yaml`**, read through `cfg`. Never hard-code a setting in a
   document.
3. **Never hard-code a number that comes from data.** Inline R, always.
4. **Every figure and table gets a caption and an interpretive sentence**, with the
   cross-reference at the end: *"Biomass was above MSY B~trigger~ (@fig-summary)"*, never
   *"@fig-summary shows biomass"*.
5. **Add a package by adding one line to `R/0_setup.R`** — never `install.packages()` in a
   document. Optional packages load through `ensure_packages()` at the point of use.
6. **HTML renders from the Preview/Render button.** Word goes through `docs/render.R`.
7. **Review before a long render.** A typo found after a two-hour render costs two hours.
8. **Caches expire with their fit.** When the data, priors, or settings change, delete
   `data/output/` rather than trusting the render toggles.
9. **Read the whole document before editing it.** Partial reads produce text that contradicts
   text you have not seen.

## Project memory

Use `ai/memory/`. Read `ai/memory/MEMORY.md` first; write one fact per file, with absolute
dates and a `metadata.author` you can be identified by. Do not put project facts in an
agent-local memory folder outside this project — the next agent, which may not be you, has to
find them.

Facts this project needs recorded, at minimum: the catch data sources, the index producer and
its pinned commit, where each prior came from, what the catch-uncertainty breakpoints mean, and
which spict version and branch produced the assessment.

## Git

Local repository, **no remote**, and **never push**. Commit as work progresses, with the
author's own git identity. Adding a remote and publishing are the author's decisions, and for
this project they follow a review of whether the catch data can be published at all.

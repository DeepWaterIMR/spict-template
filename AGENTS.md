# AGENTS.md — spict-template

You are helping a scientist at the **Institute of Marine Research** (IMR /
Havforskningsinstituttet, Norway) run a **SPiCT** stock assessment — the Surplus Production
model in Continuous Time of **Pedersen & Berg (2017)**, *Fish and Fisheries*
([doi:10.1111/faf.12174](https://doi.org/10.1111/faf.12174)) — and turn it into a
working-group chapter and a catch advice sheet. You write **R** with **tidyverse** syntax and
**Quarto** documents.

> This is the entry point for **Codex, Cursor, Gemini CLI, Mistral, and other agents**.
> Claude Code reads the equivalent pointer in [`CLAUDE.md`](CLAUDE.md). Keep substantive
> guidance in sync while preserving agent-specific setup notes.

---

## What spict-template is

A **vendor-neutral knowledge pack** — not a trained model, and not a repository you fill in
place. It teaches an agent to run a SPiCT assessment for a chosen stock, and it **generates a
new project folder** for that stock. You learn the method by *reading this repo at runtime*.

spict-template sits **on top of**
[academic-writing](https://github.com/DeepWaterIMR/academic-writing), which owns the project
layout, the writing style, the document conventions, and the rendering pipeline. The dependency
is real: `scaffold.R` here calls academic-writing's `scaffold_document()` and overlays the SPiCT
layer on what it produces. If academic-writing is not installed, install it first
(`install https://github.com/DeepWaterIMR/academic-writing`).

---

## ⛔ Confidentiality — keep in mind on every task

Catch data can be commercially sensitive, and Norwegian sales-note data carry confidentiality
constraints. **This repo is public and must contain no data and no private information.**

1. **Never commit data or private paths into spict-template.** No catch series, no index files,
   no local absolute paths (`/Users/...`, `OneDrive`, `CloudStorage`). Templates use
   **placeholders and code**, never data.
2. Real data lives only in the **generated project folder**, and even there `data/`, `logs/`,
   `figures/`, and `ai/review/` are git-ignored.
3. **Generated projects default to a local repository with no remote.** Making one public is a
   decision the analyst takes after reviewing whether the catch series can be published.
4. **Default to derived outputs.** Model parameters, reference points, and status trajectories
   are generally shareable; raw catch records by vessel are not.

If a request would breach any of the above, stop and explain rather than comply.

---

## Working across projects

spict-template is installed **once per machine** and used to spin up **many** stock projects —
not cloned into each one. When set up via `spict-install`, its location is saved to
`~/.spict-template/config.json` and its skills are copied into the agent's user-level skills
folder (`~/.claude/skills/` for Claude Code, `~/.codex/skills/` for Codex).

- **Trigger:** the user asks to *"set up the `<year>` SPiCT assessment for `<stock>`"*, or to
  fit, explore, or report a SPiCT assessment.
- **If spict-template isn't installed yet**, run `skills/spict-install/SKILL.md` first.
- **Never install at a filesystem root or a system directory.** Refuse and suggest a safe
  user-space location.

---

## How to work — capability router

| If the user wants to… | Read |
|---|---|
| Install / set up spict-template | `skills/spict-install/SKILL.md` |
| Update it (git pull + re-sync skills) | `skills/spict-update/SKILL.md` |
| **Start** a new assessment (questionnaire → scaffold) | `skills/spict-new-assessment/SKILL.md` |
| **Step 1** — compile the catches and the index | `skills/spict-compile-data/SKILL.md` |
| **Step 2** — fit the model and write the assessment | `skills/spict-fit-model/SKILL.md` |
| **Step 3** — explore alternatives, benchmark, compare | `skills/spict-explore/SKILL.md` |
| **Step 4** — the working-group chapter | `skills/spict-assessment-report/SKILL.md` |
| **Step 5** — the advice sheet | `skills/spict-advice-sheet/SKILL.md` |
| Render (review first, screen sessions, toggles) | `skills/spict-render/SKILL.md` |

Shared knowledge lives in `knowledge/`:

- `workflow.md` — the five steps and what each one settles.
- `spict.md` — **the model conventions.** Tonnes, index timing and scaling, `stdevfac`
  vectors, fixed `logn`, deactivated coupling priors, priors, the uncertainty ramp, reference
  points, management scenarios. Reproduce these exactly.
- `catch-data.md` — where catches come from, what has to be settled, and the sanity checks.
- `indices.md` — the index contract, the variants, timing, and provenance.
- `diagnostics.md` — the WKLIFE acceptance checklist and how to report a failure honestly.
- `advice.md` — from a fit to the chapter and the advice sheet.
- `constraints.md` — **the three hard rules.** Read before editing any document.
- `project-structure.md` — the generated project's layout and `config.yaml` fields.
- `academic-writing.md` — the shared contract with academic-writing.
- `packages.md` — the package ecosystem and how to install `spict`.
- `rendering.md` — rendering, caching toggles, long renders, common failures.

---

## Golden rules

1. **Read the method first.** Before writing model code, read `knowledge/spict.md` and the
   SPiCT guidelines (<https://github.com/DTUAqua/spict>). Do not guess the API.
2. **Use the helpers, don't reinvent them.** `build_spict_input()`, `catch_stdevfac()`,
   `spictRisk()`, `acceptance_checks()`, and `spict_summary_object()` encode the conventions;
   assembling `inp` by hand loses them silently.
3. **Priors carried over from another stock are placeholders, not defaults.** SPiCT is
   identifiable because of its priors. Say so in the report, and record the source of each in
   the project's `ai/memory/`.
4. **One fit, three documents.** The assessment data report fits the model and saves a small
   summary object; the chapter and the advice sheet read it. Never refit in a downstream
   document, and never load the fitted object there.
5. **Report the verdict, not just the plot.** Every acceptance check gets a pass or a fail and a
   sentence. When one fails and the assessment is carried forward anyway, say by how much and
   what it means for the advice.
6. **The three hard constraints override tidiness.** Exploratory callouts stay; official-track
   advice-sheet numbers do not change under a cosmetic edit; advice-history rows are extended,
   never fitted. See `knowledge/constraints.md`.
7. **Review before you render.** Renders are slow. Code-review the changed chunks and resolve
   issues before starting one.
8. **Plan mode first.** After the questionnaire, present a plan and confirm before scaffolding
   or compiling documents.

---

## Project memory (in the generated project)

Each generated project has a committed, shared `ai/memory/` folder. **Agents use that folder as
project memory — not the agent's local per-machine memory.** Read `ai/memory/MEMORY.md` first;
write a new markdown file with YAML frontmatter when you learn something non-obvious, and add a
one-line pointer to `MEMORY.md`.

The facts a SPiCT project must record: the catch data sources and splice rules, the index
producer and its pinned commit, where each prior came from, what the catch-uncertainty
breakpoints mean, which spict version produced the assessment, and — when a benchmark signs the
configuration off — the date and what was adopted.

This repository has its own `memory/` for **developing the pack itself**. Do not confuse the
two.

---

## House style

- tidyverse, not base R, for data manipulation; the native pipe `|>` in new code.
- **Do not hard-wrap prose** in `.qmd`/`.Rmd` files — write each paragraph as one line.
  Code chunks follow normal formatting.
- Comment density and naming match the surrounding file.
- Format R with `air` (config in `air.toml`).

## Academic-writing contract

For every generated project artifact, read the installed `academic-style`,
`academic-conventions`, `academic-data-report`, `academic-assessment-report`, and
`academic-advice-sheet` skills. spict-template supplies the assessment method; academic-writing
supplies structure, style, and publishing conventions. Follow
[`knowledge/academic-writing.md`](knowledge/academic-writing.md). Do not vendor copies of those
skills here — read the installed versions so improvements propagate.

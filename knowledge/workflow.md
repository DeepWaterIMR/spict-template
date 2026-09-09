# The SPiCT assessment workflow

An assessment runs in five steps. Each has a skill; each produces something the next step
reads. The steps are ordered, but not one-way — a failed diagnostic in step 3 sends you back
to step 2, and a benchmark year runs step 4 (exploration) before settling step 3.

| Step | Skill | Produces |
|---|---|---|
| 0 | `spict-new-assessment` | A scaffolded project folder and a filled `config.yaml` |
| 1 | `spict-compile-data` | `data/output/<stock>_catches.rds` and `<stock>_index.rds` |
| 2 | `spict-fit-model` | `docs/data-report/spict-assessment/` and the saved summary object |
| 3 | `spict-explore` | Candidate fits, comparison reports, the Shiny explorer |
| 4 | `spict-assessment-report` | `docs/assessment-report/` — the working-group chapter |
| 5 | `spict-advice-sheet` | `docs/advice-sheet/` — the catch advice |

Step 3 is optional in an update year and mandatory in a benchmark year.

## What each step actually settles

**Step 1 — data.** SPiCT needs two series and nothing else: total catch in tonnes by year,
and one relative-biomass index with a per-observation uncertainty. Everything hard about
step 1 is provenance: which catch sources are combined, how countries and historical
reconstructions are spliced, which index variant is the assessment index, and what fraction of
the year the index observation refers to. See [`catch-data.md`](catch-data.md) and
[`indices.md`](indices.md).

**Step 2 — the fit.** Priors, the catch-uncertainty ramp, the production-function shape, and
the acceptance diagnostics. The output is a *data report* — every chunk visible, every number
inline — because the reader's job is to check the arithmetic. See [`spict.md`](spict.md) and
[`diagnostics.md`](diagnostics.md).

**Step 3 — exploration.** Sensitivity to priors and initial values, alternative index
variants, alternative shapes, and side-by-side comparison of candidate fits. This is where a
benchmark spends its time. The Shiny explorer exists so the analyst can turn a knob and see
the consequence without editing a script.

**Step 4 — the chapter.** A working-group report chapter, in the group's Word template, with
the group's float numbering. It reports the *selected* run; it does not refit.

**Step 5 — the advice.** The short public document. Every number is inline R against the saved
summary object from step 2. See [`advice.md`](advice.md).

## Where the assessment sits relative to the official one

At IMR Deep-water, SPiCT is often an **exploratory supplement** to an age-structured official
assessment (gadget3 for the Barents Sea redfishes). When that is the case, both the data
report and the advice sheet carry a callout saying so, and that callout is a hard constraint —
see [`constraints.md`](constraints.md). Set `EXPLORATORY: false` in `config.yaml` only when the
working group has adopted SPiCT as the assessment model for the stock.

## Provenance

The workflow is distilled from the `reg-spict` (golden redfish) and `reb-spict` (beaked
redfish) projects of the Deep-water species and cartilaginous fish group at the Institute of
Marine Research, and from the SPiCT guidelines of Mildenberger et al. (2021,
<https://github.com/DTUAqua/spict>). The generated project's documents are spict-template's own
evolving implementation of that routine — improve them here, in the pack, whenever a lesson
generalises beyond one stock.

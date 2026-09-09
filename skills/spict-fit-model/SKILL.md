---
name: spict-fit-model
description: Step 2 of the SPiCT workflow — fit the assessment model, run the acceptance diagnostics, project the management scenarios, and write the assessment data report. Use after the data are compiled (step 1) and the user is ready to run the assessment.
---

# Step 2 — Fit the model

Goal: a fitted SPiCT model that passes its acceptance checks, a data report documenting it, and
the small summary object the chapter and the advice sheet read.

Read `knowledge/spict.md` and `knowledge/diagnostics.md` before writing model code, and the
SPiCT guidelines (<https://github.com/DTUAqua/spict>). Do not guess the API.

The document is `docs/data-report/spict-assessment/<stock>-spict-assessment.qmd`. It is an
`academic-data-report`: every chunk visible but folded, every number inline. Read that skill
before editing it.

## Step 1 — Settle the priors

**This is the step, not a preliminary to it.** SPiCT is a state-space model fitted to two short
series; it is the priors that make it identifiable, and a scaffolded project ships another
stock's values.

| Prior | Set it from |
|---|---|
| `logbkfrac` | What the fishery was doing in the first year of the series |
| `logr` | FishLife, a published *r* for the species or a close congener, or `r ≈ 2 F_MSY` |
| `logsdb` | How smooth the biomass trajectory can plausibly be |

Write each value, and where it came from, into `ai/memory/priors.md`. "Carried over from
`<other stock>` and not yet recalibrated" is an acceptable entry; leaving the file unwritten is
not.

Do the same for the catch-uncertainty breakpoints: `STDEV_HIGH_YEAR` and `STDEV_LOW_YEAR` are
reporting-quality events for this stock, not round numbers.

## Step 2 — Fit

`build_spict_input()` in `R/spict_helpers.R` applies the template's conventions — tonnes,
mean-scaled index, `stdevfac` vectors averaging one, `logn` fixed at the Schaefer value,
`logalpha` and `logbeta` deactivated. Use it rather than assembling `inp` by hand; the
conventions are there because each one has a failure mode behind it.

The document fits, then runs `calc.osa.resid()`, `calc.process.resid()`, `check.ini()`,
`retro()`, and `hindcast()`. All five cache to `data/output/` behind document parameters.

## Step 3 — Judge it

`acceptance_checks()` returns the WKLIFE checks with a verdict for each. Report the verdicts,
not only the plots: a diagnostics section with seven figures and no conclusions leaves the
reader unable to tell whether the assessment passed.

Then look at the things a table cannot capture:

- **Process residuals.** A run of same-signed biomass innovations means the production function
  cannot follow the data, usually because `logr` is held too low by its prior.
- **Priors against posteriors.** A posterior on top of its prior means the data say nothing
  about that parameter. A posterior pushed to the edge means the data disagree with the prior
  and are losing. Both need a sentence in the report.
- **Hindcast MASE.** Above one means the model predicts the index worse than "same as last
  year". Say so plainly.

**When a check fails, do not quietly carry on.** Either fix it — which usually means going back
to the priors or to step 3, exploration — or state which check failed, by how much, and what it
means for the weight the advice can carry. That sentence has to reach the advice sheet's
*Quality of the assessment* section too.

## Step 4 — Management scenarios

Four scenarios: the advice rule, F = F~MSY~, F = F~sq~, and F = 0. `spictRisk()` turns them
into tail probabilities. **Report the risk table beside the catch table** — a scenario with an
acceptable median and a substantial chance of dropping below B~lim~ is not an acceptable
scenario, and the catch table alone does not show that.

## Step 5 — Save the summary

`spict_summary_object()` writes the small object the downstream documents read. Keep it small:
the fitted object is large and slow to load, and neither the chapter nor the advice sheet needs
it. When the advice sheet needs a value it does not have, **add a field here** rather than
loading the fit there.

## Step 6 — Write the report

Prose in the past tense, every value inline R, one interpretive sentence per figure with the
cross-reference at the end. Say what you tried and dropped, not only what worked — the next
reader's first question is usually "did you consider…".

The exploratory-status callout stays. See `knowledge/constraints.md`.

## Rendering

Renders are slow. **Code-review the changed chunks before starting one** — see
`spict-render`. Once the cached objects exist, flip the toggles to `FALSE` while you iterate on
prose, and back to `TRUE` for the final render. Delete the cache whenever the data, the priors,
or the settings change.

## Done

Report: whether the fit converged, which acceptance checks passed and which did not, Mohn's
rho, the hindcast MASE, the estimated stock status, and the advised catch. Say which values are
ready for the working group and which are provisional, and what the spict version was.

Next: `spict-explore` in a benchmark year, otherwise `spict-assessment-report` and
`spict-advice-sheet`.

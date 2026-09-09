---
name: spict-explore
description: Step 3 of the SPiCT workflow — explore alternative configurations, test sensitivity to priors, index variants, and settings, compare candidate fits side by side, and drive the interactive Shiny explorer. Use during a benchmark, a sensitivity analysis, or when a diagnostic in step 2 failed.
---

# Step 3 — Explore alternatives

Goal: understand what the assessment is sensitive to, and settle which configuration the
working group adopts. Optional in an update year; mandatory in a benchmark year, and mandatory
whenever a step-2 diagnostic failed.

Read `knowledge/spict.md` and `knowledge/diagnostics.md` first.

## Three ways to explore, in increasing formality

**1. The Shiny explorer** — for the first hour. Sliders for every prior, the index timing, and
the uncertainty ramp, refitting as you go.

```r
shiny::runApp("shiny/spict-explorer")
```

It reads the same compiled series the assessment does, so what it shows is what a re-render
would produce. It writes nothing back: when a configuration is worth keeping, put it in
`config.yaml` or in `R/explore_fit.R`.

**2. `R/explore_fit.R`** — one candidate, saved and reported. Edit the marked block, give the
run a short unique name, source the file. It fits, saves to
`data/output/candidate_<name>.rds`, and renders `docs/data-report/exploration/single-fit.qmd`
with the full diagnostics.

**3. `R/explore_compare.R`** — several saved candidates side by side, rendering
`docs/data-report/exploration/model-comparison.qmd`.

## What is worth varying

In rough order of how much it usually moves the answer:

1. **The prior on `logr`.** Almost always the most influential single choice, and the one most
   often inherited from another stock.
2. **The prior on `logbkfrac`.** Determines where the biomass trajectory starts, which
   determines the depletion the model infers.
3. **The index variant.** A different length slice or a different survey combination is a
   different assessment, not a robustness check.
4. **The index timing.** Test it if the survey month is uncertain.
5. **The catch-uncertainty ramp.** How much the historical catches are allowed to matter.
6. **`logsdb`.** How closely the biomass track is allowed to chase the index.
7. **The production-function shape.** Freeing `logn` is a benchmark decision, and usually a
   demonstration that it is not identified rather than an improvement.

## The comparability rule

**Candidates fitted to different data are not comparable by likelihood or AIC.** Changing a
prior keeps the data fixed and the likelihoods comparable; changing the index variant, the
year range, or the timing does not. Comparing their trajectories and their diagnostics is still
informative — comparing their AICs is not.

Say in the comparison report which kind of comparison you are making. A table of AICs across
candidates fitted to different index variants is a wrong answer presented as a right one.

## Choosing

The candidate that wins is the one that passes its diagnostics and whose priors the analyst can
defend, not the one with the best fit statistic. A model that fits beautifully because `logr`
was tuned until it did is not evidence about the stock.

When the working group adopts a candidate that is not the best-diagnosing one, **say so in the
chapter** under *Future development of the assessment*, with the alternative named.

## Record it

Write `ai/memory/` entries for what was tested and what it showed — not just the winner. Next
year's assessor will otherwise repeat the same sensitivity analysis to reach the same
conclusion.

If a benchmark signs the configuration off, write `ai/memory/benchmark-signoff.md` with the
date, who was present, and what was adopted. **That file activates the byte-identical-output
constraint on the advice sheet** — see `knowledge/constraints.md`.

## Done

Report which candidates were fitted, what each varied, how they differed in status and advice,
which diagnostics separated them, and which is recommended and why. Then move the recommended
configuration into `config.yaml` and re-run step 2 so the assessment report reflects it.

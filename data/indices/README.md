# Survey indices

Place the stock's survey/abundance index `.rds` here. The qmd pipeline expects:

```text
data/indices/{{STOCK_CODE}}-assessment-survey-indices.rds
```

## Expected structure

A **named list of data frames**, where each name is a different index split (e.g. size class, area, total vs juvenile), produced by `get_index_split()` (from the IMR Deep-water group's index-production toolchain). One element of the list is selected for the assessment via `[[index]]` in the qmd setup chunk.

Inherited example structure from `reb-spict`:

```r
list(
  "Total biomass"         = data.frame(model, year, est, lwr, upr, log_est, se, se_natural, type, cv),
  "Over 30 cm biomass"    = data.frame(...),   # used for the assessment ([[2]])
  "Under 10 cm abundance" = data.frame(...)
)
# attr(*, "method") = "get_index_split"
```

Required columns per data frame: `year`, `est`, `lwr`, `upr`, `se`. Additional columns (`model`, `log_est`, `se_natural`, `type`, `cv`) are tolerated and currently unused.

The qmd then scales the chosen index by its mean (`est / mean(est)`) and uses `se / mean(se)` as a per-observation stdev multiplier.

## Where this file comes from

These RDS files are usually produced by a **separate index repo**, not by `spict-template` itself. The IMR Deep-water group's pattern is one index-production repo per species or species group, e.g.:

- [`DeepWaterIMR/ref-assessment-index`](https://github.com/DeepWaterIMR/ref-assessment-index) — survey indices for golden and beaked redfish
- [`DeepWaterIMR/ref-index`](https://github.com/DeepWaterIMR/ref-index) — companion manuscript / methodology

When onboarding a new stock, ask the analyst for the **URL of the index producer repo for this stock** and pin a specific commit/tag in `memory/index_data_sources.md`. The agent-driven scaffolding interview (`memory/template_scaffold_interview.md`) walks through this.

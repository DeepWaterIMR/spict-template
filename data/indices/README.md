# Indices

Place the stock's abundance index `.rds` here. The qmd pipeline expects:

```text
data/indices/{{STOCK_CODE}}-assessment-survey-indices.rds
```

(The filename historically says "survey-indices" but the content can be a CPUE index too — see below.)

## What kind of index?

SPiCT does not care whether the index is fisheries-independent or fisheries-dependent. Anything that approximates relative biomass over time, with a per-observation uncertainty, can drive the model. Common shapes:

- **Survey biomass index** — design-based (stratified mean) or model-based (GAM, sdmTMB, VAST) from a research bottom-trawl, beam-trawl, acoustic, or longline survey.
- **Survey abundance index** — count-based variants of the above, often per size or age class.
- **CPUE** — fisheries-dependent catch-per-unit-effort, optionally standardised (year + vessel + gear + area + month effects) via GLM, GLMM, or Tweedie-flavoured `sdmTMB`.
- **Composite** — multiple of the above combined post-hoc; SPiCT can also accept multiple `obsI` series natively, but the current template wires a single index.

The IMR Deep-water redfish case (the worked example carried over from reb-spict) is the *"over 30 cm biomass"* slice of a model-based survey biomass index estimated with `sdmTMB` from all available bottom-trawl data. That's one option among many — other stocks will use entirely different index types.

## Required contract

For SPiCT to consume the index, the qmd setup chunk needs three things per observation:

| Column | Meaning |
|---|---|
| `year` | Numeric year (fractional acceptable; the template adds `+ 6/12` for June timing) |
| `est` | The point estimate (units don't matter — the qmd rescales by the mean) |
| `se` | Standard error on the (log) scale, used to build a stdev multiplier |

Optional: `lwr`, `upr` (used for plotting CIs). If your producer outputs `cv` instead of `se`, convert before saving.

## Inherited wrapper structure (from reb-spict)

The reb-spict `.rds` is a **named list of data frames** — one per index variant — produced by `get_index_split()`:

```r
list(
  "Total biomass"         = data.frame(model, year, est, lwr, upr, log_est, se, se_natural, type, cv),
  "Over 30 cm biomass"    = data.frame(...),   # used for the assessment ([[2]])
  "Under 10 cm abundance" = data.frame(...)
)
# attr(*, "method") = "get_index_split"
```

The qmd extracts `[[2]]`, scales `est / mean(est)`, and uses `se / mean(se)` as the stdev multiplier.

**If your stock's index has a different wrapper** (a single data frame, a list keyed differently, a tibble from a CPUE GLM, …), you have two options:

1. Save it as `data/indices/{{STOCK_CODE}}-assessment-survey-indices.rds` with the same shape (named list whose chosen element has `year`, `est`, `se`) — this lets you reuse the qmd setup chunk unchanged.
2. Save it in its native shape and edit the survey-index chunk in `1 assessment model.qmd` (and `src/exploration/1 fit model.R`) to do whatever extraction your structure needs. This is the honest path for CPUE indices, which rarely come as a list.

Document the choice in `memory/index_data_sources.md`.

## Where this file comes from

These RDS files are usually produced by a **separate index repo**, not by `spict-template` itself. The IMR Deep-water group's pattern is one index-production repo per species or species group, e.g.:

- `DeepWaterIMR/ref-assessment-index` (internal) — survey indices for golden and beaked redfish (sdmTMB-based)
- `DeepWaterIMR/ref-index` (internal) — companion manuscript / methodology

For CPUE-based stocks the producer might instead be a logbook-cleaning + standardisation script that lives wherever the analyst keeps it; ask.

When onboarding a new stock, the scaffolding agent should ask the analyst for the **URL (or other location) of the index producer repo / script** and pin a specific commit/tag in `memory/index_data_sources.md`. The agent-driven scaffolding interview (`memory/template_scaffold_interview.md`) walks through this.

# SPiCT essentials

SPiCT — the Surplus Production model in Continuous Time (Pedersen & Berg 2017,
<https://doi.org/10.1111/faf.12174>) — is a state-space biomass-dynamic model. It estimates
biomass and fishing mortality relative to their MSY levels from a catch series and one or more
relative-abundance indices. It has no age structure and no recruitment process: everything the
stock does is compressed into a production function.

Read the package guidelines before writing model code:
<https://github.com/DTUAqua/spict/blob/master/spict/vignettes/spict_guidelines.pdf>. Do not
guess the API.

## Input object

```r
inp <- list(
  timeC   = catches$year,          # calendar year of each catch observation
  obsC    = catches$total,         # catch in TONNES
  timeI   = index$year + timing,   # fractional year of each index observation
  obsI    = index$est,             # index, scaled to its own mean
  stdevfacI = index$se_scaled      # per-observation uncertainty multiplier
)
```

### Conventions this pack fixes

These are the template's conventions. Departing from one is a decision to record in
`ai/memory/`, not a preference.

- **Catches are in tonnes throughout.** Every table, every axis, every advice number. The only
  place they are divided by 1000 is a kilotonne axis label.
- **Index timing is a fraction of the year.** `year + 6/12` for a June survey. Winter surveys
  land at `+ 1/12` or `+ 2/12`, autumn surveys at `+ 10/12`, a standardised CPUE series is
  usually centred at `+ 0.5`. Set `INDEX_TIMING` in `config.yaml`; do not hard-code it.
- **The index is scaled by its own mean** (`est / mean(est)`). SPiCT estimates the catchability
  that links index to biomass, so the absolute scale is arbitrary; scaling keeps the estimated
  `logq` near zero and the optimiser well behaved.
- **`stdevfac` vectors must average to 1.** They are *multipliers* on an estimated observation
  standard deviation, not standard deviations. A vector that does not average to 1 silently
  rescales the estimated observation error and makes fits incomparable. Build them as
  `se / mean(se)` and assert the mean.
- **`logn` is fixed at the Schaefer value** unless a benchmark decided otherwise:
  `inp$phases$logn <- -1; inp$ini$logn <- log(2)`. A production-function shape estimated from
  a short catch series and one index is not identified; leaving `logn` free is the most common
  way to get a fit that converges to nonsense.
- **`logalpha` and `logbeta` priors are deactivated**: `inp$priors$logalpha <- c(0, 0, 0)` and
  the same for `logbeta`. These couple observation and process error; with informative priors
  on `logsdb` they fight each other.
- **Use the native pipe `|>`** in new code.

## Priors

SPiCT is a state-space model fitted to two short series. It is priors, not data, that make it
identifiable. Three matter:

| Prior | What it controls | How to set it |
|---|---|---|
| `logbkfrac` | Biomass at the start of the series, as a fraction of *K* | From what the fishery was doing then. A stock lightly fished in the first year starts near 1; a depleted one near 0.2 |
| `logr` | Intrinsic population growth rate | From life history: FishLife, a published *r* for the species or a congener, or `r ≈ 2 F_MSY`. Long-lived deep-water species sit at 0.05–0.2 |
| `logsdb` | Process (biomass) error | Usually the tightest prior in the model. Too wide and the biomass track chases the index |

Each is a length-3 vector `c(log(mean), sd, use)` where `use = 1` activates the prior.

**Priors carried over from another stock are placeholders, not defaults.** The scaffolded
project ships the golden-redfish values so the document renders; replace them before anything
leaves the building, and record the source of each in `ai/memory/priors.md`.

## The catch-uncertainty ramp

Historical catches are worse than recent ones, and SPiCT lets you say so through `stdevfacC`.
The template's pattern is a two-breakpoint ramp: high uncertainty before `STDEV_HIGH_YEAR`,
low after `STDEV_LOW_YEAR`, linear in between, rescaled so the vector averages to 1.

The breakpoints are stock-specific and are reporting-quality thresholds, not round numbers.
For golden redfish they are 1987 (when AFWG began correcting catches) and 2022 (when Norwegian
sales-note data became trustworthy for the species). Ask the analyst what the equivalent events
are; write them into `config.yaml` as `STDEV_HIGH_YEAR` and `STDEV_LOW_YEAR`, and the reasoning
into `ai/memory/`.

## Reference points

SPiCT gives **relative** reference points. B/B~MSY~ and F/F~MSY~ are estimated; B~lim~ and
MSY B~trigger~ are not, and must be supplied by the advice framework. The ICES convention for
SPiCT stocks is:

| Point | Value | Basis |
|---|---|---|
| MSY B~trigger~ | B/B~MSY~ = 0.5 | ICES convention for stocks assessed with SPiCT |
| F~MSY~ | F/F~MSY~ = 1 | Estimated by the model |
| B~lim~ | B/B~MSY~ = 0.3 | ICES convention |
| F~lim~ | F/F~MSY~ = 1.7 | Used in `spictRisk()` for the risk table; not usually reported |

These live in `config.yaml` (`BLIM_BMSY`, `BTRIGGER_BMSY`, `FLIM_FMSY`) so a working group with
a different convention changes one file. If the stock has **absolute** reference points from
another assessment, they belong in the advice-sheet narrative — not in the SPiCT model.

Deterministic (`sumspict.drefpoints()`) and stochastic (`sumspict.srefpoints()`) reference
points differ; report both and say which the advice uses.

## Management scenarios

Scenarios come from `add.man.scenario()` / `manage()`. The four the advice sheet expects are:

- **ICES advice rule** — the MSY hockey-stick with B~lim~ and the 35th percentile of the
  projected catch distribution. This is the advice.
- **Fish at F~MSY~**
- **Keep current F** (F~sq~)
- **No fishing** (F = 0)

`spictRisk()` in `R/spict_helpers.R` turns the scenarios into tail probabilities — P(B < B~MSY~),
P(B < B~lim~), P(B < a chosen fraction), P(F > F~MSY~), P(F > F~lim~) — under a lognormal
assumption. Report it alongside the catch scenarios; a scenario with an acceptable median and a
40 % chance of dropping below B~lim~ is not an acceptable scenario.

## Reading

- Pedersen, M.W. & Berg, C.W. (2017). A stochastic surplus production model in continuous time.
  *Fish and Fisheries* 18, 226–243. <https://doi.org/10.1111/faf.12174>
- Mildenberger, T.K., Berg, C.W., Pedersen, M.W., Kokkalis, A. & Nielsen, J.R. (2020).
  Time-variant productivity in biomass dynamic models on seasonal and long-term scales.
  *ICES Journal of Marine Science* 77, 174–187.
- ICES (2021). *Workshop on the Development of Quantitative Assessment Methodologies based on
  LIFE-history traits, exploitation characteristics, and other relevant parameters for
  data-limited stocks (WKLIFE X)*. The source of the SPiCT acceptance checklist.

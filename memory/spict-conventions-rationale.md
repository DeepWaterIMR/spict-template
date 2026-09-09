---
name: spict-conventions-rationale
description: Why each fixed SPiCT convention exists, and what breaks without it
metadata:
  type: project
  author: spict-template
  created: 2026-09-09
---

# Why the SPiCT conventions are fixed

The conventions in `knowledge/spict.md` read like preferences. Each is a failure mode.

| Convention | What happens without it |
|---|---|
| `stdevfac` vectors average to 1 | They multiply an *estimated* observation standard deviation. A vector averaging 1.4 silently inflates that estimate, and two fits with different multipliers are not comparable even though nothing errors |
| `logn` fixed at the Schaefer value | The production-function shape is not identified from one short catch series and one index. Left free, the optimiser converges on a shape the data cannot support, and reports it with a confidence interval |
| `logalpha` / `logbeta` deactivated | They couple observation and process error. With an informative prior on `logsdb` the three pull against each other and the fit becomes sensitive to starting values |
| Index scaled by its own mean | Keeps the estimated `logq` near zero. Unscaled, the optimiser starts far from the optimum and `check.ini()` finds multiple optima |
| Index timing as a fraction of the year | A winter survey entered at 0.5 shifts the biomass trajectory half a year against the catches. It shows up as a stubborn OSA-residual pattern that no prior will fix, and the usual response is to loosen a prior until it goes away |
| Catches in tonnes throughout | Mixed units are caught only when someone compares an advice number against a working-group report — which is to say, after publication |
| No gaps in the catch series | SPiCT fits a series with a hole in it without complaint, and returns a biomass trajectory that reflects the hole |

**How to apply**: when a task seems to require breaking one, that is a decision for the
analyst and the working group, recorded in the project's `ai/memory/` — not a convenience an
agent takes.

Related: [[reference-sources]], [[conventions]]

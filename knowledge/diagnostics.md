# Diagnostics and acceptance

A SPiCT fit that converges is not a SPiCT fit that can be used. The checklist below is the
WKLIFE acceptance list (ICES 2020); the report presents each check, states whether it passed,
and — when one fails — says what was done about it rather than moving on.

## The acceptance checklist

1. **Convergence.** `fit$opt$convergence == 0`. A non-zero code means nothing downstream is
   meaningful. Do not report parameters from a non-converged fit.
2. **All variance parameters are finite and positive.** `all(is.finite(fit$sd))`.
3. **No violation of the model assumptions in the residuals.** `calc.osa.resid()` then
   `plotspict.diagnostic()`: no significant autocorrelation (Ljung–Box), no significant bias
   (a *t*-test on the mean), and normality not rejected (Shapiro–Wilk). Report the *p*-values,
   not just the plot.
4. **Consistent retrospective pattern.** `retro()` with `nretroyears` peels, then
   `mohns_rho()`. Mohn's rho for B/B~MSY~ and F/F~MSY~ inside ±0.2 for a long-lived species is
   the usual bar; state the bar you are using and where it comes from.
5. **Realistic production curve.** `calc.bmsyk()` between 0.1 and 0.9. Outside that, the shape
   parameter is doing something the data cannot support — which is why `logn` is fixed.
6. **High assessment uncertainty is a warning.** The ratio of the upper to lower CI on
   B/B~MSY~ and F/F~MSY~ below 1 signals a model that is not informative; ICES suggests
   treating anything above 5–10 as too uncertain to advise on.
7. **Initial-value sensitivity.** `check.ini(fit, ntrials = 30)`. Every trial that converges
   should land on the same optimum. A fit whose answer depends on where the optimiser started
   is not a fit.

## Hindcasting

`hindcast()` with `nhindcastyears` peels and `plotspict.hindcast()`. The mean absolute scaled
error (MASE) against a persistence baseline says whether the model predicts the index better
than "next year is the same as this year". MASE below 1 is predictive skill; above 1 is not,
and is worth saying plainly in the report rather than burying under the plot.

## Process residuals

`plotspict.diagnostic()` covers observation residuals. Process residuals — the biomass and
fishing-mortality innovations — are the ones that reveal a structurally wrong model: a run of
same-signed biomass innovations means the production function cannot follow what the data are
saying, usually because *r* is fixed too low by its prior.

## Priors against posteriors

`plotspict.priors()`. Two failure modes:

- **The posterior sits on top of the prior.** The data say nothing about that parameter; the
  answer is the prior you chose. Say so.
- **The posterior is pushed to the edge of the prior.** The data disagree with the prior and
  are losing. Either the prior is wrong or the data are, and the report has to take a view.

## What goes in the report

For each check: the number, the threshold, the verdict, and one sentence. A diagnostics section
that shows seven plots and no verdicts has not done its job — the reader cannot tell whether
the assessment passed.

When a check fails and the assessment is carried forward anyway (which happens, particularly in
an exploratory setting), say which check failed, by how much, and what that means for how much
weight the advice can carry. That sentence belongs in *Quality of the assessment* on the advice
sheet as well as in the data report.

## Cost control

`retro()`, `hindcast()`, and `check.ini()` are the expensive parts of the render. The document
has toggles — `run_retro`, `run_hindcast`, `run_check_ini` — and caches their results in
`data/output/`. Fit once, cache, then flip the toggles to `FALSE` while you iterate on prose.
Flip them back before the final render, and note in the report which run the cached objects came
from. A cached diagnostic from a superseded fit is worse than no diagnostic.

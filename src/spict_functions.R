# ─────────────────────────────────────────────────────────────────────────────
# SPiCT helpers used in the production assessment workflow.
#
# Three formerly-defined helpers (`set.spict`, `run.spict`, `retro_rerun`)
# were unused at the time of the 2026 benchmark and have been moved to
# `src/temp/spict_dead_funcs.R` — source that file from an exploration
# script if you need them.
# ─────────────────────────────────────────────────────────────────────────────

#' Risk probabilities from SPiCT management scenarios
#'
#' Computes the probability that biomass is below MSY B-trigger, B-lim, or a
#' user-specified B/B[MSY] fraction, and the probability that fishing
#' mortality is above F[MSY] / F[lim], for each management scenario stored on
#' a SPiCT fit. Used downstream of `add.man.scenario()` / `manage()`.
#'
#' For each scenario in `rep$man`, the function reads log-space B/B[MSY] and
#' F/F[MSY] estimates with their standard errors and converts them to tail
#' probabilities under a lognormal assumption. B[lim]/B[MSY] is fixed at
#' 0.3; F[lim]/F[MSY] is fixed at 1.7. Values are rounded to 3 decimals.
#'
#' @param rep A SPiCT fit object that already contains a `man` element
#'   (i.e. `add.man.scenario()` or `manage()` has been run on it). The
#'   function aborts if `rep$man` is missing.
#' @param bmsyfrac Numeric. The B/B[MSY] threshold used in the third tail
#'   probability column (`BbelowX`). For example, `0.5` to evaluate the
#'   probability of being below MSY B-trigger.
#' @param years Optional character/numeric vector of years to evaluate; if
#'   `NULL`, only the final row of each scenario is used. Year matching is
#'   done by `rownames(get.par("logBBmsy", ...))`.
#'
#' @return A data frame with one row per scenario × year, containing
#'   `Scenario`, `Year`, `BbelowBmsy`, `BbelowBlim`, `BbelowX`,
#'   `FaboveFmsy`, and `FaboveFlim`.
spictRisk <- function(rep, bmsyfrac, years = NULL) {
  if (!any(names(rep) == "man")) {
    stop(
      "Management calculations not found, 'run manage()' or 'add.man.scenario()' to include them."
    )
  }
  CI <- 0.95
  df <- data.frame()
  for (i in seq_along(rep$man)) {
    lBBmsy <- get.par("logBBmsy", rep$man[[i]], exp = FALSE, CI = CI)
    lFFmsy <- get.par("logFFmsy", rep$man[[i]], exp = FALSE, CI = CI)

    BMSY <- get.par("Bmsyd", rep)[2]
    FMSY <- get.par("Fmsyd", rep)[2]
    BlimBmsy <- (BMSY * 0.3) / BMSY
    FFlim <- (FMSY * 1.7) / FMSY

    if (is.null(years)) {
      ind <- nrow(lBBmsy)
    } else {
      ind <- which(rownames(lBBmsy) %in% years)
    }
    for (t in seq_along(ind)) {
      probs <- round(
        pnorm(
          log(c(1, BlimBmsy, bmsyfrac)),
          lBBmsy[ind[t], 2],
          sd = lBBmsy[ind[t], 4]
        ),
        3
      )
      probsF <- round(
        pnorm(
          log(c(1, FFlim)),
          lFFmsy[ind[t], 2],
          sd = lFFmsy[ind[t], 4]
        ),
        3
      )
      df <- rbind(
        df,
        data.frame(
          Scenario = names(rep$man[i]),
          Year = rownames(lBBmsy)[ind[t]],
          BbelowBmsy = probs[1],
          BbelowBlim = probs[2],
          BbelowX = probs[3],
          FaboveFmsy = 1 - probsF[1],
          FaboveFlim = 1 - probsF[2]
        )
      )
    }
  }
  df
}

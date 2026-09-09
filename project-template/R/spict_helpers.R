# spict_helpers.R — building, fitting, and summarising the SPiCT model.
#
# The conventions encoded here are spict-template's, and are documented in the pack's
# knowledge/spict.md. Departing from one is a decision to record in ai/memory/, not a
# preference: catches in tonnes, the index scaled by its own mean, stdevfac vectors that
# average to 1, logn fixed at the Schaefer value, and logalpha/logbeta priors deactivated.
#
# Source this after R/0_setup.R.

ensure_packages("spict")

# --- Input -------------------------------------------------------------------------------

#' Build a SPiCT input list from the project's catch and index series
#'
#' Applies the template's conventions: catches in tonnes on calendar years, the index shifted
#' by `timing` and scaled by its own mean, and `stdevfac` multipliers that average to 1 on
#' both series. Reference-point conventions and the production-function shape come from
#' `config.yaml` through `cfg`, so a working group with different conventions changes one file.
#'
#' @param catches Data frame with `year` (integer) and `total` (tonnes), no gaps.
#' @param index Data frame with `year`, `est`, and `se`.
#' @param priors Named list of length-3 `c(log(mean), sd, use)` vectors. Defaults to the
#'   `PRIOR_*` fields of `config.yaml`.
#' @param timing Fraction of the year the index observation refers to. Defaults to
#'   `cfg$INDEX_TIMING`.
#' @param catch_sdfac Per-year multiplier on the catch observation error. Defaults to the ramp
#'   built by [catch_stdevfac()].
#' @param shape Production-function shape. `"schaefer"` fixes `logn` at `log(2)`; any other
#'   value leaves it free, which is a benchmark decision.
#'
#' @return A SPiCT input list, ready for `spict::check.inp()`.
build_spict_input <- function(catches,
                              index,
                              priors = config_priors(),
                              timing = cfg$INDEX_TIMING %||% 0.5,
                              catch_sdfac = catch_stdevfac(catches$year),
                              shape = cfg$PRODUCTION_MODEL %||% "schaefer") {

  stopifnot(
    all(c("year", "total") %in% names(catches)),
    all(c("year", "est", "se") %in% names(index))
  )

  # A gap in the catch series is not an error SPiCT will report; it is a biomass trajectory
  # that quietly reflects the gap.
  gaps <- setdiff(seq(min(catches$year), max(catches$year)), catches$year)
  if (length(gaps)) {
    stop("Catch series has missing years: ", paste(gaps, collapse = ", "), call. = FALSE)
  }

  inp <- list(
    timeC = catches$year,
    obsC  = catches$total,
    timeI = index$year + timing,
    obsI  = index$est / mean(index$est, na.rm = TRUE)
  )

  inp$stdevfacC <- normalise_stdevfac(catch_sdfac)
  inp$stdevfacI <- normalise_stdevfac(index$se)

  inp$priors <- priors

  # logalpha and logbeta couple observation and process error. With an informative prior on
  # logsdb they pull against it, so they are deactivated rather than left at their defaults.
  inp$priors$logalpha <- c(0, 0, 0)
  inp$priors$logbeta  <- c(0, 0, 0)

  if (identical(tolower(shape), "schaefer")) {
    # A production-function shape estimated from one short catch series and one index is not
    # identified. Fixing it is what keeps the optimiser away from nonsense.
    inp$phases$logn <- -1
    inp$ini$logn    <- log(2)
  }

  spict::check.inp(inp)
}

#' Rescale a vector of observation-error multipliers to average 1
#'
#' `stdevfac` entries multiply an *estimated* observation standard deviation. A vector that
#' does not average to 1 silently rescales that estimate and makes fits incomparable.
#'
#' @param x Numeric vector of relative uncertainties.
#' @return `x` divided by its mean.
normalise_stdevfac <- function(x) {
  m <- mean(x, na.rm = TRUE)
  if (!is.finite(m) || m <= 0) stop("stdevfac values must be finite and positive.", call. = FALSE)
  x / m
}

#' Build the catch-uncertainty ramp
#'
#' Historical catches are less reliable than recent ones. The ramp is flat at
#' `cfg$STDEV_FAC_HIGH` up to `cfg$STDEV_HIGH_YEAR`, flat at `cfg$STDEV_FAC_LOW` from
#' `cfg$STDEV_LOW_YEAR`, and linear between. The breakpoints are reporting-quality events for
#' the stock, not round numbers — see the pack's knowledge/spict.md.
#'
#' @param years Integer vector of catch years.
#' @return A numeric vector the same length as `years`, before normalisation.
catch_stdevfac <- function(years) {
  hi_year <- cfg$STDEV_HIGH_YEAR
  lo_year <- cfg$STDEV_LOW_YEAR
  hi_fac  <- cfg$STDEV_FAC_HIGH %||% 3
  lo_fac  <- cfg$STDEV_FAC_LOW %||% 1

  if (is.null(hi_year) || is.null(lo_year)) {
    stop("Set STDEV_HIGH_YEAR and STDEV_LOW_YEAR in config.yaml.", call. = FALSE)
  }
  if (lo_year <= hi_year) {
    stop("STDEV_LOW_YEAR must be later than STDEV_HIGH_YEAR.", call. = FALSE)
  }

  out <- approx(
    x = c(hi_year, lo_year), y = c(hi_fac, lo_fac),
    xout = years, rule = 2
  )$y
  out
}

#' Read the priors out of config.yaml
#'
#' @return A named list of length-3 `c(log(mean), sd, use)` vectors, for the priors that are
#'   configured. Missing entries are left to SPiCT's own defaults.
config_priors <- function() {
  wanted <- c(logr = "PRIOR_LOGR", logbkfrac = "PRIOR_LOGBKFRAC", logsdb = "PRIOR_LOGSDB",
              logsdf = "PRIOR_LOGSDF", logsdi = "PRIOR_LOGSDI", logsdc = "PRIOR_LOGSDC")
  out <- list()
  for (nm in names(wanted)) {
    value <- cfg[[wanted[[nm]]]]
    if (is.null(value)) next
    value <- as.numeric(unlist(value))
    if (length(value) != 3) {
      stop(wanted[[nm]], " must be three numbers: c(log(mean), sd, use).", call. = FALSE)
    }
    out[[nm]] <- value
  }
  out
}

# --- Diagnostics --------------------------------------------------------------------------

#' Risk probabilities from SPiCT management scenarios
#'
#' Computes the probability that biomass is below B[MSY], below B[lim], or below a chosen
#' B/B[MSY] fraction, and the probability that fishing mortality is above F[MSY] or F[lim],
#' for each management scenario on a fitted object. Used downstream of `add.man.scenario()`
#' or `manage()`.
#'
#' Log-space B/B[MSY] and F/F[MSY] estimates and their standard errors are converted to tail
#' probabilities under a lognormal assumption. The B[lim] and F[lim] conventions come from
#' `config.yaml` (`BLIM_BMSY`, `FLIM_FMSY`).
#'
#' @param rep A SPiCT fit that already carries a `man` element. Aborts if it does not.
#' @param bmsyfrac B/B[MSY] threshold for the third column, e.g. `0.5` for MSY B[trigger].
#' @param years Years to evaluate, matched against `rownames(get.par("logBBmsy", ...))`. When
#'   `NULL`, only the final row of each scenario is used.
#'
#' @return A data frame with one row per scenario and year: `Scenario`, `Year`, `BbelowBmsy`,
#'   `BbelowBlim`, `BbelowX`, `FaboveFmsy`, `FaboveFlim`.
spictRisk <- function(rep, bmsyfrac = cfg$BTRIGGER_BMSY %||% 0.5, years = NULL) {
  if (!any(names(rep) == "man")) {
    stop(
      "Management calculations not found; run manage() or add.man.scenario() first.",
      call. = FALSE
    )
  }

  blim_bmsy <- cfg$BLIM_BMSY %||% 0.3
  flim_fmsy <- cfg$FLIM_FMSY %||% 1.7

  CI <- 0.95
  df <- data.frame()
  for (i in seq_along(rep$man)) {
    lBBmsy <- get.par("logBBmsy", rep$man[[i]], exp = FALSE, CI = CI)
    lFFmsy <- get.par("logFFmsy", rep$man[[i]], exp = FALSE, CI = CI)

    ind <- if (is.null(years)) nrow(lBBmsy) else which(rownames(lBBmsy) %in% years)

    for (t in seq_along(ind)) {
      probs <- round(
        pnorm(log(c(1, blim_bmsy, bmsyfrac)), lBBmsy[ind[t], 2], sd = lBBmsy[ind[t], 4]),
        3
      )
      probsF <- round(
        pnorm(log(c(1, flim_fmsy)), lFFmsy[ind[t], 2], sd = lFFmsy[ind[t], 4]),
        3
      )
      df <- rbind(
        df,
        data.frame(
          Scenario   = names(rep$man[i]),
          Year       = rownames(lBBmsy)[ind[t]],
          BbelowBmsy = probs[1],
          BbelowBlim = probs[2],
          BbelowX    = probs[3],
          FaboveFmsy = 1 - probsF[1],
          FaboveFlim = 1 - probsF[2]
        )
      )
    }
  }
  df
}

#' The WKLIFE acceptance checks, as a table
#'
#' Runs the checks a SPiCT fit has to pass before its output can be used, and returns the
#' verdict for each. A diagnostics section that shows plots without verdicts leaves the reader
#' unable to tell whether the assessment passed; this produces the verdicts.
#'
#' `check.ini()` is the expensive one, so it is optional and its result can be passed in.
#'
#' @param fit A fitted SPiCT object, with OSA residuals already calculated.
#' @param ini Optional output of `spict::check.ini()`.
#' @param retro_fit Optional output of `spict::retro()`.
#'
#' @return A data frame with `Check`, `Criterion`, `Value`, and `Passed`.
acceptance_checks <- function(fit, ini = NULL, retro_fit = NULL) {
  # SPiCT reports on a sub-annual time grid whose last rows are predictions. The ratio is
  # taken at the terminal observed catch time, which is the status the advice is about.
  terminal_row <- function(p) {
    times <- suppressWarnings(as.numeric(rownames(p)))
    if (all(is.na(times))) return(nrow(p))
    which.min(abs(times - max(fit$inp$timeC)))
  }
  ci_ratio <- function(par) {
    p <- get.par(par, fit, exp = TRUE)
    unname(p[terminal_row(p), 3] / p[terminal_row(p), 1])
  }

  rows <- list(
    data.frame(
      Check = "Convergence",
      Criterion = "opt$convergence == 0",
      Value = as.character(fit$opt$convergence),
      Passed = identical(fit$opt$convergence, 0L) || identical(fit$opt$convergence, 0)
    ),
    data.frame(
      Check = "Finite variances",
      Criterion = "all variance parameters finite",
      Value = if (all(is.finite(fit$sd))) "all finite" else "not all finite",
      Passed = all(is.finite(fit$sd))
    ),
    data.frame(
      Check = "Production curve",
      Criterion = "0.1 < Bmsy/K < 0.9",
      Value = sprintf("%.2f", calc.bmsyk(fit)),
      Passed = calc.bmsyk(fit) > 0.1 && calc.bmsyk(fit) < 0.9
    ),
    data.frame(
      Check = "B/Bmsy uncertainty",
      Criterion = "CI ratio below 5",
      Value = sprintf("%.1f", ci_ratio("logBBmsy")),
      Passed = ci_ratio("logBBmsy") < 5
    ),
    data.frame(
      Check = "F/Fmsy uncertainty",
      Criterion = "CI ratio below 5",
      Value = sprintf("%.1f", ci_ratio("logFFmsy")),
      Passed = ci_ratio("logFFmsy") < 5
    )
  )

  if (!is.null(ini)) {
    # Row 1 is the base fit; the rest are the trials, and a trial that did not converge has a
    # missing distance. Only the converged trials can say anything about the optimum.
    distances <- ini$check.ini$resmat[-1, "Distance"]
    converged <- distances[!is.na(distances)]
    rows <- c(rows, list(data.frame(
      Check = "Initial-value sensitivity",
      Criterion = "every converged trial reaches the base optimum",
      Value = paste0(
        sum(!is.na(distances)), "/", length(distances), " converged; max distance ",
        if (length(converged)) sprintf("%.3f", max(converged)) else "NA"
      ),
      Passed = length(converged) > 0 && max(converged) < 0.01
    )))
  }

  if (!is.null(retro_fit)) {
    rho <- mohns_rho(retro_fit, what = c("FFmsy", "BBmsy"))
    rows <- c(rows, list(data.frame(
      Check = "Retrospective pattern",
      Criterion = "|Mohn's rho| < 0.2",
      Value = paste(names(rho), sprintf("%.2f", rho), sep = " = ", collapse = ", "),
      Passed = all(abs(rho) < 0.2)
    )))
  }

  do.call(rbind, rows)
}

# --- The summary object ---------------------------------------------------------------------

#' Extract the small summary object the downstream documents read
#'
#' The fitted SPiCT object is large and slow to load, and neither the working-group chapter
#' nor the advice sheet needs it. They read this instead, which is what makes all three
#' documents quote the same numbers by construction.
#'
#' When the advice sheet needs a value it does not have, add a field here rather than loading
#' the fit in the advice sheet.
#'
#' @param fit A fitted SPiCT object carrying management scenarios.
#' @param assessment_year The assessment year.
#' @param man_table The scenario table, scenario names in a `Scenario` column and at least
#'   `C`, `B/Bmsy`, and `F/Fmsy`. Built from `sumspict.manage(fit, include.unc = TRUE)`, which
#'   returns the estimates and their intervals as separate matrices.
#' @param checks Optional output of [acceptance_checks()].
#'
#' @return A named list, saved by the assessment data report to `data/output/`.
spict_summary_object <- function(fit, assessment_year, man_table, checks = NULL) {
  stopifnot("Scenario" %in% names(man_table), "C" %in% names(man_table))
  list(
    assessment_year = assessment_year,
    spict_version   = as.character(utils::packageVersion("spict")),
    summary         = spict_series(fit),
    state           = sumspict.states(fit),
    drefpoints      = sumspict.drefpoints(fit),
    srefpoints      = sumspict.srefpoints(fit),
    manTable        = man_table,
    risk            = spictRisk(fit),
    diagnostics     = checks
  )
}

#' The per-year series the summary object carries
#'
#' Kept separate so the columns the downstream documents rely on — `year`, `total_catch`,
#' `index`, the `BBmsy.*` and `FFmsy.*` triplets, and `Catch_pred.est` — are assembled in one
#' place. Changing a column name here means changing it in all three documents.
#'
#' @param fit A fitted SPiCT object.
#' @return A data frame of the annual series.
spict_series <- function(fit) {
  bb <- get.par("logBBmsy", fit, exp = FALSE)
  ff <- get.par("logFFmsy", fit, exp = FALSE)

  out <- data.frame(
    year      = as.numeric(rownames(bb)),
    BBmsy.ll  = bb[, 1], BBmsy.est = bb[, 2], BBmsy.ul = bb[, 3]
  )
  ff_df <- data.frame(
    year      = as.numeric(rownames(ff)),
    FFmsy.ll  = ff[, 1], FFmsy.est = ff[, 2], FFmsy.ul = ff[, 3]
  )
  out <- merge(out, ff_df, by = "year", all = TRUE)

  catches <- data.frame(year = fit$inp$timeC, total_catch = fit$inp$obsC)
  index   <- data.frame(year = floor(fit$inp$timeI[[1]]), index = fit$inp$obsI[[1]])

  # Predicted catch, used by the advice sheet for the intermediate year.
  #
  # `get.par("logCpred", ...)` labels every row "logCpred" rather than with a time, so the
  # times come from `inp$timeCpred`, which is the catch-interval grid the predictions are on.
  # Intervals are summed within a year: a sub-annual grid would otherwise report one interval's
  # catch as the year's.
  cpred_par <- get.par("logCpred", fit, exp = TRUE)
  times <- fit$inp$timeCpred
  if (length(times) != nrow(cpred_par)) {
    stop(
      "logCpred has ", nrow(cpred_par), " rows but inp$timeCpred has ", length(times),
      " times; cannot align predicted catches to years.",
      call. = FALSE
    )
  }
  cpred <- aggregate(
    Catch_pred.est ~ year,
    data = data.frame(year = floor(times), Catch_pred.est = cpred_par[, 2]),
    FUN = sum
  )

  out <- merge(out, catches, by = "year", all.x = TRUE)
  out <- merge(out, index, by = "year", all.x = TRUE)
  out <- merge(out, cpred, by = "year", all.x = TRUE)
  out[order(out$year), ]
}

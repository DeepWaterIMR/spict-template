# spict_exploration.R — comparing candidate SPiCT fits.
#
# Tidying parameters across several fits, building cross-model comparison tables, and plotting
# them. Used by R/explore_compare.R, the exploration documents, and the Shiny explorer; not by
# the production assessment.
#
# Source this after R/0_setup.R.

ensure_packages("spict")


#' Extract a tidy parameter table from a single SPiCT fit
#'
#' Pulls a configurable set of parameters out of a SPiCT fit object and
#' returns them in long format with a `var` column, ready for binding across
#' models in `comp_df()`.
#'
#' For variables whose name starts with `"log"`, `take_logs = TRUE` returns
#' the back-transformed (exponentiated) value; `take_logs = FALSE` keeps
#' them on the log scale. Variables not starting with `"log"` are always
#' returned as-is.
#'
#' If `"logCpred"` or `"logIpred"` is among the requested variables, a
#' `time` column is appended using `inp$timeC` or `inp$timeI[[1]]`
#' respectively.
#'
#' @param m A fitted SPiCT object.
#' @param variables Character vector of parameter names. Defaults to the
#'   reference-point and final-year set commonly compared across runs.
#' @param take_logs Logical. If `TRUE` (default), back-transform `log*`
#'   parameters via `exp = TRUE`.
#'
#' @return A data frame with one row per parameter × time index, including
#'   confidence-interval columns from `get.par()`.
params_df <- function(
  m,
  variables = c(
    'logFmsy',
    'logBmsy',
    "logMSY",
    "logFl",
    "logBl",
    "logCp",
    "logFlFmsy",
    "logBlBmsy",
    "logK"
  ),
  take_logs = TRUE
) {
  c_p_df <- map_dfr(variables, function(.v) {
    if (take_logs == TRUE) {
      if (substr(.v, 1, 3) == "log") {
        v_df <- as.data.frame(get.par(.v, m, exp = TRUE))
      } else {
        v_df <- as.data.frame(get.par(.v, m, exp = FALSE))
      }
    } else {
      if (substr(.v, 1, 3) == "log") {
        v_df <- as.data.frame(get.par(.v, m, exp = FALSE))
      } else {
        v_df <- as.data.frame(get.par(.v, m, exp = FALSE))
      }
    }

    v_df$var <- .v

    v_df
  })

  if ("logCpred" %in% variables) {
    c_p_df$time <- seq(min(m$inp$timeC), max(m$inp$timeC) + 1)
  } else if ("logIpred" %in% variables) {
    c_p_df$time <- seq(min(m$inp$timeI[[1]]), max(m$inp$timeI[[1]]))
  }

  rownames(c_p_df) <- NULL

  return(c_p_df)
}

#' Round a numeric for display, with magnitude-aware significant figures
#'
#' Below 1 → 2 sig figs, below 100 → 3 sig figs, otherwise rounded to the
#' nearest integer. NA stays NA.
#'
#' @param number Numeric (or coercible). Vectorised over `case_when` rules.
#' @return Numeric of the same length as `number`.
round_est <- function(number) {
  number <- as.numeric(number)
  case_when(
    is.na(number) ~ NA_real_,
    number < 1 ~ signif(number, 2),
    number < 100 ~ signif(number, 3),
    TRUE ~ round(number, 0)
  )
}

#' Strip a leading "log" from a parameter name for display
#'
#' Used to label facet panels in `comp_plot()` so users see e.g. `"Fmsy"`
#' instead of `"logFmsy"`.
#'
#' @param var_name Character.
#' @return Character with the first three characters removed if they were
#'   `"log"`, otherwise the unchanged input.
edit_var_name <- function(var_name) {
  if (substr(var_name, 1, 3) == "log") {
    var_label <- substring(var_name, 4)
  } else {
    var_label <- var_name
  }
}

#' Combine parameter tables from many SPiCT fits into one tidy frame
#'
#' Loops over a named list of SPiCT fits, calls `params_df()` on each, and
#' annotates each row with the model name pulled from
#' `attributes(m)$model_name`. Adds an integer `x` axis position and a
#' per-facet `y_nudge` (2% of panel range) used by `comp_plot()` to space
#' point labels.
#'
#' @param ms A named list of fitted SPiCT objects. Each must have a
#'   `model_name` attribute.
#' @param variables Character vector passed to `params_df()`.
#' @param take_logs Logical, passed to `params_df()`.
#'
#' @return A data frame ready for `comp_plot()`.
comp_df <- function(
  ms,
  variables = c(
    'logFmsy',
    'logBmsy',
    "logMSY",
    "logFl",
    "logBl",
    "logCp",
    "logFlFmsy",
    "logBlBmsy",
    "logK"
  ),
  take_logs = TRUE
) {
  ms_df <- map_dfr(ms, function(m) {
    m_df <- params_df(m, variables, take_logs)
    m_df$m <- attributes(m)$model_name
    m_df
  })

  ms_df <- ms_df %>%
    rowwise() %>%
    mutate(
      label_est = as.character(round_est(est)),
      label_var = edit_var_name(var),
      label_m = m
    ) %>%
    ungroup() %>%
    mutate(
      x = as.integer(factor(m, levels = unique(m))),
      label_m = factor(label_m, levels = unique(label_m))
    )

  facet_nudge <- ms_df %>%
    group_by(var) %>%
    summarise(
      y_min = min(ll, na.rm = TRUE),
      y_max = max(ul, na.rm = TRUE),
      y_nudge = 0.02 * (y_max - y_min),
      .groups = "drop"
    )

  ms_df <- ms_df %>% left_join(facet_nudge %>% select(var, y_nudge), by = "var")

  return(ms_df)
}


#' Faceted error-bar comparison of estimates across SPiCT fits
#'
#' Given a list of fits, produces one facet per parameter with model name on
#' the x-axis and estimate ± 95% CI on the y-axis. Estimates are also drawn
#' as text next to each point.
#'
#' @param ms A named list of SPiCT fits.
#' @param variables Character vector passed through to `comp_df()`.
#' @param env Logical. If `TRUE`, also `print()` the plot as a side effect.
#'
#' @return A `ggplot` object.
comp_plot <- function(
  ms,
  variables = c(
    'logFmsy',
    'logBmsy',
    "logMSY",
    "logFl",
    "logBl",
    "logCp",
    "logFlFmsy",
    "logBlBmsy",
    "logK"
  ),
  env = F
) {
  ms_df <- comp_df(ms, variables)

  p <- ggplot(ms_df, aes(x = x, y = est, color = label_m)) +
    geom_errorbar(aes(ymin = ll, ymax = ul), width = 0.15) +
    geom_point(size = 3) +
    geom_text(
      aes(y = est + y_nudge, label = label_est, x = x + 0.1),
      size = 3,
      hjust = 0,
      vjust = 0.5,
      show.legend = F
    ) +
    facet_wrap(~label_var, scales = "free_y") +
    labs(color = "Model") +
    scale_x_discrete() +
    labs(x = NULL, y = NULL) +
    theme_minimal()

  if (env) {
    plot(p)
  }

  return(p)
}


#' Build a long-format predicted-vs-observed frame for catches or indices
#'
#' Calls `params_df()` on each fit to extract predicted catches (`logCpred`)
#' or index (`logIpred`), then prepends one row of observed data per time
#' point so the observed series shows up alongside model predictions when
#' faceted. The first model in `ms` defines the time vector for observed.
#'
#' @param ms A named list of SPiCT fits.
#' @param variables Length-1 character. Either `"logCpred"` (catches) or
#'   `"logIpred"` (index 1). Other values silently fall through with no
#'   observed rows added.
#'
#' @return A data frame with `time`, `var`, `est`, `m`, and (for predicted
#'   rows) confidence-interval columns.
obs_fit_comp <- function(ms, variables = c("logCpred")) {
  ms_preds_df <- map_dfr(ms, function(m) {
    m_df <- params_df(m, variables)
    m_df$m <- attributes(m)$model_name
    m_df
  })

  if (variables == c("logCpred")) {
    obs_df <- data.frame(
      time = ms[[1]]$inp$timeC,
      var = "logCpred",
      est = ms[[1]]$inp$obsC,
      m = "C_obs"
    )
  } else if (variables == c("logIpred")) {
    obs_df <- data.frame(
      time = ms[[1]]$inp$timeI[[1]],
      var = "logIpred",
      est = ms[[1]]$inp$obsI[[1]],
      m = "I_obs"
    )
  }

  ms_preds_obs_df <- bind_rows(obs_df, ms_preds_df)

  return(ms_preds_obs_df)
}

#' Predicted-vs-observed plot across SPiCT fits
#'
#' Wraps `obs_fit_comp()` and overlays observations (orange points) with
#' per-model predictions (lines + 10% confidence ribbon). Useful for
#' comparing how well alternative SPiCT runs reproduce the observed catch
#' or index series.
#'
#' @param ms A named list of SPiCT fits.
#' @param variables Length-1 character; `"logCpred"` or `"logIpred"`.
#' @param env Logical. If `TRUE`, `print()` the plot as a side effect.
#'
#' @return A `ggplot` object.
comp_plot2 <- function(ms, variables = c("logCpred"), env = FALSE) {
  ms_df <- obs_fit_comp(ms, variables)

  preds_df <- ms_df %>% filter(substr(m, 3, 5) != "obs")
  obs_df <- ms_df %>% filter(substr(m, 3, 5) == "obs")

  p <- ggplot() +
    geom_point(
      data = obs_df,
      aes(x = time, y = est),
      color = "orange",
      size = 3
    ) +
    geom_line(data = preds_df, aes(x = time, y = est, color = m)) +
    geom_point(data = preds_df, aes(x = time, y = est, color = m)) +
    geom_ribbon(
      data = preds_df,
      aes(x = time, ymin = ll, ymax = ul, color = NULL, fill = m),
      alpha = 0.1,
      show.legend = F
    ) +
    labs(y = variables, x = "", color = "Model", fill = NA) +
    theme_minimal()

  if (env) {
    plot(p)
  }

  return(p)
}

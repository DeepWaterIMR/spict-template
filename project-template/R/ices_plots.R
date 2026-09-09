# ices_plots.R — the three-panel stock summary figure used on page one of the advice sheet.
#
# Source this after R/0_setup.R and R/advice_tables.R.

ensure_packages("cowplot")

#' ICES-style stock summary plot
#'
#' The figure that opens an advice sheet: total catches as bars, relative fishing pressure
#' with its confidence ribbon, and relative exploitable biomass with its confidence ribbon.
#' Catches in the two most recent years are drawn in a lighter colour, because they are
#' preliminary.
#'
#' Reference lines are drawn at F/F[MSY] = 1, and at MSY B[trigger] and B[lim] as configured
#' in `config.yaml`. F[lim] is deliberately omitted from the F panel: ICES advice sheets do not
#' show it, and drawing it invites a reader to compare against a point the advice does not use.
#'
#' The x-axis spans the catch series, so a stock with a long reconstructed history and one with
#' thirty years of data both get sensible breaks.
#'
#' @param x A SPiCT summary object — the contents of
#'   `data/output/<stock>_spict_summary_<year>.rds`. Needs `summary` (with `year`,
#'   `total_catch`, and the `BBmsy.*` and `FFmsy.*` triplets) and `assessment_year`.
#' @param lang `"eng"` (default) or `"nor"`. Switches axis labels and panel titles.
#' @param blim B/B[MSY] value of B[lim]. Defaults to `cfg$BLIM_BMSY`.
#' @param btrigger B/B[MSY] value of MSY B[trigger]. Defaults to `cfg$BTRIGGER_BMSY`.
#'
#' @return A cowplot grid of three ggplot panels, ready to print.
summary_plot <- function(x,
                         lang = "eng",
                         blim = cfg$BLIM_BMSY %||% 0.3,
                         btrigger = cfg$BTRIGGER_BMSY %||% 0.5) {

  stopifnot(is.list(x), !is.null(x$summary), !is.null(x$assessment_year))

  ices_theme <- theme_advice(8)

  df <- x$summary |>
    dplyr::filter(year <= x$assessment_year) |>
    dplyr::transmute(
      year,
      FMSY = 1,
      `MSY Btrigger` = btrigger,
      BLim = blim,
      F = exp(FFmsy.est),
      SSB = exp(BBmsy.est),
      F_low = exp(FFmsy.ll),
      F_up = exp(FFmsy.ul),
      SSB_low = exp(BBmsy.ll),
      SSB_up = exp(BBmsy.ul),
      total_catch
    ) |>
    dplyr::as_tibble()

  # Anchor the axis on the catch series rather than a fixed year, so the plot works for a
  # stock with a reconstructed history back to the 1910s and for one starting in 1990.
  first_year <- min(df$year[!is.na(df$total_catch)], na.rm = TRUE)
  span <- x$assessment_year - first_year
  catch_break <- if (span > 60) 10 else 5
  panel_break <- if (span > 60) 20 else 10

  p1 <- ggplot2::ggplot() +
    ggplot2::geom_col(
      data = dplyr::filter(df, !is.na(total_catch), year < (x$assessment_year - 1)),
      ggplot2::aes(year, total_catch / 1e3),
      fill = "#002b5f"
    ) +
    ggplot2::geom_col(
      data = dplyr::filter(df, !is.na(total_catch), year >= (x$assessment_year - 1)),
      ggplot2::aes(year, total_catch / 1e3),
      fill = "#548cab", alpha = 0.6
    ) +
    ggplot2::scale_x_continuous(
      breaks = seq(first_year, x$assessment_year, catch_break),
      expand = ggplot2::expansion(c(0.01))
    ) +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(c(0, 0.01))) +
    ggplot2::labs(
      y = ifelse(lang == "eng", "Catches (kt)", "Fangst i 1000 tonn"),
      title = ifelse(lang == "eng", "Total catch", "Totalfangst")
    ) +
    ices_theme +
    ggplot2::theme(title = ggplot2::element_text(color = "#002b5f", face = "bold"))

  p2 <- df |>
    dplyr::filter(!is.na(total_catch)) |>
    ggplot2::ggplot() +
    ggplot2::geom_ribbon(ggplot2::aes(year, ymin = F_low, ymax = F_up), fill = "#f2a497") +
    ggplot2::geom_line(ggplot2::aes(year, F), linewidth = 0.5, color = "#ed5f26") +
    ggplot2::geom_line(
      ggplot2::aes(x = year, y = FMSY, linetype = "FMSY", colour = "FMSY")
    ) +
    ggplot2::scale_color_manual(values = "black", labels = expression("F"[MSY])) +
    ggplot2::scale_linetype_manual(values = 1, labels = expression("F"[MSY])) +
    ggplot2::scale_x_continuous(
      breaks = seq(first_year, x$assessment_year, panel_break),
      expand = ggplot2::expansion(c(0.01))
    ) +
    ggplot2::scale_y_continuous(limits = c(0, NA), expand = ggplot2::expansion(c(0, 0.05))) +
    ggplot2::labs(
      y = expression(bold(F / F[MSY])),
      title = ifelse(lang == "eng", "Fishing mortality", "Fiskedødelighet"),
      linetype = "", colour = ""
    ) +
    ices_theme +
    ggplot2::theme(
      legend.position = "bottom",
      plot.title = ggplot2::element_text(color = "#ed5f26", face = "bold")
    )

  p3 <- ggplot2::ggplot(df) +
    ggplot2::geom_ribbon(
      ggplot2::aes(year, ymin = SSB_low, ymax = SSB_up), fill = "#047c6c", alpha = 0.5
    ) +
    ggplot2::geom_line(ggplot2::aes(year, SSB), linewidth = 0.5, color = "#047c6c") +
    ggplot2::geom_line(ggplot2::aes(
      x = year, y = `MSY Btrigger`, linetype = "MSY Btrigger", colour = "MSY Btrigger"
    )) +
    ggplot2::geom_line(ggplot2::aes(x = year, y = BLim, linetype = "BLim", colour = "BLim")) +
    ggplot2::scale_color_manual(
      values = c("black", "blue"),
      labels = c(expression("B"[lim]), expression("MSY B"[trigger]))
    ) +
    ggplot2::scale_linetype_manual(
      values = c(2, 1),
      labels = c(expression("B"[lim]), expression("MSY B"[trigger]))
    ) +
    ggplot2::scale_x_continuous(
      breaks = seq(first_year, x$assessment_year, panel_break),
      expand = ggplot2::expansion(c(0.01))
    ) +
    ggplot2::scale_y_continuous(limits = c(0, NA), expand = ggplot2::expansion(c(0, 0.05))) +
    ggplot2::labs(
      y = expression(bold(B / B[MSY])),
      title = ifelse(lang == "eng", "Biomass", "Biomasse"),
      linetype = "", colour = ""
    ) +
    ices_theme +
    ggplot2::theme(
      legend.position = "bottom",
      plot.title = ggplot2::element_text(color = "#047c6c", face = "bold")
    )

  cowplot::plot_grid(p1, cowplot::plot_grid(p2, p3, ncol = 2), nrow = 2)
}

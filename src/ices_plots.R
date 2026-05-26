#' ICES-style summary plot for the SPiCT golden-redfish assessment
#'
#' Builds the three-panel figure shown on page 1 of the ICES advice sheet:
#' total catches as bars (top), F/F[MSY] with confidence ribbon (bottom-left),
#' and B/B[MSY] with confidence ribbon (bottom-right). The most-recent year of
#' catch is rendered in a lighter colour to flag that it is preliminary.
#'
#' Reference lines are drawn for F[MSY] = 1, MSY B-trigger = 0.5, and
#' B[lim] = 0.3. F[lim] is intentionally omitted from the F panel.
#'
#' Axis ranges are anchored at year 1915 (the earliest plausible catch
#' record) and extended to `x$assessment_year`. Adjust those constants in
#' the `seq()` calls if your stock has a longer history.
#'
#' @param x A SPiCT summary object (e.g. the contents of
#'   `data/model_output/spict_summaries/sum_<stock>_spict_<year>.rds`). Must
#'   contain `summary` (data frame with `year`, `total_catch`, and the four
#'   `BBmsy.*` / `FFmsy.*` columns) and `assessment_year` (numeric).
#' @param lang Either `"eng"` (default) or `"nor"`. Switches axis labels and
#'   panel titles between English and Norwegian.
#'
#' @return A `cowplot` grid of three `ggplot` panels, ready to print.
summary_plot <- function(x = spict_summary, lang = "eng") {
  ices_theme <- theme_bw(8) +
    theme(
      axis.title.y = element_text(face = "bold"),
      axis.title.x = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.grid.minor.x = element_blank(),
      panel.grid.minor.y = element_blank(),
      strip.background = element_blank(),
      panel.background = element_blank(),
      plot.background = element_blank(),
      legend.background = element_blank(),
      legend.box.background = element_blank(),
      plot.margin = margin(t = 3, r = 3, b = 3, l = 3, unit = "pt")
    )

  df <- x$summary %>%
    filter(year %in% c(1914:x$assessment_year)) %>%
    transmute(
      year = year,
      FMSY = 1,
      FLim = 1.7,
      `MSY Btrigger` = .5,
      BLim = .3,
      F = exp(FFmsy.est),
      SSB = exp(BBmsy.est),
      F_low = exp(FFmsy.ll),
      F_up = exp(FFmsy.ul),
      SSB_low = exp(BBmsy.ll),
      SSB_up = exp(BBmsy.ul),
      total_catch
    ) %>%
    as_tibble()

  p1 <- ggplot() +
    geom_col(
      data = df %>% filter(!is.na(total_catch), year < (x$assessment_year - 1)),
      aes(year, total_catch / 1e3),
      fill = "#002b5f"
    ) +
    geom_col(
      data = df %>% filter(year >= (x$assessment_year - 1)),
      aes(year, total_catch / 1e3),
      fill = "#548cab",
      alpha = .6
    ) +
    scale_x_continuous(
      breaks = seq(1915, x$assessment_year, 5),
      expand = expansion(c(0.01))
    ) +
    scale_y_continuous(expand = expansion(c(0, 0.01))) +
    labs(
      y = ifelse(lang == "eng", "Catches (kt)", "Fangst i 1000 tonn"),
      title = ifelse(lang == "eng", "Total catch", "Totalfangst")
    ) +
    ices_theme +
    theme(title = element_text(color = "#002b5f", face = "bold"))

  p2 <- df %>%
    filter(!is.na(total_catch)) %>%
    ggplot() +
    geom_ribbon(aes(year, ymin = F_low, ymax = F_up), fill = "#f2a497") +
    geom_line(
      aes(year, F),
      linewidth = 0.5,
      color = "#ed5f26",
      show.legend = FALSE
    ) +
    geom_line(aes(x = year, y = FMSY, linetype = "FMSY", colour = "FMSY")) +
    scale_color_manual(
      values = c("black"),
      labels = c(expression('F'[MSY]))
    ) +
    scale_linetype_manual(
      values = c(1),
      labels = c(expression('F'[MSY]))
    ) +
    scale_x_continuous(
      breaks = seq(1915, x$assessment_year, 10),
      expand = expansion(c(0.01))
    ) +
    scale_y_continuous(limits = c(0, NA), expand = expansion(c(0, 0.05))) +
    labs(
      y = expression(bold(F / F[MSY])),
      title = ifelse(lang == "eng", "Fishing mortality", "Fiskedødelighet"),
      linetype = "",
      colour = ""
    ) +
    ices_theme +
    theme(
      legend.position = "bottom",
      plot.title = element_text(color = "#ed5f26", face = "bold")
    )

  p3 <- df %>%
    ggplot() +
    geom_ribbon(
      aes(year, ymin = SSB_low, ymax = SSB_up),
      fill = "#047c6c",
      alpha = 0.5
    ) +
    geom_line(aes(year, SSB), linewidth = 0.5, color = "#047c6c") +
    geom_line(aes(
      x = year,
      y = `MSY Btrigger`,
      linetype = "MSY Btrigger",
      colour = "MSY Btrigger"
    )) +
    geom_line(aes(x = year, y = BLim, linetype = "BLim", colour = "BLim")) +
    scale_color_manual(
      values = c("black", "blue"),
      labels = c(expression('B'[lim]), expression('MSY B'[trigger]))
    ) +
    scale_linetype_manual(
      values = c(2, 1),
      labels = c(expression('B'[lim]), expression('MSY B'[trigger]))
    ) +
    scale_x_continuous(
      breaks = seq(1915, x$assessment_year, 10),
      expand = expansion(c(0.01))
    ) +
    scale_y_continuous(
      limits = c(0, NA),
      expand = expansion(c(0, 0.05))
    ) +
    labs(
      y = expression(bold(B / B[MSY])),
      title = ifelse(lang == "eng", "Biomass", "Biomasse"),
      linetype = "",
      colour = ""
    ) +
    ices_theme +
    theme(
      legend.position = "bottom",
      plot.title = element_text(color = "#047c6c", face = "bold")
    )

  cowplot::plot_grid(p1, cowplot::plot_grid(p2, p3, ncol = 2), nrow = 2)
}

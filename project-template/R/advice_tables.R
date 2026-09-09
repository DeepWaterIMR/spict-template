# advice_tables.R — tables and figure styling for the advice sheet and the working-group
# chapter.
#
# Two problems this file solves. First, the same data has to render as a table in HTML, Word,
# and LaTeX, and the three want different objects — `make_table()` dispatches. Second, an ICES
# advice sheet has a house table style (grey header, thin black rules, Calibri 9, fitted to the
# page width) and reference points that must appear as real subscripts rather than "Bmsy" —
# `ices_ft()` and the compose idiom below handle that.
#
# Source this after R/0_setup.R.

ensure_packages("officer", "icesAdvice")

# --- Page geometry -------------------------------------------------------------------------
# The ICES advice template's text column. Tables wider than this are silently clipped by Word
# rather than reflowed, so every advice-sheet table is fitted to it explicitly.
page_width_in <- 6.7

#' Detect the current knitr output target
#'
#' Reads `knitr::opts_knit$get("rmarkdown.pandoc.to")`. When it is missing — running
#' interactively, outside knitr — `"html"` is assumed so downstream code still has a branch.
#'
#' @return A length-1 character: usually `"html"`, `"docx"`, or `"latex"`.
output_type <- function() {
  out <- knitr::opts_knit$get("rmarkdown.pandoc.to")
  if (length(out) == 0) "html" else out
}

# --- The ICES advice-sheet table idiom ------------------------------------------------------

#' Fit a flextable to the page width
#'
#' Scales the existing column widths proportionally so their total is `max_width`, then fixes
#' the layout. Called at the end of a chain, after any explicit `width()` calls, so the
#' relative widths the author chose are preserved while the total fits the page.
#'
#' @param ft A flextable.
#' @param max_width Target total width in inches.
#' @return The flextable, fitted.
fit_ft_page <- function(ft, max_width = page_width_in) {
  col_widths <- ft$body$colwidths
  total <- sum(col_widths)
  if (length(total) == 1 && is.finite(total) && total > 0) {
    ft <- flextable::width(ft, j = seq_along(col_widths), width = col_widths * max_width / total)
  }
  flextable::set_table_properties(ft, layout = "fixed", width = 1)
}

#' Apply the ICES advice-sheet table style
#'
#' Grey header, thin inner rules and a heavier outer rule, Calibri 9, centred header, tight
#' padding, fitted to the page. Use it as the last styling step before any column-specific
#' alignment or width.
#'
#' @param ft A flextable.
#' @return The styled flextable.
ices_ft <- function(ft) {
  ft |>
    flextable::bg(bg = "#E8EAEA", part = "header") |>
    flextable::border_inner(officer::fp_border(color = "black", width = 0.5)) |>
    flextable::border_outer(officer::fp_border(color = "black", width = 0.75)) |>
    flextable::font(fontname = "Calibri", part = "all") |>
    flextable::fontsize(size = 9, part = "all") |>
    flextable::align(align = "center", part = "header") |>
    flextable::padding(padding = 2, part = "all") |>
    flextable::autofit() |>
    fit_ft_page()
}

#' A two-column "item / description" table, as ICES uses for the basis blocks
#'
#' *Basis of the advice*, *Basis of the assessment*, and the management-plan block are all this
#' shape: no header row, a bold grey label column, and a wide description column.
#'
#' @param x A two-column data frame. The first column is the label.
#' @param label_width Width of the label column in inches.
#' @return A flextable.
ices_basis_ft <- function(x, label_width = 1.6) {
  stopifnot(ncol(x) == 2)
  flextable::flextable(x) |>
    flextable::delete_part(part = "header") |>
    flextable::bg(j = 1, bg = "#E8EAEA", part = "body") |>
    flextable::border_inner(officer::fp_border(color = "black", width = 0.5)) |>
    flextable::border_outer(officer::fp_border(color = "black", width = 0.75)) |>
    flextable::font(fontname = "Calibri", part = "all") |>
    flextable::fontsize(size = 9, part = "all") |>
    flextable::align(align = "left", part = "body") |>
    flextable::bold(j = 1, part = "body") |>
    flextable::width(j = 1, width = label_width) |>
    flextable::width(j = 2, width = page_width_in - label_width) |>
    fit_ft_page()
}

#' Compose a reference-point label with a real subscript
#'
#' Word and HTML both need `B~MSY~` rendered as a subscript, and flextable will not read
#' markdown inside a cell. This wraps the `as_paragraph()` / `as_sub()` idiom so a caller
#' writes `ref_point("B", "MSY")` instead of five lines.
#'
#' @param base The symbol, e.g. `"B"` or `"F"`.
#' @param sub The subscript, e.g. `"MSY"`, `"lim"`, or a year.
#' @param over Optional denominator symbol, giving `B/B[MSY]` rather than `B[MSY]`.
#' @return A flextable paragraph, for use in `flextable::compose(value = ...)`.
ref_point <- function(base, sub, over = NULL) {
  if (is.null(over)) {
    flextable::as_paragraph(base, flextable::as_sub(as.character(sub)))
  } else {
    flextable::as_paragraph(
      base, "/", over, flextable::as_sub(as.character(sub))
    )
  }
}

#' Round the way the advice framework rounds
#'
#' Thin wrapper on `icesAdvice::icesRound()` so the sheet's numbers match what goes into the
#' ICES advice database. Use it for every ratio the framework rounds; use [fmt()] from
#' `report_helpers.R` for tonnages.
#'
#' @param x Numeric vector.
#' @return A character vector.
ices_round <- function(x) {
  vapply(x, function(v) if (is.na(v)) "–" else icesAdvice::icesRound(v), character(1))
}

# --- The advice-sheet ggplot theme -----------------------------------------------------------

#' The advice-sheet figure theme
#'
#' Small type, no vertical grid, bold y-axis titles, no axis title on x. Advice-sheet figures
#' are printed at roughly a third of a page, so the base size is well below the project's
#' `theme_bw(base_size = 12)` default.
#'
#' @param base_size Base font size.
#' @return A ggplot2 theme.
theme_advice <- function(base_size = 8) {
  ggplot2::theme_bw(base_size) +
    ggplot2::theme(
      axis.title.y = ggplot2::element_text(face = "bold"),
      axis.title.x = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor.x = ggplot2::element_blank(),
      panel.grid.minor.y = ggplot2::element_blank(),
      strip.background = ggplot2::element_blank(),
      panel.background = ggplot2::element_blank(),
      plot.background = ggplot2::element_blank(),
      legend.background = ggplot2::element_blank(),
      legend.box.background = ggplot2::element_blank(),
      plot.margin = ggplot2::margin(t = 3, r = 5, b = 3, l = 3, unit = "pt")
    )
}

#' Set the flextable defaults the advice sheet expects
#'
#' Call once in a document's setup chunk. A thin space as the thousands mark is the SI
#' convention and matches `fmt()` in `report_helpers.R`.
set_advice_table_defaults <- function() {
  flextable::set_flextable_defaults(
    font.family = "Calibri",
    font.size = 9,
    table.layout = "fixed",
    border.color = "black",
    background.color = "white",
    big.mark = " ",
    decimal.mark = ".",
    padding = 2
  )
  invisible(NULL)
}

# --- Cross-format tables for the data reports -------------------------------------------------

#' Render a data frame as a table in the active output format
#'
#' Dispatches on [output_type()]: HTML uses `knitr::kable()` with kableExtra styling, Word uses
#' flextable, and anything else falls through to a LaTeX `kable` with booktabs and longtable.
#' The same data and caption flow through all three branches, so a caller does not special-case
#' the format.
#'
#' Use this in the data reports. The advice sheet builds its tables explicitly, because each
#' one has its own subscripts, merged cells, and footnotes.
#'
#' @param tmp A data frame or tibble.
#' @param caption Table caption.
#' @param digits Decimal places for numeric columns.
#' @param font_size Font size, used in Word output only.
#' @param escape Passed to `knitr::kable()`. `FALSE` keeps pre-formatted HTML or LaTeX.
#'
#' @return A kable or a flextable, depending on the output target. Print as-is in a chunk.
make_table <- function(tmp, caption = "", digits = 0, font_size = 10, escape = TRUE) {
  if (output_type() == "html") {
    knitr::kable(
      tmp,
      caption = caption,
      format.args = list(big.mark = ""),
      digits = digits,
      row.names = FALSE,
      escape = escape
    ) |>
      kableExtra::kable_styling(bootstrap_options = c("striped", "condensed"))
  } else if (output_type() == "docx") {
    flextable::flextable(tmp) |>
      flextable::fontsize(size = font_size, part = "all") |>
      flextable::set_caption(caption = caption) |>
      flextable::align_nottext_col(align = "center") |>
      flextable::align_text_col(align = "left") |>
      flextable::colformat_int(big.mark = "", na_str = "") |>
      flextable::colformat_double(big.mark = "", digits = digits, na_str = "") |>
      flextable::theme_booktabs() |>
      fit_ft_page()
  } else {
    knitr::kable(
      tmp,
      format = "latex",
      caption = caption,
      booktabs = TRUE,
      longtable = TRUE,
      row.names = FALSE,
      escape = escape,
      format.args = list(big.mark = ""),
      digits = digits
    ) |>
      kableExtra::kable_styling(latex_options = c("striped", "hold_position"))
  }
}

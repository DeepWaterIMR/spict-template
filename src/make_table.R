# ─────────────────────────────────────────────────────────────────────────────
# Cross-format table helper: chooses kableExtra (HTML/LaTeX) or flextable
# (DOCX) based on the active Pandoc output target.
# ─────────────────────────────────────────────────────────────────────────────

packages <- c("knitr", "kableExtra", "flextable")

installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

invisible(lapply(packages, function(x) {
  suppressPackageStartupMessages(library(x, character.only = TRUE))
}))

#' Detect the current knitr output target
#'
#' Reads `knitr::opts_knit$get("rmarkdown.pandoc.to")` to identify whether
#' the document is currently rendering to HTML, DOCX, LaTeX, etc. When the
#' value is missing (e.g. running interactively outside knitr), defaults to
#' `"html"` so downstream code still has a sensible branch to take.
#'
#' @return A length-1 character: typically `"html"`, `"docx"`, or
#'   `"latex"`.
output_type <- function() {
  out <- knitr::opts_knit$get("rmarkdown.pandoc.to")
  if (length(out) == 0) "html" else out
}

#' Render a data frame as a table in the active output format
#'
#' Dispatches on `output_type()`: HTML uses `knitr::kable` +
#' `kableExtra::kable_styling`; DOCX uses `flextable` with auto-fit; any
#' other format falls through to a LaTeX `kable` with `booktabs` and
#' `longtable`. The same data and caption flow through all branches so
#' callers don't need to special-case format.
#'
#' @param tmp A data frame (or tibble) to render.
#' @param caption Character. Table caption.
#' @param digits Integer. Decimal places for numeric columns.
#' @param font_size Numeric. Font size used in DOCX output only.
#' @param escape Logical. Passed through to `knitr::kable`. Set to `FALSE`
#'   if the data contains pre-formatted HTML/LaTeX you want to keep.
#'
#' @return A `kable`/`kableExtra` object or a `flextable` object,
#'   depending on the output target. Print as-is in a knitr chunk.
make_table <- function(
  tmp,
  caption = "",
  digits = 0,
  font_size = 10,
  escape = TRUE
) {
  if (output_type() == "html") {
    knitr::kable(
      tmp,
      caption = caption,
      format.args = list(big.mark = ""),
      digits = digits,
      row.names = FALSE,
      escape = escape
    ) %>%
      kableExtra::kable_styling(bootstrap_options = c("striped", "condensed"))
  } else if (output_type() == "docx") {
    FitFlextableToPage <- function(ft, pgwidth = 6) {
      ft_out <- ft %>%
        flextable::set_table_properties(layout = "autofit") %>%
        flextable::autofit()
      ft_out <- flextable::width(
        ft_out,
        width = dim(ft_out)$widths * pgwidth / (flextable::flextable_dim(ft_out)$widths)
      )
      return(ft_out)
    }

    flextable::flextable(tmp) %>%
      flextable::fontsize(size = font_size, part = "all") %>%
      flextable::set_caption(caption = caption) %>%
      flextable::align_nottext_col(align = "center") %>%
      flextable::align_text_col(align = "left") %>%
      flextable::colformat_int(big.mark = "", na_str = "") %>%
      flextable::colformat_double(
        big.mark = "",
        digits = digits,
        na_str = ""
      ) %>%
      flextable::theme_booktabs()
  } else {
    tmp %>%
      knitr::kable(
        format = "latex",
        caption = caption,
        booktabs = TRUE,
        longtable = TRUE,
        row.names = FALSE,
        escape = escape,
        format.args = list(big.mark = ""),
        digits = digits
      ) %>%
      kableExtra::kable_styling(latex_options = c("striped", "hold_position"))
  }
}

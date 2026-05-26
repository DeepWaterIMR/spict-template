# ─────────────────────────────────────────────────────────────────────────────
# Master runner for the {{STOCK_NAME}} SPiCT assessment.
#
# Renders the two production Quarto documents in order, parameterised
# with the assessment / advice year, and copies the rendered deliverables
# into `docs/assessment/<assessment_year>/`.
#
# Run from the project root:
#
#   source("run_assessment.R")                                  # uses defaults
#   run_assessment()                                            # same
#   run_assessment(assessment_year = {{ASSESSMENT_YEAR}} + 1)   # next year's run
#   run_assessment(assessment_year = ..., advice_year = ...)    # override +1
#
# NOTE: This is an EXPLORATORY assessment — not official {{WORKING_GROUP}} advice.
# ─────────────────────────────────────────────────────────────────────────────

library(quarto)

run_assessment <- function(
  assessment_year = {{ASSESSMENT_YEAR}},
  advice_year = assessment_year + 1,
  prev_advice_year = {{PREV_ADVICE_YEAR}}
) {
  stopifnot(
    is.numeric(assessment_year),
    is.numeric(advice_year),
    advice_year > assessment_year
  )

  out_dir <- file.path("docs", "assessment", assessment_year)
  if (!dir.exists(out_dir)) {
    dir.create(out_dir, recursive = TRUE)
  }

  docs <- list(
    list(
      input = "1 assessment model.qmd",
      params = list(
        assessment_year = assessment_year,
        advice_year = advice_year,
        prev_advice_year = prev_advice_year
      ),
      outputs = c(
        "{{STOCK_NAME}} assessment model.html",
        "{{STOCK_NAME}} assessment model.pdf"
      )
    ),
    list(
      input = "2 advice sheet.qmd",
      params = list(
        assessment_year = assessment_year,
        advice_year = advice_year
      ),
      outputs = "{{STOCK_NAME}} advice sheet.docx"
    )
  )

  for (d in docs) {
    message("── Rendering ", d$input, " ──")
    quarto::quarto_render(input = d$input, execute_params = d$params)

    for (o in d$outputs) {
      if (file.exists(o)) {
        dest <- file.path(out_dir, basename(o))
        file.copy(o, dest, overwrite = TRUE)
        message("  copied -> ", dest)
      } else {
        warning("expected output not found: ", o)
      }
    }
  }

  invisible(out_dir)
}

if (!interactive() && identical(sys.nframe(), 0L)) {
  run_assessment()
}

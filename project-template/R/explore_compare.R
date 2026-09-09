# explore_compare.R — put saved candidates side by side.
#
# Fits are compared, not re-run: name the candidates saved by `explore_fit.R` and this renders
# a comparison report of their parameters, reference points, and trajectories.
#
# Candidates fitted to DIFFERENT DATA are not comparable by likelihood or AIC. Comparing their
# trajectories is still informative — comparing their AICs is not. Say which you are doing.
#
# Run from the project root:  source(here::here("R", "explore_compare.R"))

source(here::here("R", "0_setup.R"))
source(here::here("R", "spict_exploration.R"))

# ─── WHAT TO COMPARE ──────────────────────────────────────────────────────────────────────
candidates <- c("v1-config-priors", "v2-higher-r", "v3-winter-timing")
description <- "Sensitivity of the assessment to the prior on r and to the index timing."
# ──────────────────────────────────────────────────────────────────────────────────────────

paths <- file.path(output_dir, paste0("candidate_", candidates, ".rds"))
missing <- candidates[!file.exists(paths)]
if (length(missing)) {
  stop(
    "No saved candidate for: ", paste(missing, collapse = ", "),
    ". Fit them with explore_fit.R first.",
    call. = FALSE
  )
}

quarto::quarto_render(
  input = here::here("docs", "data-report", "exploration", "model-comparison.qmd"),
  execute_params = list(
    description = description,
    candidates  = candidates,
    output_dir  = output_dir
  ),
  output_file = paste0("comparison-", paste(candidates, collapse = "-"), ".html")
)

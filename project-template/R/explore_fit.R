# explore_fit.R — fit one candidate configuration and render its diagnostic report.
#
# The exploration loop. Change one thing — a prior, the index variant, the uncertainty ramp,
# the production-function shape — give the run a short unique name, source this file, and read
# the report it renders. The fit is saved so `explore_compare.R` can put several candidates
# side by side.
#
# Settings that belong to the STOCK live in config.yaml and are read from there. Settings that
# belong to THIS CANDIDATE are the block marked below; that is the only part you edit between
# runs.
#
# Run from the project root:  source(here::here("R", "explore_fit.R"))

source(here::here("R", "0_setup.R"))
source(here::here("R", "spict_helpers.R"))

# --- The data -----------------------------------------------------------------------------
stock_slug <- cfg$STOCK_SLUG
catches <- readRDS(file.path(output_dir, paste0(stock_slug, "_catches.rds")))
index   <- readRDS(file.path(output_dir, paste0(stock_slug, "_index.rds")))

# ─── THIS CANDIDATE ───────────────────────────────────────────────────────────────────────
# Give every run a short unique name; it becomes the filename and the label in comparisons.
run_name        <- "v1-config-priors"
run_description <- "Baseline: the priors and settings in config.yaml, unchanged."

# Start from the project's configured priors and override what this candidate changes.
run_priors <- config_priors()
# run_priors$logr <- c(log(0.12), 0.5, 1)   # e.g. a higher intrinsic growth rate

run_timing <- cfg$INDEX_TIMING
# run_timing <- 2/12                        # e.g. a winter survey

run_shape <- cfg$PRODUCTION_MODEL
# ──────────────────────────────────────────────────────────────────────────────────────────

inp <- build_spict_input(
  catches = catches,
  index   = index,
  priors  = run_priors,
  timing  = run_timing,
  shape   = run_shape
)

inp$optimiser.control <- list(iter.max = 1e5, eval.max = 1e5)

fit <- fit.spict(inp)
fit <- calc.osa.resid(fit)
fit <- calc.process.resid(fit)

fit_path <- file.path(output_dir, paste0("candidate_", run_name, ".rds"))
saveRDS(fit, fit_path, compress = "xz")
message("Saved candidate to ", fit_path)

# --- The report -----------------------------------------------------------------------------
report_dir <- here::here("docs", "data-report", "exploration")

quarto::quarto_render(
  input = file.path(report_dir, "single-fit.qmd"),
  execute_params = list(
    run_name        = run_name,
    run_description = run_description,
    fit_path        = fit_path,
    run_ini_trials  = 10,
    run_retro       = FALSE,
    retro_years     = cfg$NRETROYEARS %||% 5,
    hindcast_years  = cfg$NHINDCASTYEARS %||% 5,
    run_manage      = FALSE
  ),
  output_file = paste0("candidate-", run_name, ".html")
)

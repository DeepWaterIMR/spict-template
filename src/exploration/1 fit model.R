## Source run first
source("src/0_setup.R")
library(quarto)

# Keep spict up to date!
# remotes::install_github("DTUAqua/spict/spict", ref = "dev")
library(spict)

## Catch data ####
# Loads the per-stock catches CSV produced by src/1_process_catches.R.
# Expected columns: at minimum `year` and `total` (catches in tonnes).
# The `dplyr::select(-hist)` below is a beaked-redfish-specific column drop
# inherited from the worked example — remove it if your catches CSV has no
# `hist` column.

catches <- read.csv("data/catches/{{STOCK_NAME}}_catches_for_SPiCT.csv") |>
  as_tibble() |>
  rename_with(tolower) |>
  dplyr::select(-hist)


### Survey indices ####

index <- read_rds("data/indices/{{STOCK_CODE}}-assessment-survey-indices.rds")[[2]] |>
  mutate(
    index = est / mean(est),
    index_lwr = lwr / mean(est),
    index_upr = upr / mean(est),
    stdevI = se / mean(se) # used as a multiplicator for stdev prior
  )

r_inp <- list(
  timeC = catches$year,
  obsC = catches$total,
  timeI = index$year + (6 / 12), # June timing
  obsI = index$index
)

# Fix n through phases (Schaefer) ####
r_inp$phases$logn <- -1
r_inp$ini$logn <- log(2)

## Priors and model settings ####
# PLACEHOLDER: All prior values below are carried over from the golden redfish
# 2026 benchmark. Replace with beaked redfish life-history priors from
# FishLife or JRN-AFWG literature before a real assessment.

r_priors <- list(
  logbkfrac = c(log(0.9), 0.5, 1), # PLACEHOLDER: initial depletion prior
  logr = c(log(0.064), 0.5, 1), # PLACEHOLDER: intrinsic growth rate prior
  logsdb = c(log(0.05), 0.2, 1) # PLACEHOLDER: process variance prior
)

# Deactivate coupling priors (alpha and beta)
r_priors$logalpha <- c(0, 0, 0)
r_priors$logbeta <- c(0, 0, 0)

## Catch uncertainty ramp ####
# PLACEHOLDER: Breakpoints below are golden redfish values.
# stdev_high_year: year before which catch uncertainty is elevated (e.g., when
#   species-level reporting improved for beaked redfish).
# stdev_low_year:  year from which catches are considered reliable (e.g., when
#   Norwegian sales-note data started being used directly).
# Consult JRN-AFWG data quality assessment to set appropriate values.

stdev_high_year <- 1987 # PLACEHOLDER
stdev_low_year <- 2022 # PLACEHOLDER
stdev_high_val <- 3 # PLACEHOLDER: multiplier for uncertain historical catches

r_sdfacs <- list(
  stdevfacC = data.frame(year = min(catches$year):max(catches$year)) |>
    mutate(
      uncertainty = case_when(
        year < stdev_high_year ~ stdev_high_val,
        year > stdev_low_year ~ 1,
        .default = NA
      )
    ) |>
    mutate(uncertainty = zoo::na.approx(uncertainty)) |>
    mutate(stdevC = uncertainty / mean(uncertainty)) |> # stdevfacs must average 1
    pull(stdevC),
  stdevfacI = index$stdevI
)

# Quarto render ####

r_model <- "reb_bm_v1" # give this model run a short, unique name
r_description <- "Exploratory beaked redfish SPiCT model"

out_dir <- "docs/model_exploration_reports"
out_dir_report <- file.path("../..", "docs/model_exploration_reports")
if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}

## Render the report ####

# Uncomment for interactive debugging:
# params <- list(model = r_model, run_description = r_description, run_inp = r_inp,
#   run_priors = r_priors, run_sdfacs = r_sdfacs, run_ini_trials = 10,
#   run_retro_chunk = FALSE, retro_years = 5, hindcast_years = 5,
#   run_manage_chunk = TRUE, save_large_files = TRUE)

quarto_render(
  input = "src/exploration/report.qmd",
  execute_params = list(
    model = r_model,
    run_description = r_description,
    run_inp = r_inp,
    run_priors = r_priors,
    run_sdfacs = r_sdfacs,
    run_ini_trials = 10,
    run_retro_chunk = FALSE,
    retro_years = 5,
    hindcast_years = 5,
    save_large_files = FALSE,
    run_manage_chunk = FALSE
  ),
  metadata = list(title = paste("Model", r_model)),
  output_file = paste0("model_", r_model, ".html"),
  quarto_args = c("--output-dir", out_dir_report)
)

# Packages

source("src/0_setup.R")

# Compare models using the comparator.qmd template. This will generate a report comparing the specified models.

model_dir <- "data/model_output/saved_models"
models_to_compare <- c("bm_jan", "bm_jun", "bm_sep")
comparison_name <- paste0(
  "Comparison_",
  paste0(models_to_compare, collapse = "_")
)

r_description <- "Comparing some models..."

out_dir <- "docs/model_comparisons"
out_dir_report <- "../../docs/model_comparisons"
if (!dir.exists(out_dir)) {
  dir.create(out_dir)
}

# debug params
# params <- list(description = r_description, models = models_to_compare, model_directory = model_dir)
quarto::quarto_render(
  input = "src/exploration/comparator.qmd",
  execute_params = list(
    description = r_description,
    models = models_to_compare,
    model_directory = model_dir
  ),
  metadata = list(title = comparison_name),
  output_file = paste0(
    "comp_",
    paste0(models_to_compare, collapse = "_"),
    ".html"
  ),
  quarto_args = c("--output-dir", out_dir_report)
)

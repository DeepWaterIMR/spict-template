# Exploration workflow

Scripts and Quarto documents for fitting, diagnosing, and comparing candidate
SPiCT configurations. Not part of the annual production run — used during
benchmarks, sensitivity work, and interactive exploration.

## Usage

Run from the **project root**:

```r
source("src/exploration/1 fit model.R")       # fit a candidate model
source("src/exploration/2 compare models.R")  # compare saved models
```

## Files

| File | Purpose |
|---|---|
| `1 fit model.R` | Define catch data, survey index, priors, sdfacs; render `report.qmd` |
| `2 compare models.R` | Load saved model RDS files; render `comparator.qmd` |
| `report.qmd` | Full diagnostic report for a single SPiCT fit |
| `comparator.qmd` | Side-by-side comparison of multiple fits |
| `shiny_dashboard.qmd` | Shiny-compatible dashboard for interactive exploration |
| `additional_spict_funcs.R` | `params_df()`, `comp_df()`, `comp_plot()`, `comp_plot2()` — comparison helpers; also used by Shiny |
| `spict_explorer/app.R` | Standalone interactive Shiny app (preferred over `1 fit model.R` for exploration) |

## Shiny explorer

Launch from the **project root**:

```r
shiny::runApp("src/exploration/spict_explorer")
```

`additional_spict_funcs.R` provides the data extraction and comparison
functions used by the Shiny backend.

## Output

Rendered HTML reports land in:

- `docs/model_exploration_reports/` — single-model reports from `1 fit model.R`
- `docs/model_comparisons/` — comparison reports from `2 compare models.R`

Fitted model RDS objects are saved to:

- `data/model_output/saved_models/` (excluded from git)

## Per-stock items

When adapting for a new stock, the following items in this folder will need to
be revisited (see also `memory/template_open_items.md`):

- **Priors** (`logbkfrac`, `logr`, `logsdb`) in `1 fit model.R` — currently
  beaked-redfish-flavoured placeholders inherited from golden redfish.
- **Catch uncertainty ramp breakpoints** (`stdev_high_year`, `stdev_low_year`)
  — stock-specific reporting quality thresholds.
- **Model naming convention** (`r_model`, `r_description`) — set to short,
  unique identifiers for each fit.

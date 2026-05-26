## SPiCT Explorer — interactive alternative to src/exploration/1 fit model.R
## {{STOCK_NAME}} ({{STOCK_LATIN}}), ICES areas {{ICES_AREAS}}
## Launch from the project root with:  shiny::runApp("src/exploration/spict_explorer")

cran_pkgs <- c(
  "shiny", "bslib", "shinycssloaders", "dplyr", "tidyr",
  "readr", "ggplot2", "zoo", "DT", "tibble", "cowplot"
)
missing_cran <- cran_pkgs[!vapply(cran_pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_cran) > 0) {
  message("Installing missing CRAN packages: ", paste(missing_cran, collapse = ", "))
  install.packages(missing_cran, quiet = TRUE)
}

if (!requireNamespace("spict", quietly = TRUE)) {
  message("Installing spict from GitHub (DTUAqua/spict, dev branch)…")
  if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes", quiet = TRUE)
  remotes::install_github("DTUAqua/spict/spict", ref = "dev", quiet = TRUE)
}

suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(shinycssloaders)
  library(spict)
  library(dplyr)
  library(tidyr)
  library(readr)
  library(ggplot2)
  library(zoo)
  library(DT)
})

# ── Locate the project root ────────────────────────────────────────────────
# `here::here()` cannot anchor reliably here (no .Rproj / no .git in this
# checkout), so walk up from the app or working directory until we find a
# sentinel file from the project root (CLAUDE.md + run_assessment.R).
locate_project_root <- function() {
  candidates <- character()

  # 1. Directory containing this file when sourced in RStudio
  this_file <- tryCatch(
    rstudioapi::getSourceEditorContext()$path,
    error = function(e) ""
  )
  if (!is.null(this_file) && nzchar(this_file)) {
    candidates <- c(candidates, dirname(this_file))
  }

  # 2. Current working directory (set by shiny::runApp() to the app dir)
  candidates <- c(candidates, getwd())

  for (start in candidates) {
    d <- normalizePath(start, mustWork = FALSE)
    for (i in 1:6) {
      if (
        file.exists(file.path(d, "CLAUDE.md")) &&
          file.exists(file.path(d, "run_assessment.R"))
      ) {
        return(d)
      }
      parent <- dirname(d)
      if (parent == d) break
      d <- parent
    }
  }
  stop(
    "Could not locate project root (looked for CLAUDE.md + run_assessment.R). ",
    "Launch with shiny::runApp(\"src/exploration/spict_explorer\") from the project root."
  )
}

PROJECT_ROOT <- locate_project_root()
source(file.path(PROJECT_ROOT, "src", "ices_plots.R"))

CATCH_PATH <- file.path(
  PROJECT_ROOT,
  "data",
  "catches",
  "{{STOCK_NAME}}_catches_for_SPiCT.csv"
)
INDEX_PATH <- file.path(
  PROJECT_ROOT,
  "data",
  "indices",
  "{{STOCK_CODE}}-assessment-survey-indices.rds"
)

message("SPiCT Explorer — resolved paths:")
message("  project root: ", PROJECT_ROOT)
message("  catches:      ", CATCH_PATH)
message("  indices:      ", INDEX_PATH)

# ── Data loading (mirrors 1 assessment model.qmd) ──────────────────────────
load_catches <- function() {
  read.csv(CATCH_PATH) |>
    tibble::as_tibble() |>
    rename_with(tolower) |>
    dplyr::select(-any_of("hist"))
}

load_index <- function() {
  readRDS(INDEX_PATH)[[2]] |>
    mutate(
      index = est / mean(est, na.rm = TRUE),
      index_lwr = lwr / mean(est, na.rm = TRUE),
      index_upr = upr / mean(est, na.rm = TRUE),
      stdevI = se / mean(se, na.rm = TRUE)
    )
}

CATCHES_DEFAULT <- load_catches()
INDEX_DEFAULT <- load_index()
INDEX_NAME_DEFAULT <- unique(INDEX_DEFAULT$model)[1] %||% "Survey index"

# ── Defaults extracted from 1 assessment model.qmd ─────────────────────────
DEFAULTS <- list(
  # priors set in the qmd (mean on natural scale, SD on log scale)
  logbkfrac = list(mean = 0.9, sd = 0.5, on = TRUE),
  logr = list(mean = 0.064, sd = 0.5, on = TRUE),
  logsdb = list(mean = 0.05, sd = 0.2, on = TRUE),
  # priors not enabled by default in the qmd — exposed here for exploration
  logn = list(mean = 2, sd = 0.5, on = FALSE),
  logm = list(mean = 1e5, sd = 0.5, on = FALSE),
  logK = list(mean = 1e6, sd = 0.5, on = FALSE),
  logq = list(mean = 1, sd = 0.5, on = FALSE),
  logsdf = list(mean = 0.2, sd = 0.5, on = FALSE),
  logsdc = list(mean = 0.1, sd = 0.5, on = FALSE),
  logsdi = list(mean = 0.2, sd = 0.5, on = FALSE),
  # timing
  catch_dtc = 1, # annual catch interval
  index_month = 6, # June
  # catch uncertainty ramp (placeholder breakpoints from the qmd)
  stdev_high_year = 1987,
  stdev_low_year = 2022,
  stdev_high_val = 3,
  # Schaefer is the assumed shape
  schaefer = TRUE
)

# ── Helpers ────────────────────────────────────────────────────────────────
make_prior_vec <- function(mean_nat, sd_log, on) {
  if (!isTRUE(on)) {
    return(c(0, 0, 0)) # deactivated prior
  }
  if (is.na(mean_nat) || is.na(sd_log) || mean_nat <= 0 || sd_log <= 0) {
    return(c(0, 0, 0))
  }
  c(log(mean_nat), sd_log, 1)
}

build_stdevfacC <- function(catches, hi_year, lo_year, hi_val) {
  yrs <- min(catches$year):max(catches$year)
  tibble::tibble(year = yrs) |>
    mutate(
      uncertainty = case_when(
        year < hi_year ~ hi_val,
        year > lo_year ~ 1,
        .default = NA_real_
      )
    ) |>
    mutate(uncertainty = zoo::na.approx(uncertainty, na.rm = FALSE)) |>
    mutate(stdevC = uncertainty / mean(uncertainty, na.rm = TRUE)) |>
    pull(stdevC)
}

build_inp <- function(catches, index, controls) {
  inp <- list(
    timeC = catches$year,
    obsC = catches$total,
    dtc = controls$catch_dtc,
    timeI = index$year + (controls$index_month / 12),
    obsI = index$index
  )

  if (isTRUE(controls$schaefer)) {
    inp$phases$logn <- -1
    inp$ini$logn <- log(2)
  }

  inp <- check.inp(inp, verbose = FALSE)

  inp$priors$logbkfrac <- make_prior_vec(
    controls$logbkfrac_mean,
    controls$logbkfrac_sd,
    controls$logbkfrac_on
  )
  inp$priors$logr <- make_prior_vec(
    controls$logr_mean,
    controls$logr_sd,
    controls$logr_on
  )
  inp$priors$logsdb <- make_prior_vec(
    controls$logsdb_mean,
    controls$logsdb_sd,
    controls$logsdb_on
  )
  inp$priors$logm <- make_prior_vec(
    controls$logm_mean,
    controls$logm_sd,
    controls$logm_on
  )
  inp$priors$logK <- make_prior_vec(
    controls$logK_mean,
    controls$logK_sd,
    controls$logK_on
  )
  inp$priors$logsdf <- make_prior_vec(
    controls$logsdf_mean,
    controls$logsdf_sd,
    controls$logsdf_on
  )
  inp$priors$logsdc <- make_prior_vec(
    controls$logsdc_mean,
    controls$logsdc_sd,
    controls$logsdc_on
  )
  inp$priors$logsdi <- make_prior_vec(
    controls$logsdi_mean,
    controls$logsdi_sd,
    controls$logsdi_on
  )
  inp$priors$logq <- make_prior_vec(
    controls$logq_mean,
    controls$logq_sd,
    controls$logq_on
  )
  if (!isTRUE(controls$schaefer) && isTRUE(controls$logn_on)) {
    inp$priors$logn <- make_prior_vec(
      controls$logn_mean,
      controls$logn_sd,
      TRUE
    )
  }

  # Always deactivate alpha/beta coupling priors (matches the qmd)
  inp$priors$logalpha <- c(0, 0, 0)
  inp$priors$logbeta <- c(0, 0, 0)

  inp$stdevfacC <- build_stdevfacC(
    catches,
    controls$stdev_high_year,
    controls$stdev_low_year,
    controls$stdev_high_val
  )
  inp$stdevfacI <- index$stdevI

  inp$optimiser.control <- list(
    iter.max = controls$iter_max,
    eval.max = controls$eval_max
  )
  inp
}

build_spict_summary <- function(fit, catches) {
  bbmsy <- as.data.frame(get.par("logBBmsy", fit, exp = FALSE))
  ffmsy <- as.data.frame(get.par("logFFmsy", fit, exp = FALSE))
  sum_df <- data.frame(
    year = as.numeric(rownames(bbmsy)),
    BBmsy = bbmsy,
    FFmsy = ffmsy
  ) |>
    left_join(
      data.frame(year = catches$year, total_catch = catches$total),
      by = "year"
    )
  list(
    summary = sum_df,
    assessment_year = max(catches$year, na.rm = TRUE) + 1
  )
}

fmt_val <- function(x) {
  dplyr::case_when(
    is.na(x)       ~ NA_character_,
    abs(x) > 1e3   ~ formatC(x, digits = 0, format = "f"),
    abs(x) > 10    ~ formatC(x, digits = 1, format = "f"),
    abs(x) > 1     ~ formatC(x, digits = 3, format = "f"),
    abs(x) >= 1e-3 ~ formatC(x, digits = 4, format = "f"),
    TRUE            ~ formatC(x, digits = 3, format = "e")
  )
}

prior_row_ui <- function(id_root, label, default, step_mean = 0.01) {
  fluidRow(
    column(
      4,
      checkboxInput(
        paste0(id_root, "_on"),
        label = HTML(paste0("<b>", label, "</b>")),
        value = default$on
      )
    ),
    column(
      4,
      numericInput(
        paste0(id_root, "_mean"),
        "mean (nat.)",
        value = default$mean,
        min = 0,
        step = step_mean
      )
    ),
    column(
      4,
      numericInput(
        paste0(id_root, "_sd"),
        "sd (log)",
        value = default$sd,
        min = 0,
        step = 0.05
      )
    )
  )
}

# ── UI ─────────────────────────────────────────────────────────────────────
ui <- page_navbar(
  title = "SPiCT Explorer — {{STOCK_NAME}}",
  theme = bs_theme(version = 5, bootswatch = "cosmo", base_font_size = "0.9rem"),
  header = tags$style(HTML(
    "
    .form-group { margin-bottom: 0.4rem; }
    .form-control, .form-select { font-size: 0.85rem; padding: 0.2rem 0.4rem; }
    .form-label { font-size: 0.8rem; margin-bottom: 0.15rem; }
    .accordion-button { font-size: 0.9rem; padding: 0.5rem 0.75rem; }
    .accordion-body { padding: 0.6rem 0.75rem; }
    .control-card { font-size: 0.85rem; }
    .conv-ok  { color: #1a7f37; font-weight: 700; }
    .conv-bad { color: #b30000; font-weight: 700; }
  "
  )),
  sidebar = sidebar(
    width = 360,
    title = "Controls",
    accordion(
      open = c("priors", "fit"),
      accordion_panel(
        "Priors",
        value = "priors",
        helpText("Tick to activate; mean is natural scale, SD is log scale."),
        prior_row_ui("logbkfrac", "logbkfrac (B/K t1)", DEFAULTS$logbkfrac),
        prior_row_ui("logr", "logr", DEFAULTS$logr, step_mean = 0.001),
        prior_row_ui("logsdb", "logsdb", DEFAULTS$logsdb, step_mean = 0.001),
        prior_row_ui("logm", "logm (MSY)", DEFAULTS$logm, step_mean = 100),
        prior_row_ui("logK", "logK", DEFAULTS$logK, step_mean = 1000),
        prior_row_ui("logq", "logq", DEFAULTS$logq),
        prior_row_ui("logn", "logn (n shape)", DEFAULTS$logn, step_mean = 0.1),
        prior_row_ui("logsdf", "logsdf", DEFAULTS$logsdf),
        prior_row_ui("logsdc", "logsdc", DEFAULTS$logsdc),
        prior_row_ui("logsdi", "logsdi", DEFAULTS$logsdi),
        actionButton(
          "reset_priors",
          "Reset priors to defaults",
          class = "btn-outline-secondary btn-sm",
          width = "100%"
        )
      ),
      accordion_panel(
        "Timing",
        value = "timing",
        numericInput(
          "catch_dtc",
          "Catch interval dtc (year fraction)",
          value = DEFAULTS$catch_dtc,
          min = 0.01,
          max = 1,
          step = 0.05
        ),
        numericInput(
          "index_month",
          paste0("Index month — ", INDEX_NAME_DEFAULT),
          value = DEFAULTS$index_month,
          min = 1,
          max = 12,
          step = 1
        ),
        helpText("Survey timing in SPiCT = year + month/12."),
        hr(),
        h6("Catch uncertainty ramp"),
        numericInput(
          "stdev_high_year",
          "High-uncertainty until year",
          value = DEFAULTS$stdev_high_year,
          step = 1
        ),
        numericInput(
          "stdev_low_year",
          "Low-uncertainty from year",
          value = DEFAULTS$stdev_low_year,
          step = 1
        ),
        numericInput(
          "stdev_high_val",
          "High-uncertainty multiplier",
          value = DEFAULTS$stdev_high_val,
          min = 1,
          step = 0.5
        )
      ),
      accordion_panel(
        "Model & fit",
        value = "fit",
        checkboxInput(
          "schaefer",
          "Fix Schaefer shape (n = 2)",
          value = DEFAULTS$schaefer
        ),
        numericInput(
          "iter_max",
          "iter.max",
          value = 1000,
          min = 100,
          step = 100
        ),
        numericInput(
          "eval_max",
          "eval.max",
          value = 1000,
          min = 100,
          step = 100
        ),
        actionButton(
          "fit_btn",
          "Fit model",
          icon = icon("play"),
          class = "btn-primary",
          width = "100%"
        ),
        br(),
        br(),
        uiOutput("fit_status")
      )
    )
  ),
  nav_panel(
    "Summary",
    layout_columns(
      col_widths = c(12),
      card(
        card_header(
          class = "d-flex justify-content-between align-items-center",
          span("ICES assessment summary"),
          uiOutput("conv_badge")
        ),
        plotOutput("plot_ices", height = "480px") |> withSpinner(type = 6)
      )
    ),
    layout_columns(
      col_widths = c(5, 7),
      card(
        card_header("Key estimates (95% CI)"),
        DTOutput("key_estimates") |> withSpinner(type = 6),
        hr(),
        card_header("Input data"),
        plotOutput("plot_input", height = "300px") |> withSpinner(type = 6)
      ),
      card(
        card_header("Parameter estimates"),
        DTOutput("param_estimates") |> withSpinner(type = 6)
      )
    )
  ),
  nav_panel(
    "Diagnostics",
    layout_columns(
      col_widths = c(12),
      card(
        card_header("Fits to observations — plotspict.fit()"),
        plotOutput("plot_fit", height = "650px") |> withSpinner(type = 6)
      ),
      card(
        card_header("OSA residual diagnostics — plotspict.diagnostic()"),
        plotOutput("plot_diag", height = "650px") |> withSpinner(type = 6)
      ),
      card(
        downloadButton(
          "dl_diag_pdf",
          "Download diagnostics PDF",
          class = "btn-outline-primary"
        )
      )
    )
  ),
  nav_panel(
    "Retrospective",
    card(
      card_header("Retrospective analysis"),
      sliderInput(
        "nretroyears",
        "Number of peels",
        min = 3,
        max = 7,
        value = 5,
        step = 1
      ),
      actionButton(
        "retro_btn",
        "Run retrospective",
        icon = icon("clock-rotate-left"),
        class = "btn-primary"
      ),
      uiOutput("retro_status"),
      verbatimTextOutput("retro_rho"),
      plotOutput("plot_retro", height = "550px") |> withSpinner(type = 6)
    )
  ),
  nav_panel(
    "Management",
    card(
      card_header("Management scenarios"),
      helpText(
        "Runs spict::manage() with scenarios: currentF, Fmsy, noF, ices."
      ),
      actionButton(
        "manage_btn",
        "Run management scenarios",
        icon = icon("chart-line"),
        class = "btn-primary"
      ),
      uiOutput("manage_status"),
      DTOutput("manage_table"),
      plotOutput("plot_manage", height = "500px") |> withSpinner(type = 6)
    )
  )
)

# ── Server ─────────────────────────────────────────────────────────────────
server <- function(input, output, session) {
  fitR <- reactiveVal(NULL)
  retroR <- reactiveVal(NULL)
  manageR <- reactiveVal(NULL)
  fit_err <- reactiveVal(NULL)
  retro_err <- reactiveVal(NULL)
  manage_err <- reactiveVal(NULL)

  catches <- reactive(CATCHES_DEFAULT)
  index <- reactive(INDEX_DEFAULT)

  collect_controls <- function() {
    list(
      logbkfrac_mean = input$logbkfrac_mean,
      logbkfrac_sd = input$logbkfrac_sd,
      logbkfrac_on = input$logbkfrac_on,
      logr_mean = input$logr_mean,
      logr_sd = input$logr_sd,
      logr_on = input$logr_on,
      logsdb_mean = input$logsdb_mean,
      logsdb_sd = input$logsdb_sd,
      logsdb_on = input$logsdb_on,
      logm_mean = input$logm_mean,
      logm_sd = input$logm_sd,
      logm_on = input$logm_on,
      logK_mean = input$logK_mean,
      logK_sd = input$logK_sd,
      logK_on = input$logK_on,
      logq_mean = input$logq_mean,
      logq_sd = input$logq_sd,
      logq_on = input$logq_on,
      logn_mean = input$logn_mean,
      logn_sd = input$logn_sd,
      logn_on = input$logn_on,
      logsdf_mean = input$logsdf_mean,
      logsdf_sd = input$logsdf_sd,
      logsdf_on = input$logsdf_on,
      logsdc_mean = input$logsdc_mean,
      logsdc_sd = input$logsdc_sd,
      logsdc_on = input$logsdc_on,
      logsdi_mean = input$logsdi_mean,
      logsdi_sd = input$logsdi_sd,
      logsdi_on = input$logsdi_on,
      catch_dtc = input$catch_dtc,
      index_month = input$index_month,
      stdev_high_year = input$stdev_high_year,
      stdev_low_year = input$stdev_low_year,
      stdev_high_val = input$stdev_high_val,
      schaefer = input$schaefer,
      iter_max = input$iter_max,
      eval_max = input$eval_max
    )
  }

  # Reset priors ------------------------------------------------------------
  observeEvent(input$reset_priors, {
    for (nm in c(
      "logbkfrac",
      "logr",
      "logsdb",
      "logm",
      "logK",
      "logq",
      "logn",
      "logsdf",
      "logsdc",
      "logsdi"
    )) {
      d <- DEFAULTS[[nm]]
      updateNumericInput(session, paste0(nm, "_mean"), value = d$mean)
      updateNumericInput(session, paste0(nm, "_sd"), value = d$sd)
      updateCheckboxInput(session, paste0(nm, "_on"), value = d$on)
    }
  })

  # Fit ---------------------------------------------------------------------
  observeEvent(input$fit_btn, {
    fitR(NULL)
    retroR(NULL)
    manageR(NULL)
    fit_err(NULL)

    showNotification("Fitting SPiCT…", type = "message", duration = 2)
    res <- tryCatch(
      {
        inp <- build_inp(catches(), index(), collect_controls())
        fit <- fit.spict(inp)
        fit <- tryCatch(calc.osa.resid(fit), error = function(e) fit)
        fit <- tryCatch(calc.process.resid(fit), error = function(e) fit)
        fit
      },
      error = function(e) {
        fit_err(conditionMessage(e))
        NULL
      }
    )
    fitR(res)
  })

  # Status ------------------------------------------------------------------
  output$fit_status <- renderUI({
    if (!is.null(fit_err())) {
      div(class = "alert alert-danger p-2 small", "Fit failed: ", fit_err())
    } else if (!is.null(fitR())) {
      conv <- fitR()$opt$convergence
      sd_ok <- all(is.finite(fitR()$sd))
      if (conv == 0 && sd_ok) {
        div(class = "alert alert-success p-2 small", "Converged.")
      } else {
        div(
          class = "alert alert-warning p-2 small",
          sprintf(
            "Issue — exit code %s, finite SDs: %s",
            conv,
            sd_ok
          )
        )
      }
    } else {
      div(class = "text-muted small", "No fit yet.")
    }
  })

  output$conv_badge <- renderUI({
    f <- fitR()
    if (is.null(f)) return(NULL)
    conv <- f$opt$convergence
    sd_ok <- all(is.finite(f$sd))
    ok <- conv == 0 && sd_ok
    tags$span(
      class = if (ok) "badge bg-success" else "badge bg-danger",
      if (ok) "Converged" else sprintf("Not converged (code %s)", conv)
    )
  })

  # ICES summary plot -------------------------------------------------------
  output$plot_ices <- renderPlot(
    {
      f <- fitR()
      if (is.null(f)) {
        ggplot() +
          annotate(
            "text", x = 0.5, y = 0.5,
            label = "Fit the model to see the ICES summary plot.",
            colour = "grey60", size = 5
          ) +
          theme_void()
      } else {
        sm <- tryCatch(
          build_spict_summary(f, catches()),
          error = function(e) NULL
        )
        if (is.null(sm)) {
          ggplot() +
            annotate(
              "text", x = 0.5, y = 0.5,
              label = "Could not build ICES summary.", colour = "red", size = 4
            ) +
            theme_void()
        } else {
          summary_plot(sm)
        }
      }
    },
    res = 120
  )

  # Parameter estimates table ----------------------------------------------
  output$param_estimates <- renderDT({
    f <- fitR()
    req(f)
    parest <- tryCatch(
      {
        sumspict.parest(f) |>
          as.data.frame() |>
          tibble::rownames_to_column("parameter") |>
          mutate(across(where(is.numeric), fmt_val))
      },
      error = function(e) NULL
    )
    req(parest)

    key_pars <- c(
      "r", "K", "MSY", "Bmsy", "Fmsy", "n",
      "B/Bmsy", "F/Fmsy", "B", "F",
      "sdb", "sdf", "sdc", "sdi"
    )
    row_is_key <- grepl(
      paste(key_pars, collapse = "|"),
      parest$parameter,
      ignore.case = TRUE
    )

    datatable(
      parest,
      rownames = FALSE,
      colnames = c("Parameter", "Lower 95%", "Estimate", "Upper 95%"),
      options = list(
        dom = "ftp",
        pageLength = 20,
        order = list(),
        columnDefs = list(
          list(className = "dt-right", targets = 1:3)
        )
      )
    ) |>
      formatStyle(
        "parameter",
        fontWeight = styleRow(which(row_is_key), "bold"),
        color = styleRow(which(row_is_key), "#002b5f")
      )
  })

  # Key estimates ----------------------------------------------------------
  output$key_estimates <- renderDT({
    f <- fitR()
    req(f)
    pars <- c("logBBmsy", "logFFmsy", "logMSY", "logK", "logr", "logBmsy", "logFmsy")
    labels <- c("B/Bmsy", "F/Fmsy", "MSY", "K", "r", "Bmsy", "Fmsy")
    rows <- lapply(seq_along(pars), function(i) {
      v <- tryCatch(
        get.par(pars[i], f, exp = TRUE),
        error = function(e) NULL
      )
      if (is.null(v)) {
        return(NULL)
      }
      last <- nrow(v)
      data.frame(
        Parameter = labels[i],
        Estimate = signif(v[last, 2], 4),
        Lower95 = signif(v[last, 1], 4),
        Upper95 = signif(v[last, 3], 4)
      )
    })
    out <- do.call(rbind, Filter(Negate(is.null), rows))
    datatable(out, rownames = FALSE, options = list(dom = "t", paging = FALSE))
  })

  # Input plot --------------------------------------------------------------
  output$plot_input <- renderPlot(
    {
      ctch <- catches()
      idx <- index()
      idx_t <- idx$year + (input$index_month %||% 6) / 12
      y_max <- max(ctch$total, na.rm = TRUE)
      idx_lo <- floor(min(idx$index, na.rm = TRUE) * 10) / 10
      idx_hi <- ceiling(max(idx$index, na.rm = TRUE) * 10) / 10
      sf <- y_max / (idx_hi - idx_lo)

      ggplot() +
        geom_col(
          data = ctch,
          aes(x = year, y = total),
          fill = "grey75",
          colour = "grey55"
        ) +
        geom_line(
          aes(x = idx_t, y = (idx$index - idx_lo) * sf),
          colour = "#cc3333",
          linewidth = 1
        ) +
        geom_point(
          aes(x = idx_t, y = (idx$index - idx_lo) * sf),
          colour = "#cc3333",
          size = 1.5
        ) +
        scale_y_continuous(
          name = "Catch (t)",
          expand = expansion(c(0, 0.05)),
          sec.axis = sec_axis(
            ~ ./sf + idx_lo,
            name = "Survey index (relative)"
          )
        ) +
        labs(x = "Year") +
        theme_bw(base_size = 12)
    },
    res = 120
  )

  # Diagnostics -------------------------------------------------------------
  output$plot_fit <- renderPlot(
    {
      f <- fitR()
      req(f)
      plot(f)
    },
    res = 120
  )

  output$plot_diag <- renderPlot(
    {
      f <- fitR()
      req(f)
      tryCatch(
        plotspict.diagnostic(f),
        error = function(e) {
          plot.new()
          text(
            0.5,
            0.5,
            paste("Diagnostics unavailable:", conditionMessage(e)),
            col = "red"
          )
        }
      )
    },
    res = 120
  )

  output$dl_diag_pdf <- downloadHandler(
    filename = function() {
      sprintf("spict_diagnostics_%s.pdf", format(Sys.time(), "%Y%m%d_%H%M%S"))
    },
    content = function(file) {
      f <- fitR()
      req(f)
      pdf(file, width = 9, height = 6)
      tryCatch(plot(f), error = function(e) NULL)
      tryCatch(plotspict.diagnostic(f), error = function(e) NULL)
      tryCatch(plotspict.priors(f), error = function(e) NULL)
      tryCatch(plotspict.fb(f), error = function(e) NULL)
      dev.off()
    }
  )

  # Retrospective -----------------------------------------------------------
  observeEvent(input$retro_btn, {
    f <- fitR()
    if (is.null(f)) {
      showNotification("Fit the model first.", type = "warning")
      return()
    }
    retroR(NULL)
    retro_err(NULL)
    showNotification("Running retrospective…", type = "message", duration = 2)
    out <- tryCatch(
      retro(f, nretroyear = input$nretroyears, mc.cores = 1),
      error = function(e) {
        retro_err(conditionMessage(e))
        NULL
      }
    )
    retroR(out)
  })

  output$retro_status <- renderUI({
    if (!is.null(retro_err())) {
      div(
        class = "alert alert-danger p-2 small",
        "Retro failed: ",
        retro_err()
      )
    } else if (!is.null(retroR())) {
      div(class = "text-success small", "Retro complete.")
    } else {
      NULL
    }
  })

  output$retro_rho <- renderPrint({
    r <- retroR()
    req(r)
    rho_b <- tryCatch(mohns.rho(r, what = "BBmsy"), error = function(e) NA)
    rho_f <- tryCatch(mohns.rho(r, what = "FFmsy"), error = function(e) NA)
    cat(sprintf("Mohn's rho   B/Bmsy = %.3f   F/Fmsy = %.3f\n", rho_b, rho_f))
  })

  output$plot_retro <- renderPlot(
    {
      r <- retroR()
      req(r)
      plotspict.retro(r)
    },
    res = 120
  )

  # Management --------------------------------------------------------------
  observeEvent(input$manage_btn, {
    f <- fitR()
    if (is.null(f)) {
      showNotification("Fit the model first.", type = "warning")
      return()
    }
    manageR(NULL)
    manage_err(NULL)
    showNotification("Running management scenarios…", type = "message", duration = 2)
    out <- tryCatch(
      {
        TACyear <- tail(f$inp$timeC, 1) + 2
        manage(
          f,
          scenarios = c("currentF", "Fmsy", "noF", "ices"),
          maninterval = c(TACyear, TACyear + 1),
          maneval = TACyear + 1,
          verbose = FALSE
        )
      },
      error = function(e) {
        manage_err(conditionMessage(e))
        NULL
      }
    )
    manageR(out)
  })

  output$manage_status <- renderUI({
    if (!is.null(manage_err())) {
      div(
        class = "alert alert-danger p-2 small",
        "Management failed: ",
        manage_err()
      )
    } else if (!is.null(manageR())) {
      div(class = "text-success small", "Management scenarios complete.")
    } else {
      NULL
    }
  })

  output$manage_table <- renderDT({
    m <- manageR()
    req(m)
    tryCatch(
      {
        out <- sumspict.manage(m, include.unc = TRUE)$est |>
          as.data.frame() |>
          tibble::rownames_to_column("scenario")
        datatable(
          out,
          rownames = FALSE,
          options = list(dom = "t", paging = FALSE, scrollX = TRUE)
        ) |>
          formatRound(columns = which(sapply(out, is.numeric)), digits = 3)
      },
      error = function(e) {
        datatable(
          data.frame(error = conditionMessage(e)),
          options = list(dom = "t")
        )
      }
    )
  })

  output$plot_manage <- renderPlot(
    {
      m <- manageR()
      req(m)
      plotspict.hcr(m)
    },
    res = 120
  )
}

shinyApp(ui, server)

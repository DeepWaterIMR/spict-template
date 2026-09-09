# scaffold.R — create a new SPiCT assessment project.
#
# The project base — the folder layout, R/0_setup.R, R/report_helpers.R, R/docx_postprocess.R,
# docs/render.R, docs/assets/, and the .gitignore — comes from academic-writing's
# scaffold_document(). This script calls it, then overlays the SPiCT layer on top: the model
# helpers, the three documents' SPiCT content, the exploration workflow, and the Shiny explorer.
#
# There is one copy of the shared infrastructure and it lives in academic-writing. A fix to
# docs/render.R belongs there; a fix to R/spict_helpers.R belongs here.
#
# Usage:
#   source("<spict-template>/scaffold.R")
#   scaffold_spict("config.yaml", "../reb-spict")
#   scaffold_spict("config.yaml", "../reb-spict", dry = TRUE)   # preview
#
# Requires: yaml, and academic-writing installed. (install.packages("yaml"))

`%||%` <- function(a, b) if (is.null(a)) b else a

# The document types a SPiCT project gets. A benchmark year adds "benchmark-report"; pass it
# through `types` rather than editing this.
SPICT_DOCUMENT_TYPES <- c("data-report", "assessment-report", "advice-sheet")

# --- Read a YAML file as UTF-8, independent of the R locale --------------------------------
.read_yaml_utf8 <- function(path) {
  txt <- readChar(path, file.info(path)$size, useBytes = TRUE)
  Encoding(txt) <- "UTF-8"
  yaml::yaml.load(txt)
}

# --- Locate this pack -----------------------------------------------------------------------
# Order: explicit argument -> ~/.spict-template/config.json (written by spict-install) ->
# the folder this script was sourced from -> the working directory.
.find_spict_pack <- function(pack = NULL) {
  valid <- function(p) {
    !is.null(p) && dir.exists(file.path(p, "project-template")) &&
      dir.exists(file.path(p, "skills"))
  }
  if (valid(pack)) return(normalizePath(pack))

  cfg_json <- path.expand("~/.spict-template/config.json")
  if (file.exists(cfg_json) && requireNamespace("jsonlite", quietly = TRUE)) {
    p <- tryCatch(jsonlite::read_json(cfg_json)$spict_template_path, error = function(e) NULL)
    if (valid(p)) return(normalizePath(p))
  }

  for (frame in rev(sys.frames())) {
    f <- frame$ofile
    if (is.character(f) && length(f) && nzchar(f[[1]])) {
      p <- dirname(normalizePath(f[[1]], mustWork = FALSE))
      if (valid(p)) return(p)
    }
  }

  if (valid(getwd())) return(normalizePath(getwd()))

  stop("Cannot locate the spict-template repository. Pass it explicitly via `pack=`.",
       call. = FALSE)
}

# --- Locate academic-writing ------------------------------------------------------------------
# The dependency is real: without it there is no project skeleton to overlay onto.
.find_academic_writing <- function(academic_writing = NULL, spict_pack = NULL) {
  valid <- function(p) {
    !is.null(p) && file.exists(file.path(p, "scaffold.R")) &&
      dir.exists(file.path(p, "project-template"))
  }
  if (valid(academic_writing)) return(normalizePath(academic_writing))

  cfg_json <- path.expand("~/.academic-writing/config.json")
  if (file.exists(cfg_json) && requireNamespace("jsonlite", quietly = TRUE)) {
    p <- tryCatch(jsonlite::read_json(cfg_json)$academic_writing_path, error = function(e) NULL)
    if (valid(p)) return(normalizePath(p))
  }

  # Packs are conventionally cloned side by side.
  if (!is.null(spict_pack)) {
    sibling <- file.path(dirname(spict_pack), "academic-writing")
    if (valid(sibling)) return(normalizePath(sibling))
  }

  stop(
    "Cannot locate academic-writing, which spict-template builds on.\n",
    "Install it with the `academic-writing-install` skill, or from\n",
    "https://github.com/DeepWaterIMR/academic-writing, then try again.\n",
    "If it is already cloned, pass its path via `academic_writing=`.",
    call. = FALSE
  )
}

# --- Validate the SPiCT half of the config ------------------------------------------------------
.validate_spict_config <- function(cfg) {
  required <- c(
    "STOCK_CODE", "STOCK_NAME", "STOCK_SLUG", "STOCK_NAME_SNAKE", "STOCK_LATIN",
    "ICES_AREAS", "WORKING_GROUP", "ASSESSMENT_YEAR", "ADVICE_YEAR"
  )
  miss <- setdiff(required, names(cfg))
  if (length(miss)) {
    stop("config.yaml is missing required keys: ", paste(miss, collapse = ", "), call. = FALSE)
  }

  if (!grepl("^[a-z0-9-]+$", as.character(cfg$STOCK_SLUG))) {
    stop("STOCK_SLUG must be lower-case kebab-case (a-z, 0-9, -): got '",
         cfg$STOCK_SLUG, "'", call. = FALSE)
  }
  if (!grepl("^[a-z0-9_]+$", as.character(cfg$STOCK_NAME_SNAKE))) {
    stop("STOCK_NAME_SNAKE must be lower-case snake_case: got '",
         cfg$STOCK_NAME_SNAKE, "'", call. = FALSE)
  }
  if (as.numeric(cfg$ADVICE_YEAR) <= as.numeric(cfg$ASSESSMENT_YEAR)) {
    stop("ADVICE_YEAR must be later than ASSESSMENT_YEAR.", call. = FALSE)
  }

  # The priors are the values that make a state-space model with two short series
  # identifiable, so a project scaffolded without them is not a project.
  for (key in c("PRIOR_LOGR", "PRIOR_LOGBKFRAC", "PRIOR_LOGSDB")) {
    v <- cfg[[key]]
    if (is.null(v)) next
    if (length(unlist(v)) != 3) {
      stop(key, " must be three numbers: c(log(mean), sd, use).", call. = FALSE)
    }
  }

  if (isTRUE(cfg$EXPLORATORY) && is.null(cfg$OFFICIAL_ASSESSMENT)) {
    stop(
      "EXPLORATORY is true, so OFFICIAL_ASSESSMENT must name the model that is official ",
      "for this stock. The exploratory callout quotes it.",
      call. = FALSE
    )
  }

  invisible(TRUE)
}

#' Scaffold a new SPiCT assessment project
#'
#' @param config Path to a filled-in `config.yaml`. See `examples/redfish/config.yaml`.
#' @param target Directory to create. Must not exist, or must be empty.
#' @param types Document types to scaffold. Defaults to the three a SPiCT assessment needs;
#'   add `"benchmark-report"` in a benchmark year.
#' @param pack Path to the spict-template repository. Located automatically when omitted.
#' @param academic_writing Path to the academic-writing repository. Located automatically when
#'   omitted.
#' @param dry Preview without writing anything.
#' @return The target path, invisibly.
scaffold_spict <- function(config,
                           target,
                           types = SPICT_DOCUMENT_TYPES,
                           pack = NULL,
                           academic_writing = NULL,
                           dry = FALSE) {

  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("The 'yaml' package is required: install.packages('yaml')", call. = FALSE)
  }
  if (!file.exists(config)) stop("No such config file: ", config, call. = FALSE)

  pack <- .find_spict_pack(pack)
  aw <- .find_academic_writing(academic_writing, spict_pack = pack)
  overlay <- file.path(pack, "project-template")

  msg <- function(...) cat(if (dry) "[dry] " else "", ..., "\n", sep = "")

  cfg <- .read_yaml_utf8(config)
  .validate_spict_config(cfg)

  # --- Lay down the academic-writing base ---------------------------------------------------
  # scaffold_document() validates PROJECT_TITLE, PROJECT_SLUG, AUTHORS, AFFILIATIONS, copies
  # its own project-template, keeps only the requested document types, copies each type's Word
  # templates and CSL into docs/assets/, and stamps its own tokens.
  source(file.path(aw, "scaffold.R"), local = FALSE)
  scaffold_document(config = config, target = target, types = types, pack = aw, dry = dry)
  msg("Laid down the academic-writing base from ", aw)

  if (dry) {
    msg("Would overlay the SPiCT layer from ", overlay)
    return(invisible(target))
  }

  # --- Overlay the SPiCT layer -----------------------------------------------------------------
  file.copy(
    list.files(overlay, full.names = TRUE, all.files = TRUE, no.. = TRUE),
    target, recursive = TRUE, overwrite = TRUE, copy.mode = TRUE
  )
  msg("Overlaid the SPiCT layer")

  # academic-writing's generic data-report skeleton is replaced by the SPiCT assessment and the
  # exploration documents, which live one level deeper, and its generic data script by the
  # catch and index pipelines. Leaving either behind gives the project two answers to the same
  # question.
  unlink(file.path(target, "docs", "data-report", "data-report.qmd"))
  unlink(file.path(target, "R", "1_data.R"))
  unlink(file.path(target, "website"), recursive = TRUE)

  # --- Merge the bibliographies ------------------------------------------------------------------
  # academic-writing ships R, Quarto, knitr, ggplot2, and tidyverse; spict-template adds the
  # SPiCT and ICES references its documents cite. Appending keeps both.
  bib_main  <- file.path(target, "docs", "assets", "references.bib")
  bib_spict <- file.path(target, "docs", "assets", "spict-references.bib")
  if (file.exists(bib_spict)) {
    if (file.exists(bib_main)) {
      cat("\n\n", readLines(bib_spict, warn = FALSE), sep = "\n", file = bib_main, append = TRUE)
    } else {
      file.copy(bib_spict, bib_main)
    }
    unlink(bib_spict)
  }
  msg("Merged the SPiCT references into docs/assets/references.bib")

  # --- Rename the slug-bearing files ---------------------------------------------------------------
  slug <- as.character(cfg$STOCK_SLUG)
  for (f in list.files(target, recursive = TRUE, full.names = TRUE)) {
    if (grepl("^SLUG", basename(f))) {
      file.rename(f, file.path(dirname(f), sub("^SLUG", slug, basename(f))))
    }
  }
  msg("Renamed SLUG-* files to ", slug, "-*")

  # --- Stamp the tokens -------------------------------------------------------------------------
  # The overlay's files have not been through academic-writing's stamping, so both token sets
  # are applied here. `.author_block()` and `.affiliation_block()` come from the sourced
  # academic-writing scaffold, so the two packs cannot disagree about the YAML they emit.
  sentence_case <- function(x) {
    x <- as.character(x)
    paste0(toupper(substring(x, 1, 1)), substring(x, 2))
  }

  tokens <- c(
    # academic-writing's set, for the overlay files
    "{{PROJECT_TITLE}}"      = as.character(cfg$PROJECT_TITLE),
    "{{PROJECT_SLUG}}"       = as.character(cfg$PROJECT_SLUG),
    "{{PROJECT_YEAR}}"       = as.character(cfg$PROJECT_YEAR %||% cfg$ASSESSMENT_YEAR),
    "{{AUTHOR_BLOCK}}"       = .author_block(cfg$AUTHORS),
    "{{AFFILIATION_BLOCK}}"  = .affiliation_block(cfg$AFFILIATIONS),
    "{{LANGUAGE}}"           = as.character(cfg$LANGUAGE %||% "en-US"),
    "{{FIG_WIDTH_DOUBLE}}"   = format(round((cfg$FIG_WIDTH_DOUBLE_MM %||% 170) / 25.4, 2)),
    "{{FIG_WIDTH_SINGLE}}"   = format(round((cfg$FIG_WIDTH_SINGLE_MM %||% 85) / 25.4, 2)),
    "{{TODAY}}"              = format(Sys.Date(), "%Y-%m-%d"),
    # spict-template's set
    "{{STOCK_CODE}}"         = as.character(cfg$STOCK_CODE),
    "{{STOCK_NAME}}"         = as.character(cfg$STOCK_NAME),
    "{{STOCK_NAME_SENTENCE}}" = sentence_case(cfg$STOCK_NAME),
    "{{STOCK_SLUG}}"         = slug,
    "{{STOCK_NAME_SNAKE}}"   = as.character(cfg$STOCK_NAME_SNAKE),
    "{{STOCK_LATIN}}"        = as.character(cfg$STOCK_LATIN),
    "{{ICES_AREAS}}"         = as.character(cfg$ICES_AREAS),
    "{{ICES_STOCK_ID}}"      = as.character(cfg$ICES_STOCK_ID %||% "[stock ID not set]"),
    "{{WORKING_GROUP}}"      = as.character(cfg$WORKING_GROUP),
    "{{WORKING_GROUP_LONG}}" = as.character(cfg$WORKING_GROUP_LONG %||% cfg$WORKING_GROUP),
    "{{ASSESSMENT_YEAR}}"    = as.character(cfg$ASSESSMENT_YEAR),
    "{{ADVICE_YEAR}}"        = as.character(cfg$ADVICE_YEAR),
    "{{PREV_ADVICE_YEAR}}"   = as.character(cfg$PREV_ADVICE_YEAR %||%
                                              (as.numeric(cfg$ASSESSMENT_YEAR) - 1)),
    "{{FIRST_DATA_YEAR}}"    = as.character(cfg$FIRST_DATA_YEAR %||% "")
  )

  text_ext <- c("qmd", "rmd", "r", "md", "yaml", "yml", "css", "bib", "tex", "lua")
  files <- list.files(target, recursive = TRUE, full.names = TRUE, all.files = TRUE)
  files <- unique(files[
    tolower(tools::file_ext(files)) %in% text_ext | basename(files) == "VERSION"
  ])

  for (f in files) {
    txt <- tryCatch({
      s <- readChar(f, file.info(f)$size, useBytes = TRUE); Encoding(s) <- "UTF-8"; s
    }, error = function(e) NULL)
    if (is.null(txt)) next
    new <- txt
    for (tok in names(tokens)) new <- gsub(tok, tokens[[tok]], new, fixed = TRUE)
    if (!identical(new, txt)) writeBin(charToRaw(enc2utf8(new)), f)
  }
  msg("Stamped identity tokens")

  writeLines(c("version: 0.1.0", paste0("date: ", Sys.Date())), file.path(target, "VERSION"))

  # --- Sanity check ---------------------------------------------------------------------------
  # BibTeX protects proper nouns with doubled braces — {{ICES}} — so the bibliography is
  # excluded from the check rather than reported as an unstamped placeholder every time.
  left <- character()
  for (f in files) {
    if (!file.exists(f) || tolower(tools::file_ext(f)) == "bib") next
    txt <- tryCatch({
      s <- readChar(f, file.info(f)$size, useBytes = TRUE); Encoding(s) <- "UTF-8"; s
    }, error = function(e) "")
    if (grepl("\\{\\{[A-Z_]+\\}\\}", txt)) left <- c(left, f)
  }
  if (length(left)) {
    warning("Leftover placeholders in:\n  ", paste(left, collapse = "\n  "))
  } else {
    msg("No leftover placeholders.")
  }

  message("\nScaffolded '", cfg$PROJECT_TITLE, "' at: ", normalizePath(target))
  message("Next:")
  message("  1. cd into the project and run: git init   (local only, no remote)")
  message("  2. Record the questionnaire answers in ai/memory/scaffold-interview.md")
  message("  3. Put the raw catch sources and the index .rds in data/source/")
  message("  4. Step 1 — compile the data (spict-compile-data)")
  message("")
  message("  The priors in config.yaml are placeholders until you replace them.")

  invisible(target)
}

# ─────────────────────────────────────────────────────────────────────────────
# scaffold.R — instantiate this template for a specific stock.
#
# Reads stock_config.yaml and does literal text find-replace of {{KEY}} → VALUE
# across every text file in the repo. Binary files (.docx, .xlsx, .rds, images)
# are skipped. Files inside excluded directories (.git/, data/, docs/, figures/,
# src/example_advice_sheets/) are skipped.
#
# Usage from the project root:
#
#   source("scaffold.R")
#   scaffold("stock_config.yaml")              # apply config, write changes
#   scaffold("stock_config.yaml", dry = TRUE)  # report what would change
#
# After running, walk through memory/template_open_items.md.
# ─────────────────────────────────────────────────────────────────────────────

scaffold <- function(config_path = "stock_config.yaml", dry = FALSE) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    install.packages("yaml")
  }
  # Read with explicit UTF-8 so non-ASCII comments don't break parsing on
  # systems whose default locale isn't UTF-8.
  yaml_text <- paste(
    readLines(config_path, encoding = "UTF-8", warn = FALSE),
    collapse = "\n"
  )
  config <- yaml::yaml.load(yaml_text)

  required_keys <- c(
    "STOCK_CODE", "STOCK_NAME", "STOCK_NAME_LOWER_SNAKE", "STOCK_LATIN",
    "ICES_AREAS", "ICES_STOCK_ID", "ASSESSMENT_YEAR", "ADVICE_YEAR",
    "PREV_ADVICE_YEAR", "FIRST_DATA_YEAR", "WORKING_GROUP"
  )
  missing <- setdiff(required_keys, names(config))
  if (length(missing)) {
    stop("stock_config.yaml is missing keys: ", paste(missing, collapse = ", "))
  }

  # Coerce numeric values to strings; YAML may parse 2026 as integer.
  config <- lapply(config, as.character)

  text_exts <- c("qmd", "R", "md", "css", "yaml", "yml", "toml", "csl", "bib", "Rmd", "txt", "lua")

  exclude_dirs <- c(".git", "data", "docs", "figures",
                    file.path("src", "example_advice_sheets"))

  # Meta-files about scaffolding itself — both contain literal `{{KEY}}`
  # in their documentation and would trigger false warnings.
  exclude_files <- c("scaffold.R", "stock_config.yaml")

  all_files <- list.files(".", recursive = TRUE, all.files = FALSE, no.. = TRUE)

  # Filter to text files outside excluded dirs and not meta-files.
  is_excluded <- function(path) {
    any(vapply(exclude_dirs, function(d) {
      identical(path, d) || startsWith(path, paste0(d, "/"))
    }, logical(1)))
  }
  candidates <- all_files[
    !vapply(all_files, is_excluded, logical(1)) &
      !all_files %in% exclude_files &
      tools::file_ext(all_files) %in% text_exts
  ]

  pattern_for <- function(key) paste0("{{", key, "}}")

  changes <- list()
  for (f in candidates) {
    raw <- readLines(f, warn = FALSE, encoding = "UTF-8")
    original <- raw
    for (key in names(config)) {
      raw <- gsub(pattern_for(key), config[[key]], raw, fixed = TRUE)
    }
    if (!identical(raw, original)) {
      n_changed <- sum(raw != original)
      changes[[f]] <- n_changed
      if (!dry) {
        writeLines(raw, f, useBytes = TRUE)
      }
    }
  }

  if (length(changes) == 0) {
    message("scaffold(): no files contained placeholders. Nothing to do.")
    return(invisible(NULL))
  }

  verb <- if (dry) "would modify" else "modified"
  message(sprintf("scaffold(): %s %d files:", verb, length(changes)))
  for (f in names(changes)) {
    message(sprintf("  %s (%d lines)", f, changes[[f]]))
  }

  # Sanity check: warn on any remaining {{...}} placeholders.
  if (!dry) {
    remaining <- c()
    for (f in candidates) {
      raw <- readLines(f, warn = FALSE, encoding = "UTF-8")
      hits <- grep("\\{\\{[A-Z_]+\\}\\}", raw, value = TRUE)
      if (length(hits)) {
        remaining <- c(remaining, sprintf("  %s:\n    %s", f, paste(hits, collapse = "\n    ")))
      }
    }
    if (length(remaining)) {
      warning(
        "scaffold(): some {{...}} placeholders remain unfilled. Likely keys missing from stock_config.yaml:\n",
        paste(remaining, collapse = "\n")
      )
    } else {
      message("scaffold(): all known placeholders filled. Next: walk through memory/template_open_items.md.")
    }
  }

  invisible(changes)
}

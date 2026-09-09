# validate-scaffold.R — structural checks on a synthetic scaffold.
#
# Run from the spict-template repository root:
#
#   Rscript config/validate-scaffold.R
#
# It scaffolds a project into a temporary directory against examples/redfish/config.yaml,
# parses every R file and every R chunk, validates each document's YAML against the contract,
# and confirms no placeholder survived. It deliberately does NOT fit a model or touch real
# data: this checks the contract, not the science.
#
# academic-writing must be installed, or its path passed as SPICT_ACADEMIC_WRITING.

source("scaffold.R")

pack <- normalizePath(".")
aw <- Sys.getenv("SPICT_ACADEMIC_WRITING", unset = "")
if (!nzchar(aw)) aw <- NULL

workspace <- Sys.getenv("SPICT_TEMPLATE_TEST_DIR", unset = tempfile("spict-scaffold-"))
dir.create(workspace, recursive = TRUE, showWarnings = FALSE)

# Read and write as UTF-8 bytes so Scandinavian characters survive whatever the R locale is —
# the same reason scaffold.R has .read_yaml_utf8().
write_yaml_utf8 <- function(x, path) {
  writeBin(charToRaw(enc2utf8(yaml::as.yaml(x))), path)
}

cfg <- .read_yaml_utf8("examples/redfish/config.yaml")

# Non-ASCII names, quotes, and a second author with two affiliations: the metadata shapes that
# break naive string interpolation.
cfg$AUTHORS <- list(
  list(name = 'Test: Åuthor "One"', affiliation = "test"),
  list(name = "Second Author", affiliation = "other")
)
cfg$AFFILIATIONS <- list(
  list(id = "test", name = "Synthetic Institute"),
  list(id = "other", name = "Other Institute")
)

config_file <- file.path(workspace, "config.yaml")
write_yaml_utf8(cfg, config_file)

target <- file.path(workspace, "project")
scaffold_spict(config_file, target, pack = pack, academic_writing = aw)

# --- Layout -------------------------------------------------------------------------------
stopifnot(all(dir.exists(file.path(target, c(
  "R", "ai/memory", "ai/tests", "ai/review", "config", "data/source", "data/output",
  "docs/assets", "docs/data-report/spict-assessment", "docs/data-report/exploration",
  "docs/assessment-report", "docs/advice-sheet", "figures", "logs", "shiny/spict-explorer"
)))))

# The generic academic-writing skeletons must be gone: two answers to the same question is
# worse than one wrong answer.
stopifnot(!any(file.exists(file.path(target, c(
  "docs/data-report/data-report.qmd", "R/1_data.R", "memory"
)))))

stopifnot(
  file.exists(file.path(target, ".here")),
  .read_yaml_utf8(file.path(target, "VERSION"))$version == "0.1.0",
  file.exists(file.path(target, "docs/assets/references.bib")),
  !file.exists(file.path(target, "docs/assets/spict-references.bib"))
)

# The slug-bearing document was renamed.
stopifnot(file.exists(file.path(
  target, "docs/data-report/spict-assessment",
  paste0(cfg$STOCK_SLUG, "-spict-assessment.qmd")
)))

# Both bibliographies survived the merge.
bib <- readLines(file.path(target, "docs/assets/references.bib"), warn = FALSE)
stopifnot(
  any(grepl("@Manual{rcoreteam", bib, fixed = TRUE)),
  any(grepl("@article{pedersen2017", bib, fixed = TRUE))
)

# --- R files ------------------------------------------------------------------------------
for (path in list.files(file.path(target, "R"), "\\.R$", full.names = TRUE)) parse(path)
invisible(parse(file.path(target, "docs/render.R")))
invisible(parse(file.path(target, "shiny/spict-explorer/app.R")))

# --- Documents ----------------------------------------------------------------------------
qmds <- list.files(file.path(target, "docs"), "\\.qmd$", recursive = TRUE, full.names = TRUE)
stopifnot(length(qmds) == 5L)

read_header <- function(text) {
  ends <- which(trimws(text) == "---")
  yaml::yaml.load(paste(text[(ends[1] + 1):(ends[2] - 1)], collapse = "\n"))
}

for (path in qmds) {
  text <- readLines(path, warn = FALSE, encoding = "UTF-8")

  # No placeholder survived stamping.
  stopifnot(!any(grepl("\\{\\{[A-Z_]+\\}\\}", text)))

  # Every R chunk parses, and no chunk option is given twice.
  in_r <- FALSE
  code <- character()
  for (line in text) {
    if (grepl("^```\\{r", line)) {
      in_r <- TRUE
      code <- character()
    } else if (in_r && grepl("^```", line)) {
      parse(text = code)
      option_lines <- grep("^#\\| ", code, value = TRUE)
      option_keys <- sub("^#\\| ([^:]+):.*$", "\\1", option_lines[grepl(":", option_lines)])
      stopifnot(!anyDuplicated(option_keys))
      in_r <- FALSE
    } else if (in_r) {
      code <- c(code, line)
    }
  }
  stopifnot(!in_r)

  header <- read_header(text)

  # Assets referenced from the YAML resolve relative to the document, not the project root.
  for (key in c("csl", "bibliography")) {
    if (!is.null(header[[key]])) {
      stopifnot(file.exists(file.path(dirname(path), header[[key]])))
    }
  }
  stopifnot(header$`published-title` == "Version")
}

# --- The assessment data report ---------------------------------------------------------------
assessment <- qmds[grepl("spict-assessment\\.qmd$", qmds)]
text <- readLines(assessment, warn = FALSE, encoding = "UTF-8")
header <- read_header(text)

# The name round-trips through a file, so the two sides carry different encoding marks even
# when the bytes agree. Under Rscript's C locale enc2utf8() will not reconcile them, so the
# comparison is made on the bytes.
same_text <- function(a, b) {
  identical(charToRaw(as.character(a)), charToRaw(as.character(b)))
}

stopifnot(
  same_text(header$author[[1]]$name, cfg$AUTHORS[[1]]$name),
  header$affiliations[[1]]$id == "test",
  header$author[[1]]$affiliations[[1]]$ref == "test",
  header$format$html$`toc-title` == header$title,
  isTRUE(header$format$html$`code-fold`),
  header$format$html$`code-summary` == "Show code",
  # `echo: false` would silence every chunk and make code-fold do nothing. Its absence is the
  # one YAML difference that makes this a data report.
  !identical(header$execute$echo, FALSE),
  header$format$html$`fig-width` == 6.69,
  header$params$assessment_year == cfg$ASSESSMENT_YEAR,
  header$params$advice_year == cfg$ADVICE_YEAR,
  any(text == "# References {.unnumbered}"),
  which(text == "# References {.unnumbered}") <
    which(text == "# Appendix: analysis scripts {.appendix}")
)

# Scripts named in the appendix must exist: readLines() runs at render time even under
# eval: false, so a missing script breaks the render rather than being papered over.
for (script in regmatches(text, gregexpr('here::here\\("R", "[^"]+"\\)', text))) {
  for (s in script) {
    file <- sub('.*"R", "([^"]+)".*', "\\1", s)
    stopifnot(file.exists(file.path(target, "R", file)))
  }
}

# --- The hard constraints ------------------------------------------------------------------------
# The exploratory callout is the only thing standing between a rendered .docx and a SPiCT
# supplement being mistaken for the official assessment. Check it is present where the config
# says the assessment is exploratory.
if (isTRUE(cfg$EXPLORATORY)) {
  for (path in c(assessment, qmds[grepl("advice-sheet\\.qmd$", qmds)])) {
    body <- readLines(path, warn = FALSE, encoding = "UTF-8")
    stopifnot(
      any(grepl("callout-warning", body, fixed = TRUE)),
      any(grepl("not official", body, fixed = TRUE))
    )
  }
}

# --- Bad metadata must fail, before anything is created --------------------------------------------
cfg_bad <- cfg
cfg_bad$AUTHORS[[1]]$affiliation <- "missing"
write_yaml_utf8(cfg_bad, config_file)
bad <- try(
  scaffold_spict(config_file, file.path(workspace, "invalid"), pack = pack, academic_writing = aw),
  silent = TRUE
)
stopifnot(inherits(bad, "try-error"), !dir.exists(file.path(workspace, "invalid")))

# A stock whose advice year precedes its assessment year is a typo, not a configuration.
cfg_bad <- cfg
cfg_bad$ADVICE_YEAR <- cfg$ASSESSMENT_YEAR - 1
write_yaml_utf8(cfg_bad, config_file)
bad <- try(
  scaffold_spict(config_file, file.path(workspace, "invalid2"), pack = pack, academic_writing = aw),
  silent = TRUE
)
stopifnot(inherits(bad, "try-error"), !dir.exists(file.path(workspace, "invalid2")))

# An exploratory assessment that cannot name the official model cannot write its own callout.
cfg_bad <- cfg
cfg_bad$OFFICIAL_ASSESSMENT <- NULL
write_yaml_utf8(cfg_bad, config_file)
bad <- try(
  scaffold_spict(config_file, file.path(workspace, "invalid3"), pack = pack, academic_writing = aw),
  silent = TRUE
)
stopifnot(inherits(bad, "try-error"), !dir.exists(file.path(workspace, "invalid3")))

message("\nvalidate-scaffold.R: all checks passed.")
message("Scaffolded project left at: ", target)

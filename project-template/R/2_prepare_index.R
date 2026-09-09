# 2_prepare_index.R — the producer's index output into the series SPiCT is fitted to.
#
# ─────────────────────────────────────────────────────────────────────────────────────────
# The index is not produced here. It comes from a separate producer — for the Barents Sea
# redfishes, an sdmTMB spatiotemporal index built with index-template
# (https://github.com/DeepWaterIMR/index-template) — and this script adapts whatever shape
# that producer emits to the one contract everything downstream relies on:
#
#   data/output/<STOCK_SLUG>_index.rds    year, est, se   (lwr and upr optional, for plots)
#
# The extraction below assumes the producer's named-list-of-data-frames shape. A CPUE series
# is rarely a list; when that is what you have, delete the list indexing rather than wrapping
# a single data frame in a list to satisfy code that expects one.
#
# See the pack's knowledge/indices.md before editing.
# ─────────────────────────────────────────────────────────────────────────────────────────

source(here::here("R", "0_setup.R"))

stock_slug <- cfg$STOCK_SLUG

# --- Read ---------------------------------------------------------------------------------
# Pin the producer's commit or tag in ai/memory/index-data-sources.md. An index that changed
# between last year's assessment and this one, unrecorded, is indistinguishable from a stock
# that changed.

raw <- readRDS(file.path(source_dir, paste0(cfg$STOCK_CODE, "-assessment-indices.rds")))

# --- Select the variant ----------------------------------------------------------------------
# INDEX_ELEMENT names the variant. Selecting by name rather than by position matters: `[[2]]`
# silently becomes a different variant the first time the producer adds one.

element <- cfg$INDEX_ELEMENT

index_raw <- if (is.data.frame(raw)) {
  raw
} else if (is.character(element)) {
  if (!element %in% names(raw)) {
    stop(
      "INDEX_ELEMENT '", element, "' is not one of: ", paste(names(raw), collapse = ", "),
      call. = FALSE
    )
  }
  raw[[element]]
} else {
  raw[[as.integer(element)]]
}

# --- Adapt to the contract ---------------------------------------------------------------------

if (!"se" %in% names(index_raw) && "cv" %in% names(index_raw)) {
  # A CV on the natural scale is approximately the standard error on the log scale for small
  # CVs. Convert once, here, rather than in a document.
  index_raw$se <- sqrt(log1p(index_raw$cv^2))
}

missing_cols <- setdiff(c("year", "est", "se"), names(index_raw))
if (length(missing_cols)) {
  stop(
    "Index is missing required columns: ", paste(missing_cols, collapse = ", "),
    ". Available: ", paste(names(index_raw), collapse = ", "),
    call. = FALSE
  )
}

index <- index_raw |>
  dplyr::select(dplyr::any_of(c("year", "est", "se", "lwr", "upr"))) |>
  dplyr::filter(!is.na(est), !is.na(se)) |>
  dplyr::arrange(year)

# --- Check ---------------------------------------------------------------------------------------

if (any(index$se <= 0)) stop("Index standard errors must be positive.", call. = FALSE)
if (anyDuplicated(index$year)) stop("Index has duplicated years.", call. = FALSE)

message(
  "Index '", if (is.character(element)) element else paste("element", element), "': ",
  min(index$year), "-", max(index$year), ", ", nrow(index), " observations, ",
  "timing ", cfg$INDEX_TIMING, " of the year. ",
  "Confirm that timing matches when the survey actually runs."
)

# --- Write ---------------------------------------------------------------------------------------

saveRDS(index, file.path(output_dir, paste0(stock_slug, "_index.rds")))

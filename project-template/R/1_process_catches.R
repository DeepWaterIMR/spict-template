# 1_process_catches.R — raw catch sources into the series SPiCT is fitted to.
#
# ─────────────────────────────────────────────────────────────────────────────────────────
# THIS IS A WORKED EXAMPLE, NOT A DEFAULT.
#
# What follows is the beaked redfish pipeline: the IMR landings database for Norwegian
# catches from 2022, the JRN-AFWG international catch spreadsheet before that, Russian and
# other-nation catches from the spreadsheet, and a reconstructed total before 1993. Almost
# every stock combines a different set of sources on a different splice. Expect to REPLACE
# this script rather than edit it.
#
# What must not change is the contract:
#
#   data/output/<STOCK_SLUG>_catches.rds   year (integer), total (TONNES), no missing years
#   data/output/<STOCK_SLUG>_landings.rds  year, one column per country or fleet
#   data/output/<STOCK_SLUG>_gear.rds      year, gear, tonnes           (optional)
#
# Raw inputs live in data/source/ and are git-ignored, as are the outputs. See the pack's
# knowledge/catch-data.md for the questions to settle before writing your version.
# ─────────────────────────────────────────────────────────────────────────────────────────

source(here::here("R", "0_setup.R"))

assessment_year <- cfg$ASSESSMENT_YEAR
stock_slug <- cfg$STOCK_SLUG

# --- Definitions ---------------------------------------------------------------------------
# IMR main areas making up ICES subareas 1 and 2.
main_area_filter <- c(0:7, 10:18, 20:27, 30, 34:39, 50)

# --- Read ------------------------------------------------------------------------------------

catch_imr <- readRDS(file.path(source_dir, "catches-from-imr-database.rds"))

catch_ices <- readxl::read_excel(
  file.path(source_dir, "sebastes-international-catch-afwg.xlsx"),
  sheet = "s mentella",
  range = "F2:AD100"
) |>
  dplyr::filter(!is.na(Year)) |>
  tidyr::pivot_longer(-Year) |>
  dplyr::mutate(
    name = dplyr::case_when(
      name %in% c("Total", "Norway", "Russia") ~ name,
      .default = "Other"
    )
  ) |>
  dplyr::summarise(value = sum(value, na.rm = TRUE), .by = c(Year, name)) |>
  tidyr::pivot_wider(names_from = name, values_from = value) |>
  dplyr::rename(year = Year) |>
  dplyr::mutate(dplyr::across(dplyr::everything(), \(x) dplyr::na_if(x, 0)))

# --- Allocate by nation -----------------------------------------------------------------------
# Norwegian catches come from the IMR database from 2022, when species attribution in the
# sales notes became reliable for redfish, and from the working-group spreadsheet before that.

nor_catches <- catch_imr |>
  dplyr::filter(
    main_area %in% main_area_filter,
    species == "Snabeluer",
    nation == "NOR",
    year >= 2022, year < assessment_year
  ) |>
  dplyr::summarise(tonnes = sum(weight) / 1e3, .by = year) |>
  dplyr::bind_rows(
    catch_ices |>
      dplyr::filter(year < 2022, year >= 1993) |>
      dplyr::select(year, tonnes = Norway)
  ) |>
  dplyr::arrange(year)

#' Carry the previous year forward when the most recent year has not been reported
#'
#' Working-group spreadsheets routinely lag by a year for some nations. Carrying the previous
#' value forward keeps the series gap-free; the advice sheet marks the year as preliminary.
#' Anything more elaborate than a carry-forward is a decision to record in ai/memory/.
carry_forward_last_year <- function(x, to_year) {
  if (to_year %in% x$year) return(x)
  previous <- x$tonnes[x$year == to_year - 1]
  if (!length(previous)) return(x)
  dplyr::bind_rows(x, dplyr::tibble(year = to_year, tonnes = previous))
}

rus_catches <- catch_ices |>
  dplyr::filter(year < assessment_year, year >= 1993) |>
  dplyr::select(year, tonnes = Russia) |>
  carry_forward_last_year(assessment_year - 1)

other_catches <- catch_ices |>
  dplyr::filter(year < assessment_year, year >= 1993) |>
  dplyr::select(year, tonnes = Other) |>
  carry_forward_last_year(assessment_year - 1)

# Before 1993 only a reconstructed total exists, with no nation breakdown.
hist_catches <- catch_ices |>
  dplyr::filter(year < 1993) |>
  dplyr::select(year, tonnes = Total)

# --- Combine ------------------------------------------------------------------------------------

landings <- nor_catches |>
  dplyr::rename(Norway = tonnes) |>
  dplyr::full_join(dplyr::rename(rus_catches, Russia = tonnes), by = "year") |>
  dplyr::full_join(dplyr::rename(other_catches, Other = tonnes), by = "year") |>
  dplyr::full_join(dplyr::rename(hist_catches, Historical = tonnes), by = "year") |>
  dplyr::arrange(year)

catches <- landings |>
  dplyr::rowwise() |>
  dplyr::mutate(
    total = sum(dplyr::c_across(-year), na.rm = TRUE)
  ) |>
  dplyr::ungroup() |>
  dplyr::select(year, total)

# --- Check ---------------------------------------------------------------------------------------
# A gap in the series is not something SPiCT reports; it is a biomass trajectory that quietly
# reflects the gap. Fail here instead.

gaps <- setdiff(seq(min(catches$year), max(catches$year)), catches$year)
if (length(gaps)) {
  stop("Catch series has missing years: ", paste(gaps, collapse = ", "))
}
if (min(catches$year) != cfg$FIRST_DATA_YEAR) {
  warning(
    "First catch year (", min(catches$year), ") does not match FIRST_DATA_YEAR (",
    cfg$FIRST_DATA_YEAR, ") in config.yaml. One of the two is wrong."
  )
}

message(
  "Catch series: ", min(catches$year), "-", max(catches$year), ", ",
  nrow(catches), " years, ", round(sum(catches$total)), " t total. ",
  "Compare the recent years against the last working-group report before going on."
)

# --- Write -----------------------------------------------------------------------------------------

saveRDS(catches, file.path(output_dir, paste0(stock_slug, "_catches.rds")))
saveRDS(landings, file.path(output_dir, paste0(stock_slug, "_landings.rds")))

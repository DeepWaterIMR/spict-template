## ---------------------------
##
## Script name: Catches
##
## Purpose of script: Load and process catch data for SPiCT input.
##
## NOTE FOR TEMPLATE USERS:
##   This script is a WORKED EXAMPLE from the beaked redfish (reb) stock.
##   It combines IMR database extracts with the JRN-AFWG international
##   catch spreadsheet and is **expected to be rewritten per stock**.
##
##   The CONTRACT to keep is the output: a CSV at
##     data/catches/{{STOCK_NAME}}_catches_for_SPiCT.csv
##   with at minimum a `year` column and a `total` column (catches in
##   tonnes). Additional country/component columns are fine; the
##   assessment qmd selects what it needs.
##
## ---------------------------

## Source or list custom functions used within the script

if (!exists("theme_cust")) {
  source("src/0_setup.R")
}

if (!exists("assessment_year")) {
  assessment_year <- {{ASSESSMENT_YEAR}}
}

## ---------------------------

## Definitions

MainAreaFilter <- c(0:7, 10:18, 20:27, 30, 34:39, 50) # ICES areas 1 and 2

## Read data ####

### Catch data downloaded from IMR database
catchIMR <- readRDS("data/catches/Catches from IMR database.rds")

### Catch data from the ICES spreadsheet
catchICES <- readxl::read_excel(
  "data/catches/Sebastes men and nor international catch from AFWG.xlsx",
  "s mentella",
  range = "F2:AD100"
) %>%
  filter(!is.na(Year)) %>%
  tidyr::pivot_longer(c(-Year)) %>%
  mutate(
    name = case_when(
      name == "Total" ~ "Total",
      name == "Norway" ~ "Norway",
      name == "Russia" ~ "Russia",
      TRUE ~ "Other"
    )
  ) %>%
  group_by(Year, name) %>%
  reframe(value = sum(value, na.rm = TRUE)) %>%
  pivot_wider(names_from = name, values_from = value) %>%
  rename("year" = "Year") |>
  mutate(across(everything(), na_if, 0))

## Catch allocation (a bit clumsy way, reproduced from reb-gadget) ####

### Nor ####

Nor_catches <- catchIMR %>%
  bind_rows() %>%
  filter(
    main_area %in% MainAreaFilter,
    species == "Snabeluer",
    nation == "NOR"
  ) %>%
  filter(year >= 2022, year < assessment_year) %>%
  group_by(year) %>%
  reframe(total_weight = sum(weight) / 1e3) %>% # Convert to tonnes
  bind_rows(
    catchICES %>%
      filter(year < 2022, year >= 1993) %>%
      dplyr::select(year, Norway) |>
      rename(total_weight = Norway)
  ) %>%
  arrange(year)

### Rus ####

Rus_catches <- catchICES %>%
  filter(year < assessment_year, year >= 1993) %>%
  dplyr::select(year, Russia) %>%
  rename(total_weight = Russia)

## If missing, assume the catches in the last year are equal to the previous year
if (!(assessment_year - 1) %in% Rus_catches$year) {
  Rus_catches <- Rus_catches %>%
    add_row(
      year = assessment_year - 1,
      total_weight = Rus_catches %>%
        filter(year == assessment_year - 2) %>%
        pull(total_weight)
    )
}

### Int ####

Int_catches <- catchICES %>%
  filter(year < assessment_year, year >= 1993) %>%
  dplyr::select(year, Other) %>%
  rename(total_weight = Other)

## If missing, assume the catches in the last year are equal to the previous year
if (!(assessment_year - 1) %in% Int_catches$year) {
  Int_catches <- Int_catches %>%
    add_row(
      year = assessment_year - 1,
      total_weight = Int_catches %>%
        filter(year == assessment_year - 2) %>%
        pull(total_weight)
    )
}


### Hist ####

Hist_catches <- catchICES %>%
  filter(year < 1993) %>%
  dplyr::select(year, Total) %>%
  rename(total_weight = Total)

# All catches compiled ####

Catches <- full_join(
  Nor_catches |> rename(nor = total_weight),
  Rus_catches |> rename(rus = total_weight),
  by = "year"
) |>
  full_join(Int_catches |> rename(int = total_weight), by = "year") |>
  full_join(Hist_catches |> rename(hist = total_weight), by = "year") |>
  arrange(year) |>
  rowwise() |>
  mutate(total = sum(c(nor, rus, int, hist), na.rm = TRUE))

## Save data ####

write.csv(
  Catches,
  "data/catches/{{STOCK_NAME}}_catches_for_SPiCT.csv",
  row.names = FALSE
)

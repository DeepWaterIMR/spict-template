# Catches

Place the stock's catch series here. The qmd pipeline reads two files:

| File | Purpose | Consumer |
|---|---|---|
| `{{STOCK_NAME}}_catches_for_SPiCT.csv` | The processed catch series fed into the SPiCT model. Min cols: `year`, `total` (catches in tonnes). | `1 assessment model.qmd`, `src/exploration/1 fit model.R` |
| `{{STOCK_NAME}}_landings_for_SPiCT.csv` | Annual landings table used in the advice sheet text (often semicolon-separated, with one column per country/nation plus an `OtherNations` column). | `2 advice sheet.qmd` |
| `landings_by_gear_pct_allNations.csv` *(optional)* | Gear-breakdown percentages for the advice sheet's "catch by gear" table. | `2 advice sheet.qmd` |

Raw inputs (database extracts, ICES working-group spreadsheets, country submissions) live here too, named descriptively. `src/1_process_catches.R` is the per-stock script that turns raw inputs into the processed files above — **expect to rewrite it for each stock**.

## Where do catches come from?

At IMR Deep-water, catch data typically come from one or more of:

- **IMR landings database** — Norwegian sales notes, accessed via an internal extract (`.rds` file is committed to the repo).
- **ICES working-group spreadsheets** — multi-tab `.xlsx`, one tab per species, with columns per country plus a total.
- **StoX outputs** — for stocks where landings are derived from StoX runs.
- **Bespoke country submissions** — Russian, Faroese, etc. data delivered via the working group.
- **Reconstructed historical series** — pre-1970 from grey literature, often as a single "Hist" column.

For the new stock, the **scaffolding agent should ask the analyst** what combination applies (see `memory/template_scaffold_interview.md` § 2) and record sources in `memory/catch_data_sources.md`.

## Sensitivity note

Norwegian sales-note data may carry confidentiality constraints. Confirm with the analyst before committing raw IMR extracts to a public repo; if in doubt, keep the repo private and add the raw file to `.gitignore` while keeping the processed (aggregated) CSV in.

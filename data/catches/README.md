# Catches

Place the stock's catch series here. Conventions used by `src/1_process_catches.R`:

- Raw input (e.g. an IMR DB export): an `.rds` or `.xlsx`/`.csv` named explicitly (e.g. `{{STOCK_CODE}}_catches_raw.rds`).
- Processed output (consumed by `1 assessment model.qmd`): `{{STOCK_NAME}}_catches_for_SPiCT.csv` with columns `year, catch`.
- Optional gear breakdown for the advice sheet: `landings_by_gear_pct_allNations.csv`.

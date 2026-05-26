# spict-template

A standardized scaffold for **IMR exploratory SPiCT assessments** maintained by
the Deep-water species and cartilaginous fish group at the Institute of Marine
Research (Havforskningsinstituttet, Norway). Derived from the `reg-spict`
(golden redfish) and `reb-spict` (beaked redfish) projects.

> **This is a template repository**, not a runnable assessment. Do not render
> from this repo — scaffold a new project from it first.

## What you get

- Production Quarto pipeline: `1 assessment model.qmd` → `2 advice sheet.qmd`,
  rendered together via `run_assessment.R` with canonical year parameters.
- Exploration workflow under `src/exploration/` (benchmark fits, side-by-side
  comparisons, standalone Shiny explorer).
- ICES advice-sheet Word template auto-generated from Pandoc's default
  `reference.docx` at render time.
- A `memory/` folder for **shared, committed, multi-agent project memory** —
  every collaborator (human or AI) reads and writes here.
- `AGENTS.md` instructing any LLM on how to participate.

## Scaffolding a new stock project

1. Create the new project from this template on GitHub:

   ```bash
   gh repo create DeepWaterIMR/<stock>-spict \
     --template DeepWaterIMR/spict-template \
     --private --clone
   cd <stock>-spict
   ```

2. Fill in `stock_config.yaml`:

   ```yaml
   STOCK_CODE:             reb           # ICES short code, lower-case
   STOCK_NAME:             BeakedRedfish # CamelCase, used in file names
   STOCK_NAME_LOWER_SNAKE: beaked_redfish
   STOCK_LATIN:            Sebastes mentella
   ICES_AREAS:             1, 2
   ICES_STOCK_ID:          reb.27.1-2
   ASSESSMENT_YEAR:        2026
   ADVICE_YEAR:            2027
   PREV_ADVICE_YEAR:       2024
   FIRST_DATA_YEAR:        1987
   WORKING_GROUP:          JRN-AFWG
   ```

3. Run the scaffolder:

   ```r
   source("scaffold.R")
   scaffold("stock_config.yaml")
   ```

   This does literal find-replace of `{{STOCK_CODE}}`, `{{STOCK_NAME}}`, etc.,
   across every text file in the repo, and writes the resulting stock identity
   to `memory/stock_identity.md`.

4. Walk through `memory/template_open_items.md`. Every item on that list is a
   stock-specific surface (data sources, priors, gear breakdown, advice
   framework, bibliography, narrative prose) that must be revisited.

## Repository layout

```text
.
├── 1 assessment model.qmd       # production: assessment document
├── 2 advice sheet.qmd           # production: ICES-format advice sheet
├── run_assessment.R             # master runner; renders both, copies outputs
├── scaffold.R                   # template scaffolder (find-replace + memory init)
├── stock_config.yaml            # per-stock values consumed by scaffold.R
├── AGENTS.md                    # contract for any LLM working in this repo
├── CLAUDE.md                    # short pointer to AGENTS.md for Claude Code
├── memory/                      # shared, committed project memory
│   ├── README.md                # format spec
│   ├── MEMORY.md                # index
│   ├── template_*.md            # inherited from this template
│   └── stock_identity.md        # written by scaffold.R
├── data/
│   ├── catches/                 # per-stock catch processing inputs/outputs
│   ├── indices/                 # survey indices (.rds)
│   └── model_output/            # generated, mostly git-ignored
├── docs/                        # generated outputs (renders)
└── src/
    ├── 0_setup.R                # shared bootstrap
    ├── 1_process_catches.R      # worked example from beaked redfish — rewrite per stock
    ├── spict_functions.R        # spictRisk()
    ├── ices_plots.R             # summary_plot()
    ├── make_table.R             # make_table()
    ├── documents/               # advice-sheet word template, bib, CSL
    └── exploration/             # benchmark / sensitivity workflow + Shiny explorer
```

## Key conventions

- **Units**: catches in tonnes throughout.
- **Survey timing**: `year + 6/12` (June) for SPiCT.
- **Index scaling**: survey estimates divided by their mean.
- **`stdevfac` vectors must average to 1**.
- **`logn` fixed** (Schaefer): `phases$logn <- -1`, `ini$logn <- log(2)`.
- **`logalpha` / `logbeta` priors deactivated** (`c(0, 0, 0)`).
- Use the tidyverse pipe `|>`.
- Format R code with `air` (config in `air.toml`).

## Requirements

- R 4.5+, Quarto CLI, system libraries for `sf`
- `src/0_setup.R` installs missing packages on first run

## Maintenance

Improvements that apply to **all stocks** (helper functions, advice-sheet
styling, rendering pipeline, conventions) should land back in this template
repo. Stock-specific narrative, data, and priors stay in the downstream stock
repos.

See `AGENTS.md` for the multi-agent collaboration contract and `memory/README.md`
for the project-memory format.

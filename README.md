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

**This template is designed to be populated with an AI coding agent driving the
process** (Claude Code, Cursor, Windsurf, ChatGPT in a workspace, etc.), in
collaboration with the analyst. The agent is responsible for asking the
analyst the right questions, filling `stock_config.yaml`, running the
scaffolder, then walking the analyst through the data-onboarding steps and
the open-items checklist. The full interview protocol lives in
[`memory/template_scaffold_interview.md`](memory/template_scaffold_interview.md).

### Recommended (agent-driven) flow

1. Create the new project on GitHub:

   ```bash
   gh repo create DeepWaterIMR/<stock>-spict \
     --template DeepWaterIMR/spict-template \
     --private --clone
   cd <stock>-spict
   ```

2. Open the repo in your AI coding tool of choice and ask it:

   > "Help me scaffold this new SPiCT stock project. Read `AGENTS.md` and
   > `memory/template_scaffold_interview.md`, then walk me through the
   > questions."

   The agent should:
   - Ask all 11 stock-identity fields (stock code, name, latin name, ICES
     areas, ICES stock ID, assessment / advice / previous-advice years, first
     data year, working group).
   - Write `stock_config.yaml` and run `scaffold.R`.
   - Ask about **catch data sources** — where do they live, how are they
     combined, is there a gear breakdown — and rewrite `src/1_process_catches.R`
     accordingly.
   - Ask about **survey indices** — including a URL to the index producer repo
     (at IMR Deep-water this is `DeepWaterIMR/ref-assessment-index`, an
     internal repository),
     which split of the indices list to use, and how the `.rds` file gets into
     `data/indices/`.
   - Ask about **working-group conventions** — advice framework, reference
     points, Word template, bibliography.
   - Record every non-obvious decision as a new file in `memory/`.

3. Walk through [`memory/template_open_items.md`](memory/template_open_items.md)
   with the agent. Every item is a stock-specific surface (priors, narrative
   prose, gear breakdown, bibliography, advice history) that needs revisiting
   beyond the mechanical scaffolding step.

### Manual fallback

If you'd rather fill the config by hand:

```yaml
# stock_config.yaml
STOCK_CODE:             reb
STOCK_NAME:             BeakedRedfish
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

```r
source("scaffold.R")
scaffold("stock_config.yaml")
```

Then walk `memory/template_open_items.md` yourself.

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

## License

GPL-3, matching `spict` itself. See [`LICENSE`](LICENSE).

The bibliography (`src/documents/zotero_library.bib`) ships only the handful of
references the template's own documents cite. Replace or extend it with your
stock's sources, and export **without** local `file = {...}` paths.

`src/documents/advice_template.docx` is a styles-only Quarto `reference-doc` —
heading, table and body styles plus page setup, with no document content.
Swap in your working group's own template if it has one.

# The generated project structure

`spict-new-assessment` produces a **new project folder** for one stock. spict-template itself is
never this structure.

The layout is academic-writing's, unchanged, plus what a SPiCT assessment needs. The base is
laid down by academic-writing's `scaffold_document()`; spict-template overlays the R helpers,
the three documents' SPiCT content, and the stock-specific `config.yaml` fields. See
[`academic-writing.md`](academic-writing.md) for the contract that governs everything under
`docs/`.

```
<stock>-spict/
├── AGENTS.md / CLAUDE.md    # Agent contract and Claude pointer
├── config.yaml              # Stock identity, years, model settings, authors
├── VERSION                  # version: 0.1.0 and the scaffold date
├── .here / _quarto.yml      # Project root and editor-preview execution directory
├── .gitignore
├── R/
│   ├── 0_setup.R            # academic-writing: packages, config, theme, figure widths
│   ├── report_helpers.R     # academic-writing: fmt(), list_values(), spell_number()
│   ├── docx_postprocess.R   # academic-writing: unwraps Quarto's Word float wrappers
│   ├── 1_process_catches.R  # Raw catch sources -> the SPiCT catch series
│   ├── 2_prepare_index.R    # Producer output -> year/est/se
│   ├── spict_helpers.R      # SPiCT package loading, input building, spictRisk()
│   ├── ices_plots.R         # summary_plot(): the three-panel advice figure
│   ├── advice_tables.R      # ICES flextable idiom, page fitting, make_table()
│   ├── spict_exploration.R  # params_df(), comp_df(), comp_plot() — comparison helpers
│   ├── explore_fit.R        # Fit one candidate and render its diagnostic report
│   └── explore_compare.R    # Compare saved candidates
├── docs/
│   ├── render.R             # Renders the non-HTML formats and post-processes them
│   ├── assets/              # references.bib, ICES JMS CSL, Word templates, advice CSS
│   ├── data-report/
│   │   ├── spict-assessment/<stock>-spict-assessment.qmd   # Step 2: the assessment
│   │   └── exploration/
│   │       ├── single-fit.qmd        # One candidate, full diagnostics
│   │       └── model-comparison.qmd  # Candidates side by side
│   ├── assessment-report/assessment-report.qmd   # Step 4: the WG chapter
│   └── advice-sheet/advice-sheet.qmd             # Step 5: the catch advice
├── shiny/spict-explorer/    # Interactive prior and setting explorer
├── data/
│   ├── source/              # Raw catch extracts, spreadsheets, the index .rds; ignored
│   └── output/              # Processed series, fits, summaries; ignored
├── figures/                 # Exported figures; ignored except README
├── logs/                    # Render logs; ignored except README
├── ai/
│   ├── memory/              # Shared project memory: read MEMORY.md first
│   ├── tests/               # Small validation checks and synthetic fixtures
│   └── review/              # Reviews and audit outputs; ignored except README
└── config/                  # Tooling configuration, separate from analysis settings
```

`shiny/` is spict-template's one addition to the academic-writing layout. Everything else
matches, so an analyst moving between an index project, a SPiCT project, and a manuscript finds
the same folders in the same places.

## Rules

- **`data/`, `logs/`, `figures/`, and `ai/review/` are git-ignored.** Only code, documents,
  `ai/memory/`, and `config.yaml` are committed. Raw catch extracts and the index file never
  enter git.
- **`config.yaml` is the single source of truth.** Stock identity, the year parameters, priors,
  the uncertainty ramp, reference-point conventions, and index handling all live there and are
  read at run time through `R/0_setup.R`. Documents do not hard-code settings.
- **The three documents do not refit.** The assessment data report fits the model and saves the
  summary; the chapter and the advice sheet read it.
- **Expensive steps cache to `data/output/`.** The fit, the retrospective, the hindcast, and
  the initial-value check are toggle-controlled. See [`rendering.md`](rendering.md).
- **Project memory is `ai/memory/`.** Agents read `ai/memory/MEMORY.md` first and write new
  memory files there — never into an agent-local per-machine memory folder.

## `config.yaml` fields

**Stamped into paths and document YAML by `scaffold.R`** (changing one afterwards means editing
the documents too):

`PROJECT_TITLE`, `PROJECT_SLUG`, `PROJECT_YEAR`, `AUTHORS`, `AFFILIATIONS` (academic-writing's
schema — accountable humans, never invented), `STOCK_NAME` (display name for prose),
`STOCK_SLUG` (kebab-case, used in filenames), `STOCK_NAME_SNAKE` (snake_case, used in object
and file names), `STOCK_LATIN`, `STOCK_CODE`, `ICES_AREAS`, `ICES_STOCK_ID`, `WORKING_GROUP`,
`WORKING_GROUP_LONG`.

**Read at run time** (change freely; re-render):

| Field | Meaning |
|---|---|
| `ASSESSMENT_YEAR` / `ADVICE_YEAR` / `PREV_ADVICE_YEAR` | The canonical year parameters, also the documents' `params:` defaults |
| `PREV_ADVICE_CATCH` | Last advised catch in tonnes; 0 when there was none |
| `FIRST_DATA_YEAR` | First year of the catch series |
| `EXPLORATORY` | `true` when SPiCT supplements an official assessment |
| `OFFICIAL_ASSESSMENT` | The official model's name, for the callout |
| `ADVICE_FRAMEWORK` | e.g. "ICES MSY approach" |
| `INDEX_NAME` / `INDEX_ELEMENT` / `INDEX_TIMING` | Which index variant, and its fraction of the year |
| `PRIOR_LOGR` / `PRIOR_LOGBKFRAC` / `PRIOR_LOGSDB` | `c(log(mean), sd, use)` vectors |
| `STDEV_HIGH_YEAR` / `STDEV_LOW_YEAR` | Catch-uncertainty ramp breakpoints |
| `PRODUCTION_MODEL` | `schaefer` fixes `logn`; anything else is a benchmark decision |
| `BLIM_BMSY` / `BTRIGGER_BMSY` / `FLIM_FMSY` | Reference-point conventions |
| `NRETROYEARS` / `NHINDCASTYEARS` | Peels for the retrospective and hindcast |
| `BASE_SIZE`, `FIG_WIDTH_*`, `CSL`, `BIBLIOGRAPHY`, paths | academic-writing's settings |

## The canonical year parameters

These names are matched across `config.yaml`, all three documents' `params:` blocks,
`docs/render.R`, and the exploration scripts. Renaming one means renaming it everywhere, in the
same commit.

| Name | Meaning |
|---|---|
| `assessment_year` | The year the assessment is conducted |
| `advice_year` | The year advice applies to; usually `assessment_year + 1` |
| `prev_advice_year` | The year advice was last given |
| `intermediate_year` | The projection's intermediate year; defaults to `assessment_year` |
| `first_data_year` | First year in the catch series; derived from the data |
| `last_data_year` | Most recent year with realised catch; derived from the data |

New chunks referencing a year use one of these, never a literal.

## One stock per project

A project assesses one stock. Two stocks that share a catch spreadsheet still get two projects —
the advice sheets, the reference points, and the working-group float numbers are all per stock,
and the coupling costs more than the shared data saves.

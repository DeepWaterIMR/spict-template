---
name: template_layout
description: production/exploration/temp split, canonical year parameters, run_assessment.R contract
metadata:
  type: project
  author: spict-template
  created: 2026-05-26
---

# Repository layout

The repo is split into three layers, inherited from the `reg-spict` 2026 refactor:

- **Production** (project root): `1 assessment model.qmd`, `2 advice sheet.qmd`, plus `run_assessment.R` which renders both with canonical year parameters and copies outputs into `docs/assessment/<assessment_year>/`.
- **Exploration** (`src/exploration/`): benchmark / sensitivity scripts and parameterised templates (`1 fit model.R`, `2 compare models.R`, `report.qmd`, `comparator.qmd`, `shiny_dashboard.qmd`, `spict_explorer/app.R`, `additional_spict_funcs.R`). Own README. Paths run from project root.
- **Parked / reference**: prior-art scripts and dead helpers can be kept in `src/temp/` with its own README. Not active in the rendering pipeline.

# Canonical year parameters

The following names are matched across `run_assessment.R`, the qmd YAML `params:` blocks, and the exploration scripts. Do not rename without updating all sites simultaneously.

| Variable | Meaning |
|---|---|
| `assessment_year` | The year the assessment is conducted |
| `advice_year` | Year for which advice is given (defaults to `assessment_year + 1`) |
| `prev_advice_year` | Year advice was last given |
| `intermediate_year` | Mid-year for projections (defaults to `assessment_year`) |
| `last_data_year` | Most recent year with realised data (auto-derived from data) |
| `first_data_year` | Earliest year used in the model (auto-derived from data) |
| `first_catch_year` | First year in the catch series |
| `first_index_year` | First year in the survey index |

**Why**: Centralising these names makes the rendering pipeline parameterisable from `run_assessment.R` and prevents silent divergence between the two production qmds.

**How to apply**: When adding new chunks that reference a year, use one of these variables rather than a literal. New parameters are fine — extend `params:` in both qmds plus `run_assessment.R` together.

Related: [[template_constraints]], [[template_helpers]]

---
name: architecture
description: How spict-template is organised, and why it overlays academic-writing rather than duplicating it
metadata:
  type: project
  author: spict-template
  created: 2026-09-09
---

# Architecture

spict-template is a knowledge pack in the BAIT / academic-writing / index-template family:
`skills/` installed globally, `knowledge/` as the source of truth, `project-template/` copied
into each generated project, `scaffold.R` stamping it.

It differs from index-template in one respect that matters. **`scaffold.R` calls
academic-writing's `scaffold_document()` and overlays only the SPiCT layer on top**, rather
than shipping its own copy of the project skeleton. index-template duplicates
`R/0_setup.R`, `R/report_helpers.R`, and `docs/render.R`; spict-template does not.

**Why**: two copies of a shared file diverge. The moment academic-writing fixes a render bug,
a duplicating pack is wrong and nobody notices until a project fails. Overlaying costs a hard
dependency at scaffold time — academic-writing must be installed — and buys a single source of
truth for everything shared.

**How to apply**:

- A fix to `docs/render.R`, `R/0_setup.R`, `R/report_helpers.R`, `R/docx_postprocess.R`, the
  project `.gitignore`, the Word templates, or the CSL belongs in **academic-writing**.
- A fix to `R/spict_helpers.R`, `R/advice_tables.R`, `R/ices_plots.R`, or the SPiCT content of
  the three documents belongs **here**.
- `project-template/` here holds **only** files that override or add to academic-writing's
  skeleton. Anything identical to what academic-writing already ships must not be duplicated.
- `scaffold.R` deletes academic-writing's generic `docs/data-report/data-report.qmd` and
  `R/1_data.R` after the overlay: leaving them gives the project two answers to the same
  question.

The generated project is self-contained. Only *scaffolding* needs academic-writing; rendering
does not.

Related: [[conventions]], [[reference-sources]]

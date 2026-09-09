# Academic-writing compatibility

spict-template owns the SPiCT method. **[academic-writing](https://github.com/DeepWaterIMR/academic-writing)
owns the writing and artifact conventions for every file a generated project produces** — prose,
R scripts, figures, tables, bibliographies, and the agent instructions themselves.

Before creating or revising project artifacts, read the **installed** `academic-style`,
`academic-conventions`, and the relevant document skill. If they are not available, run
`academic-writing-install`, or install
<https://github.com/DeepWaterIMR/academic-writing>. **Do not vendor copies of those skills into
this pack**: read the installed versions so improvements propagate to every project.

## The dependency is real, not decorative

`scaffold.R` in this pack **calls academic-writing's `scaffold_document()`** to lay down the
project base — the layout, `R/0_setup.R`, `R/report_helpers.R`, `R/docx_postprocess.R`,
`docs/render.R`, `docs/assets/`, and the `.gitignore` — and then overlays the SPiCT-specific R
helpers and document content on top. There is one copy of the shared infrastructure and it
lives in academic-writing.

Consequences worth knowing:

- Scaffolding a project requires academic-writing to be installed. Rendering one does not: the
  generated project is self-contained.
- A fix to `docs/render.R` or `R/0_setup.R` belongs in academic-writing, not here. A fix to
  `R/spict_helpers.R` belongs here.
- The `spict` package is declared in academic-writing's `optional_packages`, alongside
  `sdmTMB` for index-template. Documents reach it through `ensure_packages("spict")`, never
  through an `install.packages()` call inside a chunk.

## Which skill owns which document

| Document | Skill | Format |
|---|---|---|
| `docs/data-report/spict-assessment/` | `academic-data-report` | HTML, code folded |
| `docs/data-report/exploration/` | `academic-data-report` | HTML, code folded |
| `docs/assessment-report/` | `academic-assessment-report` | Word, in the group's template |
| `docs/advice-sheet/` | `academic-advice-sheet` | Word, plus an HTML preview |

A benchmark year additionally uses `academic-benchmark-report`; scaffold that document type
alongside the others when the working group has called a benchmark.

## Report contract

- **Accountable human authors and affiliations.** The scaffold takes academic-writing's
  `AUTHORS`/`AFFILIATIONS` schema, validates the affiliation IDs, and serialises it as YAML.
  Confirm the metadata during the questionnaire; never invent it.
- **Keep `published-title: "Version"`, an ISO date, the configured language, a title-matched
  `toc-title` on HTML, `code-fold: true`, and `code-summary: "Show code"`.** Never globally
  disable `echo` in a data report — that is the one YAML difference that makes it a data
  report, and setting `echo: false` makes `code-fold` do nothing.
- **Figure widths are 6.69 in (170 mm) or 3.35 in (85 mm)**, with `theme_bw(base_size = 12)`.
  Raster figures are JPEG where size matters. Respect explicit author overrides.
- **Inline R for every data-derived value.** Methods and results in the past tense. Every figure
  and table gets a caption and an interpretive sentence carrying the cross-reference at the end.
- **Verified literature in `docs/assets/references.bib`**, cited through the shared ICES JMS
  CSL. Cite R, Quarto, knitr, `spict`, and every package that influenced the result, in prose,
  with inline versions from `citation()`. A dump of raw `citation()` output does not satisfy
  this.
- **AI disclosure**: the exact researcher-confirmed model list and roles, appended to any
  existing list, never replacing it. Never imply an author approved an unreviewed draft.
- **Disclose every script the report used**, in run order, in a folded appendix, with real
  paths. References come before the appendices. Do not hide a missing script behind fallback
  text — `readLines()` runs at render time even under `eval: false`, and a missing script
  should break the render.
- **Local Git, no remote, no push** without the author's authorisation. `VERSION` starts at
  0.1.0 with the scaffold date.

## Validation

Before an expensive render, check R syntax, YAML, paths, metadata, citations, cross-references,
figure captions, code visibility, and that the SPiCT conventions in
[`spict.md`](spict.md) still hold. `Rscript config/validate-scaffold.R` exercises a synthetic
scaffold without touching real data or fitting a model; `--render` additionally renders a small
synthetic report through the same metadata, assets, and code-fold settings.

Review first, then render through [`rendering.md`](rendering.md). A scaffolded skeleton is not a
completed assessment: it still needs the stock's data, its priors, and the researcher's review.

## Scope

This layout applies to **new projects**. Do not silently migrate an existing stock repository —
propose the migration, and let the analyst decide when in the assessment cycle to take it.

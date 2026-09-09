# Contributing to spict-template

spict-template is a **public knowledge pack** for running SPiCT stock assessments. It contains
**instructions only — never data**. Contributions are welcome; please keep the following in
mind.

## The golden rule: no data, no private paths

- **Never commit data** (`.rds`, `.rda`, `.csv`, `.xlsx`, catch series, index files, model
  output) — the `.gitignore` blocks common extensions as a safety net, but the responsibility
  is yours.
- **Never commit private or local paths** (`/Users/...`, `OneDrive`, `CloudStorage`, internal
  database paths). Use placeholders (`{{...}}`) and `config.yaml` fields.
- Examples use **code and synthetic or rounded values**, never real catches or indices.

Catch data by country and vessel can be commercially sensitive, and Norwegian sales-note data
carry confidentiality constraints. A number that looks harmless in a worked example may not be.

## What lives where

- **`knowledge/`** — the shared source of truth (the model conventions, catch data, indices,
  diagnostics, advice, constraints, project structure, packages, rendering). **Prefer improving
  these over duplicating guidance in a skill.**
- **`skills/spict-*/SKILL.md`** — one skill per recurring task. Keep it short and link into
  `knowledge/` for detail. Frontmatter must carry `name` and `description`.
- **`project-template/`** — the SPiCT layer overlaid onto academic-writing's skeleton. Only
  files that are SPiCT-specific belong here; anything shared belongs in academic-writing.
- **`examples/`** — worked examples: a filled `config.yaml` plus notes on what to change.
- **`memory/`** — development memory for the pack itself. Generated projects carry their own
  `ai/memory/`; do not confuse the two.

## Where a change belongs

| Change | Repository |
|---|---|
| `docs/render.R`, `R/0_setup.R`, `R/report_helpers.R`, `R/docx_postprocess.R`, the project layout, the `.gitignore`, Word templates, the CSL | [academic-writing](https://github.com/DeepWaterIMR/academic-writing) |
| Writing style, document structure, AI-disclosure wording | academic-writing |
| SPiCT conventions, the model helpers, the assessment/advice documents' SPiCT content | here |
| Survey-index construction | [index-template](https://github.com/DeepWaterIMR/index-template) |
| Biotic data access | [BAIT](https://github.com/DeepWaterIMR/BAIT) |

Duplicating a shared file here to avoid a cross-repo change makes two copies that will
disagree. Make the change upstream.

## Style

- Markdown wrapped at about 92 columns; **`.qmd`/`.Rmd` prose is NOT hard-wrapped** — one
  paragraph per line, for soft-wrap editors.
- R uses tidyverse syntax and the native pipe `|>` in new code; match the surrounding file's
  comment density. Format with `air` (config in `air.toml`).
- Roxygen documentation on every exported helper, including *why* the convention exists.

## Testing a change

Before opening a pull request:

1. **Privacy check.** `grep -rIn -e '/Users/' -e 'OneDrive' -e 'CloudStorage' .` must find
   nothing outside placeholders.
2. **Scaffold check.** `Rscript config/validate-scaffold.R` — it scaffolds a synthetic project
   against `examples/redfish/config.yaml`, parses every R file and chunk, validates the
   document YAML, and confirms no `{{...}}` placeholder survives.
3. Confirm every `SKILL.md` has valid frontmatter and that its `knowledge/` links resolve.
4. If you changed a model convention in `knowledge/spict.md`, change the helper in
   `project-template/R/spict_helpers.R` in the same commit. The two are meant to agree.

The validator deliberately does **not** fit a model: it checks the contract, not the science.

## Version stamping

The repo stamps `VERSION` and the README version line on every commit. Enable the hook once
per clone:

```bash
git config core.hooksPath .githooks
```

The patch level bumps automatically. To bump the minor or major level, edit `VERSION` by hand
before committing — the hook keeps a hand-set version and only refreshes the date.

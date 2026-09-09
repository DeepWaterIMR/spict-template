---
name: reference-sources
description: The assessments and documents this pack's content is distilled from
metadata:
  type: reference
  author: spict-template
  created: 2026-09-09
---

# Where the content came from

- **`reg-spict`** — the golden redfish (*Sebastes norvegicus*) SPiCT assessment, ICES subareas
  1 and 2. The production pipeline, the advice-sheet structure, the ICES table idiom, and the
  byte-identical-output constraint all originate here.
- **`reb-spict`** — the beaked redfish (*Sebastes mentella*) exploratory assessment. The worked
  example in `examples/redfish/`, and the source of the priors that are now labelled as
  placeholders because they were never recalibrated from golden redfish.
- **SPiCT guidelines** — Mildenberger et al., <https://github.com/DTUAqua/spict>. The API and
  the recommended settings.
- **WKLIFE X** (ICES 2020) — the acceptance checklist in `knowledge/diagnostics.md`.

Both source repositories are internal to DeepWaterIMR and contain data. **Nothing from them is
copied here verbatim if it carries a number, a path, or a stock-specific narrative** — the
content here is the method, parameterised.

Related: [[architecture]], [[spict-conventions-rationale]]

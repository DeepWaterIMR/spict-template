---
name: template_constraints
description: Byte-identical-output rule on `2 advice sheet.qmd`; exploratory-status callouts must stay
metadata:
  type: project
  author: spict-template
  created: 2026-05-26
---

# Hard constraints inherited from the template

## 1. Byte-identical numeric output on `2 advice sheet.qmd`

Once this repo is producing official-track advice, `2 advice sheet.qmd` must render **byte-for-byte identical numeric output** before and after any change. Only cosmetic or provably functionally-equivalent edits are allowed. Before editing, verify the replacement evaluates to the same value for the current `assessment_year` and `advice_year`.

**Why**: It is the official ICES advice-sheet deliverable. A different number rendered after a "harmless" refactor is the worst-case failure mode of this pipeline.

**How to apply**: Arithmetic equivalences must be verified. Example: `rep(0, 10)` ↔ `rep(0, assessment_year - 2017 + 1)` for `assessment_year = 2026`. If unsure, render before and after and `diff` the output `.docx` programmatically (officer or python-docx) — visual inspection is not enough.

This constraint does NOT apply while the repo is still in exploratory development with placeholder data; treat it as activated once a benchmark sign-off has happened, recorded in a memory entry.

## 2. Exploratory-status callouts

Both production qmds carry a callout block at the top stating the document is exploratory and not official advice (where applicable to the working group's gadget-based official assessment). These must not be removed or softened without explicit human authorisation recorded in `memory/`.

**Why**: Mis-attribution risk. If a SPiCT supplement is mistaken for the official assessment by a downstream reader, the consequences run from confusion to misuse in management advice.

**How to apply**: If an LLM edit pass would remove or soften these callouts, stop and ask a human first.

## 3. Advice-sheet annual-update task

In `2 advice sheet.qmd`, the `ICES Advice` string vector is typically hard-coded with one entry per year. When `assessment_year` advances past the last hard-coded year, the list must be extended manually or the docx column lengths will mismatch.

This is flagged at the relevant chunk; do not paper over a length mismatch — extend the vector.

Related: [[template_layout]], [[template_advice_sheet]]

---
name: template_helpers
description: Use `list_values()` from `src/0_setup.R` for inline list enumerations in qmd narrative text
metadata:
  type: feedback
  author: spict-template
  created: 2026-05-26
---

# Use `list_values()` for inline list enumerations

When writing inline R expressions inside Quarto narrative paragraphs that produce comma-separated lists ("X, Y, and Z" / "X and Y" / "X"), use the `list_values()` helper from `src/0_setup.R` rather than ad-hoc `paste(..., collapse = ", ")` calls.

`list_values()` handles the three cases correctly:

- 1 item → `"X"`
- 2 items → `"X and Y"`
- ≥ 3 items → `"X, Y, and Z"` (Oxford comma)

**Why**: Produces grammatically natural enumerations without per-site comma logic. Confirmed useful across both `reg-spict` and `reb-spict`.

**How to apply**: When writing or editing inline `` `r ...` `` expressions in `1 assessment model.qmd`, `2 advice sheet.qmd`, or any future qmd, use `list_values(some_vector)` for human-readable lists.

Don't replace existing manual `paste`-`collapse` calls in `2 advice sheet.qmd` unless explicitly authorised — see [[template_constraints]] for the byte-identical-output rule.

Related: [[template_constraints]]

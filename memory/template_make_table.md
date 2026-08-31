---
name: template_make_table
description: make_table() cross-format helper — LaTeX branch must include caption= or PDF captions are silently dropped
metadata:
  type: feedback
  author: spict-template
  created: 2026-06-03
---

# `make_table()` — cross-format table helper (`src/make_table.R`)

`make_table(df, caption = "...")` dispatches on `output_type()` to render
tables correctly across HTML, DOCX, and PDF (LaTeX). It lives in
`src/make_table.R` and is sourced from both production qmds.

## Known bug (fixed 2026-06-03)

The LaTeX `else` branch was missing `caption = caption` in its `knitr::kable()`
call, causing **all table captions to be silently dropped from PDF output**.
The HTML and DOCX branches passed the caption correctly; only LaTeX was broken.

**Fix applied in both `reb-spict` and `spict-template`:**

```r
knitr::kable(
  format = "latex",
  caption = caption,          # ← was missing
  booktabs = TRUE,
  longtable = TRUE,
  ...
) |>
  kableExtra::kable_styling(latex_options = c("striped", "hold_position"))
  #                                                        ↑ also added
```

`"hold_position"` prevents tables from floating away from their in-text
position in the PDF.

**Why:** Discovered when rendering `reb-spict` to PDF — all table captions
were absent. Root cause: copy-paste across the three branches missed the
`caption =` argument in the LaTeX branch.

**How to apply:** Any time you write or copy a cross-format `make_table()`-
style dispatcher, verify that `caption` is forwarded in **every** branch,
including the LaTeX one. Test PDF output explicitly — HTML and DOCX may
look fine while LaTeX is silently broken.

Related: [[template_helpers]]

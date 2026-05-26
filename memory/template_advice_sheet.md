---
name: template_advice_sheet
description: How the ICES advice sheet (`2 advice sheet.qmd`) renders and how the Word template is generated
metadata:
  type: project
  author: spict-template
  created: 2026-05-26
---

# Advice sheet rendering pipeline

The advice sheet (`2 advice sheet.qmd`) renders to **docx, html, and pdf**.

## Word template auto-generation

`src/documents/advice_template.docx` is regenerated at render time (in the setup chunk) by:

1. Finding the Pandoc executable (`rmarkdown::pandoc_exec()` or a known Quarto / Positron path).
2. Exporting Pandoc's default `reference.docx` to a temp file.
3. Reading it with `officer::read_docx()`, locating `Heading1` style in `styles.xml` via `xml2`.
4. Setting fill `002B5F` (ICES navy), white text `FFFFFF`, bold, Calibri 10pt on the heading style.
5. Writing back and saving to `src/documents/advice_template.docx`.

**Why**: A blank `read_docx()` lacks heading style definitions; the file must start from Pandoc's default.

**How to apply**: If heading styles break in the rendered docx, the fix is in `create_ices_template()` inside the setup chunk of `2 advice sheet.qmd`. The key is starting from `pandoc --print-default-data-file reference.docx`.

## PDF coloured section headers

Implemented via `titlesec` + `\colorbox{icesblue}` in LaTeX header includes (Quarto's lualatex engine by default).

## HTML styling

`src/documents/ices_advice.css` adds navy `#002B5F` background to `h1` elements.

## Tables

- `flextable` for docx and html
- `kableExtra` for pdf (conditional on `knitr::is_latex_output()`)

## Per-stock customisation

If a working group has its own Word template (e.g. `JRN-AFWG-specific.docx`), drop it into `src/documents/` and update the `reference-doc:` line in the qmd YAML. The auto-generation step can be skipped if the template is human-curated.

Related: [[template_constraints]] (byte-identical output rule), [[template_layout]]

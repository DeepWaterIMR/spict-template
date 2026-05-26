# Memory index

Template-level memories (inherited from `spict-template`, apply to every stock):

- [template_layout.md](template_layout.md) — production/exploration/temp split, canonical year parameters, run_assessment.R contract
- [template_constraints.md](template_constraints.md) — byte-identical-output rule on `2 advice sheet.qmd`; exploratory-status callouts must stay
- [template_advice_sheet.md](template_advice_sheet.md) — ICES advice sheet renders to docx/html/pdf; Word template auto-generated from Pandoc default ref via officer+xml2
- [template_helpers.md](template_helpers.md) — Use `list_values()` from `src/0_setup.R` for inline list enumerations in qmd narrative text
- [template_open_items.md](template_open_items.md) — Checklist of stock-specific surfaces every new stock must walk through after scaffolding

Stock-level memories (written by collaborators as work progresses):

- [stock_identity.md](stock_identity.md) — Stock identity for this project (filled by scaffold.R)

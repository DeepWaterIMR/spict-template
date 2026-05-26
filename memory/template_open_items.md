---
name: template_open_items
description: Checklist of stock-specific surfaces every new stock must walk through after scaffolding
metadata:
  type: project
  author: spict-template
  created: 2026-05-26
---

# Open items every new stock must address after scaffolding

`scaffold.R` mechanically fills `{{STOCK_*}}` placeholders. It does NOT rewrite narrative prose, swap priors, or replace data. The following items are stock-specific surfaces that an analyst (human + AI in collaboration) must walk through before the assessment is usable.

**The agent driving this should also read `template_scaffold_interview.md`**, which has the structured Q&A protocol for the data sections below.

When you complete one of these for the current stock, add a memory file recording what you chose and why, then strike the item from this checklist (or replace this whole file once everything is done).

## Data

- [ ] **Catch processing** (`src/1_process_catches.R`) — currently a worked example for beaked redfish (IMR DB + JRN-AFWG xlsx). Ask the analyst which catch sources apply (IMR landings DB, ICES working-group spreadsheet, StoX, bespoke country submissions, reconstructed historical series) and rewrite the script. Output contract: `data/catches/{{STOCK_NAME}}_catches_for_SPiCT.csv` with `year` and `total` columns at minimum. Record sources in a new `memory/catch_data_sources.md`.
- [ ] **Survey indices** — drop the stock-specific indices `.rds` into `data/indices/{{STOCK_CODE}}-assessment-survey-indices.rds`. The file is a **named list of data frames** (e.g. "Total biomass", "Over 30 cm biomass", "Under 10 cm abundance"), one element of which is the assessment index. Required columns per frame: `year`, `est`, `lwr`, `upr`, `se`. **Ask the analyst for the URL of the index producer repo** (the IMR Deep-water pattern is one repo per species, e.g. `DeepWaterIMR/ref-assessment-index` for redfish) and pin a commit/tag in a new `memory/index_data_sources.md`. Confirm which `[[i]]` of the list is the chosen index — default is `[[2]]`, but this varies per stock.
- [ ] **Gear breakdown** for the advice sheet — `data/catches/landings_by_gear_pct_allNations.csv` (column convention inherited from reg-spict; verify against the working group's reporting format).
- [ ] **Landings file** for the advice sheet — `data/catches/{{STOCK_NAME}}_landings_for_SPiCT.csv` (semicolon-separated; columns include nations + `OtherNations`).

## Model configuration

- [ ] **Priors** — `logr`, `logbkfrac`, `logsdb` in both `1 assessment model.qmd` and `src/exploration/1 fit model.R` are golden redfish placeholders. Recalibrate from FishLife, the working group's literature, or expert judgement.
- [ ] **Catch uncertainty ramp** — `stdev_high_year` and `stdev_low_year` in the setup chunk of `1 assessment model.qmd` (and `1 fit model.R`) are golden redfish breakpoints. Set to your stock's catch reporting quality breakpoints.
- [ ] **`first_data_year`** — typically auto-derived from the catches CSV via `min(catches$year, na.rm = TRUE)`. Verify this is correct.

## Document content

- [ ] **`1 assessment model.qmd` Introduction** — rewrite the narrative paragraphs about the stock, biology, working group, ICES area context. Keep the exploratory-status callout intact (see `template_constraints.md`).
- [ ] **`2 advice sheet.qmd`** — every `[PLACEHOLDER …]` marker. Tables, captions, advice-history rows, references, stock-issues bullets, citation strings.
- [ ] **Bibliography** — `src/documents/zotero_library.bib` is the golden-redfish-flavoured starting set. Replace or extend.
- [ ] **Word template** — `src/documents/advice_template.docx` is regenerated from Pandoc's default at render time (see `template_advice_sheet.md`). If the working group has its own template, drop it in and disable the auto-generation step.

## Identity and metadata

- [ ] **ICES stock code** — verify against the current ICES stock register.
- [ ] **`stock_identity.md`** — written by `scaffold.R`; verify the entries are correct.

## Operational

- [ ] **GitHub repo settings** — confirm visibility (private until data sensitivity is reviewed), branch protection, who has access.
- [ ] **CI / rendering** — if the working group expects renders on push, set up the action.

---

**How to apply**: Walk this list top to bottom. After each item, write a small memory file describing the choice. Once the list is empty, this file can be deleted from the repo and replaced with a memory entry noting "stock fully scaffolded on YYYY-MM-DD."

Related: [[template_layout]], [[template_constraints]], [[stock_identity]]

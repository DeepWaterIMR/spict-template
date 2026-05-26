---
name: template_scaffold_interview
description: Structured interview for an AI agent onboarding a new stock from this template
metadata:
  type: project
  author: spict-template
  created: 2026-05-26
---

# Scaffold interview — for AI agents driving a new stock onboarding

This file is the protocol an AI agent should follow when a human collaborator asks "help me scaffold a new stock from `spict-template`." The agent walks the human through the questions below, fills `stock_config.yaml`, runs `scaffold.R`, then escorts them through `template_open_items.md`.

**This is a guideline, not a script.** Adapt phrasing, batch related questions, and use whatever question-asking facility your harness provides. Do not paste this file verbatim at the user.

## How to use this interview

1. Confirm the repo was just scaffolded from `spict-template` (look for `{{` placeholders in any qmd or at the README's `## Scaffolding…` section).
2. Work through the four sections below in order — *Identity*, *Catch data*, *Survey indices*, *Working group conventions*.
3. After Identity and the year fields, write `stock_config.yaml` and run `scaffold.R`. This unblocks the rest of the work even before data has arrived.
4. For *Catch data* and *Survey indices*, when the analyst has source links (e.g. another GitHub repo), follow them — fetch the producer repo's README, infer the column structure, propose a `data/` layout that matches, and confirm before writing code.
5. Record every non-obvious decision as a new file in `memory/` (e.g. `data_sources.md`, `priors_chosen.md`). Sign with `metadata.author`.
6. End by writing a `memory/onboarding_done.md` summarising what was decided and what's still open from `template_open_items.md`.

## Section 1 — Stock identity

Ask all of these. Don't proceed to scaffold.R until they're answered.

| Question | Maps to | Notes / examples |
|---|---|---|
| What's the ICES short code for the stock? | `STOCK_CODE` | lower-case, e.g. `reb`, `reg`, `ghl`, `ahl` |
| Stock name in CamelCase, for filenames? | `STOCK_NAME` | e.g. `BeakedRedfish`, `GreenlandHalibut`, `AtlanticHalibut` |
| Stock name in snake_case, for model RDS names? | `STOCK_NAME_LOWER_SNAKE` | e.g. `beaked_redfish`, `greenland_halibut` |
| Latin binomial? | `STOCK_LATIN` | e.g. `Sebastes mentella` (no italics markers) |
| ICES subareas? | `ICES_AREAS` | e.g. `1, 2` (comma-separated; just the numbers) |
| Full ICES stock ID? | `ICES_STOCK_ID` | e.g. `reb.27.1-2`. Verify against the current ICES stock register. |
| Assessment year? | `ASSESSMENT_YEAR` | The year the assessment is being conducted. |
| Advice year? | `ADVICE_YEAR` | Usually `ASSESSMENT_YEAR + 1`. Confirm. |
| Previous advice year? | `PREV_ADVICE_YEAR` | The year advice was last given. |
| First data year? | `FIRST_DATA_YEAR` | The earliest year in the planned catch series. |
| Working group? | `WORKING_GROUP` | e.g. `JRN-AFWG`, `WGDEEP`, `AFWG`, `WGEF` |

Once these are filled, write `stock_config.yaml`, run `scaffold.R`, and confirm the placeholder count is zero before continuing.

## Section 2 — Catch data

The contract: a CSV at `data/catches/<STOCK_NAME>_catches_for_SPiCT.csv` with at minimum a `year` column and a `total` column (catches in tonnes). The existing `src/1_process_catches.R` is a *worked example from beaked redfish* combining the IMR database with a JRN-AFWG ICES spreadsheet — almost certainly the wrong combination for your stock.

Ask:

1. **Where do the catch data come from?** Common sources at IMR Deep-water:
   - IMR landings database (Norwegian sales notes, internal extract `.rds`)
   - ICES working-group spreadsheets (catches by country, often multi-tab xlsx covering historical + recent years)
   - StoX outputs
   - Bespoke country submissions
   - Reconstructed historical series (e.g. pre-1970 from grey literature)
2. **Do the catches need allocating by country / fleet / area?** If yes, on what split rule? (See `src/1_process_catches.R` for the beaked redfish pattern: Norway from IMR DB post-2022 + ICES sheet pre-2022, Russia from ICES sheet, "Other" residual, Hist pre-1993.)
3. **What's the species filter on the raw data?** (For beaked redfish: `species == "Snabeluer"` in the IMR DB; `"s mentella"` tab in the ICES xlsx.) For other stocks the analyst will know the equivalent.
4. **Is there a gear breakdown?** Used by `2 advice sheet.qmd` — file convention `data/catches/landings_by_gear_pct_allNations.csv`. Optional but expected for ICES advice format.
5. **Discards treatment?** Discards are not modelled by SPiCT directly; the advice sheet narrative declares whether they are assumed negligible or already included in catches.

When sources are identified, rewrite `src/1_process_catches.R` for the new stock (or, more honestly, **replace it entirely** — the existing code is the wrong shape for most stocks). Save a `memory/catch_data_sources.md` documenting:

- Each raw file path / repo / URL
- The transformations applied
- Any year cutoffs and why
- Sanity-check totals vs the most recent ICES report

## Section 3 — Indices

SPiCT consumes a single index series approximating relative biomass over time. It does NOT care whether the index is fisheries-independent (survey) or fisheries-dependent (CPUE) — anything with `year`, an estimate, and a per-observation uncertainty works.

**The reb-spict worked example uses one specific choice**: the "over 30 cm biomass" slice of a model-based survey biomass index estimated with `sdmTMB` from all available bottom-trawl data. The qmd setup chunk hard-codes `readRDS(...)[[2]]` against a **named list of data frames** with columns `model, year, est, lwr, upr, log_est, se, se_natural, type, cv`, produced by `get_index_split()`.

**Other stocks will use entirely different index types.** Do not assume.

### Question A — what kind of index?

Ask the analyst first. Common shapes at IMR Deep-water and beyond:

- Survey biomass index — design-based (stratified mean) or model-based (GAM, sdmTMB, VAST) from a research bottom-trawl, beam-trawl, acoustic, or longline survey.
- Survey abundance index — count-based, often per size or age class.
- CPUE — fisheries-dependent catch-per-unit-effort, optionally standardised (year + vessel + gear + area + month effects) via GLM, GLMM, or Tweedie-flavoured `sdmTMB`.
- Composite of the above.

This shapes everything downstream — which producer to ask for, what the RDS structure looks like, whether the qmd's `[[2]]` extraction needs rewriting.

### Question B — which surveys / which fleet?

For survey-based indices:
- Which surveys feed the index? (Northeast Arctic examples: Norwegian Bottom Trawl Survey, Ecosystem Survey, Winter Survey, acoustic. Other regions and stocks differ.)
- Coverage years per survey? Gear? Area stratification?

For CPUE indices:
- Which fleet / vessel class?
- What's the effort metric (hours fished, hooks, days at sea, swept area)?
- Already standardised, or do we need to standardise here?

### Question C — where does the file come from?

The IMR Deep-water pattern for survey indices is a dedicated producer repo per species, e.g. [`DeepWaterIMR/ref-assessment-index`](https://github.com/DeepWaterIMR/ref-assessment-index) (redfish, sdmTMB-based) and the companion [`DeepWaterIMR/ref-index`](https://github.com/DeepWaterIMR/ref-index). For CPUE-based stocks the producer is more often a logbook-cleaning + standardisation script that lives wherever the analyst keeps it.

Ask the analyst for the **URL or path of whatever produces the index for this stock**. If it's a GitHub repo, fetch its README and infer:

- What survey(s) or fleet(s) are combined
- The structure of the output object (list of data frames? single data frame? tibble? long vs wide?)
- Whether there are multiple variants to choose from (size classes, area splits, juveniles vs adults)
- How the `.rds` gets into `data/indices/` (download a release artefact, copy from OneDrive, run a script locally, symlink)

### Question D — which variant is the assessment index?

If the producer outputs multiple variants (the reb-spict case), confirm which one is the assessment index and why. Default in the current code is `[[2]]`; change the extraction in `1 assessment model.qmd` and `src/exploration/1 fit model.R` if needed.

If the producer outputs a single object, the analyst is choosing the variant implicitly — record what they picked and why (e.g. "30+ cm because recruitment is treated separately by gadget3").

### Question E — what's the structure on disk?

The current qmd code expects, after `[[i]]` extraction, a data frame with at least `year`, `est`, `lwr`, `upr`, `se`. If the producer outputs different names (`cv` instead of `se`, `index`/`obs` instead of `est`, etc.), either:

- (a) rename in the producer or in a small adapter step before saving the RDS, or
- (b) edit the survey-index chunk in `1 assessment model.qmd` and `src/exploration/1 fit model.R` to read whatever names the producer uses.

For CPUE indices the wrapper is rarely a list — it's typically a single tibble of year + standardised index + se. In that case option (b) is the honest path: rewrite the chunk to do `index <- read_rds(...)` (no `[[2]]`).

### Question F — index timing within the year?

SPiCT expects fractional years. The template uses `year + 6/12` (June). Confirm this matches when your survey actually runs — winter surveys land at `year + 1/12` or `year + 2/12`; autumn surveys at `year + 10/12`; CPUE indices are usually centred (`year + 0.5`).

### After

Write `memory/index_data_sources.md` with:

- Index type (survey biomass / abundance / CPUE / composite / ...)
- Producer repo URL or script path + commit/tag pinned, if applicable
- For surveys: which survey(s), years, gear, area; for CPUE: which fleet, effort metric, standardisation method
- Which named element / variant of the index is used for the assessment, and why
- Structural shape of the `.rds` on disk and whether the qmd setup chunk needed editing
- Timing offset chosen and why
- How the `.rds` file gets into `data/indices/` (download, symlink, manual copy)

## Section 4 — Working group conventions

These are easy to overlook and bite at advice-sheet time.

1. **Advice framework**: ICES MSY approach? Precautionary approach? Working-group-bespoke? The current `2 advice sheet.qmd` carries `[PLACEHOLDER]` markers for this — confirm what to put.
2. **Reference points**: Does the stock have absolute reference points (B~lim~, MSY B~trigger~)? SPiCT alone provides only relative ones. If absolute points exist, they enter the advice-sheet text but not the model.
3. **Word template**: Does the working group ship its own `reference-doc` Word template? If yes, drop it into `src/documents/` and update `2 advice sheet.qmd` YAML; otherwise the template auto-generates an ICES-flavoured one (see `template_advice_sheet.md`).
4. **Bibliography**: `src/documents/zotero_library.bib` is the inherited bib. Replace or add stock-specific references; nothing in the pipeline cares about extras, but the analyst probably does.
5. **Repo visibility**: The scaffolded repo defaults to private. When advice is published, the analyst may want to flip the repo to public — confirm before doing so, after a sensitivity review of catch and index data.

## After the interview

- All `{{STOCK_*}}` placeholders are resolved (`grep -r '{{' .` returns nothing actionable).
- `memory/stock_identity.md` reflects the chosen values.
- `memory/catch_data_sources.md` and `memory/index_data_sources.md` exist.
- `memory/template_open_items.md` is annotated with what's done vs still open.
- A summary `memory/onboarding_done.md` exists with the date, who participated (humans + which AI agents), and any unresolved questions kicked to a follow-up session.

Related: [[template_open_items]], [[template_layout]], [[stock_identity]]

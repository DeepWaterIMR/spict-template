---
name: spict-compile-data
description: Step 1 of the SPiCT workflow — compile the catch series and the abundance index into the two objects the model is fitted to, and record their provenance. Use after a SPiCT project is scaffolded and the user is ready to prepare the data.
---

# Step 1 — Compile the data

Goal: turn the raw sources into `data/output/<stock>_catches.rds` and
`data/output/<stock>_index.rds`, and record where every number came from.

Read `knowledge/catch-data.md` and `knowledge/indices.md` before writing code. The contracts
those files describe are what everything downstream relies on.

## Before you start

Confirm the raw inputs are in `data/source/` and that the analyst has confirmed which sources
apply. Do not download, guess at, or synthesise data to make the script run.

## Step 1 — The catches

`R/1_process_catches.R` ships as a worked example from beaked redfish. **Expect to replace it,
not edit it** — almost every stock combines a different set of sources on a different splice.

What it must produce:

- `data/output/<stock>_catches.rds` — `year` (integer) and `total` (tonnes), **no missing
  years**.
- `data/output/<stock>_landings.rds` — `year` plus one column per country or fleet.
- `data/output/<stock>_gear.rds` — optional, for the advice sheet's catch-by-gear table.

Run the checks the script already carries, and add the ones it cannot:

- No gap in the year sequence. A gap is not an error SPiCT reports; it is a biomass trajectory
  that quietly reflects the gap.
- The country columns sum to the total, within rounding.
- **The recent-year totals match the last working-group report.** A silent join failure looks
  like a total 8 % low, not like an error. This check is the point of the whole step.
- `min(catches$year)` matches `FIRST_DATA_YEAR` in `config.yaml`.

## Step 2 — The index

`R/2_prepare_index.R` adapts whatever the producer emits to `year`, `est`, `se`.

- Select the variant **by name**, not by position. `[[2]]` becomes a different variant the first
  time the producer adds one.
- Convert `cv` to `se` here, once, not in a document.
- Confirm `INDEX_TIMING` matches when the survey actually runs. A winter survey entered at 0.5
  shifts the biomass trajectory half a year against the catches, and shows up later as a
  stubborn pattern in the OSA residuals that no prior will fix.
- **Pin the producer's commit or tag.** An index that changed between last year's assessment
  and this one, unrecorded, is indistinguishable from a stock that changed.

If the index does not exist yet and should come from an sdmTMB spatiotemporal model, that is
[index-template](https://github.com/DeepWaterIMR/index-template)'s work. Do not build a survey
index inside a SPiCT project.

## Step 3 — Look at what you made

Plot the two series together before fitting anything. Catches and an index that move in
plausible relation to each other are the precondition for everything that follows; a mismatch
is far cheaper to find here than after a model has been fitted to it.

## Step 4 — Record it

Write `ai/memory/catch-data-sources.md` and `ai/memory/index-data-sources.md`, following the
lists at the end of `knowledge/catch-data.md` and `knowledge/indices.md`. Add pointers to
`ai/memory/MEMORY.md`.

These two files are what makes next year's assessment possible without repeating this
conversation.

## Done

Report the series that were compiled — their year ranges, their totals, and how the recent
years compared against the last working-group report — and say which checks passed. Then point
at **step 2, fit the model** (`spict-fit-model`).

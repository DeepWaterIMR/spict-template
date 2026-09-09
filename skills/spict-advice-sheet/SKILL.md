---
name: spict-advice-sheet
description: Step 5 of the SPiCT workflow — produce the catch advice sheet from the selected SPiCT run, with the catch scenarios, reference points, and advice history. Use when the assessment is settled and the advice is due.
---

# Step 5 — The advice sheet

Goal: the short public document carrying the catch advice to managers, built entirely from the
assessment output.

**Load the installed `academic-advice-sheet` skill first.** It owns the section order, the
table idiom, and the writing rules. This skill covers only what is specific to a SPiCT
assessment.

The document is `docs/advice-sheet/advice-sheet.qmd`.

## Three properties of this document

1. **It is quoted directly**, by managers and by journalists, and a wrong number here is a
   public error.
2. **It is regenerated each year** against a new assessment, so anything typed rather than
   derived goes stale silently.
3. **Once it is on the official track its numeric output must not change** under a cosmetic
   edit. See `knowledge/constraints.md`.

## It reads the summary object

`data/output/<stock>_spict_summary_<year>.rds`, saved by step 2. Do not fit, and do not load
the fitted object here — it is large, slow, and unnecessary. When the sheet needs a value the
summary does not carry, add a field to `spict_summary_object()` and re-render step 2.

## SPiCT specifics

- **Look the advice up by scenario name**, not by row position. The advice-rule row is not
  necessarily row 1, and will not stay row 1 when a scenario is added.
- **Derive the status sentence in code.** Fishing pressure above or below F~MSY~; biomass below
  B~lim~, between B~lim~ and MSY B~trigger~, or above MSY B~trigger~. Written as an `if`/`else`
  against the same object the table uses, the prose cannot contradict the table beside it.
- **Say that the reference points are relative** and that SPiCT provides no absolute ones. This
  is the single most common misreading of a SPiCT advice sheet.
- **Round with `ices_round()`** — a wrapper on `icesAdvice::icesRound()` — for every ratio the
  framework rounds, so the sheet matches the advice database. Use `fmt()` for tonnages.
- **Quality of the assessment carries the diagnostics honestly.** The summary object holds the
  acceptance-check verdicts; where one failed, say so and say what it means for the confidence
  the advised catch deserves. Do not soften it. Managers are entitled to know.
- **The exploratory callout stays** where SPiCT supplements an official assessment.

## The tables

The ICES table idiom lives in `R/advice_tables.R`:

- `ices_ft()` — the house style: grey header, thin inner rules, Calibri 9, fitted to the page.
- `ices_basis_ft()` — the two-column item/description blocks.
- `ref_point()` — reference-point labels with real subscripts. flextable will not read markdown
  inside a cell, so `B~MSY~` has to be composed rather than written.
- `fit_ft_page()` — call it last. Word clips a table wider than the text column rather than
  reflowing it.

Captions carrying a year are built as string objects in the `advice-values` chunk and
referenced with `#| tbl-cap: !expr cap_catch_scenarios`, rather than `sprintf()` inline where a
literal `%` has to be doubled. Note that a `!expr` caption is evaluated even when its chunk has
`eval: false`, so the object must already exist.

## The two annual traps

**The advice-history table.** The advice text is a historical record and cannot be derived, so
it is hard-coded — keyed by year, so a missing year fails loudly instead of shifting every row
by one. When the assessment year advances, **add that year's entry**. Never pad, recycle, or
shorten the year range to make lengths match.

**The release-time values.** The publication line, the advice DOI, and the download URL sit in
one marked block near the top. Leave them as visible placeholders until the working group
supplies them: a plausible-looking DOI that resolves to nothing is worse than an obvious blank.

## Rendering

```bash
Rscript docs/render.R advice-sheet docx
```

Pick the template in the YAML — IMR or ICES — and remember that the `normal-style.lua` filter
belongs with the IMR template only. Against the ICES template it forces every paragraph into a
style that template does not use.

HTML previews from the Preview button, styled with `assets/ices_advice.css`.

## Before it goes out

- Every number traces to the summary object; nothing is typed.
- The advised catch matches the assessment report and the data report.
- The advice-history table covers every year up to the advice year.
- The release-time values are filled or obviously marked as pending.
- The AI disclosure names the actual models and roles, appended to any existing list.
- The exploratory callout is present and unsoftened.

## Done

Report which sections are drafted, that the numbers come from the current run, which
release-time values still need filling, and — plainly — any acceptance check the assessment
failed, since that is what the *Quality of the assessment* section has to carry.

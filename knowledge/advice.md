# From a fit to catch advice

Two documents come out of a settled SPiCT run: the working-group **chapter**, and the **advice
sheet**. Neither refits the model. Both read `data/output/<stock>_spict_summary_<year>.rds`,
the small summary object the assessment data report saves, so all three documents quote the
same numbers by construction.

## The summary object

Written at the end of the assessment data report:

```r
spict_summary <- list(
  assessment_year = assessment_year,
  summary   = <year, total_catch, index, BBmsy.est/ll/ul, FFmsy.est/ll/ul, Catch_pred.est>,
  state     = sumspict.states(fit),
  drefpoints = sumspict.drefpoints(fit),
  srefpoints = sumspict.srefpoints(fit),
  manTable  = sumspict.manage(fit),
  risk      = spictRisk(fit, bmsyfrac = cfg$BTRIGGER_BMSY),
  diagnostics = <the acceptance-checklist verdicts>
)
```

It is deliberately small: the fitted SPiCT object is large and slow to load, and the advice
sheet needs none of it. Keep it that way — if the advice sheet needs something new, add a field
here rather than loading the fit.

## The advice sheet

Structure, tables, and the writing rules are owned by academic-writing's
**`academic-advice-sheet`** skill. Read it. What is specific to SPiCT:

- **The advice comes from the `manTable` row matching the advice rule**, not from row 1. Look
  it up by scenario name.
- **Reference points are relative.** The sheet reports B/B~MSY~ and F/F~MSY~ against the
  conventional B~lim~ = 0.3 and MSY B~trigger~ = 0.5, and says explicitly that the SPiCT model
  provides no absolute reference points. Where the stock has absolute points from another
  assessment, name their source; do not imply SPiCT produced them.
- **Stock status is a sentence, derived in code**: fishing pressure above or below F~MSY~, and
  biomass below B~lim~, between B~lim~ and MSY B~trigger~, or above MSY B~trigger~. Deriving it
  with `if`/`else` rather than typing it means it cannot contradict the table beside it.
- **Round with `icesAdvice::icesRound()`** for anything the advice framework rounds, so the
  sheet matches the ICES database.
- **The catch-scenario table** is grouped: an *Advice basis* block holding the advice rule row,
  then an *Other scenarios* block with F = F~MSY~, F = F~sq~, and F = 0. Percentage columns are
  change in biomass and change from the previous advice; when there was no previous advice the
  column is a dash, not a zero.

## The annual-update trap

The advice-history table carries one row per year with the text of that year's advice. That
text cannot be derived — it is a historical record — so it is a hard-coded vector, and when
`assessment_year` advances past its last entry the column lengths stop matching.

**Extend the vector. Do not pad it, recycle it, or shorten the year range to fit.** The
scaffolded document builds the table from a named list keyed by year for exactly this reason:
a missing year fails loudly instead of silently shifting every row by one.

## Release-time values

The publication line, the advice DOI, and the download URL change when the sheet is published
and cannot be derived from the assessment. They sit in one marked block near the top of the
document so the annual edit is in one place. Leave them as visible placeholders until the
working group supplies them — a plausible-looking DOI that resolves to nothing is worse than an
obvious blank.

## The working-group chapter

Owned by academic-writing's **`academic-assessment-report`** skill. Two things it needs from
here:

- **The float numbers are the group's**, assigned in the report as a whole. Write the assigned
  number into the caption text and mirror it in the label. Never renumber to match your prose.
- **Report the selected run.** If exploration in step 3 produced a better-diagnosing model that
  the working group did not adopt, the chapter reports what was adopted and describes the
  alternative under *Future development of the assessment*.

## Exploratory status

Where SPiCT supplements an official age-structured assessment rather than replacing it, both
the data report and the advice sheet carry a callout saying so, and the advice sheet's *Basis
of the assessment* names the official model. This is a hard constraint — see
[`constraints.md`](constraints.md).

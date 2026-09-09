---
name: spict-assessment-report
description: Step 4 of the SPiCT workflow — write the working-group assessment chapter from the selected SPiCT run, in the group's Word template with its float numbering. Use when the assessment is settled and the chapter is due for ICES, AFWG, JRN-AFWG, or an internal IMR report.
---

# Step 4 — The working-group chapter

Goal: a chapter of the working group's report documenting this stock's assessment, in the
group's template, ready to drop into the compiled report.

**Load the installed `academic-assessment-report` skill first.** It owns the section order, the
float-numbering convention, the templates, and the writing rules. This skill covers only what is
specific to a SPiCT assessment.

The document is `docs/assessment-report/assessment-report.qmd`.

## It reports; it does not refit

The chapter reads `data/output/<stock>_spict_summary_<year>.rds`, saved by step 2. Do not fit a
model here, and do not recreate the model code — every number the chapter quotes must be the
same number the data report and the advice sheet quote, and reading one object is what
guarantees that.

If the chapter needs a value the summary object does not carry, add a field to
`spict_summary_object()` in `R/spict_helpers.R` and re-render step 2.

## What a SPiCT chapter has to say that others do not

- **The index is relative.** State it, and say what it is an index *of* and what effort
  denominator it uses. A reader who takes a SPiCT index for an absolute biomass will misread
  everything after it.
- **The reference points are relative.** SPiCT estimates F~MSY~ and B~MSY~; B~lim~ and MSY
  B~trigger~ are conventions from the advice framework. Where the stock has absolute reference
  points from another assessment, name their source and do not imply SPiCT produced them.
- **There is no recruitment.** A surplus-production model compresses recruitment, growth, and
  natural mortality into one production function. Under *Comments to the assessment*, say
  whether that matters for this stock — a stock whose productivity has changed over the series
  is represented only approximately.
- **Name the spict version.** Results can differ between versions and branches; an assessment
  that cannot say which produced it is not reproducible.
- **The exploratory-status notice stays** where SPiCT supplements an official assessment. See
  `knowledge/constraints.md`.

## Float numbers

The working group assigns them. The `chapter` parameter stamps the chapter number into every
caption, so a renumbering by the group is one parameter change rather than an edit to twenty
captions. Never renumber a float to match your prose — other chapters cross-reference the
group's number.

All floats sit at the end under *Tables and figures*, in the group's order, not interleaved
with the text.

## Future development of the assessment

Be specific enough that this section becomes the next benchmark's issue list. Real candidates:

- Priors still carried over from another stock.
- Catch-uncertainty breakpoints that were assumed rather than established.
- Any acceptance check that failed this year.
- An alternative configuration from `spict-explore` that diagnosed better but was not adopted.

## Rendering

```bash
Rscript docs/render.R assessment-report docx
```

HTML previews from the Preview button. The Word post-processing unwraps Quarto's float wrappers
so the tables sit inline the way the group's template expects — which is why Word goes through
the script and not the button.

## Done

Report which sections are drafted, that the numbers come from the current run and which run
that is, and what the working group still has to supply: the template, the float numbers, the
stock data category, or reference points from outside the model.

Next: `spict-advice-sheet`.

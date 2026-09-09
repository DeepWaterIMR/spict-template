---
name: spict-new-assessment
description: Start a new SPiCT stock assessment project — run the structured questionnaire, confirm a plan, then scaffold a project folder from project-template with config.yaml. Use when the user says "set up a SPiCT assessment for <stock>", "scaffold a spict-template project", or asks to start a biomass-dynamic assessment.
---

# Start a new SPiCT assessment

Goal: turn *"let's run a SPiCT assessment for `<stock>`"* into a scaffolded project ready for
the workflow. **Ask the questionnaire, plan, then scaffold — do not start writing model code
yet.**

Read `knowledge/workflow.md` and `knowledge/project-structure.md` first, then
`knowledge/academic-writing.md` and the installed `academic-style`, `academic-conventions`, and
`academic-data-report` skills. spict-template supplies the assessment method; academic-writing
supplies the structure, style, and publishing conventions for every file that comes out.

## Step 1 — The questionnaire

Group the questions, offer defaults, but **get real answers**. Every one of these drives the
project, and a guess here is a wrong number in an advice sheet six months from now. Record the
answers for `ai/memory/scaffold-interview.md`.

### Stock identity

Stock code, display name (as it reads in a sentence, e.g. "beaked redfish"), kebab-case slug,
snake_case name, Latin binomial, ICES subareas as they read in a sentence, the full ICES stock
ID, and the working group's short and long names. **Verify the stock ID against the current
ICES stock register**; do not recall it from memory.

### Assessment status

- Is SPiCT the **official** assessment for this stock, or an **exploratory supplement**?
- If exploratory, which model is official? The exact wording goes into the callout that every
  document carries.
- Which advice framework applies — the ICES MSY approach, a precautionary approach, or a
  management plan?

### Years

Assessment year, advice year, the year advice was last given, the previous advised catch in
tonnes (zero when there was none), and the first year of the catch series.

### Catch data

Which sources cover which years, on what splice rule. The species filter on each source. Is
there a gear breakdown? How are discards treated? Which years are preliminary? See
`knowledge/catch-data.md` for the full list and the sanity checks. Follow any link the analyst
gives — read the producer's documentation rather than inferring its column names.

### The index

What kind of index, from which producer, which variant, and what fraction of the year the
observation refers to. See `knowledge/indices.md`. If the index does not exist yet and should
come from an sdmTMB spatiotemporal model, that is
[index-template](https://github.com/DeepWaterIMR/index-template)'s job, not this project's —
say so and settle the SPiCT project's other questions in the meantime.

### Model settings

- Where do the priors on `logr`, `logbkfrac`, and `logsdb` come from? "From another stock" is
  an answer, and it means the priors are placeholders that must be replaced before the
  assessment is used.
- What are the catch-uncertainty ramp breakpoints, and what reporting-quality events do they
  correspond to?
- Schaefer, or has a benchmark decided otherwise?
- Does the working group use the ICES conventions for B~lim~ and MSY B~trigger~, or its own?

### Human metadata

Accountable authors and affiliations, using academic-writing's `AUTHORS` and `AFFILIATIONS`
schema. **Never invent these.** Confirm the exact AI models and roles before anything is
disclosed in a document.

### Working-group conventions

Which Word template for the chapter and for the advice sheet? Which bibliography? Does the
group assign float numbers, and from which chapter?

## Step 2 — Plan

Summarise the answers, the resulting `config.yaml`, the documents to be created, and the order
of work. **Confirm with the user before scaffolding.** Flag anything ambiguous — particularly
carried-over priors, an index timing that does not match the survey, and any question the
analyst could not answer.

## Step 3 — Scaffold

1. Choose a target directory, usually a sibling of the current repo. Never scaffold at a system
   root.
2. Write `config.yaml` from the answers. Copy `examples/redfish/config.yaml` and replace the
   values; the field list is in `knowledge/project-structure.md`.
3. Run the scaffolder:

   ```r
   source("<spict_template_path>/scaffold.R")
   scaffold_spict(config = "config.yaml", target = "<target-dir>")   # dry = TRUE to preview
   ```

   This calls academic-writing's `scaffold_document()` for the project base, overlays the SPiCT
   layer, merges the bibliographies, and stamps every `{{PLACEHOLDER}}`. Confirm none remains.

   In a benchmark year, add the benchmark chapter:
   `types = c(SPICT_DOCUMENT_TYPES, "benchmark-report")`.

4. Initialise local Git in the new project, with **no remote**. Commit or push only when the
   user authorises it — and for a SPiCT project, publishing follows a review of whether the
   catch data can be published at all.

## Step 4 — Seed project memory

In the new project's `ai/memory/`:

- Fill `scaffold-interview.md` with the actual Q&A, including what the analyst could not answer.
- Note in `MEMORY.md` which of the listed memory files are still to be written.
- Write `priors.md` now if the priors came from another stock, saying so plainly — that is the
  single most consequential placeholder in the project.

## Done

Tell the user the project is scaffolded and what comes next: **step 1, compile the data**
(`spict-compile-data`), which needs the raw catch sources and the index file in `data/source/`.
Remind them that the generated project's `ai/memory/` is the shared project memory from now on,
and that the priors in `config.yaml` are placeholders until someone replaces them.

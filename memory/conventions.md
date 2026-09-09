---
name: conventions
description: House rules for editing spict-template itself
metadata:
  type: feedback
  author: spict-template
  created: 2026-09-09
---

# House rules for this repo

- **Improve `knowledge/` rather than duplicating guidance in a skill.** A `SKILL.md` stays
  short and links into `knowledge/`; academic-writing's validator flags skills over ~150 lines
  and the same target applies here.
- **A convention in `knowledge/spict.md` and its implementation in
  `project-template/R/spict_helpers.R` change in the same commit.** They are meant to agree,
  and a reader who finds them disagreeing cannot tell which is right.
- **Markdown wraps at about 92 columns. `.qmd`/`.Rmd` prose does not wrap** — one paragraph per
  line, for soft-wrap editors.
- **No data, no private paths.** `.gitignore` and `.claudeignore` are safety nets, not the
  policy.
- **Run `Rscript config/validate-scaffold.R` before every PR.** It scaffolds a synthetic
  project, parses every chunk, checks the document contract, and confirms the hard constraints
  are still in the templates. It does not fit a model: it checks the contract, not the science.

**Why**: this pack is read by agents at runtime. A contradiction between two files is not a
style problem — it is an agent making a defensible choice that happens to be wrong.

Related: [[architecture]]

---
name: spict-install
description: Install or set up spict-template for building SPiCT biomass-dynamic stock assessments. Use when the user says "install spict-template", "install https://github.com/DeepWaterIMR/spict-template", "set up spict-template", or first asks to run a SPiCT assessment and spict-template is not yet installed. Runs onboarding: ensure academic-writing, clone spict-template, install skills globally, verify the spict toolchain.
---

# Install spict-template

Goal: get spict-template working **once per machine** so it is available in every project — not
cloned into each stock repository. spict-template builds on academic-writing, so that must be
present first.

> Trigger: the user prompts *"install https://github.com/DeepWaterIMR/spict-template"* (or
> similar), or asks to run a SPiCT assessment with nothing installed yet.

## Step 1 — academic-writing first

spict-template does not carry its own project skeleton, style rules, or rendering pipeline: it
overlays academic-writing's. Without it, `scaffold_spict()` cannot run.

1. Check `~/.academic-writing/config.json`. If academic-writing is **not** installed, run its
   `academic-writing-install` skill (`install https://github.com/DeepWaterIMR/academic-writing`)
   before going on.
2. Confirm the `academic-style`, `academic-conventions`, `academic-data-report`,
   `academic-assessment-report`, and `academic-advice-sheet` skills are available.

## Step 2 — Clone spict-template

Clone it beside academic-writing (read `academic_writing_path` from that config and use its
parent), or another user-space location the user prefers. **Never clone at a filesystem root or
a system directory** — refuse and suggest a safe location.

```bash
git clone https://github.com/DeepWaterIMR/spict-template "<path>/spict-template"
```

If the user started by cloning the URL into the current workspace, reuse that clone rather than
duplicating it.

## Step 3 — Install the skills globally

Copy the `spict-*` skills into the agent's user-level skills folder so they work in every
project:

- Claude Code → `~/.claude/skills/`
- Codex → `~/.codex/skills/`
- Other agents → point their instructions at `<spict-template>/skills/`

Record the install in `~/.spict-template/config.json`:

```json
{ "spict_template_path": "<path>/spict-template", "installed_at": "<date>" }
```

`scaffold.R` reads that file to locate itself, so skipping it means passing `pack=` by hand
every time.

## Step 4 — Verify the toolchain

`spict` is not on CRAN and compiles a TMB model, so it needs a working compiler.

```r
if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")
if (!requireNamespace("spict", quietly = TRUE)) {
  remotes::install_github("DTUAqua/spict/spict", dependencies = TRUE, upgrade = "never")
}
library(spict)
packageVersion("spict")

for (p in c("quarto", "flextable", "officer", "icesAdvice", "cowplot", "readxl", "yaml")) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p)
}
```

If the `spict` install fails on a missing compiler, that is a toolchain problem: run
academic-writing's `academic-toolchain-setup` skill (Rtools on Windows, Xcode command line
tools on macOS) rather than retrying the install.

See `knowledge/packages.md` for the `dev` branch and why the version matters.

## Step 5 — Optional: index-template

If the abundance index will come from an sdmTMB spatiotemporal model rather than an existing
producer, install [index-template](https://github.com/DeepWaterIMR/index-template) as well. It
sits on BAIT and produces the index a SPiCT project consumes. A SPiCT project never builds its
own survey index.

## Done

Tell the user spict-template is installed, name the spict version, and say how to start:

> *"Let's set up the `<year>` SPiCT assessment for `<stock>` using spict-template."*

That triggers `spict-new-assessment`.

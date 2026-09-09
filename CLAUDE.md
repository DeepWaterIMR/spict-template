# CLAUDE.md — spict-template (Claude Code)

This is the **Claude Code** pointer. The full agent contract is in [`AGENTS.md`](AGENTS.md) —
read it. This file only adds Claude-specific notes.

## What this repo is

A **knowledge pack** (like [BAIT](https://github.com/DeepWaterIMR/BAIT) and
[index-template](https://github.com/DeepWaterIMR/index-template)) that teaches an agent to run a
**SPiCT** biomass-dynamic stock assessment and **generates a new project folder** for the stock.
It is installed once per machine; its skills live in `~/.claude/skills/` as `spict-*`.

It is **public — never commit data or private paths here.** See the confidentiality section of
[`AGENTS.md`](AGENTS.md).

It builds on [academic-writing](https://github.com/DeepWaterIMR/academic-writing): `scaffold.R`
calls that pack's `scaffold_document()` and overlays the SPiCT layer. There is one copy of the
shared infrastructure and it lives there, not here.

## Where things are

- **Skills** — `skills/spict-*/SKILL.md`. Installed globally by `skills/spict-install`.
- **Shared knowledge** — `knowledge/*.md`. `spict.md` and `constraints.md` are the two to read
  before touching anything.
- **Project overlay** — `project-template/`, copied over academic-writing's skeleton and
  stamped by `scaffold.R`.
- **Worked example** — `examples/redfish/`.
- **Pack development memory** — `memory/`. This is for developing spict-template itself, not
  for generated projects.

## Claude-specific notes

- **Project memory, not local memory.** When working *inside a generated project*, use that
  project's `ai/memory/` folder (read `ai/memory/MEMORY.md` first). Do **not** use
  `~/.claude/projects/.../memory/` for project facts — that folder is only for user-level
  preferences and identity. When working *in this pack*, use `memory/` here.
- **Skills** — when the user asks to compile data, fit, explore, or report a SPiCT assessment,
  invoke the matching `spict-*` skill. For prose and document structure, defer to the
  `academic-*` skills. For a survey index, defer to index-template's `index-*` skills; for
  Biotic data access, to BAIT's `biotic-*`.
- **Plan mode** — after the questionnaire in `spict-new-assessment`, use plan mode to confirm
  the approach before scaffolding.
- **Code review before render** — renders are slow; run `/code-review` on changed chunks first.
  See `knowledge/rendering.md`.
- **This is a template repository, not a runnable assessment.** The documents under
  `project-template/` contain `{{STOCK_NAME}}` and other placeholders that resolve only when
  `scaffold_spict()` has run. Do not try to render them here.
- **Template-level changes belong here**; stock-specific priors, narrative, and data belong in
  the generated project. A fix to `docs/render.R` or `R/0_setup.R` belongs in academic-writing.

For everything else, see [`AGENTS.md`](AGENTS.md).

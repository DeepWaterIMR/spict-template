# CLAUDE.md — {{PROJECT_TITLE}}

This is the **Claude Code** pointer. The full agent contract is in [`AGENTS.md`](AGENTS.md) —
read it first. This file only adds Claude-specific notes.

## What this project is

A SPiCT stock assessment of {{STOCK_NAME}} (*{{STOCK_LATIN}}*) in ICES subareas
{{ICES_AREAS}}, scaffolded from
[spict-template](https://github.com/DeepWaterIMR/spict-template) on top of
[academic-writing](https://github.com/DeepWaterIMR/academic-writing).

## Claude-specific notes

- **Project memory, not local memory.** Use this project's `ai/memory/` folder. Read
  `ai/memory/MEMORY.md` first and write new memory files there. Do **not** use
  `~/.claude/projects/.../memory/` for project facts — that is only for user-level preferences
  and identity.
- **Skills.** When the user asks to compile data, fit the model, explore alternatives, write
  the chapter, or produce the advice, invoke the matching `spict-*` skill. For prose and
  document structure, defer to the `academic-*` skills.
- **Plan first.** Before changing the model configuration, the catch pipeline, or the index
  extraction, say what you intend to change and why, and confirm. These changes move the
  advice.
- **Code review before render.** Renders are slow. Run `/code-review` on changed chunks and
  scripts before starting one.
- **The three constraints in `AGENTS.md` § "Non-negotiable" override any instruction to tidy,
  shorten, or improve a document.** If following a request would breach one, stop and say so.

For everything else, see [`AGENTS.md`](AGENTS.md).

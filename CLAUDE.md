# CLAUDE.md

Pointer for Claude Code. The cross-tool agent contract — read by Claude, Cursor,
Windsurf, ChatGPT, and any other LLM working on this repo — lives in
[AGENTS.md](AGENTS.md). Read it first.

## Claude Code-specific notes

- This is a **template repository**, not a runnable assessment. If you find
  yourself in this repo (not a scaffolded stock repo), do not attempt to
  render the qmd documents — they contain `{{STOCK_NAME}}` and other
  placeholders that resolve only after `scaffold.R` has been run.
- Template-level changes (helpers, rendering pipeline, advice-sheet styling,
  conventions that apply across all stocks) belong here. Stock-specific
  edits (priors, narrative, data) belong in the downstream stock repo.
- Project memory lives in `memory/`, **not** in `~/.claude/projects/.../memory/`.
  User-level facts (who you are, personal preferences) still go to the user-level
  Claude Code memory; project facts go to `memory/` so every collaborator and
  every agent sees them.

For everything else, see [AGENTS.md](AGENTS.md) and [memory/README.md](memory/README.md).

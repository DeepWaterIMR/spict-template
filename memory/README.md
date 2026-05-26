# memory/

Shared, committed, multi-agent project memory for this repository. Every
collaborator — human or AI — reads from and writes to this folder.

Distinct from **user-level memory** (e.g. `~/.claude/projects/.../memory/` for
Claude Code), which is personal to one user and stays out of the repo. Project
memory is in-repo, versioned, and shared.

## Format

Each memory is one file. One fact per file. Filenames are kebab-case slugs
matching the `name:` field in the frontmatter.

```markdown
---
name: <kebab-case-slug>
description: <one-line summary; used by readers deciding whether to load this>
metadata:
  type: project | reference | feedback | decision
  author: <agent or person identifier, e.g. claude-code-mikko, human-mikko>
  created: YYYY-MM-DD
---

<the fact, in plain markdown>

**Why**: <reasoning — why we chose this, why it matters>
**How to apply**: <when this knowledge bears on future work>

Related: [[other-memory-slug]]
```

`Related: [[other-slug]]` links to another memory file by its slug. Liberally
linking is encouraged — a link to a slug that doesn't yet exist marks a future
memory worth writing, not an error.

For decisions that supersede an older choice, add a `Supersedes: [[old-slug]]`
line. The old file stays in place (preserves the audit trail) — don't delete.

## The index

`MEMORY.md` is the human + agent index. One line per memory, newest at the
bottom. Format:

```
- [<title>](<file>.md) — <short hook>
```

When adding a memory, append its line to `MEMORY.md`.

## Types

| `type` | Use when… |
|---|---|
| `project`   | A fact specific to this stock/assessment (priors chosen, data provenance, etc.) |
| `reference` | Pointer to an external resource (paper, dashboard, ICES advice URL) |
| `feedback`  | Guidance about how to work in this repo (style, conventions, gotchas) |
| `decision`  | A choice made between alternatives, with reasoning (often paired with a `Supersedes:` line) |

## Template-level vs stock-level memories

Files named `template_*.md` are inherited from `spict-template` and apply to
every stock built from the template. Treat them as nearly read-only: improve
them when an improvement applies to all stocks, and push that improvement back
upstream to the template repo.

All other files are stock-specific and live with this repo only.

## What goes here vs what doesn't

**Goes here**:
- Priors chosen and why
- Data provenance and quirks
- Calibration decisions
- Cross-cutting conventions specific to this stock
- Open items still needing work
- Non-obvious constraints learned the hard way

**Does not go here**:
- Personal preferences (use your tool's user-level memory)
- Code structure (visible in the repo)
- Information already in git history
- Transient session state

## See also

- `../AGENTS.md` — full multi-agent contract
- `MEMORY.md` — the index

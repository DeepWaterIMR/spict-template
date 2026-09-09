---
name: spict-update
description: Update spict-template to the latest version — git pull the repository and re-sync the spict-* skills into the global skills folder. Use when the user says "update spict-template", "pull the latest spict-template", or asks for newer SPiCT assessment recipes or skills.
---

# Update spict-template

Goal: pull the latest spict-template and re-sync its skills, mirroring academic-writing's
`academic-writing-update`.

## Step 1 — Locate the install

Read `spict_template_path` from `~/.spict-template/config.json`. If there is no config, or no
git repository there, tell the user to run `spict-install` first and stop.

## Step 2 — Pull

```bash
git -C "<spict_template_path>" fetch --quiet
git -C "<spict_template_path>" pull --ff-only
```

If the working tree has local changes, report them and let the user decide. Do not discard
work, and do not stash silently — a local change in this repo is usually an improvement
someone meant to contribute upstream.

## Step 3 — Update academic-writing too

spict-template's scaffolder calls academic-writing's, so the two drift apart if only one is
pulled. Offer to run `academic-writing-update` in the same pass.

## Step 4 — Re-sync the skills

Copy the updated `skills/spict-*` into the agent's user-level skills folder
(`~/.claude/skills/` for Claude Code, `~/.codex/skills/` for Codex), overwriting the old
copies. Touch only `spict-*`; leave the `academic-*`, `index-*`, and `biotic-*` skills alone.

## Step 5 — Report

Summarise what changed since the last pull from the git log — new or updated skills, knowledge
files, and changes to `project-template/`.

Say explicitly that **existing assessment projects are not migrated**. They keep the templates
they were scaffolded with; a new project picks up the new ones. Where a change matters to an
existing project — a fixed helper, a corrected convention — name it, and let the analyst decide
when in the assessment cycle to take it. Mid-advice-round is rarely the moment.

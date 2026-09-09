# Rendering

## How to render what

| Output | Command |
|---|---|
| Any HTML preview | The Preview button in Positron, the Render button in RStudio, or `quarto render <file>` |
| The advice sheet, Word | `Rscript docs/render.R advice-sheet docx` |
| The working-group chapter, Word | `Rscript docs/render.R assessment-report docx` |
| Everything, every configured format | `Rscript docs/render.R` |

`docs/render.R` comes from academic-writing. It finds the project root, renders through Quarto,
tolerates the intermediate-folder cleanup failing on a synced or network drive, and — for Word
output — unwraps Quarto's float wrapper tables so the tables sit inline the way the ICES and
working-group templates expect. HTML needs none of that, which is why the button is enough.

## Toggles and caching

A SPiCT render is dominated by four things: the fit, the retrospective, the hindcast, and the
initial-value check. All four cache to `data/output/`, controlled by document parameters:

```yaml
params:
  refit:         true    # Fit the model, or load the cached fit
  run_retro:     true    # Run retro(), or load the cached peels
  run_hindcast:  true    # Run hindcast(), or load the cached result
  run_check_ini: true    # Run check.ini(), or load the cached trials
```

The working pattern: run once with everything `true`, then set them `false` while you iterate on
prose and tables, then set them back to `true` for the final render.

Two rules around that:

- **A cached diagnostic from a superseded fit is worse than no diagnostic.** When the input data,
  the priors, or the settings change, delete the cache rather than trusting the toggle.
- **Never add `freeze:` or `cache:` to a document silently.** Quarto's own freezing produces a
  document that disagrees with its own data, and the disagreement is invisible in the output.

## Long renders

A benchmark-scale render — several candidate fits, each with a retrospective — takes hours. Run
it detached, with a log:

```bash
screen -dmS spict-render bash -c 'Rscript docs/render.R > logs/render-$(date +%F-%H%M).log 2>&1'
```

Tell the analyst the session name and the log path. Reattach with `screen -r spict-render`, or
watch the log with `tail -f`.

## Review before you render

Renders are slow and the failure modes are cheap to catch by reading: a typo in a chunk label, a
path that assumes the wrong working directory, an object referenced before the chunk that builds
it, a `!expr` caption whose object does not exist. **Code-review the changed chunks and scripts
before starting an expensive render.** A typo found after a two-hour render costs two hours.

`Rscript config/validate-scaffold.R` in the pack checks a synthetic scaffold end to end without
data or a model fit; use it after changing the templates.

## Figure formats

Keep rendered HTML small. Raster figures render as JPEG; vector output is for the Word documents
where the working group asks for it. The advice-sheet figures are drawn at `fig-dpi: 300` and
sized to the page width in `R/advice_tables.R` rather than being scaled by Word.

## Common failures

| Symptom | Cause |
|---|---|
| `object 'cap_...' not found` in a caption | A `!expr` caption is evaluated even when its chunk has `eval: false`. Build the string in an earlier chunk that does run |
| Paths break when previewing one document | Documents set `knitr::opts_knit$set(root.dir = here::here())`; `.here` at the project root is what makes that work. Do not delete it |
| Word tables float to the end of the section | `docs/render.R` post-processing did not run. Render Word through the script, not the button |
| Heading styles wrong in the `.docx` | The wrong `reference-doc`. Check which template the YAML points at |
| The render silently uses last year's numbers | A cache that outlived its fit. Delete `data/output/` and re-run |

# shiny/

Interactive applications. This is spict-template's one addition to the academic-writing project
layout; everything else follows it unchanged.

`spict-explorer/` fits SPiCT to the project's compiled series under settings the user changes
with sliders, so a prior or a timing offset can be tried without editing a script. Launch it
from the project root:

```r
shiny::runApp("shiny/spict-explorer")
```

It reads `data/output/` and writes nothing back. When a configuration is worth keeping, put it
in `config.yaml` or in `R/explore_fit.R` so it is reproducible.

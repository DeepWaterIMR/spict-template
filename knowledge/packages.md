# The package ecosystem

A generated project declares its packages **once**, in `R/0_setup.R`, which comes from
academic-writing. Nothing installs packages from inside a document chunk.

## Required

| Package | Source | Why |
|---|---|---|
| `spict` | `DTUAqua/spict/spict` | The model |
| `TMB` | CRAN | `spict`'s engine; installed as a dependency |
| `tidyverse` | CRAN | Data handling and figures |
| `quarto` | CRAN | Rendering |
| `flextable`, `officer` | CRAN | Word tables in the advice sheet and the chapter |
| `kableExtra` | CRAN | HTML and LaTeX tables |
| `icesAdvice` | CRAN | `icesRound()`, the ICES rounding convention |
| `cowplot` | CRAN | The three-panel advice figure |
| `readxl` | CRAN | Working-group catch spreadsheets |

## Optional

| Package | Source | Why |
|---|---|---|
| `shiny`, `bslib` | CRAN | The interactive explorer under `shiny/` |
| `ggOceanMaps` | `MikkoVihtakari/ggOceanMaps` | Maps of the stock area |
| `xml2`, `zip` | CRAN | Word post-processing |

`spict` is declared in **academic-writing's** `optional_packages`, so a document reaches it
through `ensure_packages("spict")` at the point of use. Adding a package to a project means
adding one line to `R/0_setup.R`, never an `install.packages()` call in a chunk.

## Installing spict

`spict` is not on CRAN and needs a working compiler toolchain, because TMB compiles the model.

```r
remotes::install_github("DTUAqua/spict/spict", dependencies = TRUE, upgrade = "never")
```

The `dev` branch carries fixes ahead of `master`; pin it explicitly when a project needs one:

```r
remotes::install_github("DTUAqua/spict/spict@dev", dependencies = TRUE, upgrade = "never")
```

**Record which you installed in `ai/memory/`.** SPiCT results can differ between branches, and
an assessment that cannot say which version produced it is not reproducible.

If the install fails on a missing compiler, that is a toolchain problem, not a package problem —
run academic-writing's `academic-toolchain-setup` skill (Rtools on Windows, Xcode command line
tools on macOS).

## Sibling packs

| Pack | Provides |
|---|---|
| [academic-writing](https://github.com/DeepWaterIMR/academic-writing) | Writing style, document conventions, the project skeleton, rendering |
| [index-template](https://github.com/DeepWaterIMR/index-template) | The sdmTMB survey index that becomes SPiCT's `obsI` |
| [BAIT](https://github.com/DeepWaterIMR/BAIT) | IMR Biotic data access, privacy, maps, life history |

Call those rather than reimplementing them. In particular, do not build a survey index inside a
SPiCT project — index-template owns that, and a SPiCT project consumes its exported output.

# figures/

Drop-zone for assessment plots and figures exported from the Quarto
documents or generated interactively during analysis.

All files in this directory except this README are excluded from git
(see `.gitignore`). Add hand-crafted source artifacts (diagrams, maps)
to the `.gitignore` opt-in list if they should be tracked.

Generated figures are written here by scripts or report chunks that call
`ggsave()` or similar. They are not required for Quarto rendering; the
Quarto documents generate figures inline.

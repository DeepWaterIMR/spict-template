# ─────────────────────────────────────────────────────────────────────────────
# Project bootstrap: installs / loads required packages, defines the global
# ggplot theme, the project colour palette, and a small text helper used in
# Quarto narratives. Sourced from the top of every production script.
# ─────────────────────────────────────────────────────────────────────────────

packages <- c(
  "tidyverse",
  "sf",
  "lubridate",
  "scales",
  "ggOceanMaps",
  "knitr",
  "kableExtra",
  "spict",
  "rmarkdown",
  "quarto"
)

installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  if ("RstoxBase" %in% packages[!installed_packages]) {
    install.packages(
      "RstoxBase",
      repos = c(
        "https://stoxproject.github.io/repo",
        "https://cloud.r-project.org"
      )
    )
  }

  if ("RstoxData" %in% packages[!installed_packages]) {
    install.packages(
      "RstoxData",
      repos = c(
        "https://stoxproject.github.io/repo/",
        "https://cloud.r-project.org/"
      )
    )
  }

  if ("ggOceanMaps" %in% packages[!installed_packages]) {
    devtools::install_github("MikkoVihtakari/ggOceanMaps")
  }

  if ("spict" %in% packages[!installed_packages]) {
    remotes::install_github(
      "DTUAqua/spict/spict",
      ref = "dev",
      dependencies = TRUE,
      upgrade = "never"
    )
  }

  installed_packages <- packages %in% rownames(installed.packages())
  install.packages(packages[!installed_packages])
}

invisible(lapply(packages, function(x) {
  suppressPackageStartupMessages(library(x, character.only = TRUE))
}))

#' Format a vector as a natural-language list
#'
#' Joins the elements of `x` with commas and a final "and", producing
#' grammatical enumerations for use inside Quarto inline R expressions.
#' Length-1 input is returned unchanged; length-2 uses "and"; length ≥3
#' uses an Oxford comma.
#'
#' Use this in narrative text rather than ad-hoc `paste(..., collapse=", ")`
#' calls so the right separator is chosen automatically.
#'
#' @param x A vector (numeric or character). Will be coerced to character
#'   by `paste`.
#'
#' @return A length-1 character string.
#'
#' @examples
#' list_values("Norway")                       # "Norway"
#' list_values(c("Norway", "Russia"))          # "Norway and Russia"
#' list_values(c("Norway", "Russia", "Other")) # "Norway, Russia, and Other"
list_values <- function(x) {
  if (length(x) == 1) {
    paste(x)
  } else if (length(x) == 2) {
    paste(x, collapse = " and ")
  } else {
    (paste0(
      paste(x[1:(length(x) - 1)], collapse = ", "),
      ", and ",
      x[length(x)]
    ))
  }
}

# ── ggplot theme and colour palette ──────────────────────────────────────────

theme_cust <- theme_classic(base_size = 11) +
  theme(
    strip.background = element_blank(),
    panel.background = element_blank(),
    plot.background = element_blank(),
    legend.background = element_blank(),
    legend.box.background = element_blank(),
    plot.margin = margin(5.5, 10, 5.5, 5.5)
  )

theme_set(theme_cust)

cols <- c(
  "#D696C8",
  "#449BCF",
  "#82C893",
  "#FF5F68",
  "#FF9252",
  "#FFC95B",
  "#056A89"
)

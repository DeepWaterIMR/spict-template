# Catch data

SPiCT needs one series: **total catch in tonnes, by year, with no gaps**. Everything difficult
about assembling it is provenance — which sources cover which years, how they are spliced, and
what is quietly missing.

## The contract

`R/1_process_catches.R` writes:

| Object | Contents | Read by |
|---|---|---|
| `data/output/<stock>_catches.rds` | `year` (integer), `total` (tonnes). No missing years. | The assessment data report, the exploration scripts |
| `data/output/<stock>_landings.rds` | One row per year, one column per country/fleet, plus `Other` | The advice sheet's catch-history table |
| `data/output/<stock>_gear.rds` *(optional)* | `year`, `gear`, `tonnes` | The advice sheet's catch-by-gear table |

Raw inputs stay in `data/source/`, which is git-ignored. **The processed objects are derived
data and also git-ignored** — the report regenerates them.

`R/1_process_catches.R` ships as a worked example from beaked redfish (IMR landings database
spliced with a JRN-AFWG spreadsheet). It is almost certainly the wrong shape for another stock.
Expect to replace it, not edit it.

## Where catches come from

At IMR Deep-water, in rough order of how often they appear:

- **IMR landings database** — Norwegian sales notes, taken as an internal extract. Reliable for
  recent years; species attribution degrades going back.
- **ICES working-group spreadsheets** — multi-tab `.xlsx`, one tab per species, columns per
  country plus a total. The usual backbone of the historical series.
- **StoX outputs** — where landings are derived from a StoX run rather than read directly.
- **Bespoke country submissions** — Russian, Faroese, or EU data delivered through the working
  group and not in the main spreadsheet.
- **Reconstructed historical series** — pre-1970 figures from grey literature, often a single
  `Hist` column with no country breakdown.

## Questions to settle before writing the script

1. **Which sources, for which years?** The answer is usually a splice. Record the cut year and
   why it is there.
2. **Does the series need allocating by country, fleet, or area?** On what rule? The beaked
   redfish pattern is: Norway from the IMR database after 2022 and from the ICES sheet before,
   Russia from the ICES sheet throughout, `Other` as the residual, `Hist` before 1993.
3. **What is the species filter on each raw source?** Species names differ between systems —
   `"Snabeluer"` in the IMR database, the `"s mentella"` tab in the ICES workbook. Two
   *Sebastes* species sharing a spreadsheet is the classic way to assess the wrong stock.
4. **Is there a gear breakdown?** The ICES advice format expects one. Optional otherwise.
5. **How are discards treated?** SPiCT does not model discards. Either they are inside the
   catch series or they are assumed negligible — the advice sheet has to say which.
6. **Are the most recent years preliminary?** They almost always are. The advice sheet marks
   the last year with an asterisk and a "Preliminary" footnote; the model still uses it.

## Sanity checks worth running every year

- **Total against the last working-group report.** A silent join failure shows up as a total
  that is 8 % low, not as an error.
- **No missing years.** `setdiff(min(year):max(year), year)` must be empty. SPiCT will happily
  fit a series with a hole in it and give you a biomass trajectory that reflects the hole.
- **Country columns sum to the total**, within rounding.
- **The first year is the first year you mean.** `FIRST_DATA_YEAR` in `config.yaml` should
  match `min(catches$year)`; if it does not, one of the two is wrong.

## Confidentiality

Norwegian sales-note data carry confidentiality constraints, and catch data by country and
vessel can be commercially sensitive. Raw extracts stay in `data/source/`, which is
git-ignored, and the generated project defaults to a **local repository with no remote**. Before
a repository is made public, the analyst reviews whether the aggregated series it contains can
be published. Never loosen `.gitignore` to make one raw file commit.

## Record it

Write `ai/memory/catch-data-sources.md` with each raw file or query, the transformations
applied, every year cutoff and its reason, and the sanity-check totals against the most recent
working-group report.

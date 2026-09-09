# Worked example — beaked redfish (reb.27.1-2)

The exploratory SPiCT assessment of beaked redfish (*Sebastes mentella*) in ICES subareas 1
and 2, as carried out for the Joint Russian-Norwegian Working Group on Arctic Fisheries. The
official assessment for this stock uses gadget3; the SPiCT run is a supplement, which is why
`EXPLORATORY: true` and every generated document carries the exploratory callout.

`config.yaml` here is the configuration that project was scaffolded with. Copy it, replace the
values, and hand it to `scaffold_spict()`.

## What to change first

| Field | Why it matters |
|---|---|
| `AUTHORS` / `AFFILIATIONS` | Accountable humans. Never carried over from an example |
| `PRIOR_LOGR`, `PRIOR_LOGBKFRAC`, `PRIOR_LOGSDB` | The values here came from golden redfish and were never recalibrated for beaked redfish. They are placeholders in the strictest sense |
| `STDEV_HIGH_YEAR` / `STDEV_LOW_YEAR` | 1987 and 2022 are the years AFWG began correcting catches and Norwegian sales notes became trustworthy *for redfish*. Another stock has different events |
| `INDEX_ELEMENT` / `INDEX_TIMING` | Which variant of the producer's index, and when in the year the survey runs |
| `EXPLORATORY` / `OFFICIAL_ASSESSMENT` | Set `false` only when the working group has adopted SPiCT for the stock |

## Where this stock's data came from

- **Catches** — the IMR landings database for Norwegian catches after 2022, the JRN-AFWG catch
  spreadsheet (`s mentella` tab) before that, Russian catches from the spreadsheet throughout,
  and a reconstructed historical series before 1993.
- **Index** — the *over 30 cm biomass* variant of an sdmTMB spatiotemporal survey index built
  with [index-template](https://github.com/DeepWaterIMR/index-template) from all available
  bottom-trawl data. Recruitment is handled separately by gadget3, which is why the index
  starts at 30 cm.

Neither dataset is in this repository, and neither should be. See
[`knowledge/catch-data.md`](../../knowledge/catch-data.md) and
[`knowledge/indices.md`](../../knowledge/indices.md).

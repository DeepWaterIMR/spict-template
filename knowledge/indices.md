# The abundance index

SPiCT consumes a series that approximates **relative** biomass over time. It does not care
whether that series is fisheries-independent or fisheries-dependent: anything with a year, a
point estimate, and a per-observation uncertainty will drive the model.

## The contract

After extraction, the index must be a data frame with:

| Column | Meaning |
|---|---|
| `year` | Numeric year. The fractional timing offset is added later, from `INDEX_TIMING` |
| `est` | Point estimate. Units are arbitrary — it is rescaled by its own mean |
| `se` | Standard error on the log scale, used to build the `stdevfacI` multiplier |

`lwr` and `upr` are used for plotting when present. If the producer gives `cv` rather than
`se`, convert once, in `R/2_prepare_index.R`, not in the document.

`R/2_prepare_index.R` writes `data/output/<stock>_index.rds` in that shape. Everything
downstream reads that file, so a change of index producer touches one script.

## What kind of index?

Ask before assuming. The shapes that turn up:

- **Survey biomass index** — design-based (a stratified mean) or model-based (GAM, sdmTMB,
  VAST) from a research bottom-trawl, beam-trawl, acoustic, or longline survey.
- **Survey abundance index** — the count-based equivalent, often per length or age class.
- **CPUE** — fisheries-dependent catch per unit effort, raw or standardised for vessel, gear,
  area, and month through a GLM, GLMM, or Tweedie sdmTMB model.
- **Composite** — several of the above combined beforehand. SPiCT also accepts multiple `obsI`
  series natively; the template wires a single index, and adding a second is a benchmark
  decision, not an update-year one.

The choice shapes everything downstream: which producer to ask, what the object looks like on
disk, and whether the extraction in `R/2_prepare_index.R` needs rewriting.

## Where the file comes from

The index is almost never produced by this project. At IMR Deep-water the pattern is one
producer repository per species or species group; for the Barents Sea redfishes that is
[**index-template**](https://github.com/DeepWaterIMR/index-template) driving an sdmTMB
spatiotemporal index, exported at the end of its step 4.

Ask the analyst for the URL or path of whatever produces the index for this stock, then read
it rather than guessing: which surveys or fleets are combined, the structure of the output
object, whether there are several variants to choose between, and how the file physically
arrives in `data/source/`. **Pin a commit or a tag.** An index that changed between last year's
assessment and this one, unrecorded, is indistinguishable from a stock that changed.

### When the index comes from index-template

index-template's step 4 exports the selected index. Its `get_index_split()` returns a **named
list of data frames**, one per variant, each with
`model, year, est, lwr, upr, log_est, se, se_natural, type, cv`. The beaked-redfish worked
example takes element 2, the *over 30 cm biomass* variant, because recruitment is handled
separately by the official age-structured assessment.

`INDEX_ELEMENT` in `config.yaml` names the element to take. Set it by name rather than by
position where the producer gives names — `[[2]]` silently becomes the wrong variant when the
producer adds one.

### When it comes from anywhere else

A CPUE series is rarely a list. Rewrite the extraction in `R/2_prepare_index.R` to read
whatever the producer actually emits, and delete the list-indexing rather than wrapping a
single data frame in a list to satisfy code that expects one.

## Which variant is the assessment index?

If the producer emits several, the analyst is choosing one — record what they picked and why.
"Over 30 cm because recruitment is treated separately by gadget3" is a decision; "element 2" is
not.

## Timing within the year

`INDEX_TIMING` is the fraction of the year the index observation refers to, and it must match
when the survey actually runs. A winter survey entered at 0.5 shifts the biomass trajectory
half a year against the catches and shows up as a stubborn pattern in the OSA residuals.

## Record it

Write `ai/memory/index-data-sources.md` with: the index type; the producer repository or script
and the pinned commit; which surveys, years, gear, and area (or which fleet and effort metric);
which variant was chosen and why; the structural shape on disk and whether the extraction
needed editing; the timing offset and its justification; and how the file gets into
`data/source/`.

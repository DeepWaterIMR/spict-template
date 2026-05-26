# Survey indices

Place the stock's survey/abundance indices here. Conventions:

- Long-format `.rds` (e.g. `{{STOCK_CODE}}-assessment-survey-indices.rds`) with at least: `year`, `survey`, `index`, and optionally `cv` / `sd`.
- Each survey is one `survey` value. `1 assessment model.qmd` pivots wide as needed.

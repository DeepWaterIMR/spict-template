# Hard constraints

Three rules that override convenience, tidiness, and any agent's judgement about what would
read better. They are inherited from the `reg-spict` production pipeline, where each was
learned the expensive way.

## 1. Exploratory-status callouts stay

Where the SPiCT assessment is a supplement to an official age-structured assessment
(`EXPLORATORY: true` in `config.yaml`), the data report and the advice sheet each carry a
callout at the top saying so, naming the official model.

**Do not remove or soften these without explicit human authorisation recorded in
`ai/memory/`.** An edit pass that tidies a document is exactly the kind of change that quietly
drops one.

*Why*: a SPiCT supplement mistaken for the official assessment by a downstream reader runs from
confusion to misuse in management advice. The callout is the only thing standing between a
rendered `.docx` and that mistake.

## 2. Byte-identical numeric output once the sheet is official

Once the project is producing official-track advice — recorded in `ai/memory/` at benchmark
sign-off — the advice sheet **must render numerically identical output before and after any
change**. Only cosmetic edits, or edits provably equivalent in value, are allowed.

Before editing, verify that the replacement evaluates to the same value for the current
`assessment_year` and `advice_year`. Arithmetic equivalences have to be checked, not assumed:
`rep(0, 10)` and `rep(0, assessment_year - 2017 + 1)` agree in 2026 and diverge in 2027.

When unsure, render before and after and compare the outputs programmatically. Reading the two
documents side by side does not count.

*This constraint is dormant* while the project is in exploratory development with placeholder
data. It activates at sign-off, and the memory entry recording the sign-off is what activates
it.

## 3. Advice-history rows are extended, never fitted

See [`advice.md`](advice.md). When the assessment year advances past the last hard-coded row of
the advice-history table, the vector is extended with that year's actual advice text. Papering
over a length mismatch — recycling, padding with `NA`, trimming the year range — produces a
table where every row is attributed to the wrong year.

## When a constraint blocks the task

Stop and say so. Write a note in `ai/memory/` describing what you wanted to change, which
constraint blocked it, and what you would need from a human to proceed. Do not work around a
constraint because the task seemed to require it.

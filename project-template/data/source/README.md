# data/source/

Raw inputs, exactly as they arrived: catch database extracts, working-group spreadsheets,
country submissions, and the index `.rds` from its producer. **Nothing here is committed.**

Norwegian sales-note data carry confidentiality constraints, and catch data by country or
vessel can be commercially sensitive. Do not loosen `.gitignore` to make one file commit. If
a file needs to be shared, that is a conversation with the analyst, not a git decision.

`R/1_process_catches.R` and `R/2_prepare_index.R` read from here and write to `data/output/`.

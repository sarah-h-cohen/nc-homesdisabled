# Deaths in N.C. ICF/IID homes

Programs are numbered in the order they run. If you change one, re-run it and every
program after it. Each file a program writes starts with that program's number, so
`processed/05-deaths-coded.RDS` comes from `05-code-deaths.qmd`.

Paths are written with `here()` from the repo root. Names are lowercase with hyphens.

## Pipeline

| Program | Reads | Writes |
|---|---|---|
| `01-import-nc-deaths.qmd` — import and clean all NC death certificates | `data/all_death_files/` | `data/deaths_2020_to_2026_raw.RDS`, `data/deaths_cleaned_2020_to_2026.RDS`, `data/deaths2020up.duckdb` |
| `02-icf-deaths.qmd` — pull the 483 hand-identified ICF deaths | Google Sheet (RHA, Non-RHA, Gov tabs), `data/deaths2020up.duckdb` | `processed/02-icf-deaths.RDS` |
| `03-cause-code-list.qmd` — every code on the ICF deaths, with a description from the ICD-10 list or, failing that, the NCHS list | `processed/02-icf-deaths.RDS`, `data/cod-codes/allvalid2023-detailed-titles-headings.xlsx`, `data/cod-codes/icd10cm_order_2025.txt` | `processed/03-cause-code-list.RDS` |
| `04-sentinel-lookup.r` — sentinel level, plain-language definition and care area for every cause code | `processed/03-cause-code-list.RDS` | `processed/04-sentinel-lookup.RDS` |
| `05-code-deaths.qmd` — one row per cause, then one row per death with levels and flags | `processed/02-icf-deaths.RDS`, `processed/04-sentinel-lookup.RDS` | `processed/05-causes-coded.RDS`, `processed/05-deaths-coded.RDS` |
| `06-icf-provider-match.R` — match each death to a provider (CCN); nothing reads its output yet | `processed/02-icf-deaths.RDS`, `data/deaths_cleaned_2020_to_2026.RDS`, `processed/qcor-provider-nc.RDS`, `qcor/data/qcor_provider_master.RDS` | `processed/06-icf-deaths-to-code.RDS`, `processed/06-icf-deaths-matched.RDS` |

`processed/qcor-provider-nc.RDS` isn't written by any program here; it was made by hand from the QCOR provider list.

`processed/04-raw-cod-list.RDS` is the old copy of the code list from the Google Sheet. `03` reproduces it exactly, and nothing reads it now, so it can be deleted.

## Reports

| Report | Reads | Audience |
|---|---|---|
| `reports/firstpass.qmd` | `processed/02`, `04`, `05` files | Team; includes group comparisons and names. The Excel export chunk is `eval: false`; `reports/icf-deaths-cause-coded.xlsx` was hand-formatted on Google Drive, so don't regenerate it. |
| `reports/review.qmd` | `processed/04`, `05` files | One outside reader; no group comparisons or names, `death_id` hidden |

## Other folders

- `data/` — the statewide death files from `01` and the original DHHS downloads. Large; not in git. `data/cod-codes/` holds the two code lists `03` reads; the rest of that folder isn't used.
- `archive/` — retired programs kept for reference (old import, early code-list work, `address-master.r`). Their paths weren't updated and they may not run.
- `scratch/` — examples and notes: `example-death-queries.qmd` (for teammates using the duckdb file), `claude-cod-codes.txt`.

## Adding deaths

1. Add them to the Google Sheet and re-run `02`.
2. Render `03`. Its `check-unmatched` chunk lists any codes in neither code list; those need a description by hand.
3. Run `04`. Its last line lists any codes with no sentinel level yet. Add them to `sentinel_defs` and `short_labels` in `04-sentinel-lookup.r` and run it again.
4. Render `05`, then re-run `06` if you need the provider match.
5. Re-render the reports.

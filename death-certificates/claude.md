## Project goal

This sub-project concerns the care of residents in Intermediate Care
Facilities for the Intellectually Disabled (ICF/IID) in North Carolina.

We have a public database of all NC death certificates from 2020 through
about May 2026. We identified 483 deaths in ICF/IID homes by hand; they
are in a Google Sheet (organized by ownership) and combined in the quarto doc called `02-icf-deaths.qmd`.  

Goal: use cause-of-death codes to flag deaths that may indicate
quality-of-care problems in a home, or individual cases to investigate
further with doctors, family, and others. Levels are flags for review,
for possible neglect or abuse.

## Data notes

- Causes of death are in the `record axis code` (`rac`) column. These are
  record-axis codes: there is NO line or part position. The original RAC is ordered
  according to WHO rules and have a meaning, even though the most "serious" cause
  can be anywhere in the list. 

All records have the underlying cause (the acme_uc) as the first entry in the rac causes.

There are no records that have a different manually entered (manual_uc) than the acme cause


## Data privacy

All data, including PII, is from public sources. Do not republish PII to
the GitHub repo or the web.

## Folder layout

`README.md` has the full map of programs, inputs and outputs. Keep it
current when adding or renaming a program or output.

- Programs are numbered in run order (`01-` to `06-`). Every file a
  program writes goes in `processed/` and starts with that program's
  number. Lowercase, hyphens, `.RDS`, and `here()` paths from the repo root.
- Key files: `04-sentinel-lookup.r` (builds `processed/04-sentinel-lookup.RDS`),
  `05-code-deaths.qmd` (builds `processed/05-deaths-coded.RDS`, one row
  per death), `reports/firstpass.qmd` (team report)
- `reports/review.qmd` is the firstpass report for an outside reader, with no group comparisons or names and `death_id` in a hidden column.
- `data/`: statewide death files and original NC DHHS downloads, kept
  under their original names. In `data/cod-codes/`, only
  `allvalid2023-detailed-titles-headings.xlsx` and `icd10cm_order_2025.txt`
  are used (by `03-cause-code-list.qmd`); ignore the rest.
- `archive/`: retired programs; paths not updated. `scratch/`: examples and notes.

## R conventions

- Use current tidyverse style, including the native pipe.
- Prefer annotated Quarto documents to R scripts. Use scripts only to
  separate long code that other files call (e.g., `04-sentinel-lookup.r`).
- Prefer simplicity to elegance. This analysis won't be repeated, so
  efficiency and error handling matter less than simple solutions.
- For report tables, prefer gt or reactable with the NYT themes from
  reactablefmtr and gtExtras. I'll say when I'm making a report rather
  than doing processing work. Readability and fitting a lot on a page
  matter most.

## Sentinel levels

Each ICD-10 code has a sentinel level: 0 baseline, 1 expected,
2 vigilance, 3 focused review (a LeDeR term; death review committees would want to look
for systemic breakdowns). Level 3 deaths are all reviewed. The
per-certificate rollup takes the highest level and adds flag_* columns.

Not yet done: rules for combining less-serious codes that matter
together but not alone.

Decisions already made, pending items, and deferred issues are in the
memory file `sentinel-coding-decisions.md`. Start from those decisions
and don't re-litigate them.

## Do not

- Do not regenerate the Excel export. I hand-formatted the spreadsheet on
  Google Drive. Ask first.
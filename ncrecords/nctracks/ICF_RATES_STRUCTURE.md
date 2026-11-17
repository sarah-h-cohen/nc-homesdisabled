# ICF Rates Files - Structure and Import Guide

## Summary Table

| File Name | Header Row (Excel) | Data Starts (Excel) | Skip Parameter | # Columns |
|-----------|---------------------|---------------------|-----------------|-----------|
| icfrates-2022-02-01.xlsx | 21 | 22 | 20 | 11 |
| icfrates-2022-02-09.xlsx | 4 | 5 | 3 | 11 |
| icfrates-2025-07-22.xlsx | 21 | 22 | 20 | 11 |
| icfrates-2025-08-04.xlsx | 21 | 22 | 20 | 11 |
| icfrates-2025-09-30a.xlsx | 21 | 22 | 20 | 11 |
| icfrates-2025-09–30.xlsx | 21 | 22 | 20 | 10 |
| icfrates-2025-11-12.xlsx | 21 | 22 | 20 | 10 |
| icfrates-2025-12–23.xlsx | 21 | 22 | 20 | 9 |
| icfrates-2026-03–01.xlsx | 21 | 22 | 20 | 9 |
| icfrates-2026-06-22.xlsx | 21 | 22 | 20 | 10 |

---

## R Import Commands

### Using read_excel() from readxl package

**Note:** Most files (all except 2022-02-09) use `skip = 20`. The columns and structure are consistent within groups.

```r
library(readxl)

# icfrates-2022-02-01.xlsx
icf_2022_02_01 <- read_excel("icfrates/icfrates-2022-02-01.xlsx", skip = 20)
# Columns: NPI Number | Provider Number | Provider Name | Accommodation Code | 
#          Rate | Effective Date | End Date | Notes 1 | Notes 2 | Notes 3 | Notes 4

# icfrates-2022-02-09.xlsx (different structure - earlier format)
icf_2022_02_09 <- read_excel("icfrates/icfrates-2022-02-09.xlsx", skip = 3)
# Columns: NPI # | NA | PROVIDER NUMBER | PROVIDER NAME | TOTAL CHAIN RATE | 
#          ICF rate w/ 15% COVID increase | Accommodation Code | NPI # |
#          ICF rate w/ 5% COVID increase | ICF rate w/ 10% COVID increase | 
#          ICF rate with $102.06 increase

# icfrates-2025-07-22.xlsx
icf_2025_07_22 <- read_excel("icfrates/icfrates-2025-07-22.xlsx", skip = 20)
# Columns: NPI Number | Provider Number | Provider Name | Accommodation Code | 
#          Rate | Effective Date | End Date | Notes 1 | Notes 2 | Notes 3 | Notes 4

# icfrates-2025-08-04.xlsx
icf_2025_08_04 <- read_excel("icfrates/icfrates-2025-08-04.xlsx", skip = 20)
# Columns: NPI Number | Provider Number | Provider Name | Accommodation Code | 
#          Rate | Effective Date | End Date | Notes 1 | Notes 2 | Notes 3 | Notes 4

# icfrates-2025-09-30a.xlsx
icf_2025_09_30a <- read_excel("icfrates/icfrates-2025-09-30a.xlsx", skip = 20)
# Columns: NPI Number | Provider Number | Provider Name | Accommodation Code | 
#          Rate | Effective Date | End Date | Notes 1- Organization name | 
#          Notes 2 | Notes 3 | Notes 4

# icfrates-2025-09–30.xlsx (note: en-dash in filename)
icf_2025_09_30 <- read_excel("icfrates/icfrates-2025-09–30.xlsx", skip = 20)
# Columns: NPI Number | Provider Number | Provider Name | Rate | Effective Date | 
#          End Date | Notes 1- Organization name | Notes 2 | Notes 3 | Notes 4

# icfrates-2025-11-12.xlsx
icf_2025_11_12 <- read_excel("icfrates/icfrates-2025-11-12.xlsx", skip = 20)
# Columns: NPI Number | Provider Number | Provider Name | Rate | Effective Date | 
#          End Date | Notes 1- Organization name | Notes 2 | Notes 3 | Notes 4

# icfrates-2025-12–23.xlsx (note: en-dash in filename)
icf_2025_12_23 <- read_excel("icfrates/icfrates-2025-12–23.xlsx", skip = 20)
# Columns: NPI Number | Provider Number | Provider Name | Rate | Effective Date | 
#          End Date | Notes 1 Organization name | Notes 2 | Notes 3

# icfrates-2026-03–01.xlsx (note: en-dash in filename)
icf_2026_03_01 <- read_excel("icfrates/icfrates-2026-03–01.xlsx", skip = 20)
# Columns: Provider NPI Number | Provider Number | Provider Name | Rate | 
#          Effective Date | End Date | Enitity / Organization name | 
#          New / Terminated | Notes2

# icfrates-2026-06-22.xlsx
icf_2026_06_22 <- read_excel("icfrates/icfrates-2026-06-22.xlsx", skip = 20)
# Columns: Provider NPI Number | Provider Number | Provider Name | Rate | 
#          Effective Date | End Date | Enitity / Organization name | 
#          New / Terminated | Notes2 | Notes3
```

---

## Notes on File Structure

- **Most common pattern**: Header in row 21, data starts row 22 (use `skip = 20`)
- **Exception**: icfrates-2022-02-09.xlsx has header in row 4, data starts row 5 (use `skip = 3`)
- **Column count changes**: 
  - 11 columns: 2022-02-01, 2022-02-09, 2025-07-22, 2025-08-04, 2025-09-30a
  - 10 columns: 2025-09–30, 2025-11-12, 2026-06-22
  - 9 columns: 2025-12–23, 2026-03–01
- **Naming conventions shift**: Earlier files use "NPI #" and "ICF rate" descriptions; later files use "Provider NPI Number" and simplified column names
- **Filenames**: Watch for en-dashes (–) in some filenames which differ from regular hyphens (-)

# Import all ICF Rates files
# This script loads all ICF rate spreadsheets into a single named list

library(readxl)
library(dplyr)
library(purrr)

# Define file specifications
icf_files <- list(
  icf_2022_02_01 = list(file = "nctracks/icfrates/icfrates-2022-02-01.xlsx", skip = 20, date = "2022-02-01"),
  icf_2022_02_09 = list(file = "nctracks/icfrates/icfrates-2022-02-09.xlsx", skip = 3, date = "2022-02-09"),
  icf_2025_07_22 = list(file = "nctracks/icfrates/icfrates-2025-07-22.xlsx", skip = 20, date = "2025-07-22"),
  icf_2025_08_04 = list(file = "nctracks/icfrates/icfrates-2025-08-04.xlsx", skip = 20, date = "2025-08-04"),
  icf_2025_09_30a = list(file = "nctracks/icfrates/icfrates-2025-09-30a.xlsx", skip = 20, date = "2025-09-30"),
  icf_2025_09_30 = list(file = "nctracks/icfrates/icfrates-2025-09–30.xlsx", skip = 20, date = "2025-09-30"),
  icf_2025_11_12 = list(file = "nctracks/icfrates/icfrates-2025-11-12.xlsx", skip = 20, date = "2025-11-12"),
  icf_2025_12_23 = list(file = "nctracks/icfrates/icfrates-2025-12–23.xlsx", skip = 20, date = "2025-12-23"),
  icf_2026_03_01 = list(file = "nctracks/icfrates/icfrates-2026-03–01.xlsx", skip = 20, date = "2026-03-01"),
  icf_2026_06_22 = list(file = "nctracks/icfrates/icfrates-2026-06-22.xlsx", skip = 20, date = "2026-06-22")
)

# Load all files into a named list
icf_rates <- map(names(icf_files), function(name) {
  spec <- icf_files[[name]]
  read_excel(spec$file, skip = spec$skip, col_types = "text") %>%
    # Select only the columns we need and rename them
    select(
      npi = matches("NPI"),
      provider_num = `Provider Number`,
      provider_name = `Provider Name`,
      rate = `Rate`,
      everything()
    ) %>%
    mutate(file_date = spec$date, .before = 1)
})
names(icf_rates) <- names(icf_files)

# Alternative: Load directly into global environment
# Uncomment to use this approach instead:
# invisible(mapply(function(name, spec) {
#   assign(name, read_excel(spec$file, skip = spec$skip), envir = .GlobalEnv)
# }, names(icf_files), icf_files))

# Quick check: show what was loaded
cat("Loaded", length(icf_rates), "ICF rates files:\n")
invisible(map(names(icf_rates), function(name) {
  cat(sprintf("  %s: %d rows, %d columns\n", name, nrow(icf_rates[[name]]), ncol(icf_rates[[name]])))
}))

# Access example: icf_rates$icf_2025_07_22

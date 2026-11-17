# Analyze ICF Rates by NPI - Track rate changes over time
# Skips 2022 records and focuses on 2025-2026

library(readxl)
library(dplyr)
library(purrr)
library(readr)

# Define file specifications - 2025-2026 ONLY (skipping 2022)
icf_files <- list(
  icf_2025_07_22 = list(file = "nctracks/icfrates/icfrates-2025-07-22.xlsx", skip = 20, date = "2025-07-22"),
  icf_2025_08_04 = list(file = "nctracks/icfrates/icfrates-2025-08-04.xlsx", skip = 20, date = "2025-08-04"),
  icf_2025_09_30a = list(file = "nctracks/icfrates/icfrates-2025-09-30a.xlsx", skip = 20, date = "2025-09-30"),
  icf_2025_09_30 = list(file = "nctracks/icfrates/icfrates-2025-09–30.xlsx", skip = 20, date = "2025-09-30"),
  icf_2025_11_12 = list(file = "nctracks/icfrates/icfrates-2025-11-12.xlsx", skip = 20, date = "2025-11-12"),
  icf_2025_12_23 = list(file = "nctracks/icfrates/icfrates-2025-12–23.xlsx", skip = 20, date = "2025-12-23"),
  icf_2026_03_01 = list(file = "nctracks/icfrates/icfrates-2026-03–01.xlsx", skip = 20, date = "2026-03-01"),
  icf_2026_06_22 = list(file = "nctracks/icfrates/icfrates-2026-06-22.xlsx", skip = 20, date = "2026-06-22")
)

# Load all files
icf_rates <- map(names(icf_files), function(name) {
  spec <- icf_files[[name]]
  read_excel(spec$file, skip = spec$skip, col_types = "text") %>%
    mutate(file_date = spec$date, .before = 1)
})
names(icf_rates) <- names(icf_files)

# Combine all dataframes into one and clean
all_rates_clean <- bind_rows(icf_rates, .id = "source_file") %>%
  mutate(
    file_date = as.Date(file_date),
    rate = parse_number(rate),
    # Convert Excel serial dates to actual dates (Effective Date, End Date, etc)
    across(matches("Effective|End"), ~as.Date(as.numeric(.), origin = "1899-12-30"), .names = "{.col}")
  ) %>%
  select(file_date, npi, provider_num, provider_name, rate, everything()) %>%
  arrange(npi, file_date)

# Create a summary showing which rates are new or dropped for each NPI
rates_by_npi <- all_rates_clean %>%
  group_by(npi) %>%
  mutate(
    # Flag if this rate is different from the previous date for this NPI
    rate_change = if_else(
      rate != lag(rate, default = NA_real_),
      "changed",
      "same"
    ),
    # Identify if it's newly added (wasn't in previous file)
    is_new = if_else(
      is.na(lag(rate)),
      TRUE,
      FALSE
    ),
    # Identify if it was dropped in next file (won't appear in next file)
    is_dropped = if_else(
      is.na(lead(rate)),
      TRUE,
      FALSE
    )
  ) %>%
  ungroup()

# Summary statistics
cat("\n=== ICF RATES ANALYSIS (2025-2026) ===\n\n")
cat("Total records:", nrow(all_rates_clean), "\n")
cat("Unique NPIs:", n_distinct(all_rates_clean$npi), "\n")
cat("Date range:", min(all_rates_clean$file_date), "to", max(all_rates_clean$file_date), "\n\n")

cat("Records with rate changes:", sum(rates_by_npi$rate_change == "changed", na.rm = TRUE), "\n")
cat("Newly added rates:", sum(rates_by_npi$is_new), "\n")
cat("Dropped rates:", sum(rates_by_npi$is_dropped), "\n\n")

# Show NPIs with most activity
cat("NPIs with most records:\n")
rates_by_npi %>%
  count(npi, provider_name, sort = TRUE) %>%
  head(10) %>%
  print()

cat("\n")

# Output the main analysis dataframe
# This is available for further analysis as: rates_by_npi

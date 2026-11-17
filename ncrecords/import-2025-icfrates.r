# Analyze ICF Rates by NPI - Track rate changes over time
# Skips 2022 records and focuses on 2025-2026

library(readxl)
library(readr)
library(dplyr)
library(purrr)
library(janitor)
library(lubridate)


### The empty files show up as not used in the data once we get rid of the column names

# Define file specifications - 2025-2026 ONLY (skipping 2022)
icf_files <- list(
  icf_2025_07_22 = list(file = "nctracks/icfrates/icfrates_2025_07_22.xlsx", skip = 20, date =  mdy("7/22/25") , 
        headings = c("npi", "provider", "name", "accommodation", "rate", "eff_date", "end_date", "notes1", "notes2", "notes3", "notes4"), 
        types = c("text", "text", "text", "skip", "numeric", "date", "date", "skip", "skip", "skip", "skip") 
      ),
  icf_2025_08_04 = list(file = "nctracks/icfrates/icfrates_2025_08_04.xlsx", skip = 20, date =  mdy("8/4/25") , 
        headings = c("npi", "provider", "name", "accommodation", "rate", "eff_date", "end_date", "notes1", "notes2", "notes3", "notes4"), 
        types = c("text", "text", "text", "skip", "numeric", "date", "date", "skip", "skip", "skip", "skip") 
      ),
  icf_2025_09_30 = list(file = "nctracks/icfrates/icfrates_2025_09_30.xlsx", skip = 20, date =  mdy("9/30/25"), 
        headings = c("npi", "provider", "name", "rate", "eff_date", "end_date", "org_name",  "notes2", "notes3", "rate_notes"), 
        types = c("text", "text", "text",  "numeric", "date", "date", "text", "skip", "skip", "text") 
      ),
  icf_2025_11_12 = list(file = "nctracks/icfrates/icfrates_2025_11_12.xlsx", skip = 20, date =  mdy("11/12/25"), 
        headings = c("npi", "provider", "name", "rate", "eff_date", "end_date", "org_name",  "notes2", "notes3", "rate_notes"), 
        types = c("text", "text", "text",  "numeric", "date", "date", "text", "skip", "skip", "text") 
      ),
  icf_2025_12_23 = list(file = "nctracks/icfrates/icfrates_2025_12_23.xlsx", skip = 20, date = mdy("12/23/25"),
        headings = c("npi", "provider", "name", "rate", "eff_date", "end_date", "org_name",  "notes2", "notes3"), 
        types = c("text", "text", "text",  "numeric", "date", "date", "text", "skip", "skip") 
      ),
  icf_2026_03_01 = list(file = "nctracks/icfrates/icfrates_2026_03_01.xlsx", skip = 20, date = mdy("3/1/26"),
       headings = c("npi", "provider", "name", "rate", "eff_date", "end_date", "org_name",  "new_terminated", "notes2") , 
        types = c("text", "text", "text",  "numeric", "date", "date", "text", "text", "skip") 
      ),
  icf_2026_06_22 = list(file = "nctracks/icfrates/icfrates_2026_06_22.xlsx", skip = 20, date = mdy("6/22/26"),
       headings = c("npi", "provider", "name", "rate", "eff_date", "end_date", "org_name",  "new_terminated", "notes2", "notes3") , 
        types = c("text", "text", "text",  "numeric", "date", "date", "text", "text", "skip", "skip") 
     )
)




# test it: 



# Load all files
icf_rates <- map(names(icf_files), function(name) {
  print ( paste0("working on ", name))
  spec <- icf_files[[name]]
  
  read_excel ( path = spec$file, skip = spec$skip, col_names = spec$headings, col_types = spec$types) |> 
    filter (row_number() > 1) |> 
    mutate (file_date = spec$date)
}
)
names(icf_rates) <- names(icf_files)

# Combine all dataframes into one and clean

all_rates_clean <- bind_rows(icf_rates, .id = "source_file") |> 
  clean_names() |> 
  arrange (npi, file_date, eff_date) |> 
  group_by(npi) |> 
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

saveRDS(all_rates_clean, "nctracks/all_rates_by_npi.RDS")


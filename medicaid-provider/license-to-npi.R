colnames <-
  c(
    "license",
    "legal_name",
    "dba_name",
    "contact_name",
    "contact_number",
    "fax",
    "npi",
    "owner",
    "management",
    "site_city",
    "site_state",
    "site_zip",
    "fac_addr",
    "fac_addr2",
    "fac_city",
    "fac_state",
    "fac_zip",
    "county",
    "lic_date",
    "expire_date",
    "ccn_id",
    "prog_code",
    "prog_code_type",
    "age_code",
    "beds",
    "disabiity category",
    "facility_type",
    "total_bed_count",
    "total_resident_count"
  )

google_id <- "14yCjtoATpmPczuKX-n1pfrxdNoz3m0AHUsw4mTs9vCQ"

library(googlesheets4)
library(tidyverse)
library(duckdb)

licenses <- read_sheet(google_id, sheet = "nclist-2026-03", skip = 4) |>
  janitor::clean_names() |>
  select(
    row_no,
    license_number,
    name_of_licensee_legal_name,
    npi,
    owner,
    site_city,
    facility_address,
    facility_city,
    county,
    beds
  )


# sum the beds by npi and take the last one

unique_npis <-
  licenses |>
  mutate(npi = replace_values(npi, from = 3416336, to = 1528127602)) |>
  group_by(npi) |>
  summarize(
    facilities = n(),
    cities = n_distinct(facility_city),
    beds = sum(beds, na.rm = TRUE),
    legal_name = last(name_of_licensee_legal_name),
    .groups = "drop"
  )


con <- dbConnect(duckdb(), "working/medicaid-provider-spending.duckdb")
npi_list <- unique_npis |>
  filter(!is.na(npi)) |>
  mutate(npi = str_c("'", npi, "'"))
npis <- npi_list$npi |> paste0(collapse = ", ")


dbListTables(con)
dbListFields(con, "dataset")


# just for the time
bearcreek_npis <- c("1942320759", "1043379340", "1427112895") |>  
  str_glue_data('"{.}"')



bearcreek_npis <- c("1942320759", "1043379340", "1427112895") 

bearcreek_qry <- glue("'{bearcreek_npis}'") |>  str_flatten ( collapse= ", ")

|>
  # really weird way to have to use an anonymous function. 
  # this is one of those that would be good to make into a real function
  (\(x) str_c('"', x, '"'))() |>
  str_flatten(collapse = ", ")


library(glue)





  str_flatten( collapse=", ")
  
sql <- sprintf(
  "SELECT * FROM dataset WHERE BILLING_PROVIDER_NPI_NUM IN (%s) ",
  bearcreek_npis
)
sql

my_npidata <- dbGetQuery(con, sql)


license_match <-
  unique_npis |>
  mutate(npi = as.character(npi)) |>
  inner_join(my_npidata, join_by(npi == BILLING_PROVIDER_NPI_NUM))

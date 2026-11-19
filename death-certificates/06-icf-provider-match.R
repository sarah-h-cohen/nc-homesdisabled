### MAtch up the list of deaths in Malena's file to the provider listing

library(tidyverse)
library(here) 
library(stringdist)

i_am("death-certificates/06-icf-provider-match.R")
here()

ncproviders <- 
  readRDS(here("qcor/data/qcor_provider_master.RDS")) |> 
  filter ( state == "NC")


icfdeaths <- 
    readRDS(here("death-certificates/processed/02-icf-deaths.RDS")) |> 
    select ( death_id, facility = `Facility Name`, owner = `Facility Owner` )


# get the deaths from the saved version of the data. 

all_deaths <- 
  readRDS(here("death-certificates/data/deaths_cleaned_2020_to_2026.RDS")) |>
  select ( death_id, decedent_name, dod, dob, dplace, dinsti, death_street, citytext_d, zip9_d, res_street, citytext_r, zip9_r) 
  
deaths_to_code <- 
  icfdeaths |> 
  inner_join ( all_deaths, join_by ( death_id))

saveRDS(deaths_to_code, here("death-certificates/processed/06-icf-deaths-to-code.RDS"))


### Assign each death to a provider (ccn) ----------------------------------
# Order of rules:
#   1. NC Government (state centers, unnamed in the file): by residence city, then death city
#        Butner = Murdoch (34G002), Morganton = J. Iverson Riddle (34G003), Kinston = Caswell (34G001)
#        (Caswell is coded "For Profit" in the CMS file, but it is a state center.)
#   2. Residence address (street number + first street word + zip5) matches the provider address
#   3. Facility name matches provider name (Jaro-Winkler distance <= 0.12)
#   4. Death address matches the provider address
#   5. Manual fixes

providers <- readRDS(here("death-certificates/processed/qcor-provider-nc.RDS"))
deaths_to_code <- readRDS(here("death-certificates/processed/06-icf-deaths-to-code.RDS"))

addr_key <- function(x) {
  x <- toupper(x)
  num <- str_extract(x, "^\\d+")
  word <- str_remove(x, "^\\d+\\s*") |>
    str_remove("^(N|S|E|W|NORTH|SOUTH|EAST|WEST|OLD)\\.?\\s+") |>
    str_extract("^[A-Z0-9]+")
  if_else(is.na(num) | is.na(word), NA_character_, paste(num, word))
}

name_key <- function(x) {
  toupper(x) |>
    str_replace_all("[^A-Z0-9 ]", " ") |>
    str_remove_all("\\b(GROUP HOME|HOME|ICF|MR|IDD|INC|THE|CENTER|CTR|RESIDENCE|FACILITY|COTTAGE|HOUSE)\\b") |>
    str_squish()
}

prov_keys <- providers |>
  mutate(addr_key = addr_key(address), zip5 = str_sub(zip_code, 1, 5), name_key = name_key(provider_name))

addr_lkp <- prov_keys |> distinct(addr_key, zip5, .keep_all = TRUE) |> select(addr_key, zip5, ccn)

best_name <- function(f) {
  if (is.na(f) || f == "") return(tibble(ccn_name = NA_character_, name_dist = NA_real_))
  dist <- stringdist(f, prov_keys$name_key, method = "jw", p = 0.1)
  i <- which.min(dist)
  tibble(ccn_name = prov_keys$ccn[i], name_dist = dist[i])
}

gov_ccn <- c(BUTNER = "34G002", MORGANTON = "34G003", KINSTON = "34G001")

manual_fixes <- tribble(
  ~facility,   ~res_street,          ~ccn_fix,
  "YADKIN II", "3220 US HIGHWAY 21", "34G166"   # YADKIN II & III, not YADKIN I
)

icf_deaths_matched <- deaths_to_code |>
  mutate(
    res_key = addr_key(res_street),   res_zip5 = str_sub(zip9_r, 1, 5),
    d_key   = addr_key(death_street), d_zip5   = str_sub(zip9_d, 1, 5)
  ) |>
  left_join(addr_lkp |> rename(ccn_res = ccn), join_by(res_key == addr_key, res_zip5 == zip5)) |>
  left_join(addr_lkp |> rename(ccn_death = ccn), join_by(d_key == addr_key, d_zip5 == zip5)) |>
  bind_cols(map_dfr(name_key(deaths_to_code$facility), best_name)) |>
  left_join(manual_fixes, join_by(facility, res_street)) |>
  mutate(
    ccn = case_when(
      !is.na(ccn_fix) ~ ccn_fix,
      owner == "NC Government" & citytext_r %in% names(gov_ccn) ~ gov_ccn[citytext_r],
      owner == "NC Government" & citytext_d %in% names(gov_ccn) ~ gov_ccn[citytext_d],
      owner == "NC Government" ~ NA_character_,
      !is.na(ccn_res) ~ ccn_res,
      name_dist <= .12 ~ ccn_name,
      !is.na(ccn_death) ~ ccn_death
    ),
    match_method = case_when(
      !is.na(ccn_fix) ~ "manual",
      owner == "NC Government" & !is.na(ccn) ~ "state center city",
      !is.na(ccn) & ccn == ccn_res ~ "residence address",
      !is.na(ccn) & ccn == ccn_name ~ "facility name",
      !is.na(ccn) ~ "death address",
      .default = "unmatched"
    )
  ) |>
  select(-c(res_key, res_zip5, d_key, d_zip5, ccn_res, ccn_death, ccn_name, name_dist, ccn_fix)) |>
  left_join(
    providers |> select(ccn, provider_name, provider_address = address, provider_city = city,
                        provider_zip = zip_code, certified_beds),
    join_by(ccn)
  )

count(icf_deaths_matched, match_method)

saveRDS(icf_deaths_matched, here("death-certificates/processed/06-icf-deaths-matched.RDS"))

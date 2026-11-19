# save bc cns address data and merge with NC facility addresses

library(tidyverse)
library(readxl)
library(here)

rm(list=ls())




icf_nc  <- readxl::read_excel("ncrecords/icfmr.xlsx") |> 
  janitor::clean_names()   |> 
  select ( row_no, ccn = ccn_number, license_number, 
          nc_legal_name = name_of_licensee_legal_name, 
          nc_dba = dba_name, 
          site_city, site_state, facility_address:facility_zip) |> 
  rename_with ( \(x) str_replace (x, "site", "nc_site"))  |> 
  rename_with ( \(x) str_replace(x, "facility", "nc_mgmt") )
  


# issue: the facility address in cms has no zip code; the "site" address is the matching one in the licenses, but not the address. 

# also want to keep the parent (cms) and facility (nc) adderesses

# rename to match the concepts

# providers has the zip code that's missing from the cms 3070 data

nc_providers <- readRDS("qcor/data/qcor_provider_master.RDS") |> 
  slice_tail ( n=1, by=ccn) |> 
  filter ( state=="NC") |> 
  select ( ccn:county) |> 
  rename_with  ( \(x) str_c("cms_", x) ,  .cols  = c(address:county) )  


patch_data <- nc_providers |> select (ccn, cms_site_zip = cms_zip_code)


cms <- readRDS("cms_3070g/data/cms3070g_allfields.RDS") |> 
  select ( ccn=provider_ccn, cms_dba = name_of_facility, 
          address_line1:county, state=state_code,
          parent_name:parent_ceo
        ) |> 
  filter ( state == "NC") |> 
  slice_tail ( n=1, by=ccn) |> 
  rename_with ( \(x) str_c ( "cms_site_", x), .cols=c (address_line1:state) ) |> 
  rename_with ( \(x), str_c ("cms_", x) , .cols=parent_name:parent_ceo )  




##cms <- cms |> 
#  rows_patch(
#    patch_data, 
#    by = "ccn",
#    unmatched = "ignore"
#  )

cms <- 
  cms |> 
  left_join (patch_data, join_by (ccn) ) |> 
  relocate ( cms_site_zip, .after=)

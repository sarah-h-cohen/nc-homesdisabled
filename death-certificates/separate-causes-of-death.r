
# uncomment to start with a clean slate
# rm(list=ls())

pacman::p_load("here", "tidyverse", "googlesheets4", "lubridate", "janitor")


############### Get the data that Malena has already found #########################

icf_deaths_googlesheet <- "https://docs.google.com/spreadsheets/d/1gOmJrS_-U9knRArSrUeC5SwQ8Mf-WkY9oabl3OuBxu8/"

# the structures vary slightly so it's easier to start with the whole database then 
# pare it down rather than put together the sheets again

# what are the pages called? 
# sheets <- sheet_names(icf_deaths_googlesheet)


rha_deaths <- read_sheet(icf_deaths_googlesheet, sheet="RHA Deaths")  |> 
  select ( death_id , `Facility Name`) |>  mutate (`Facility Owner` = "RHA") 

oth_deaths <- read_sheet (icf_deaths_googlesheet, sheet="Non-RHA, Non-Gov") |> 
  select ( death_id, `Facility Name`,  `Facility Owner`) 

gov_deaths <- read_sheet ( icf_deaths_googlesheet, sheet = "Gov")  |> 
  select ( death_id ) |> 
  mutate ( `Facility Name` = NA_character_, 
           `Facility Owner` = "NC Government")

# put them together into one list, and flag where they came from 

combined_list <- 
  bind_rows ( 
    "RHA Deaths" = rha_deaths,
    "Non-RHA, Non-Gov" = oth_deaths,
    "Gov" = gov_deaths, 
    .id = "df_source"
  )

# get a list of unique death_id values for the SQL statement
where_list <- combined_list |> distinct ( death_id) |> pull()


# connect to the copy of the database I have on my hard drive. YMMV
library(duckdb)
con <- duckdb::dbConnect( duckdb(), here("death-certificates/data/deaths2020up.duckdb"))
# dbListTables(con)


# get the deaths from the list. 
# glue_sql makes the quoting work right. 

all_deaths <- dbGetQuery( con, 
      glue::glue_sql ("SELECT * FROM deaths_from2020 WHERE death_id IN ({where_list*}) ",
                  .con = con)
) |> 
  select ( death_id, dod, dob, manner, lname, gname, stnum_r:zip9_r, 
           dplace, dinsti, address_d:zip9_d, countytext_d, acme_uc:autop )

# don't forget to close the connection
dbDisconnect(con, shutdown=TRUE)
rm ( con)


deaths_working <-  
  combined_list |> 
  inner_join ( all_deaths , join_by ( death_id) )


### Get a full list of the death codes by row, not combined 
cause_per_row <- 
  deaths_working |> 
  select ( death_id, df_source, manner, `Facility Name`, lname, acme_uc,  rac) |> 
  separate_rows ( rac, sep = "\\s+")  

cause_per_row |>  count(rac) |> view()


## Clean up the interim tables
rm (all_deaths, combined_list, gov_deaths, rha_deaths, oth_deaths, where_list)



### See if all of the codes are in the NCHS version 
nchs_codes <- readRDS("death-certificates/ncha_cod_codes.RDS") 

## Read the cause of death files 
icd_list <- readRDS(here( "death-certificates/cms_icd10.RDS")) |> 
  select ( -  row_order) 


  

all_code_list <- 
  nchs_codes  |> 
  full_join ( icd_list, join_by ( code)) |> 
  # just keep the ones that are in our list
  semi_join ( cause_per_row, join_by ( code == rac) ) |> 
  mutate ( description = coalesce( icd_desc, nchs_desc)) |> 
  select ( code, description, master_code, master_desc)

## BOTH LISTS HAVE BIG HOLES FOR OUR DATA
## SO here, I'll put together the full list, which has one column for ICD10 and one for NCHS



causes_translated <-
  cause_per_row |> 
  left_join ( all_code_list , join_by ( rac == code) )


causes_translated |> 
  count ( rac, description, master_desc, sort=TRUE) |> 
  saveRDS(here("working/codcodes.RDS"))


##################  save this to a page in your google sheet 
# You can delete it later on when we decide how to deal with it. 

write_sheet( causes_translated, ss=icf_deaths_googlesheet, sheet="one cause per row")


############# AFTER I EDITeD the list OF CAUSES ######################

flagged_data <- readRDS(here("working/flagged_cods.RdS"))

select_ids <- 
  cause_per_row |> 
  inner_join  ( flagged_data |> filter ( flag=="X") |> select ( rac, description), 
              join_by ( rac)
            ) |> 
  group_by ( death_id) |> 
  summarize  ( flagged_codes = str_c (rac, collapse=";") ,
              flagged_desc = str_c ( str_trunc(description, 50) , collapse="; ")) 
  

flagged_alldata <- 
  deaths_working |> 
  left_join ( select_ids, join_by ( death_id) ) 



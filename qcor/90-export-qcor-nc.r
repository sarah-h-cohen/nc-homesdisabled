library(tidyverse)
library(googlesheets4)
library(here)

i_am("qcor/90-export-qcor-nc.r")

providers <- readRDS("qcor/data/qcor_provider_master.RDS") 
all_results <- readRDS("qcor/data/qcor_survey_details.rds")  |> 
  select ( ccn, survey_id, survey_date, nyt_survey_type, survey_type, provider_name, city, state,
           level,  tag_number, tag_group, short_description, nyt_special, 
           us_code, certified_beds, ownership_type, as_of_year) |> 
  filter ( state == "NC")
    


all_summaries <- readRDS("qcor/data/qcor_survey_summaries.RDS") |> 
  select ( survey_id, ccn, provider_name, city, state, ownership_type, nyt_survey_type, 
           survey_date, deficiency_ct, condition_ct = condition, abuse_neglect_ct = abuse_neglect, staffing_ct = staffing) |> 
  filter ( state == "NC")



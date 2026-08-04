## Get the codes and see how often they are used nationally and in NC.

pacman::p_load(
  "tidyverse",
  "lubridate",
  "janitor",
  "googlesheets4",
  "readxl",
  "here"
)

i_am("qcor/05a-code-spreadsheet.r")

qcor_codes <- readRDS(here("qcor/data/qcor_deficiency_codes.RDS"))

abuse_neglect_codes <- paste0("W0", c(122, 127, 128, 150, 151, 153, 154, 155, 156, 157, 285, 287, 286, 292, 298, 306, 310))
staffing_codes <- paste0("W0", c( 152, 158 , 167, 170, 193, 194, 485, 344, 301, 183, 184, 185, 186, 187))


deficiencies <- readRDS(here("qcor/data/qcor_survey_details.RDS")) |>
  filter(level != "None") |>
  mutate ( is_nc = if_else(str_starts(survey_id, "34"), "NC", "Elsewhere") 
          ) |> 
  group_by ( tag_number) |> 
  summarize  ( nc_deficiencies = sum( is_nc == "NC") , 
              all_deficiencies = n() , 
              .groups="drop") |>
  left_join ( qcor_codes, join_by (tag_number )) |> 
  mutate ( nyt_deficiency_group = case_when  ( tag_number %in% abuse_neglect_codes ~ "Abuse / neglect" ,
                                                tag_number %in% staffing_codes ~ "Staffing", 
                                              .default = NA_character_)
          ) |> 
  select ( tag_number, level, nc_deficiencies, all_deficiencies, nyt_deficiency_group , deficiency_description, full_text = description, guidance)
  



# save to google sheet
write_sheet( deficiencies, ss="https://docs.google.com/spreadsheets/d/1c06TyWsY3F0YdOL208L3YUlDBsNpw6N00Rw05OaJxoQ")



  


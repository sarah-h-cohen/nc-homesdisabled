library(tidyverse)
library(rvest)
library(tools)
library(janitor)
library(lubridate)
library(here)
library(glue)

here::i_am("qcor/parse_all_qcor_docs.R")

# this has functions for actually parsing the html into tables.
source("qcor/parse_qcor.R")


# Process the HTML pages in batches - it might overload memory without it, and it makes it easier to deal with failures
# without having to build in a lot of error checking.

# there were four files that had no content. I moved them into bad_qcor_docs folder and will deal with them when i deal with
# any other missing files. There are some (about 30) that have no surveys from 2010-2026

# list of ccns that are already processed

all_deficiency_tables <-
  list.files(
    here("qcor/qcor_tables"),
    pattern = "\\.rds$",
    full.names = TRUE
  ) |>
  map(readRDS) |>
  list_rbind() |>
  distinct(ccn) |>
  pull()


# list of the downloaded files

ccns <- list.files(
  here("qcor/qcordocs"),
  pattern = "\\.html$",
  full.names = TRUE
) |>
  # get rid of empty files
  keep(\(x) file.size(x) > 0) |>
  basename() |>
  file_path_sans_ext()


# there are 6418 of these. Do them in batches of 100.
batch_size <- 100
num_batches <- ceiling(length(ccns) / batch_size)
# how to get starting and ending batch.
batch_numbers <- c(1:num_batches)


################ FUNCTION TO PROCESS EACH BATCH ###################

process_batch <- function(batch_ccns) {
  all_clean_htmls <-
    map(batch_ccns, \(x) clean_qcor_html(x))

  all_annual_tables <-
    map(all_clean_htmls, \(x) get_annual_tables(x))

  # check for some that have no surveys within the batch
  valid_yn <- map_lgl(all_annual_tables, \(x) !is.null(x))
  batch_ccns <- batch_ccns[valid_yn]

  all_annual_tables <- all_annual_tables[valid_yn]

  table_results <- map2(all_annual_tables, batch_ccns, \(t, c) {
    parse_surveys(t, c)
  }) |>
    # I don't know why I put the function in squiggly brackets but it doesn't seem to matter.

    # remove empty elements. I don't think there will be any but just in case...
    compact() |>

    unlist(recursive = FALSE) |>

    map(\(x) {
      tibble(
        ccn = x[[1]],
        header = x[[2]],
        deficiency_table = x[[3]],
        followup_date_1 = x[[4]][1],
        followup_date_2 = x[[4]][2]
      )
    }) |>

    list_rbind()

  table_results |> unnest(deficiency_table)
}


############## Manual for loop that changes based on the batches I want to process

# saves any parsed results into a table in the qcor_tables folder. There should
# be 65 of these in the end.

# I don't care that it's kind of manual - I have to check the output anyway

for (i in 56:65) {
  start_index <- (i - 1) * batch_size + 1
  end_index <- min(i * batch_size, length(ccns))
  batch_ccns <- ccns[start_index:end_index] |>
    discard(\(x) x %in% all_deficiency_tables)

  # Process the current batch of CCNs
  batch_table <- process_batch(batch_ccns) |> mutate(batchid = i)

  saveRDS(
    batch_table,
    here(glue("qcor/qcor_tables/batch_{sprintf('%03d', i)}.rds"))
  )
}


# now put them all together into one data frame
# THIS HAS TO BE CHANGED AS SHOWN HERE AT SOME POINT TO GET A SURVEY ID. I DON'T KNOW HOW TO MAKE SURE IT IS THE SAME EACH TIME..

all_deficiency_tables <-
  list.files(
    here("qcor/qcor_tables"),
    pattern = "\\.rds$",
    full.names = TRUE
  ) |>
  map(readRDS) |>
  list_rbind() |>
  rowid_to_column() |>
  mutate(
    survey_date = str_extract(header, "\\d{2}/\\d{2}/\\d{4}") |> mdy(),
    survey_type = str_extract(header, "(SPECIAL|COMPLAINT|STANDARD)"),
  ) |>
  arrange(ccn, survey_date, rowid) |>
  group_by(ccn, survey_date) |>
  mutate(
    survey_id = paste(
      ccn,
      format(survey_date, "%Y%m%d"),
      row_number(),
      sep = "_"
    )
  ) |>
  ungroup()


glimpse(all_deficiency_tables)

all_surveys <-
  all_deficiency_tables |>
  mutate(across(where(is.character), \(x) str_trim(x, side = "both"))) |>
  summarize(
    deficiencies = sum(str_detect(level, "^None", negate = TRUE)),
    conditions = sum(level == "Condition"),
    .by = c(ccn, header, batchid, survey_date, survey_type)
  )


all_deficiencies <-
  all_deficiency_tables |>
  select(
    ccn,
    level,
    tag_number,
    deficiency_description,
    survey_end_dt = 6,
    last_followup = 7,
    first_followup = 8
  ) |>
  filter(str_trim(level, side = "both") != "None") |>
  left_join(
    readRDS("qcor/qcor_provider_master.RDS") |>
      select(ccn, provider_name, state, ownership_type),
    by = "ccn"
  ) |>
  relocate(c(provider_name:ownership_type, survey_end_dt), .after = ccn)


test_header <- "02/11/2025 STANDARD SURVEY HEALTH SURVEY\t"

writeLines(ccns, "qcor/qcor_tables/parsed_ccns_20260628.txt")

# which ones weren't procesesed?

processed_ccns <- all_deficiency_tables |> distinct(ccn) |> pull()
missing_ccns <- !ccns %in% processed_ccns
ccns[missing_ccns]

############
#[1] "05G010": No surveys
# "15G753" : No surveys
# "29G015" : No surveys
# "33G523" :
# "36G028"
# "36G034"
# "36G041"
# "36G317"
# "36G318"
# "36G319"
# "36G320"
# "36G334"
# "36G335"
# "36G356"
# "36G357"
# "36G358"
# "36G359"
# "36G361"
# "36G364"
# "36G365"
# "36G366"
# "36G367"
# "36G515"
# "37G078"
# "37G082"
# "37G089"
#[27] "37G091"

# these should be added into the list of surveys when we do analysis. I think they'll come from the provider.
############

# There appears to be a little more info than there was in the original  -
# example 05G010 - invol termination
# I think these area all that don't have deficiencies. (ex 37G082)
# there were 4 that were skipped because there was no html in the download - I need to check them, zero bytes. They were
# 4 in a row so I think it was a hiccup.

# save the datasets

saveRDS(all_deficiencies, "qcor/qcor_deficiencies.RDS")
saveRDS(all_deficiency_tables, "qcor/qcor_raw_parse_results.RDS")
saveRDS(all_surveys, "qcor/qcor_surveys.RDS")

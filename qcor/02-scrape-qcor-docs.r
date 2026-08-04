library(tidyverse)
library(httr2)
library(rvest)
library(urltools)
library(here)
library(janitor)
library(glue)


# I'm having a hard time figuring out what is different between the survey reports and the deficiency reports, and if they all include everything.
# You definitely have to give the begin and end years no matter what, but a lot of the rest just doesn't seem to matter.
# the survey_history_popup.jsp seems to be the same as the deficiency popup with the only difference is the heading. Example of Bear Creek:

# https://qcor.cms.gov/survey_history_popup.jsp?rptname=Survey%20Activity%20Report&year_type=CY&jump=1&begin_year=2010&end_year=2026&surveyFocus=1&view_cah=&which=2&type=P&provider=11&report=new_count.jsp&prvdr_intrnl_num=34G006&prov_num=34G006
# https://qcor.cms.gov/survey_history_popup.jsp?rptname=Deficiency%20Count%20Report&year_type=CY&year_value=2010&jump=1&begin_year=2010&end_year=2026&surveyFocus=1&view_cah=&which=2&type=P&provider=11&report=report41.jsp&prvdr_intrnl_num=34G006&prov_num=34G006
# the two differences in the url are the report name and the report file. But the rest of the parameters are the same, and they both come up with the same data.

##########   ALL PROVIDER LISTING ##########################################################################
# got the full provider listing by going to "Active Provider and Supplier Counts" in the IDF portion of qcor.
# begin year = 2010, end year = 2026
# Run the report
# save the csv using the "Download csv" button underneath the table.
# did this on 6/11/26
# It includes all of the providers that were active at any point in that period.

# The individual survey results / deficiency reports for each facility isn't dependent on the year_value, even though it's in some of the urls. I'm leaving it out of this.

providers <- read_csv(
    "qcor/actprov_listing1781213863420.csv",
    skip = 6,
    col_names = TRUE,
    col_types = c(
        .default = "character",
        `Number of Certified Beds` = "integer"
    )
) |>
    clean_names() |>
    mutate(across(c(original_participation_date, termination_date), \(x) {
        mdy(x)
    }))


################ EXAMPLE URLS FOR DEFICIENCY / SURVEY REPORTS ####################
#   ----   CREATE THE PAYLOAD FOR THE REQUEST                                ----#

# example deficiency report: https://qcor.cms.gov/survey_history_popup.jsp?rptname=Deficiency%20Count%20Report&year_type=CY&year_value=2024&jump=1&begin_year=2010&end_year=2026&surveyFocus=1&view_cah=&which=2&type=P&provider=11&report=report41.jsp&prvdr_intrnl_num=13G042&prov_num=13G042
# need to change the keys prvdr_intrnl_num and prov_num which are the same things.
# don't have to change the years -- just comes up as no  surveys when it is decommissioned. Example:
# https://qcor.cms.gov/survey_history_popup.jsp?rptname=Deficiency%20Count%20Report&year_type=CY&year_value=2026&jump=1&begin_year=2010&end_year=2026&surveyFocus=1&view_cah=&which=2&type=P&provider=11&report=report41.jsp&prvdr_intrnl_num=55G721&prov_num=55G721
# there are two ways to get to the survey history, and they both end up in the same place. The only difference seems to be the heading at the top.

example_url <- "https://qcor.cms.gov/survey_history_popup.jsp?rptname=Deficiency%20Count%20Report&year_type=CY&jump=1&begin_year=2010&end_year=2026&surveyFocus=1&view_cah=&which=2&type=P&provider=11&report=report41.jsp&prvdr_intrnl_num=55G721&prov_num=55G721"

payload <- httr::parse_url(example_url) |>
    pluck("query") |>
    as.list()

payload$prvdr_intrnl_num <- NA_character_
payload$prov_num <- NA_character_


#################     CONSTANTS ################################

# now just have to change the id's for each iteration to keep them.
# this does not have ownership name. Just the type.

ccn_list <- providers$ccn
save_folder <- here("qcor/qcordocs")
root_url <- "https://qcor.cms.gov/survey_history_popup.jsp"
results_list <- list()


################ LOOP TO DOWNLOAD AND SAVE ALL DEFICIENCY REPORTS / CREATE DATA FRAME OF RESULTS ##################

for (i in seq_along(ccn_list)) {
    # for testing
    if (i <= 5) {
        next()
    }

    # make a copy of the payload, and
    # capture the ccn from the list.
    tmp_payload <- payload
    this_ccn <- ccn_list[[i]]

    # change the two identical id numbers in the payload
    tmp_payload$prvdr_intrnl_num <- this_ccn
    tmp_payload$prov_num <- this_ccn

    # convert the payload list to a get request
    this_req <- request(root_url) |>
        req_url_query(!!!tmp_payload)

    results_list[[i]] <- tryCatch(
        {
            resp <- req_perform(
                this_req,
                path = glue("{save_folder}/{this_ccn}.html")
            )

            print(path)
            print(this_req$url)

            tibble(
                provider = this_ccn,
                url = this_req$url,
                status_code = resp$status_code,
                error_message = NA_character_
            )
        },
        error = function(e) {
            tibble(
                provider = this_ccn,
                url = this_req$url,
                status_code = NA_integer_,
                error_message = e$message
            )
        } # end of error
    ) # end of tryCatch

    # pause a random amount
    wait_time <- runif(1, .05, 1.5)
    Sys.sleep(wait_time)
} # end of for


############## PUT TOGETHER THE DATA FRAME OF RESULTS ##################

scrape_results <- list_rbind(results_list)
saveRDS(scrape_results, here("deficiency_report_scrape_results.rds"))

## THERE MAY BE A HANDFUL OF MISSING PROVIDERS THAT CAME / WENT BETWEEN 2010 and 2026.
## It would only be those first licensed after that time.

## I can check against the provider listing I saved later on.

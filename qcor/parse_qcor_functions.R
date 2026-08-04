library(tidyverse)
library(janitor)
library(tools)
library(here)
library(glue)
library(rvest)


############## FIX THE HTML THAT COMES OUT OF THE QCOR SURVEY RESULTS ###############
# @ ccn = the ccn of the facility, which is also the name of the file.
# assumes the doc is held in a directory structure from the project called "qcor/qcordocs"
# here() always starts at the project (folder) level.
#######################################################################################

clean_qcor_html <- function(ccn) {
  html_path <- glue("{here('qcor/qcordocs')}/{ccn}.html")

  find_comments_except_anchor_pattern <- regex(
    "(?s)              # flag to indicate single-line or dotall mode
     <!--              # beginning of any comment
    (?!\\s*<a\\s+name) # negative lookahead for anchor comments. This means it will match any comment that ISN'T like this.
    .*?-->             # match the rest of the comment.
    ",
    comments = TRUE #this version ignores all whitespace, so I need the \\s in the <a\\sname) part.
  )

  add_ending_table_tag <- regex(
    "(<!--<a\\s+name=\"      # use single backslash to escape for R, not for the regex . Need \\s because we're in comment mode. 
    \\d{4}                # 4 digits
    \"></a>-->)", # match the end.  Don't forget to put it all in parens so you can use it in the replacement.
    comments = TRUE
  )

  remove_first_end_table <- regex(
    "</table>\\s*(<!--<a name=\"2026)"
  )

  html_fixed <- read_file(html_path) |>
    str_replace_all(find_comments_except_anchor_pattern, "") |>
    str_replace_all(add_ending_table_tag, "</table>\n\\1") |> # this replaces the found pattern with </table> + \n + found pattern
    str_replace(remove_first_end_table, "\\1") # by not using replace_all, it only does the first one

  return(html_fixed)
}

############# EXTRACT LIST OF YEARS WITH SURVEYS ###########################
# parse the html content into a list of tables
# @ good_html = the fixed HTML, which has the close table tags.
# the first table that has the info for the facility is has a bgcolor and

get_annual_tables <- function(good_html) {
  annual_tables <- read_html(good_html) |>
    html_element(".margins") |>
    html_elements(
      xpath = "./table[@border='0' and @width='100%' and not(@bgcolor)]"
    )
  # changed from     html_elements(xpath = "./table[@border='0' and @width='100%' and not(@bgcolor='#EEEEEE')]")

  # remove any empty years
  annual_tables <- annual_tables |>
    discard(\(x) str_detect(html_text2(x), "No Surveys Found"))

  # Check if "No Surveys Found" for every year. Have to handle items with no surveys.
  if (is.null(annual_tables) || length(annual_tables) == 0) {
    return(NULL)
  }

  annual_tables
}


################## PARSE THE SURVEYS WITHIN A YEAR ##########################
# Returns a list of lists. Each survey is the top level list, the
# results of the survey have 3 items each: The type/date, the deficiecies table as a data frame, and the dates of the followups (might be NA)
# Example of one item in the list:
#
######

parse_surveys <- function(annual_table, ccn) {
  yearly_rows <- html_elements(annual_table, "tr")

  survey_headers <-
    yearly_rows |>
    map_lgl(\(row) {
      row |>
        html_text2() |>
        str_detect(
          "(?s)\\d{2}/\\d{2}/\\d{4}\\s+(STANDARD|COMPLAINT|SPECIAL)\\s+SURVEY"
        )
    })

  start_indexes <- which(survey_headers)

  # this should create a list of lists - each survey is a list item, each list item has 3 items within it.

  map(start_indexes, \(start) {
    header_row <- yearly_rows[start] |> html_text2()

    deficiency_table <- yearly_rows[start] |>
      html_element(
        xpath = './following-sibling::tr//table[@bgcolor="#DDDDDD"]'
      ) |>
      html_table(header = TRUE) |>
      pluck(1) |>
      clean_names()

    raw_followup_dates <- yearly_rows[start] |>
      html_element(
        xpath = './following-sibling::tr//table[@bgcolor="#EEEEEE"]'
      ) |>
      # only picks it up if there is any.
      html_elements(xpath = './/tr[@bgcolor="#CCCCCC"]') |>
      html_text2() |>
      str_extract("\\d{2}/\\d{2}/\\d{4}")

    followup_dates <-
      if (length(raw_followup_dates) == 0) {
        c(NA_character_, NA_character_)
      } else if (length(raw_followup_dates) == 1) {
        c(raw_followup_dates, NA_character_)
      } else {
        raw_followup_dates[1:2]
      }

    list(ccn, header_row, deficiency_table, followup_dates)
  })
}

#### TESTS - COMMENT thESE OUT WHEN IT'S TIME TO USE THIS
# test_ccn <- "34G006"
# clean_test <- clean_qcor_html(test_ccn)  # this seemed to work
# survey_years <- get_annual_tables(clean_test)
# # survey_years - YAY 17 items!
#one_year <- parse_surveys(survey_years[[2]])
#one_year[[3]]

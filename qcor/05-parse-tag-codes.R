library(tidyverse)
library(pdftools)
library(jsonlite)

# Read the PDF
pdf_text <- pdf_text("qcor/qcor-codes.pdf")

# Combine all pages into one text block
full_text <- paste(pdf_text, collapse = "\n")

# Split into lines for easier processing
lines <- str_split(full_text, "\n")[[1]]

# Initialize storage
records <- list()
current_record <- NULL
in_guidance <- FALSE
guidance_buffer <- character()

for (i in seq_along(lines)) {
  line <- str_trim(lines[i])

  # Check if this is a W-code heading (starts with W followed by 3 digits)
  if (str_detect(line, "^W\\d{3}\\s*$")) {
    # Save previous record if it exists
    if (!is.null(current_record)) {
      if (length(guidance_buffer) > 0) {
        current_record$guidance <- str_trim(paste(
          guidance_buffer,
          collapse = " "
        ))
      }
      records[[length(records) + 1]] <- current_record
    }

    # Start new record
    current_record <- list(
      w_code = line,
      us_code = NA_character_,
      description = NA_character_,
      guidance = NA_character_
    )
    in_guidance <- FALSE
    guidance_buffer <- character()
    next
  }

  # If we have a current record, look for US Code (section symbol followed by number)
  if (!is.null(current_record) && is.na(current_record$us_code)) {
    # Look for the section symbol (§) followed by code number
    us_code_match <- str_extract(line, "§\\d+\\.\\d+[^\\s]*")

    if (!is.na(us_code_match)) {
      current_record$us_code <- us_code_match
      # The description is everything after the US code on this line and subsequent lines
      # until we hit "Guidance"
      description_start <- str_remove(line, paste0(".*", us_code_match, "\\s*"))
      current_record$description <- str_trim(description_start)
      next
    }
  }

  # Continue building description until we hit Guidance
  if (
    !is.null(current_record) && !is.na(current_record$us_code) && !in_guidance
  ) {
    if (str_detect(line, "^Guidance\\s+§")) {
      in_guidance <- TRUE
      next
    } else if (
      nchar(line) > 0 &&
        !str_detect(line, "^W\\d{3}") &&
        !str_detect(line, "^\\(Rev\\.")
    ) {
      # Add to description
      current_record$description <- paste(
        current_record$description,
        line,
        sep = " "
      )
    }
  }

  # Collect guidance text
  if (in_guidance && nchar(line) > 0) {
    # Skip the "Guidance §..." header line itself
    if (!str_detect(line, "^Guidance\\s+§")) {
      guidance_buffer <- c(guidance_buffer, line)
    }
  }
}

# Don't forget the last record
if (!is.null(current_record)) {
  if (length(guidance_buffer) > 0) {
    current_record$guidance <- str_trim(paste(guidance_buffer, collapse = " "))
  }
  records[[length(records) + 1]] <- current_record
}

# Convert to data frame for easier manipulation
df <- bind_rows(records) |>
  mutate(across(everything(), ~ str_squish(.))) |>
  filter(!is.na(us_code))

# Save as JSON
write_json(df, "qcor_codes.json", pretty = TRUE)


# Show summary
cat("Extracted", nrow(df), "W-codes\n\n")
cat("Sample of extracted data:\n")
print(head(df, 3))

# Show a full example
cat("\n\nFull example of one record:\n")
cat("W-Code:", df$w_code[100], "\n")
cat("US Code:", df$us_code[100], "\n")
cat("Description:", str_trunc(df$description[100], 100), "\n")
cat("Guidance:", str_trunc(df$guidance[100], 100), "\n")


## Get the categories from the original deficiencies that were actually used.

deficiencies_used <-
  readRDS("qcor/qcor_deficiencies.rds") |>
  count(level, tag_number, deficiency_description)

deficiencies_used |>
  janitor::get_dupes(tag_number)
# none.

parsed_qcor_codes <-
  df |>
  mutate(tag_number = glue::glue("W0{str_sub(w_code, 2,4)}"), .after = w_code)

library(tidyverse)
matched_qcor_codes <-
  deficiencies_used |>
  full_join(parsed_qcor_codes, join_by(tag_number))

saveRDS(matched_qcor_codes, "qcor/data/qcor_deficiency_codes.RDS")

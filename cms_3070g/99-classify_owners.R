library(dplyr)
library(stringr)

owners <- read.csv("owners.csv", stringsAsFactors = FALSE, na.strings = character(0))

classify_ownership <- function(x) {
  u <- toupper(trimws(x))
  u <- gsub("\\.", "", u)     # drop periods so "S. CORP" etc. match "S CORP" style patterns
  u <- gsub("\\s+", " ", u)   # collapse repeated whitespace

  # Values that don't actually describe an ownership structure
  # (blanks, single letters, names, facility/program codes entered by mistake)
  unknown_exact <- c("NA", "N", "V", "TYLER REX", "FUNDAMENTAL", "NOT GIVEN",
                      "NOT FILLED OUT ON RE", "CERTIFIED BY STATE", "COMMUNITY",
                      "ICF/MR", "MR/IID", "MH-ID", "PRIVATE")

  out <- case_when(
    u %in% unknown_exact ~ "Unknown",

    # ---- Other government & quasi-government ----
    # (checked BEFORE the generic non-profit/for-profit rules, since terms like
    # "QUASI-GOV NONPROFIT" or "NON PROFIT DSN BOARD" are structurally
    # government/quasi-government entities first)
    str_detect(u, "QUASI|QAISI|QUISA|QUADI|QUASU|GIVERMENTAL") ~ "Other government and quasi-government",
    str_detect(u, "\\bMHMR\\b|\\bMHR\\b|\\bLIDDA\\b|\\bMRA\\b|\\bCSB\\b|WTCSB|DSNB|DSN BOARD|\\bDDSN\\b|SCDDSN|SCDDN|SCDDW|BURTON CENTER") ~ "Other government and quasi-government",
    str_detect(u, "CONTRACT (MANAGEMENT|MGMT|MGT|MNGMNT|MANAG)") ~ "Other government and quasi-government",
    str_detect(u, "\\bCOUNTY\\b|\\bCITY\\b|\\bTOWN\\b") ~ "Other government and quasi-government",
    str_detect(u, "GOVERNMENT|GOVERNMENTA|GOVERMENT|GOVENMENT|\\bGOVT\\b") ~ "Other government and quasi-government",
    str_detect(u, "POLITICAL SUBDIVISIO|POL SUB") ~ "Other government and quasi-government",
    str_detect(u, "LOCAL PUBLIC AGENCY|LOCAL AUTHORITY|AGENCY OF LOCAL|STATE AGENCY|LOCAL GOVERNMENT") ~ "Other government and quasi-government",
    str_detect(u, "\\bCOMM\\b.*BOARD|COMMUNITY (SERV|SRV|SVCS|SVCE|SVC|CENTER|BOARD)|COMMUNITY MH|COMMUNITY LIDDA") ~ "Other government and quasi-government",

    # ---- State-owned ----
    str_detect(u, "^STATE$|STATE OF|^STATE ") ~ "State-owned",

    # ---- Non-profit ----
    str_detect(u, "NON[- ]?PROFIT|NOT[- ]?FOR[- ]?PROFIT|NON PROF\\b|CHARITABLE|NON-PROF") ~ "Non-profit",

    # ---- For-profit ----
    str_detect(u, "PROPRIETARY|PROPRIETORSHIP|PUBLICLY TRADED|FOR PROFIT|\\bPROFIT\\b|CORP|LLC|\\bINC\\b|INCORPORAT|PARTNERSHIP|PARNERSHIP|LIMITED LIAB|LIMITED LIB|LIABILITY|\\bLLB\\b|^COR$") ~ "For-profit",

    TRUE ~ NA_character_
  )

  # Fuzzy fallback: catches badly misspelled "CORPORATION" variants
  # (e.g. "COPORATION", "CORORATION", "PRIVATE COORPORATION") that slipped
  # past the exact patterns above
  idx <- which(is.na(out))
  out[idx[agrepl("CORPORATION", u[idx], max.distance = 0.3)]] <- "For-profit"

  out[is.na(out)] <- "Unknown"
  out
}

owners <- owners %>%
  mutate(category = classify_ownership(type_of_ownership))

# sanity checks
stopifnot(sum(owners$n) == sum(read.csv("owners.csv")$n))
owners %>% count(category, wt = n, name = "total_n") %>% print()

write.csv(owners, "owners_categorized.csv", row.names = FALSE)

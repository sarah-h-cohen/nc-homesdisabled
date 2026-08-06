library(tidyverse)
library(readr)

# NC Death Certificate 2014-2019: Fixed-Width Import Specification
# Source: 2014-2019 DEATH DETAIL DESCRIPTION_NS.xls
# Total record length: 1450 bytes

nc_death_cols <- fwf_positions(
  start = c(
    1, 5, 13, 26, 27, 77, 78, 128, 138, 139,
    189, 200, 201, 205, 209, 211, 213, 215, 217, 222,
    225, 227, 229, 230, 232, 233, 236, 237, 239, 241,
    245, 247, 248, 249, 250, 251, 271, 272, 273, 274,
    275, 276, 277, 278, 279, 280, 281, 282, 283, 284,
    285, 286, 316, 346, 376, 406, 436, 466, 496, 701,
    711, 713, 753, 758, 760, 770, 775, 778, 828, 833,
    834, 884, 934, 935, 985, 986, 1036, 1037, 1038, 1042,
    1044, 1055, 1059, 1061, 1063, 1113, 1143, 1173, 1187, 1211,
    1261, 1290, 1300, 1301, 1302, 1307, 1312, 1317, 1322, 1327,
    1332, 1337, 1342, 1347, 1352, 1357, 1362, 1367, 1372, 1377,
    1382, 1387, 1392, 1397, 1402, 1407, 1412, 1413, 1414, 1415,
    1416
  ),
  end = c(
    4, 6, 13, 26, 76, 77, 127, 137, 138, 188,
    189, 200, 203, 208, 210, 212, 214, 216, 221, 224,
    226, 228, 229, 230, 232, 235, 236, 238, 240, 244,
    245, 247, 248, 249, 250, 270, 271, 272, 273, 274,
    275, 276, 277, 278, 279, 280, 281, 282, 283, 284,
    285, 315, 345, 375, 405, 435, 465, 495, 525, 710,
    712, 752, 757, 759, 769, 774, 777, 827, 832, 833,
    883, 933, 934, 984, 985, 1035, 1036, 1037, 1041, 1043,
    1045, 1058, 1060, 1062, 1112, 1142, 1172, 1174, 1210, 1260,
    1289, 1290, 1300, 1301, 1305, 1310, 1315, 1320, 1325, 1330,
    1335, 1340, 1345, 1350, 1355, 1360, 1365, 1370, 1375, 1380,
    1385, 1390, 1395, 1400, 1405, 1410, 1412, 1413, 1414, 1415,
    1416
  ),
  col_names = c(
    "DOD_YR", "DSTATE", "VOID", "MFILED", "GNAME", "MNAME", "LNAME", "SUFF", "ALIAS", "FLNAME",
    "SEX", "AGETYPE", "AGE", "DOB_YR", "DOB_MO", "DOB_DY", "BPLACE_CNT", "BPLACE_ST", "CITYC", "COUNTYC",
    "STATEC", "COUNTRYC", "LIMITS", "MARITAL", "DPLACE", "COD", "DISP", "DOD_MO", "DOD_DY", "TOD",
    "DEDUC", "DETHNIC1", "DETHNIC2", "DETHNIC3", "DETHNIC4", "DETHNIC5", "RACE1", "RACE2", "RACE3", "RACE4",
    "RACE5", "RACE6", "RACE7", "RACE8", "RACE9", "RACE10", "RACE11", "RACE12", "RACE13", "RACE14",
    "RACE15", "RACE16", "RACE17", "RACE18", "RACE19", "RACE20", "RACE21", "RACE22", "RACE23", "ADDRNUM",
    "ADDRPRED", "ADDRNAME", "ADDRSUFF", "ADDRPOST", "ADDRAPT", "ZIPCODE", "BPLACE_CORES", "FACNAME", "FACCITY", "VETERAN",
    "MAIDENAME", "DADFNAME", "DADMNAME", "MOMFNAME", "MOMMNAME", "MOMLNAME", "MECASE", "MEDECLINE", "REG_YR", "REG_MO",
    "REG_DAY", "LOCALREG_YR", "LOCALREG_MO", "LOCALREG_DAY", "FUNRL_NAME", "FUNRL_ADD", "FUNRL_CITY", "FUNRL_ST", "DPLACELIT", "MNAMEFULL",
    "CITYRESTEXT", "CERTCODE", "MANNER", "PLACE", "MANUAL", "ACMECOD", "COD1", "COD2", "COD3", "COD4",
    "COD5", "COD6", "COD7", "COD8", "COD9", "COD10", "COD11", "COD12", "COD13", "COD14",
    "COD15", "COD16", "COD17", "COD18", "COD19", "COD20", "AUTOPSY", "FINDINGS", "TOBACCO", "PREG",
    "WORKINJ"
  )
)

getwd()

death_list <- map ( list("YR2014", "YR2015", "YR2017", "YR2018", "YR2019") , function(x) {
    this_file <- paste0("death-certificates/data/all_death_files/FINAL DEATHS.", x) 

    deaths <- read_fwf(
        file = paste0("death-certificates/data/all_death_files/FINAL DEATHS.", x),
        col_positions = nc_death_cols,
        col_types = cols(.default = col_character()),
        na = c("", " ", "Blank")
    )
    
    return (deaths)
}

)

deaths_2014_2019 <- list_rbind( death_list) 


deaths <- read_fwf(
  file = "death-certificates/data/all_death_files/FINAL DEATHS.YR2019",
  col_positions = nc_death_cols,
  col_types = cols(.default = col_character()),
  na = c("", " ", "Blank")
)


# ── Coded value lookup vectors ──────────────────────────────────────────────
# Structure: names are the raw codes, values are the human-readable labels.
# Usage: deaths |> mutate(SEX_lbl = sex_codes[SEX])

void_codes <- c(
  "0" = "default; valid record",
  "1" = "VOID record"
)

mfiled_codes <- c(
  "0" = "Electronic Mode",
  "1" = "Paper Mode",
  "2" = "Mixed Mode"
)

alias_codes <- c(
  "0" = "Original Record",
  "1" = "Alias Record"
)

sex_codes <- c(
  "M" = "Male",
  "F" = "Female",
  "U" = "Unknown"
)

agetype_codes <- c(
  "1" = "Years",
  "2" = "Months",
  "4" = "Days",
  "5" = "Hours",
  "6" = "Minutes",
  "9" = "Unknown (Not Classifiable)"
)

limits_codes <- c(
  "Y" = "Yes",
  "N" = "No",
  "U" = "Unknown"
)

marital_codes <- c(
  "M" = "Married",
  "A" = "Married but Separated",
  "W" = "Widowed",
  "D" = "Divorced",
  "S" = "Never Married",
  "U" = "Not Classifiable"
)

dplace_codes <- c(
  "1" = "Inpatient",
  "2" = "Emergency Room/Outpatient",
  "3" = "Dead on Arrival",
  "4" = "Decedent's Home",
  "5" = "Hospice Facility",
  "6" = "Nursing Home/Long Term Care Facility",
  "7" = "Other",
  "9" = "Unknown"
)

disp_codes <- c(
  "B" = "Burial",
  "C" = "Cremation",
  "D" = "Donation",
  "E" = "Entombment",
  "R" = "Removal from state",
  "O" = "Other",
  "U" = "Unknown"
)

deduc_codes <- c(
  "1" = "8th grade or less",
  "2" = "9th through 12th grade; no diploma",
  "3" = "High School Graduate or GED Completed",
  "4" = "Some college credit, but no degree",
  "5" = "Associate Degree",
  "6" = "Bachelor's Degree",
  "7" = "Master's Degree",
  "8" = "Doctorate Degree or Professional Degree",
  "9" = "Unknown"
)

dethnic1_codes <- c(
  "N" = "No, Not Mexican",
  "H" = "Yes, Mexican",
  "U" = "Unknown"
)

dethnic2_codes <- c(
  "N" = "No, Not Puerto Rican",
  "H" = "Yes, Puerto Rican",
  "U" = "Unknown"
)

dethnic3_codes <- c(
  "N" = "No, Not Cuban",
  "H" = "Yes, Cuban",
  "U" = "Unknown"
)

dethnic4_codes <- c(
  "N" = "No, Not other Hispanic",
  "H" = "Yes, other Hispanic",
  "U" = "Unknown"
)

veteran_codes <- c(
  "Y" = "Yes",
  "N" = "No"
)

certcode_codes <- c(
  "1" = "M.D., D.O., RTL",
  "2" = "ME",
  "3" = "P.A.",
  "4" = "NP or FNP"
)

manner_codes <- c(
  "N" = "Natural",
  "A" = "Accident",
  "S" = "Suicide",
  "H" = "Homicide",
  "P" = "Pending",
  "C" = "Could Not Be Determined",
  "Blank" = "Unknown"
)

place_codes <- c(
  "0" = "Home",
  "1" = "Residential Institution",
  "2" = "School, Other Institutions, Admin. Area",
  "3" = "Sports and Recreation Area",
  "4" = "Street/Highway",
  "5" = "Trade and Service Area",
  "6" = "Industrial and Construction Area",
  "7" = "Farm",
  "8" = "Other Specified Place",
  "9" = "Unspecified Place",
  "Blank" = "Unknown"
)

autopsy_codes <- c(
  "Y" = "Yes",
  "N" = "No",
  "U" = "Unknown"
)

findings_codes <- c(
  "Y" = "Yes",
  "N" = "No",
  "U" = "Unknown"
)

tobacco_codes <- c(
  "Y" = "Yes",
  "N" = "No",
  "P" = "Probably",
  "U" = "Unknown",
  "C" = "Not on Certificate"
)

preg_codes <- c(
  "1" = "Not pregnant w/in past year",
  "2" = "Pregnant at time of death",
  "3" = "Not pregnant, but pregnant within 42 days of death",
  "4" = "Not pregnant, but pregnant 43 days to 1 year before death",
  "9" = "Unknown if pregnant within past year",
  "7" = "Not on Certificate"
)

workinj_codes <- c(
  "Y" = "Yes",
  "N" = "No",
  "U" = "Unknown"
)

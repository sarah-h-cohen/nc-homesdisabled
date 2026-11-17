### Read the csvs from NBER then save as a duckdb database. Query it to get the NC organizations (not individuals) and save that to the ncrecords folder ###
library(tidyverse)
library(duckdb)
getwd()
# setwd("medicaid-provider")


con <- dbConnect(duckdb(), "nber-npi/npi_nber_data.duckdb", read_only = FALSE)
dbListTables(con)

### NOTE: USING NBER because it simplified the naming conventions, split it into relational tables and saved the results. They also have historical versions ###
## Downloaded from [NBER](https://www.nber.org/research/data/national-plan-and-provider-enumeration-system-nppesnpi) , used the August 2026 version. They have annual historical 
## versions if we want them. 

### Create a table in Duckdb database for the master record.
### Consider deleting the duckdb database and starting over if we have to redo to release the space

### Test 1: Read to duckdb database and query it: 
## Rather than read this into an R data frame, directly convert it into a duckdb database using read_csv() with options
### (Can use read_csv_auto() if everything is read ok, but in this case it reads the npi as double and I don't want that.
### I'm perfectly happy saving the whole thing in varchar and can make variable type adjustments after filtering. 


# read all datasets into the database, then choose any organization with the proper codes. I'm not sure of the codes - 
# in the NC license data, they use several different ones. I'll try first looking for any name like RHA, then look at the codes
# they use  

## This is WILDLY faster than any of the R-based solutions. Seconds rather than minutes with data.table and many minutes normally. 


# starts from project level, regardless of where the R file is stored.
# 

# # This one read it into an R database. I want it to go directly into duckdb. 

# orgs <- tbl(con, "read_csv_auto('nber-npi/core_202608.csv')" ) |> 
#   filter ( entity == "Organization") |> 
#   select (
#      npi, entity, replacement_npi, ein, porgname,
#      pmailline1, pmailcityname, pmailstatename, pmailzip,
#      plocline1, plocline2, ploccityname, plocstatename, ploczip,
#      penumdate, lastupdate, npideactreason, npideactdate, npireactdate,
#      aolname, aofname, aomname,
#      orgsubpart, parent_org_lbn, parent_org_tin,
#      ptaxgroup1, ptaxgroup2, certificationdate
#    ) |> 
#   collect()

# the only error under this one was that npi was read in as double. I'm not sure that's always right, so I'll try it this way: 


dbExecute(con, "
  CREATE TABLE npi_master AS 
  SELECT npi, entity, replacement_npi, ein, porgname,
     pmailline1, pmailcityname, pmailstatename, pmailzip,
     plocline1, plocline2, ploccityname, plocstatename, ploczip,
     penumdate, lastupdate, npideactreason, npideactdate, npireactdate,
     aolname, aofname, aomname,
     orgsubpart, parent_org_lbn, parent_org_tin,
     ptaxgroup1, ptaxgroup2, certificationdate
     FROM read_csv(
    'nber-npi/core_202608.csv',
    header = true,
    all_varchar = true
  )
")




# just did this the first time to make sure it was reading correctly
# tmp <- dbConnect(duckdb())

dbExecute ( con, " 
    CREATE TABLE license AS
    SELECT * FROM read_csv(
    'nber-npi/plicnum_202608.csv',
    header = true,
    all_varchar = true
  )
")

license <- dbGetQuery(con, "SELECT  * FROM license WHERE plicstate == 'NC'")
# Some of the facilities have their license number, which begins with MHL . Some are formatted with separators, others not. 


dbExecute ( con, " 
    CREATE TABLE identifiers AS
    SELECT * FROM read_csv(
    'nber-npi/othpid_202608.csv',
    header = true,
    all_varchar = true
  )

")

# there aren't any of ours - they must use a different one. 
ids <- dbGetQuery(con, "SELECT * FROM identifiers WHERE othpid ILIKE '34G%'")
# the medicaid provider number isn't the same as the ccn. But they may be like the ones that are used in the money files. 


dbExecute ( con, " 
    CREATE TABLE taxonomy AS
    SELECT * FROM read_csv(
    'nber-npi/ptaxcode_202608.csv',
    header = true,
    all_varchar = true
  )
")

icfs <- dbGetQuery(con, "SELECT * FROM taxonomy WHERE ptaxcode IN ('320900000X',  '315P00000X', '320600000X')")
# this includes way more than just icfs, and there are 31,700 of them. If I just use icfs: 
icfs |>  filter ( str_starts ( ptaxcode, "315P"))

# all set - can use this in the money part. 
# dbDisconnect(tmp, shutdown=TRUE)
dbDisconnect(con, shutdown = TRUE)


library(tidyverse)

# Get a list of medians that excludes the current values for direct care staff.
# Ignore anything wildly unrealistic: defaults to direct care staff of less than .8 FTE, or more than 1500

get_dc_medians <- function (x, min_value = 0.8 , max_value = 1500)  {
      #create a list of NA values of the list of x
      result <- rep(NA_real_, length (x) )

      
      for (i in seq_along (x) ) {
          #remove this value
          all_others <- x[-i]
          all_others <- all_others[!is.na(all_others)]
          all_others <- all_others[between(all_others, min_value, max_value) ]
          
          if (length ( all_others) > 0 ) {
            result[i] <- median ( all_others) 
          }

      }
      result
}

# example:
#  get_neighbors(c(.5, 1, 2, 5, 253, 7))

# Create a bitmap that can be converted to numeral to check what we care about. This lets us check sequentially 
# because they're in a specific order. 

# @ dc = direct care staff
# @ tot = total staff
# @ dc_res_ratio = direct care ratio using residents
# @ tot_res_ratio = total staff ratio using residents
# @ dc_bed_ratio = total direct care to licensed beds. 

## The idea is to start with one that has NO FAILURES (not ones that are ALL OK), 
## so start with 000000
## Anything that has two 1s at the beginning has failed both too-few-staff .
## Anything with two 1s in the middle failed both too-small-ratios
## Anything with two 1s at the end failed too-big. 

## These can be turned into 0's, but it's just as easy to evaluate them as strings.
## (They could be TTFFTT instead of 1s or 0s, which would make it fine as well. )
 
create_staff_bitmap <- function ( dc, tot, dc_res_ratio, tot_res_ratio, dc_bed_ratio ) {

  # begin with NO FAILURES
  bitmap <- rep(0, 6)

  # staff count: resolves to 48-63
  if ( dc < 2 )  bitmap[1] <-  "1"
  if ( tot < 3 ) bitmap[2] <-  "1"
  # staff ratio too small
  # resolves to 
  if ( dc_res_ratio  < .3 )  bitmap[3] <- "1"
  if ( tot_res_ratio < .4 )  bitmap[4] <- "1" 
  # Staff ratio too big
  if ( dc_res_ratio > 3.5 )  bitmap[5]  <-  "1"
  if ( dc_bed_ratio > 3.5 )  bitmap[6]  <- "1"

  str_flatten (bitmap, collapse="") 
  

}

 
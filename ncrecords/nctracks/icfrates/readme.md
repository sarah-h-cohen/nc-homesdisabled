# ICF Rates

These are the published rates that seem to change regularly through the year for ICFs on North Carolina’s website. 

Source: <https://ncdhhs.servicenowservices.com/fee_schedules>
There is one section for current, and below that for archived. 

Fee prior to 2022 is here: 
<https://medicaid.ncdhhs.gov/providers/fee-schedules/intermediate-care-facility-individuals-intellectual-disabilities-icf-iid-fee-schedules-archive>


QUESTION: 

The rates specifically say they are only for the FFS people. But I believe there is a requirement elsewhere that says that managed care must pay at least that much. (It’s not specifically noted here.) We need to figure that out. 

NPIs: The NPI list seems to change regularly, and we need to match up the new NPI with the old one. 

One approach to this is to take the NPI list from Medicare for each year and make a crosswalk. That shouldn’t be too hard. 


## Each file



### 2025-08-04 
All effective dates are 7/1/25, all end dates are 9999. 
Begins row 21, 
Colnames: api, provider, name, accommodation_code, rate, eff_date, end_date, notes1, notes2, notes3, notes4

All notes columns are empty


## 2025-09-30

Rate reduction sheet similar to 11/12. Notes4 is rate reduction, the notes2 and notes3 are always entry 

Npi, provider, name, rate, eff_date, end_date, org_name, notes2, notes3, notes4

### 2025-11-12

The historical ones are there if they were terminated. Otherwise, they are all effective in 2025, and end date 9999. This reflects an across-the-board rate reduction of 8%. (This may be getting rid of the extra that was put in for covid, or for labor shortages. )

Data begins row 21, colnames are api, provider, name, rate, eff_date, end_date, org_name, notes2, notes3, notes4

Notes 2 and 3 are always empty, notes 4 are about the rate reduction


### 2025-12-23
 On this one, all of the end dates are forever and all of the effective dates are 10/1/25.  This still has the “old” NPIs for the facilities like Bear Creek (1043379340)

Colnames: api, provider, name, rate, eff_date, end_date, org_name, notes_2, notes_3, unnamed extra column . Last three columns are empty.

Begin on row 21

(Have old names, so Bear creek shows up as Howell’s Lagrange)


### 2026-03-01

This has multiple rows for some facilities, with rates with real begin and end dates. Some do not have provider numbers but these provider numbers aren’t what we’re used to. This does appear to have rate history for each facility? Unsure. 

Begins row 21, 
colnames:  api, provider, name, rate, eff_date, end_date, org_name, new_terminated , notes_2. 

### 2026-06-22

All of these have an end date of 9999. They have different start dates, ranging from  7/1/25 to 4/1/26. They have “New NPI added” for most of RHA, and those NPI’s are not related to specific facilities on this sheet. (On the NPI lookup , they have the site address, so we could potentially look them up)

This one still has Bear Creek. 

This seems to mean that we have to have to both sets of NPI’s in order to look up the value of the contracts. 


Data begins row 21
Columns api, provider, name, rate, eff_date, end_date, org_name, new_terminated, notes2, notes3 

Notes2 and notes3 are empty.


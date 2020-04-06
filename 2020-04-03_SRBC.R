getwd() # "C:/R/dataRequests"



# load packages -----------------------------------------------------------


library(DBI)
library(odbc)
# library(dbplyr)

library(readxl)
library(writexl)
library(tidyverse)
library(tidylog)




# import vector of stations -----------------------------------------------

############# If stations can be imported from excel/csv, do that here and use pull() to create vector
# stations <- read_excel('2020-04-03_SRBC.xlsx', sheet = 'mystations') %>% 
#   pull(STR_STATION_ID) 

######## If stations are to be specified manually do this
stations <- c('20150413-1130-gkenderes', '20161116-1340-mbrickner', '20161116-1450-mbrickner')
sql_stations <- paste("'", as.character(stations), "'", collapse=", ", sep="")





# import slims data ---------------------------------------------------------

# make connection with SLIMS via oracle driver and ODBC package
chan_slims <- dbConnect(odbc::odbc(), "EPGDC", PWD="sqry0121")

dbListTables(chan_slims, schema = "SLIMS_DBA") # wow




# stations ----------------------------------------------------------------


# use sprintf to create sql query with collect syntax (sql_stations from above)
sta_sql <- sprintf("SELECT * FROM SLIMS_DBA.AS_STATIONS_WMAS_V WHERE STR_STATION_ID IN (%s)", sql_stations)

# new fangled way
sta_Query <- dbSendQuery(chan_slims, sta_sql)

# old fangled way (longhand)
# sta_Query <- dbSendQuery(chan_slims,"SELECT *
#                           
#                           FROM SLIMS_DBA.AS_STATIONS_WMAS_V
# 
#                           WHERE STR_STATION_ID IN ('20150413-1130-gkenderes', '20161116-1340-mbrickner', '20161116-1450-mbrickner')
# 
                          # ")



# sta_Data <- dbFetch(sta_Query, n = 10) %>% 
#   as_tibble()

sta_Data <- dbFetch(sta_Query) %>% 
  as_tibble()

str(sta_Data)
sort(names(sta_Data))
sta_Data

# get unique vector of INT_STATION_GEN_ID
gen_id_vec <- 
  sta_Data %>% 
  pull(INT_STATION_GEN_ID) 

sql_gen_id <- paste("'", as.character(gen_id_vec), "'", collapse=", ", sep="")





# methods -----------------------------------------------------------------


# methods LUT

methods_LUT_Query <- dbSendQuery(chan_slims,"SELECT INT_METHOD, STR_METHOD_DESC

                          FROM SLIMS_DBA.MI_METHODS_LUT
                          
                          ")

methods_LUT_Data <- dbFetch(methods_LUT_Query) %>% 
  as_tibble()

str(methods_LUT_Data)
methods_LUT_Data



# methods 


# use sprintf to create sql query with collect syntax (sql_stations from above)
gen_id_sql <- sprintf("SELECT INT_MI_SURVEY_GEN_ID, INT_STATION_GEN_ID, INT_METHOD, LATITUDE, LONGITUDE, REPLICATE_COMMENTS, COUNTY_NAME 
                      FROM SLIMS_DBA.STREAM_MI 
                      WHERE INT_STATION_GEN_ID IN (%s)", sql_gen_id)

# new fangled way
methods_Query <- dbSendQuery(chan_slims, gen_id_sql)


# old fangled way (longhand)
# methods_Query <- dbSendQuery(chan_slims,"SELECT INT_MI_SURVEY_GEN_ID, INT_STATION_GEN_ID, INT_METHOD, LATITUDE, LONGITUDE,
#                                                 REPLICATE_COMMENTS, COUNTY_NAME
# 
#                           FROM SLIMS_DBA.STREAM_MI
#                           
#                           WHERE INT_STATION_GEN_ID IN ('43829', '47505', '47506')
#                           
#                           ")

methods_Data <- dbFetch(methods_Query) %>% 
  as_tibble()

str(methods_Data)
methods_Data


# merge methods

methods <- 
  methods_Data %>% 
  left_join(methods_LUT_Data, by = 'INT_METHOD')
  
str(methods)
methods





# merge stations and methods ----------------------------------------------

mystations <- 
  sta_Data %>% 
  left_join(methods, by = 'INT_STATION_GEN_ID')

str(mystations)
mystations

# get unique vector of INT_MI_SURVEY_GEN_ID
gen_mi_vec <- 
  mystations %>% 
  pull(INT_MI_SURVEY_GEN_ID) 

sql_gen_mi <- paste("'", as.character(gen_mi_vec), "'", collapse=", ", sep="")




# taxa --------------------------------------------------------------------

# use sprintf to create sql query with collect syntax (sql_stations from above)
gen_mi_sql <- sprintf("SELECT INT_BUG_CODE, TAXA_SUM, INT_MI_SURVEY_GEN_ID
                        FROM SLIMS_DBA.STREAM_MI_RBP_TAXA
                        WHERE INT_MI_SURVEY_GEN_ID IN (%s)", sql_gen_mi)

# new fangled way
taxa_Query <- dbSendQuery(chan_slims, gen_mi_sql)


# longhand
# taxa_Query <- dbSendQuery(chan_slims,"SELECT INT_BUG_CODE, TAXA_SUM, INT_MI_SURVEY_GEN_ID
# 
#                           FROM SLIMS_DBA.STREAM_MI_RBP_TAXA
#                           
#                           WHERE INT_MI_SURVEY_GEN_ID IN ('66034', '68281', '68282')
#                           
#                           ")

taxa_Data <- dbFetch(taxa_Query) %>% 
  as_tibble()

str(taxa_Data)
taxa_Data


# get unique vector of INT_BUG_CODE 
int_bug_vec <- 
  taxa_Data %>% 
  pull(INT_BUG_CODE)

sql_int_bug <- paste("'", as.character(unique(int_bug_vec)), "'", collapse=", ", sep="")






# bug LUT 

# use sprintf to create sql query with collect syntax (sql_stations from above)
int_bug_sql <- sprintf("SELECT STR_ID_LEVEL, INT_BUG_CODE, INT_HILS_ID_LEVEL, STR_TROPHIC_ID_LEVEL, INT_BCG_WARM, INT_BCG_COLD
                        FROM SLIMS_DBA.MI_BUG_CODES_LUT
                        WHERE INT_BUG_CODE IN (%s)", sql_int_bug)

# new fangled way
bugLUT_Query <- dbSendQuery(chan_slims, int_bug_sql)



# old fangled - will pull all and just merge matches (inefficient)
# bugLUT_Query <- dbSendQuery(chan_slims,"SELECT STR_ID_LEVEL, INT_BUG_CODE, INT_HILS_ID_LEVEL, 
#                                             STR_TROPHIC_ID_LEVEL, INT_BCG_WARM, INT_BCG_COLD
# 
#                           FROM SLIMS_DBA.MI_BUG_CODES_LUT
#                           
#                           ")

bugLUT_Data <- dbFetch(bugLUT_Query) %>% 
  as_tibble()

str(bugLUT_Data)
bugLUT_Data



# merge taxa

alltaxa <- 
  taxa_Data %>% 
  left_join(bugLUT_Data, by = 'INT_BUG_CODE')

str(alltaxa)
alltaxa





# merge stations and taxa -------------------------------------------------

alltaxa <- 
  mystations %>% 
  left_join(alltaxa, by = 'INT_MI_SURVEY_GEN_ID')

str(alltaxa)
alltaxa





# close channel
odbcClose(chan_slims) # seems to be an RODBC function. Can't find odbc equivalent

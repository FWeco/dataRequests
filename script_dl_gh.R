library(readxl)
library(writexl)
library(tidyverse)
library(tidylog)
library(knitr)

getwd()

# We will use the function paste0 to create an easy-to-read url

# gitUrl <-
#   'https://raw.githubusercontent.com/FWeco/dataRequests/master/'
# 
# 
# paste0(
#   gitUrl,
#   '2020-04-03_SRBC.csv')

# "https://raw.githubusercontent.com/FWeco/dataRequests/master/2020-04-03_SRBC.csv"


# Read in the data:

# SRBCstations <- 
#   read_csv(
#     paste0(
#       gitUrl,
#       '2020-04-03_SRBC.csv'))
# 
# 
# 
# head(SRBCstations)
# tail(SRBCstations)
# dim(SRBCstations)
# summary(SRBCstations)
# str(SRBCstations)



library(tidyverse)

################################################################################

padISONumber <- function(item){
  if_else( 
    nchar(item)==1,
    paste0("00", item),
    if_else(
      nchar(item)==2,
      paste0("0", item),
      item
    )
  )
}

################################################################################



# load the list of countries
world_countries <- read.csv("./utilities/csv-who-countries.csv")

# check if any countries has region set but the boolean IsWHOCountry is not set correctly
world_countries %>% filter(IsWHOCountry==FALSE & WHORegion !="") %>%  select (CountryName, IsWHOCountry, WHORegion)

# fix the NA issues in Malaria data for Namibia country code
world_countries %>% filter(IsWHOCountry==TRUE & is.na(ISO2))
world_countries <- world_countries %>% mutate(ISO2=if_else(ISO3=="NAM", "NA", ISO2))
world_countries %>% filter(IsWHOCountry==TRUE & is.na(ISO2))

# convert iso number to three digits string
world_countries <- world_countries %>% mutate(ISONum=as.character(ISONum))
world_countries <- world_countries %>% mutate(ISONum=padISONumber(ISONum))

glimpse(world_countries)
world_countries %>% head()



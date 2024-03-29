
library(tidyverse)
library(data.table)
library(jsonlite)

#--------------------------------------------------------------------------------
# 
#  these are utility functions used during development, 
#  not part of the actual workflow
#
# --------------------------------------------------------------------------------


#--------------------------------------------------------------------------------
# 
#  for test purposes, the data file was split into separate files  by region
#  this helped simulate handling multiple data loads
#
# --------------------------------------------------------------------------------

data_file <- "./utilities/Consolidated_reported_numbers.csv"
data <- fread(data_file, col.names = c("country", "year","num_cases","num_deaths","region"))

splitDataByRegion <- function(){

  write.csv(
    data %>% filter(region=="Eastern Mediterranean"), "data/Eastern-Mediterranean-reported_numbers.csv", row.names=FALSE)
  
  write.csv(
    data %>% filter(region=="Africa"),  "data/Africa-reported_numbers.csv", row.names=FALSE)
  
  write.csv(
    data %>% filter(region=="Americas"), "data/Americas-reported_numbers.csv", row.names=FALSE)
  
  write.csv(
    data %>% filter(region=="Europe"), "data/Europe-reported_numbers.csv", row.names=FALSE)
  
  write.csv(
    data %>% filter(region=="South-East Asia"), "data/South-East-Asia-reported_numbers.csv", row.names=FALSE )
  
  write.csv(
    data %>% filter(region=="Western Pacific"), "data/Western-Pacific-reported_numbers.csv", row.names=FALSE )

}


getUniqueCountriesFromDataFile <- function(){
  
  unique_countries  <- data %>% select(country) %>% distinct()
  output_file    <- "./utilities/unique_countries_from_data_file.csv"

  unique_countries %>%  head()
  unique_countries %>%  count()
  
  write.csv2(unique_countries, output_file)
  
}

padISONumeric <- function(item){
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


createConsolidatedCountryList <- function(){
 # load who regions
 # load country list and join 
  
  ## found by accident
  # world_bank_pop %>% head()
  
  
  #world_countries_cols <- c("country_name","official_name","iso_2","iso_3","iso_num")
  #world_countries <- fread("./utilities/world_countries.csv", col.names = world_countries_cols)
  
  #who_countries_cols <- c("region_name", "country_name")
  #who_countries <- fread("./utilities/who_countries.csv", col.names = who_countries_cols)
  
  #who_regions_cols <- c("region", "region_code", "region_name")
  #who_regions <- read.csv("./utilities/who_regions.csv", col.names = who_regions_cols )

  #world_countries <- (world_countries %>% 
  #  left_join(who_countries, by="country_name") %>% 
  #  left_join(who_regions, by="region_name"))
  
  #world_countries <- world_countries %>% mutate(is_who_country = (!is.na(region_name)), iso_num=as.character(iso_num))
  #world_countries <- world_countries %>% mutate(iso_num= padISONumeric(iso_num))
  #world_countries <- world_countries %>% select(country_name, official_name, region, region_code,  region_name, is_who_country, iso_2, iso_3, iso_num)
  
  #world_countries <- world_countries %>% mutate(region = if_else(
  #                                                is.na(region),
  #                                                 "",
  #                                                region  
  #                                                  ) )
  #
  
  world_countries <- read.csv2("./utilities/country_list_cleaned.csv")
  output_file <- "./utilities/country_list_cleaned.csv"

  # write json file
  rownames(world_countries) <- NULL
  colnames(world_countries) <- c("CountryName", "OfficialName","WHORegion", "WHORegionCode",  "WHORegionName","IsWHOCountry", "ISO2","ISO3", "ISONum")
  
  glimpse(world_countries)
  world_countries <- as_tibble(world_countries)
  
  # REF: https://rpubs.com/Shaunson26/dataframe2json
   
  json <- toJSON(x = world_countries, dataframe = 'rows', pretty = T)
  glimpse(world_countries)
  
  write(json, "./utilities/countrylist.json")
  write.csv2(world_countries, output_file, row.names = FALSE)
  
}

# getUniqueCountriesFromDataFile()
# splitDataByRegion()
# createConsolidatedCountryList()


createKaggleVersion <- function(){
  
  # the the cleaned data file
  world_countries <- read.csv2("./utilities/country_list_cleaned.csv")
  
  world_countries <- world_countries %>%  select(CountryName, OfficialName, IsWHOCountry, WHORegion, WHORegionCode,  WHORegionName, ISO2, ISO3, ISONum)
  colnames(world_countries)[2] <- "LongName"
  glimpse(world_countries)

  world_countries %>% filter(IsWHOCountry==TRUE) %>% select(CountryName) %>% nrow()
  
  who_countries_df <- world_countries %>% filter(IsWHOCountry==FALSE) %>% select(CountryName) %>% arrange(CountryName)
  write.csv(who_countries_df, "./utilities/my-regions.csv", row.names = FALSE)
  
  write.csv(world_countries, "./utilities/csv-who_countries.csv", row.names = FALSE)
  write.csv2(world_countries, "./utilities/csv2-who-countries.csv", row.names = FALSE)
  
}

createKaggleVersion()


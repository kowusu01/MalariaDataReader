
fnFindNullsInColumn <- function(data_set,taregt_col_name){
  CURRENT_FUNCTION <- "fnFindNullsInColumn"
  
  null_values_in_target_col <- data.frame()
  the_issue_code <- NA;
  
  if(taregt_col_name=="country"){
    null_values_in_target_col <- data_set %>% filter(is.na(country) | country=="") #[is.na(data_set$country), ]
    the_issue_code <- ISSUE_CODE_COUNTRY_NOT_PRESENT 
  }
  else if(taregt_col_name=="year"){
    null_values_in_target_col <- data_set%>% filter(is.na(year) | year==0) #[is.na(data_set$year), ]
    the_issue_code <- ISSUE_CODE_YEAR_NOT_PRESENT
  }
  else if(taregt_col_name=="num_cases"){
    null_values_in_target_col <- data_set%>% filter(is.na(num_cases) | num_cases==0) # [is.na(data_set$num_cases), ]
    the_issue_code <- ISSUE_CODE_NUM_CASES_ZERO_OR_NULL
  }
  else if(taregt_col_name=="num_deaths"){
    null_values_in_target_col <- data_set%>% filter(is.na(num_deaths) | num_deaths==0) #[is.na(data_set$num_deaths), ]
    the_issue_code <- ISSUE_CODE_NUM_CASES_ZERO_OR_NULL
  }
  else{
    null_values_in_target_col <- data_set%>% filter(is.na(region) | region=="") #[is.na(data_set$region), ]
    the_issue_code <- ISSUE_CODE_REGION_NOT_PRESENT 
  }
  
  if (nrow(null_values_in_target_col) > 0){
      null_values_in_target_col <- null_values_in_target_col %>% 
      select(record_number, country, region, year, num_cases, num_deaths) %>% 
      mutate(column_name=rep(taregt_col_name, nrow(null_values_in_target_col)), 
             issue_type=rep(ISSUE_TYPE_WARNING, nrow(null_values_in_target_col)), 
             issue_code=rep(the_issue_code, nrow(null_values_in_target_col)),
             issue=rep(paste(taregt_col_name, ' is null, empty or zero'), nrow(null_values_in_target_col)))
  }
  fnDisplayDataset(null_values_in_target_col, paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - issues details dataset is empty"))
}

fnDataInconsistencyNumDeaths <- function(data_set){
  data_set_complete_cases <- data_set[complete.cases(data_set), ]
  
  deaths_more_than_cases <- data_set_complete_cases %>% filter(num_deaths > num_cases)
  
  if (nrow(deaths_more_than_cases) > 0){
    deaths_more_than_cases <- deaths_more_than_cases %>% 
      select(record_number, country, region, year, num_cases, num_deaths)  %>% 
      mutate(column_name=rep('num_deaths', nrow(deaths_more_than_cases)), 
             issue_type=rep(ISSUE_TYPE_WARNING, nrow(deaths_more_than_cases)),
             issue_code=rep(ISSUE_CODE_NUM_DEATHS_GREATER_THAN_CASES, nrow(deaths_more_than_cases)),
             issue=rep('num_deaths is greater than num_cases', nrow(deaths_more_than_cases)))
  }
  return(deaths_more_than_cases)
}


fnTransformColumns <- function(data_set){
  # convert all numeric numbers to to 0
  data_set <- data_set %>% mutate(country = if_else(is.na(country), "", country))
  data_set <- data_set %>% mutate(region = if_else(is.na(region), "", region))
  data_set <- data_set %>% mutate(year = if_else(is.na(year), 0, year))
  data_set <- data_set %>% mutate(num_cases = if_else(is.na(num_cases), 0, num_cases))
  data_set <- data_set %>% mutate(num_deaths = if_else(is.na(num_deaths), 0, num_deaths))
  data_set <- data_set %>% mutate( across(c("year", "num_cases", num_deaths), as.numeric ) )
  return (data_set)
}

fnMergeCountriesAndRegion <- function(data_set, countries){
  data_set <- data_set %>% left_join(countries, by=c("country", "region"))
  glimpse(data_set)
  data_set %>% filter(is.na(region_code))
  data_set <- data_set %>% select(record_number, country, year, num_cases, num_deaths, region, region_code, iso2)
  
  final_col_names <- c("record_number", "country", "year", "num_cases", "num_deaths", "region", "region_code", "country_code")
  colnames(data_set) <- final_col_names
  
  data_set <- data_set %>% select(record_number, country, country_code, region, region_code, year, num_cases, num_deaths)
  return(data_set)
}

fnFindCountryRegionMismatch <- function(data_set){
  # return record, plus issue,
  country_region_mismatch <- data_set %>% filter(is.na(region_code))
  if (nrow(country_region_mismatch) > 0){
    country_region_mismatch <- country_region_mismatch %>% 
      select(record_number, country, region, year, num_cases, num_deaths)  %>% 
      mutate(column_name=rep("region", nrow(country_region_mismatch)), 
             issue_type=rep(ISSUE_TYPE_ERROR, nrow(country_region_mismatch)),
             issue_code=rep(ISSUE_CODE_COUNTRY_REGION_MISMATCH, nrow(country_region_mismatch)),
             issue=rep('country and region do not match.', nrow(country_region_mismatch)))
  }
  return(country_region_mismatch)
}


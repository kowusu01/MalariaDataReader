
fnFindNullsInColumn <- function(data_set,taregt_col_name){
  
  CURRENT_FUNCTION <- "fnFindNullsInColumn"
  
  null_values_in_target_col <- data.frame()
  
  if(taregt_col_name=="country"){
    null_values_in_target_col <- data_set[is.na(data_set$country), ]
  }
  else if(taregt_col_name=="year"){
    null_values_in_target_col <- data_set[is.na(data_set$year), ]
  }
  else if(taregt_col_name=="num_cases"){
    null_values_in_target_col <- data_set[is.na(data_set$num_cases), ]
  }
  else if(taregt_col_name=="num_deaths"){
    null_values_in_target_col <- data_set[is.na(data_set$num_deaths), ]
  }
  else{
    null_values_in_target_col <- data_set[is.na(data_set$region), ]
  }
  
  if (nrow(null_values_in_target_col) > 0){
      null_values_in_target_col <- null_values_in_target_col %>% 
      select(record_number) %>% 
      mutate(column_name=rep(taregt_col_name, nrow(null_values_in_target_col)), 
             issue_type=rep(ISSUE_TYPE_ERROR, nrow(null_values_in_target_col)), 
             issue=rep(paste(taregt_col_name, ' is null'), nrow(null_values_in_target_col)))
  }
  
  
  fnDisplayDataset(null_values_in_target_col, paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - issues details dataset is empty"))
  
  
}

fnFindDataErrors <- function(data_set, target_column_name){
  
}

fnDataInconsistencyNumDeaths <- function(data_set){
  data_set_complete_cases <- data_set[complete.cases(data_set), ]
  deaths_more_than_cases <- data_set_complete_cases %>% filter(num_deaths > num_cases)
  if (nrow(deaths_more_than_cases) > 0){
    deaths_more_than_cases <- deaths_more_than_cases %>% select(record_number)  %>% 
      mutate(column_name=rep('num_deaths', nrow(deaths_more_than_cases)), 
             issue_type=rep(ISSUE_TYPE_WARNING, nrow(deaths_more_than_cases)), 
             issue=rep('num_deaths is greater than num_cases', nrow(deaths_more_than_cases)))
  }
  return(deaths_more_than_cases)
}

fnTransformColumns <- function(data_set){
  browser()
  
  # convert all numeric numbers to to 0
  data_set <- data_set %>% mutate(country = if_else(is.na(country), "", country))
  data_set <- data_set %>% mutate(region = if_else(is.na(region), "", region))
  
  data_set <- data_set %>% mutate(year = if_else(is.na(year), 0, year))
  data_set <- data_set %>% mutate(num_cases = if_else(is.na(num_cases), 0, num_cases))
  data_set <- data_set %>% mutate(num_deaths = if_else(is.na(num_deaths), 0, num_deaths))
  
  data_set <- data_set %>% mutate( across(c("year", "num_cases", num_deaths), as.numeric ) )
  
  return (data_set)
  
}
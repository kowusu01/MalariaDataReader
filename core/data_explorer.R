
fnFindNullsInColumn <- function(data_set, taregt_col_name){
  
  null_values_in_target_col <- NA
  
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
  return(null_values_in_target_col)
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

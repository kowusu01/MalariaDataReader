
FILE_DATA_PROCESSOR <- "data_processor.R"

fnReadCSVDataFile <- function(data_file_path){
  
  CURRENT_FUNCTION <- "fnReadCSVDataFile()"
  
  fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - reading ", data_file_path, "..."))
  
  data <- fread(data_file_path, col.names = MALARIA_REPORTED_DATA_COL_HEADERS)
  fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - done reading csv file."))
  fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - exiting function."))
  
  return(data)
}

ERROR_STATUS_OK <- "OK"
ERROR_STATUS_FAILED <- "FAILED"


fnProcessDataset <- function(file_name){
  # general stats
  # - number of failures
  # - get stats from bad data
  # - in this case we want failures per region
  # - which column fails most
  # - we are looking for nulls
  # - mismatch

  CURRENT_FUNCTION <- "fnProcessDataset()"
  
  my_env = new.env()
  my_env$error_status <- ERROR_STATUS_OK
  
  # only process csv files
  if (!str_detect(file_name, ".csv$")){
    fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - file: ", file_name, " not a supported file type."))
    return (NA)
  }
  
  db_connection <- NA
  countries_data <- NA
  load_stats_id <- NA

  #read countries data to augment the malaria data read
  countries_list_path <- "utilities/country_list_cleaned.csv"
  
  tryCatch(
    {
      fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - reading countries list  - ", countries_list_path))
      my_env$countries <- read.csv2(countries_list_path, col.names = c("country",
                                                                       "official_name",
                                                                       "region",
                                                                       "region_code",
                                                                       "region_display_name",
                                                                       "is_who_country",
                                                                       "iso2",
                                                                       "iso3",
                                                                       "iso_num"))
    },
    error= function(e){
      my_env$error_status <- ERROR_STATUS_FAILED
      fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - error reading countries list  - ", countries_list_path, e))
    }
  )
  
  glimpse(my_env$countries)
  
  if(my_env$error_status==ERROR_STATUS_FAILED){
    return (NA)
  }
    
  
  db_connection <- fnCreateConnection(DB_DRIVER, DB_INSTANCE, DB_SERVER_NAME, DB_PORT, DB_USER, DB_PASSWORD)
  data_file_path <- file.path(DATA_FOLDER_NAME, file_name)
  
  fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - Step 0: checking if file has already been processed - ", data_file_path))
  
  if (FILE_READER_ENFORCE_UNIQUE_DATA_FILE_NAMES){
    tryCatch(
      {
        if ( fnIsFileAlreadyProcessed(db_connection, data_file_path) ){
          fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, paste0(" - file already processed: ", file_name)))
        }
      },
      error=function(ex){
        fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, paste("- error while checking if file already processed:[", data_file_path, "]. ", ex)))
        assign("error_status", ERROR_STATUS_FAILED, env=my_env)
        }
    )
  }
  
  if(my_env$error_status==ERROR_STATUS_FAILED){
    fnCloseConnection(db_connection)
    return (NA)
  }
    
  # reset error status
  my_env$error_status <- ERROR_STATUS_OK
    
  country_is_na <- NA
  year_is_na <- NA
  numcases_is_na <- NA
  numdeaths_is_na <- NA
  region_is_na <- NA
  data_set_complete_cases <- NA
  
      # STEP 1: read the data file -  tryCatch #1 
      tryCatch({ 
          fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - Step 1: reading the data file..."))
          data_set <- fnReadCSVDataFile(data_file_path)
          fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - total records read: ", nrow(data_set)))
          
          # Add line number (record number to dataset) for better reference
          fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - adding line numbers (record_number) to dataset for reference..."))
          data_set$record_number <- seq(1, nrow(data_set))
          fnDisplayDataset(data_set)
        },
      error=function(ex){
        my_env$error_status <- ERROR_STATUS_FAILED
        error_msg <- paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - exception  trying to read csv file: [", file_name, "]. ", ex)
        fnLogMessage(error_msg)
        
        # do not rollback the load_stats record
        tryCatch(
          {
            fnSaveErrorToDB(file_name, error_msg, TABLE_LOAD_STATS, db_connection)    
            fnCloseConnection(db_connection)
          },
          error=function(ex){}
        )
      }) # try catch #1
      
      if(my_env$error_status==ERROR_STATUS_FAILED)
        return (NA)
  
      data_set <- fnMergeCountriesAndRegion(data_set, my_env$countries)
      
      # STEP 2: explore and find bad data -  tryCtach #2  
      tryCatch({
        fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " -  Step 2: explore and find bad data..."))
        fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION,  " - finding nulls in [country] field..."))
        country_is_na <- fnFindNullsInColumn(data_set, "country")
        fnDisplayDataset(country_is_na, paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - no nulls in [country] field."))
        
        fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION,  " - finding nulls in [year] field..."))
        year_is_na <- fnFindNullsInColumn(data_set, "year")
        fnDisplayDataset(year_is_na, paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " -  nulls in [year] field."))
        
        # null in num_cases col
        fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION,  " - finding nulls in [num_cases] field..."))
        numcases_is_na <- fnFindNullsInColumn(data_set, "num_cases")
        fnDisplayDataset(numcases_is_na, paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - no nulls in [num_cases] field."))
        
        # null in num_deaths col
        fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION,  " - finding nulls in [num_deaths] field."))
        numdeaths_is_na <- fnFindNullsInColumn(data_set, "num_deaths")
        fnDisplayDataset(numdeaths_is_na, paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, "no nulls values in [num_deaths] field"))
        
        # null in region
        fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION,  " - finding nulls in [region] field..."))
        region_is_na <- fnFindNullsInColumn(data_set, "region")
        fnDisplayDataset(region_is_na, paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - no nulls in [region] field."))
        
        # checking if country and region match
        fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION,  " - checking if country and region match..."))
        region_country_mismatch <- fnFindCountryRegionMismatch(data_set)
        fnDisplayDataset(region_country_mismatch, paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - no country and region mismatch found."))
        
        # sample inconsistencies in two columns: num_cases vs num_deaths
        fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION,  " - finding inconsistencies between [num_cases] and [num_deaths]..."))
        inconsistencies_numdeaths <- fnDataInconsistencyNumDeaths(data_set)
        fnDisplayDataset(inconsistencies_numdeaths, paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - no inconsistencies between [num_cases] and [num_deaths] were found."))
        
      },
      error=function(ex){ 
        my_env$error_status <- ERROR_STATUS_FAILED
        error_msg <- paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - exception in  analyzing dataset for bad data: [", file_name,"]. ", ex)
        fnLogMessage(error_msg)
        
        tryCatch(
          {
            fnRollbackTransaction(db_connection)
            fnLogMessage("ERROR!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
            fnSaveErrorToDB(file_name, error_msg, TABLE_LOAD_STATS, db_connection)
            fnCloseConnection(db_connection)
          },
          error = function(ex){
          })
      }) #  try catch #2
      
      if (my_env$error_status==ERROR_STATUS_FAILED)
        return (NA)
      
      # STEP 3: create a list of all the data issues -  tryCatch #3
      tryCatch({
        
        fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " -  Step 3: create a list of all the data issues..."))
        fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - creating issues details dataset..."))
        
        issues_details <- data.frame()
        
        fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - adding each inidividual issues detail list") )
        
        # attempt to add list of country field errors
        if (nrow(country_is_na) > 0)
          issues_details <- issues_details %>% rbind(country_is_na)
        
        fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - done with country.") )
        
        # attempt to add list of nulls in year column
        if (nrow(year_is_na) > 0)
          issues_details <- issues_details %>% rbind(year_is_na)
        
        fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - done with year.") )
        
        # errors in deaths column
        if(nrow(numcases_is_na) > 0)
          issues_details <- issues_details %>% rbind(numcases_is_na)
        
        fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - done with numcases.") )
        
        # errors in deaths column
        if(nrow(numdeaths_is_na) > 0)
          issues_details <- issues_details %>% rbind(numdeaths_is_na)
        
        fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - done with numdeaths.") )
        
        # errors in region column
        if(nrow(region_is_na) > 0)
          issues_details <- issues_details %>% rbind(region_is_na)
        
        fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - done with region.") )
        
        # errors in region and country mismatch
        if(nrow(region_country_mismatch) > 0)
          issues_details <- issues_details %>% rbind(region_country_mismatch)
        
        fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - done with region/country mismatch.") )
        
        # warning for inconsistent between numcases and num deaths
        if (nrow(inconsistencies_numdeaths) > 0)
          issues_details <- issues_details %>% rbind(inconsistencies_numdeaths)
        
        fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - done with numcases/numdeaths inconsistencies.") )
        
        fnDisplayDataset(issues_details, paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - issues details dataset is empty"))
        },
        error=function(ex){ 
          
          my_env$error_status <- ERROR_STATUS_FAILED
          error_msg <- paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - exception in building the issues dataset for bad data: ", file_name, ex)
          fnLogMessage(error_msg)
          
          tryCatch(
            {
              fnRollbackTransaction(db_connection)
              fnSaveErrorToDB(file_name, error_msg, TABLE_LOAD_STATS, db_connection)
              fnCloseConnection(db_connection)    
            },
            error = function(ex){}
          )
        }) #  try catch #3
        
        if (my_env$error_status==ERROR_STATUS_FAILED)
          return (NA)
        
        # STEP 4: saving datasets -  tryCatch #4
        # STEP 4.1 - save load_stats record, that is the main one, its primary key is used in the other tables
        
        fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - analysis completed, saving datasets for db...") )
        tryCatch({
          
          fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - creating a row for [load_stats]..."))
          
          num_errors <- issues_details %>% filter(issue_type==ISSUE_TYPE_ERROR) %>%  select(record_number) %>%  distinct() %>% nrow()
          
          num_warnings <- issues_details %>% filter(issue_type==ISSUE_TYPE_WARNING) %>%  select(record_number) %>%  distinct() %>% nrow()
          
          # is we get this point it means the data load was successful
          final_load_status <- 'Processing'
          #err_message - NA
          
          basic_stats <- data.frame(
            region =  strsplit(file_name, "_")[[1]][1],
            load_timestamp = c( now() ),
            file_path = c(data_file_path),
            load_status = final_load_status,
            num_records = c(nrow(data_set)),
            bad_data_count = c(num_errors),
            warning_data_count = c(num_warnings)
            #error_message = c(err_message)
          )
          fnDisplayDataset(basic_stats, NA)
          
          fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - done creating a row for [load_stats]."))
          fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - saving  [load_stats] row to db..."))
          fnSaveDataInDatabase(basic_stats, TABLE_LOAD_STATS, db_connection)
          fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - done saving  [load_stats] row to db."))
        },
        error=function(ex){ 
          
          my_env$error_status <- ERROR_STATUS_FAILED
          
          error_msg <- paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - exception in saving LoadStats record to db: [", file_name,"]. ",  ex)
          fnLogMessage(error_msg)
          
          tryCatch({
            fnRollbackTransaction(db_connection)  
          },
          error=function(ex){
            error_msg <- paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - saving LoadStats record failed, rolling back transaction as a result of this error also failed: [", file_name,"]. ", ex)
          })
          
          tryCatch({
            fnSaveErrorToDB(file_name, error_msg, TABLE_LOAD_STATS, db_connection)
          },
          error=function(ex){
            error_msg <- paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - building the issues dataset for bad data failed, saving Bad Data record for this error also failed: [", file_name,"]. ", ex)
          })
          
          tryCatch(
            {
              fnCloseConnection(db_connection)
            }, 
            error=function(ex){})
          
        }) #  try catch #4
        
        if (my_env$error_status==ERROR_STATUS_FAILED)
          return (NA)

        # STEP 4.2 - save the other datasets in a transaction, if anything happens rollback
        #  try catch #5
        tryCatch({
          data_set_complete_cases <- data_set[complete.cases(data_set), ]
          fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - loading load_stats id from db..."))
          load_stats_id <- fnGetLoadStatsId(db_connection)
          fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - done loading load_stats id from db"))
          
          ## BEGIN TRANS
          fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - beginning db transaction to save other datasets..."))
          fnBeginTransaction(db_connection)
          
          # load the load_id record just saved
          # fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - updating [cases_reported_complete] dataset with load_stats_id..."))
          # load_ids <- rep(load_stats_id, nrow(data_set_complete_cases))
          # load_id_df <- data.frame(load_id=c(load_ids))
          # data_set_complete_cases <- load_id_df %>% cbind(data_set_complete_cases)
          # fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - done updating [cases_reported_complete] dataset with load_stats_id."))
          
          # fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - saving [cases_reported_complete] dataset to db..."))
          # fnDisplayDataset(data_set_complete_cases, paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - [cases_reported_complete] dataset has no rows"))
          # fnSaveDataInDatabase(data_set_complete_cases, TABLE_RECORDS_COMPLETE, db_connection)
          # fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - done saving [cases_reported_complete] dataset to db."))
          
          #fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - updating [cases_reported_bad] dataset with load_stats_id..."))
          #bad_data <- data_set[!complete.cases(data_set), ]
          #load_ids <- rep(load_stats_id, nrow(bad_data))
          #load_id_df <- data.frame(load_id=c(load_ids))
          #bad_data <- load_id_df %>% cbind(bad_data)
          #fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - done updating [cases_reported_bad] dataset with load_stats_id."))
          #fnDisplayDataset(bad_data, paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - [cases_reported_bad] dataset has no rows"))
          #fnSaveDataInDatabase(bad_data, TABLE_RECORDS_BAD, db_connection)
          #fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - done saving [cases_reported_bad] dataset to db."))
          
          fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - updating [data_issues_details] dataset with load_stats_id..."))
          load_ids <- rep(load_stats_id, nrow(issues_details))
          load_id_df <- data.frame(load_id=c(load_ids))
          issues_details <- load_id_df %>% cbind(issues_details)
          fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - done updating [data_issues_details] dataset with load_stats_id."))
          fnDisplayDataset(issues_details, paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - [data_issues_details] dataset has no rows"))
          fnSaveDataInDatabase(issues_details, TABLE_ISSUES_DETAILS, db_connection)
          fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - done saving [data_issues_details] dataset to db."))
          
          #save the entire dataset as one
          data_set <- fnTransformColumns(data_set)
          fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - updating [all_cases] dataset with load_stats_id..."))
          load_ids <- rep(load_stats_id, nrow(data_set))
          load_id_df <- data.frame(load_id=c(load_ids))
          data_set <- load_id_df %>% cbind(data_set)
          fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - done updating [reported_data] dataset with load_stats_id."))
          fnDisplayDataset(data_set, paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - [reported_data] dataset has no rows"))
          fnSaveDataInDatabase(data_set, TABLE_MALARIA_REPORTED_DATA, db_connection)
          fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - done saving [reported_data] dataset to db."))
            
          ## COMMIT TRANS
          fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - commiting transaction for all other datasets"))
          
          # update load_stats status to Completed
          fnUpdateLoadStatus(db_connection, "Completed")
          fnCommitTransaction(db_connection)
        },
        error=function(ex){ 
          my_env$error_status <- ERROR_STATUS_FAILED
          
          error_msg <- paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - exception in saving the issues dataset: [", file_name,"]. ",  ex)
          fnLogMessage(error_msg)
          
          # in case of error, rollback, then update the load_stats record status to Error
          tryCatch(
            {
              fnRollbackTransaction(db_connection)
            },
            error = function(ex){
            })
          
          tryCatch(
            {
              fnSaveErrorToDB(file_name, error_msg, TABLE_LOAD_STATS, db_connection, load_stats_id)  
            },
            error = function(ex)
            {
            })
        },
        finally={
          tryCatch({
              fnCloseConnection(db_connection)
          }, error= function(ex){
                
          })
          
        }) # try catch #5
}

fnSaveDataInDatabase <- function(data_set, db_table, db_connection){
  CURRENT_FUNCTION <- "fnSaveDataInDatabase()"
  
  #https://stackoverflow.com/questions/33634713/rpostgresql-import-dataframe-into-a-table
  
  if (!is.na(db_connection))
    dbWriteTable(db_connection, db_table, data_set, row.names=FALSE, append=TRUE)
  else
    fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - db connection is null, data not saved to db"))
}

fnSaveErrorToDB <- function(data_file_path, error_msg, db_table, db_connection, current_record_id=NA){
  CURRENT_FUNCTION <- "fnSaveErrorToDB()"
  fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - saving error message to db..."))
    
  if (is.na(current_record_id)){
    error_stats <- data.frame(
      descr = strsplit(data_file_path, "_")[[1]][1],
      load_timestamp = now(),
      file_path = data_file_path,
      load_status = "Error",
      num_records = 0,
      bad_data_count = 0,
      warning_data_count = 0,
      error_message = error_msg
    )
   
    if (FULL_DEBUG=="TRUE"){
      glimpse(error_stats)
    }

    if (is.na(db_connection)){
      fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - DB connection not available, unable to save error details to db."))
    }
    else{
      dbWriteTable(db_connection, db_table, error_stats, row.names=FALSE, append=TRUE)
      fnLogMessage(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - done saving error details to db"))
    }
  }
  else{
    query <- paste0("update ", db_table, " set load_status='Error', error_message='", error_msg , "' where id=", current_record_id )
    
    if (FULL_DEBUG=="TRUE"){
      fnLogMesasge(paste0(FILE_DATA_PROCESSOR, ".", CURRENT_FUNCTION, " - ", query))
    }
    
    if (!is.na(db_connection)){
      DBI::dbSendQuery(db_connection, query)
    }
  }
}
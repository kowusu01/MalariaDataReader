
FILE_DATA_PROCESSOR <- "utils.R"

TABLE_LOAD_STATS <- "load_stats"
TABLE_RECORDS_COMPLETE <- "cases_reported_complete"
TABLE_RECORDS_BAD <- "cases_reported_bad"
TABLE_ISSUES_DETAILS <- "data_issues_details"
TABLE_MALARIA_REPORTED_DATA <- "reported_data"


ISSUE_TYPE_ERROR <- "Error"
ISSUE_TYPE_WARNING <- "Warning"

# malaria dataset
MALARIA_REPORTED_DATA_COL_HEADERS <- c("country", "year","num_cases","num_deaths","region")

################################################################################
## fnLogMessage()
################################################################################
fnLogMessage <- function(msg){
  print(paste(Sys.time(), "-", msg))
}

################################################################################
## fnDisplayDataset()
################################################################################
fnDisplayDataset <- function(data_set, default_msg){
  
  CURRENT_FUNCTION <- "fnDisplayDataSet()"
  
  if(FULL_DEBUG=="TRUE"){
    if ( is.data.frame(data_set))
      glimpse(data_set)
    else{
      if(!is.na(default_msg))
        fnLogMessage(default_msg)
    }
  }
}

FULL_DEBUG   <- Sys.getenv("FS_IN_DEBUG_MODE", unset = "TRUE")
IN_TEST_MODE <- Sys.getenv("FS_IN_TEST_MODE", unset = "TRUE")

fnLogMessage(paste0(FILE_DATA_PROCESSOR, " - APP RUNNING IN DEBUG MODE: ", FULL_DEBUG))
fnLogMessage(paste0(FILE_DATA_PROCESSOR, " - APP RUNNING IN TEST MODE: ", IN_TEST_MODE))

# using environment variables
DB_DRIVER <- Sys.getenv("PostgresDriver")
DB_SERVER_NAME <- Sys.getenv("DBServerName")
DB_INSTANCE <- Sys.getenv("DBInstance")
DB_PORT <- Sys.getenv("DBPort")
DB_USER<- Sys.getenv("DBUsername")
DB_PASSWORD <- Sys.getenv("DBPassword")

# in test mode, we bypass db, so no need to show db info
env_db_info <- paste0(FILE_DATA_PROCESSOR, " - ENVIRONMENT INFO - db_diver: ", DB_DRIVER, " db_server: ", DB_SERVER_NAME , " port: ", DB_PORT, " db_instance: ", DB_INSTANCE, " user: ", DB_USER," pw: ", DB_PASSWORD )

# but if we are in full debug mode, show the db info
if (IN_TEST_MODE=="FALSE" && FULL_DEBUG=="TRUE" )
  fnLogMessage(env_db_info) # just to make sure we are reading the correct variables

DATA_FOLDER_NAME <- Sys.getenv("FS_READER_DATA_PATH", unset = "data")
COMPLETED_DATA_FOLDER <- Sys.getenv("FS_READER_DATA_COMPLETED_PATH", unset = "data/completed")
BAD_DATA_FOLDER <- Sys.getenv("FS_READER_DATA_BAD_PATH", unset = "data/bad")

FILE_READER_WAIT_TIME_IN_SECONDS <- Sys.getenv("FILE_READER_WAIT_TIME_IN_SECONDS", unset = NA)
if (is.na(FILE_READER_WAIT_TIME_IN_SECONDS)){
  fnLogMessage(paste0(FILE_DATA_PROCESSOR, " - Environment variable FILE_READER_WAIT_TIME_IN_SECONDS not found. Using default: ", DEFAULT_FILE_READER_PROCESS_INTERVAL, "seconds."))
  FILE_READER_WAIT_TIME_IN_SECONDS <- DEFAULT_FILE_READER_PROCESS_INTERVAL
}else{
  fnLogMessage(paste0(FILE_DATA_PROCESSOR, " - Environment variable FILE_READER_WAIT_TIME_IN_SECONDS is set to : ", FILE_READER_WAIT_TIME_IN_SECONDS, "seconds."))
}


FILE_READER_ENFORCE_UNIQUE_DATA_FILE_NAMES <- Sys.getenv("FILE_READER_ENFORCE_UNIQUE_DATA_FILE_NAMES", unset = "FALSE")

if (FILE_READER_ENFORCE_UNIQUE_DATA_FILE_NAMES=="FALSE"){
  fnLogMessage(paste0(FILE_DATA_PROCESSOR, " - Unique filenames is disabled, it can be enabled in the config."))
  FILE_READER_ENFORCE_UNIQUE_DATA_FILE_NAMES <- FALSE
}else{
  fnLogMessage(paste0(FILE_DATA_PROCESSOR, " - Unique filenames is enabled, it can be disabled in the config. "))
  FILE_READER_ENFORCE_UNIQUE_DATA_FILE_NAMES <- TRUE
}


env_data_path_info <- paste0(FILE_DATA_PROCESSOR, " - DATA PATH INFO - Base folder: ", DATA_FOLDER_NAME, ", Completed folder: ", COMPLETED_DATA_FOLDER , ", Bad data folder: ", BAD_DATA_FOLDER )

env_reader_params <- paste0(FILE_DATA_PROCESSOR, " - OTHER PARAMS: Process Intervals (seconds): ", FILE_READER_WAIT_TIME_IN_SECONDS, ". Unique data file names enforced? ", FILE_READER_ENFORCE_UNIQUE_DATA_FILE_NAMES)

#if ((FULL_DEBUG=="TRUE") && (IN_TEST_MODE=="TRUE")){
fnLogMessage(env_data_path_info)
fnLogMessage(env_reader_params)
#}

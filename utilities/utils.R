

TABLE_LOAD_STATS <- "load_stats"
TABLE_RECORDS_COMPLETE <- "cases_reported_complete"
TABLE_RECORDS_BAD <- "cases_reported_bad"
TABLE_ISSUES_DETAILS <- "data_issues_details"

ISSUE_TYPE_ERROR <- "Error"
ISSUE_TYPE_WARNING <- "Warning"

# malaria dataset
MALARIA_REPORTED_DATA_COL_HEADERS <- c("country", "year","num_cases","num_deaths","region")
MALARIAL_REPORTED_DATA_DB_TABLE <- "reported_data"

################################################################################
## log message
################################################################################
fnLogMessage <- function(msg){
  print(paste(Sys.time(), "-", msg))
}


FULL_DEBUG   <- Sys.getenv("FS_IN_DEBUG_MODE", unset = FALSE)
IN_TEST_MODE <- Sys.getenv("FS_IN_TEST_MODE", unset = FALSE)

fnLogMessage(paste0("APP RUNNING IN DEBUG MODE: ", FULL_DEBUG))
fnLogMessage(paste0("APP RUNNING IN TEST MODE: ", IN_TEST_MODE))

# using environment variables
DB_DRIVER <- Sys.getenv("PostgresDriver")
DB_SERVER_NAME <- Sys.getenv("DBServerName")
DB_INSTANCE <- Sys.getenv("DBInstance")
DB_PORT <- Sys.getenv("DBPort")
DB_USER<- Sys.getenv("DBUsername")
DB_PASSWORD <- Sys.getenv("DBPassword")

env_db_info <- paste0("ENVIRONMENT INFO - db_diver: ", DB_DRIVER, " db_server: ", DB_SERVER_NAME , " port: ", DB_PORT, " db_instance: ", DB_INSTANCE, " user: ", DB_USER," pw: ", DB_PASSWORD )
if (FULL_DEBUG && IN_TEST_MODE)
  fnLogMessage(env_db_info)

DATA_FOLDER_NAME <- Sys.getenv("FS_READER_DATA_PATH")
COMPLETED_DATA_FOLDER <- Sys.getenv("FS_READER_DATA_COMPLETED_PATH")
BAD_DATA_FOLDER <- Sys.getenv("FS_READER_DATA_BAD_PATH")

FILE_READER_WAIT_TIME_IN_SECONDS <- Sys.getenv("FILE_READER_WAIT_TIME_IN_SECS", unset = NA)
if (is.na(FILE_READER_WAIT_TIME_IN_SECONDS)){
  fnLogMessage(paste0("Unable to find the value for environment variable FILE_READER_WAIT_TIME_IN_SECONDS. Setting the value to default: ", DEFAULT_FILE_READER_PROCESS_INTERVAL, "seconds"))
  FILE_READER_WAIT_TIME_IN_SECONDS <- DEFAULT_FILE_READER_PROCESS_INTERVAL
}


FILE_READER_ENFORCE_UNIQUE_DATA_FILE_NAMES <- Sys.getenv("FILE_READER_ENFORCE_UNIQUE_DATA_FILE_NAMES", unset = NA)
if (is.na(FILE_READER_ENFORCE_UNIQUE_DATA_FILE_NAMES)){
  fnLogMessage(paste0("Unable to find the value for environment variable FILE_READER_ENFORCE_UNIQUE_DATA_FILE_NAMES. Setting the value to default: FALSE"))
  FILE_READER_ENFORCE_UNIQUE_DATA_FILE_NAMES <- FALSE
}

env_data_path_info <- paste0("DATA PATH INFO - data folder: [", DATA_FOLDER_NAME, "], completed data folder: [", COMPLETED_DATA_FOLDER , "], bad data folder: [", 
 BAD_DATA_FOLDER, "], Process Intervals: [",
 FILE_READER_WAIT_TIME_IN_SECONDS, "]", ". Unique data file names enforced? [", FILE_READER_ENFORCE_UNIQUE_DATA_FILE_NAMES,"]")

if (FULL_DEBUG && IN_TEST_MODE)
  fnLogMessage(env_data_path_info)

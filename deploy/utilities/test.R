
library(config)

fn_testConfiguration <- function()
{
  
  # to be set by env var
  UNIQUE_FILE_NAMES <- Sys.getenv("UNIQUE_FILE_NAMES", unset = NA)
  
  if ( is.na(UNIQUE_FILE_NAMES) )
    {
    UNIQUE_FILE_NAMES <- TRUE
    print("NOT FOUND, using default")  
   }
  
  
  config <- config::get()
  
  ## db stuff
  db_driver <- config$db_driver
  db_name   <- config$db_name
  db_host   <- config$db_host  
  db_port   <- config$db_port
  db_uid    <- config$db_userid
  db_pwd    <- config$db_pwd
  
  print(paste("dbInfo: ", db_driver, db_name, db_host, db_port, db_uid, db_pwd))
}



tryCatch(
  
  # call main 
  fn_testConfiguration(),
  
  error=function(e) {
    message("Error creating connection")
    print(e)
  }
  
)
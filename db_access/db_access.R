
FILE_DB_ACCESS <- "db_access.R"

fnCreateConnection <- function(my_db_driver, my_db_name, my_db_host, my_db_port, my_db_uid, my_db_pwd){
 
   CURRENT_FUNCTION <- "createConnection()"
   
   if (IN_TEST_MODE==TRUE){
     fnLogMessage(paste0(FILE_DB_ACCESS, ".", CURRENT_FUNCTION, " - IN_TEST_MODE  - for test purposes to we bypass db by returning NA for connection."))
     
     return (NA) # if in test mode bypass db
   }
   
   fnLogMessage(paste0(FILE_DB_ACCESS, ".", CURRENT_FUNCTION, " - connecting to database…"))  
  
   con <- dbConnect(my_db_driver, 
            dbname = my_db_name,
            host = my_db_host, 
            port = my_db_port,
            user = my_db_uid, 
            password = my_db_pwd)
  
   fnLogMessage(paste0(FILE_DB_ACCESS, ".", CURRENT_FUNCTION, " - connection established."))
   return(con)
}

fnGetLoadStatsId <- function(db_connection){
  
  CURRENT_FUNCTION <- "getLoadStatsId()"
  
  if (IN_TEST_MODE==TRUE){
    fnLogMessage(paste0(FILE_DB_ACCESS, ".", CURRENT_FUNCTION, " - IN_TEST_MODE  - returning dummy id for load_stats_id."))  
    return (1)
  }

  fnLogMessage(paste0(FILE_DB_ACCESS, ".", CURRENT_FUNCTION, " - loading load_stats_id from db."))
  df <- DBI::dbGetQuery(db_connection, "SELECT currval('load_stats_id_seq')" )
  return (df[1,1]) # return the primary key
}

fnUpdateLoadStatus <- function(db_connection, status){
  
  CURRENT_FUNCTION <- "fnUpdateLoadStatus()"
  
  if (!IN_TEST_MODE){
    current_load_id <- fnGetLoadStatsId(db_connection)
    DBI::dbSendQuery(db_connection, paste0("update load_stats set load_status='", status, "' where id=", current_load_id) )    
  }
  fnLogMessage(paste0(FILE_DB_ACCESS, ".", CURRENT_FUNCTION, " - status for current load updated to ", status)) 
}

fnBeginTransaction <- function(db_connection){
  CURRENT_FUNCTION <- "fnBeginTransaction()"  
  fnLogMessage(paste0(FILE_DB_ACCESS, ".", CURRENT_FUNCTION, " - beginning transaction…")) 
  
  if(!is.na(db_connection)){
    DBI::dbBegin(db_connection)
  }
  fnLogMessage(paste0(FILE_DB_ACCESS, ".", CURRENT_FUNCTION, " - transaction started ")) 
}

fnCommitTransaction <- function(db_connection){
  CURRENT_FUNCTION <- "fnCommitTransaction()"  
  fnLogMessage(paste0(FILE_DB_ACCESS, ".", CURRENT_FUNCTION, " - committing transaction…")) 
  
  if (!is.na(db_connection)){
    DBI::dbCommit(db_connection)
  }
  fnLogMessage(paste0(FILE_DB_ACCESS, ".", CURRENT_FUNCTION, " - transaction committed. ")) 
}

fnRollbackTransaction <- function(db_connection){
  CURRENT_FUNCTION <- "fnRollbackTransaction()"
  fnLogMessage(paste0(FILE_DB_ACCESS, ".", CURRENT_FUNCTION, " - rolling back transaction... ")) 
  if (!is.na(db_connection)){
    DBI::dbRollback(db_connection)
  }
  fnLogMessage(paste0(FILE_DB_ACCESS, ".", CURRENT_FUNCTION, " - transaction rollback.")) 
}

fnCloseConnection <- function(db_connection){
  
  CURRENT_FUNCTION <- "fnCloseConnection()"
  
  fnLogMessage(paste0(FILE_DB_ACCESS, ".", CURRENT_FUNCTION, " - closing connection..."))
  if(!is.na(db_connection)){
    DBI::dbDisconnect(db_connection)
  }
  fnLogMessage(paste0(FILE_DB_ACCESS, ".", CURRENT_FUNCTION, " - connection closed."))
}

###############################################################################
## basic packages
##############################################################################


print(paste("======================== ", Sys.time(), " =========================") )
print(paste(Sys.time(), " - loading packages...") )
print(paste("======================== ", Sys.time(), " =========================") )

# install devtools
if (!require(devtools)){
  install.packages("devtools", dependencies=TRUE)
}

if (!require(pdftools))
  install.packages("pdftools", dependencies=TRUE)

if (!require(tidyverse))
  install.packages("tidyverse", dependencies=TRUE)

if (!require(DT))
  install.packages("DT", dependencies=TRUE)

if (!require(gt))
  install.packages("gt", dependencies=TRUE)

if (!require(RPostgreSQL))
  install.packages("RPostgreSQL", dependencies=TRUE)

if(!require(config)) 
  install.packages("config", dependencies=TRUE)

print(paste("======================== ", Sys.time(), " =========================") )
print(paste(Sys.time(), " - done loading packages.") )
print(paste("======================== ", Sys.time(), " =========================") )


library(devtools)
library(pdftools)
library(tidyverse)
library(data.table)

library(scales)
library(DT)
library(gt)
library(RPostgreSQL)
library(config)
library(lubridate)

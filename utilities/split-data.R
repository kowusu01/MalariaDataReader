
library(tidyverse)
library(data.table)

source("malaria/malaria_csv_reader.R")

data <- fnReadMalariaData("data/reported_numbers.csv", c("country", "year", "num_cases", "num_deaths", "region"))
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

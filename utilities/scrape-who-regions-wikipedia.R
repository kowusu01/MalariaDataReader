
# Load required libraries
library(rvest)
library(dplyr)


# Recently, I was working on a project involving Work health Organization Malaria data on Kaggle.
# The data included Malaria cases and deaths from various countries and regions of the world.
#
# As part of my validation, I wanted to be able to make sure that the countries
# and regions in the data are all correct. 

# World Health Organization categorizes countries into six regions called WHO regions. 
# I needed a data source that contains countries and their respective WHO regions to assist in verifying that the countries and region in the malaria data file are correct.


################################################################################
#
# The following code with generated with Bing Chat using the prompt below.
#
################################################################################
# <script src="https://gist.github.com/kowusu01/8f448bdb16c2e7fa141a5fbbda8443d9.js"></script>
# <script src="https://gist.github.com/kowusu01/ca168a72854860ccf4410e6ccfa6b053.js"></script>
#
# initial prompt
#
# - need as dataset with all the countries and their regions
# - url: https://en.wikipedia.org/wiki/List_of_WHO_regions
# - source the data: 
#  - div is "mw-content-text"
#  - under this div, 
#    the h2 element contains the regions, there are 6 regions so there are 6 h2 
#    elements
# - each region has a name and countries under it found in the h2 element
# - there is also 6 p element containing the countries 
#
# step 1: extract the region name and region code
# - get the region from the span with class mw-headline
# - split the region into region name and region code, the region code is in the 
# parenthesis
#
#
# step 2: extract the countries for that region
# - the list of countries is in the <a> elements
#
# step 3: repeat step 1 and 2
#
# I want the code in R
#
################################################################################
#
# Initially, the code did not work. Specifically the line reading
# the region_info and the line reading countries
# 
# I provided Bing Chat two feedback telling exactly what went wrong and after
# two corrections, the code worked flawlessly.
# 
# feedback 1:
#  this line is not able to read the region info 
#     - region_info <- page %>% 
#        html_nodes(paste0("div#mw-content-text > h2:nth-child(", i*2, ") span.mw-headline")) %>%
#       html_text()    
#
# feedback 2:
#   ok, regions is working but the line reading the countries is not working
#
################################################################################
#
# Python version
#
# after the code was working I asked Bing Chat to produce a python version
# the code produced did not work I provided one feedback and Bing Chat 
# fixed the issue after one correction.
# 
################################################################################


# URL of the page
url <- "https://en.wikipedia.org/wiki/List_of_WHO_regions"

# Read the HTML content of the page
page <- read_html(url)

# Extract the regions and countries
data <- data.frame(Region = character(), Code = character(), Country = character())

# Extract region name and code
region_info <- page %>% html_nodes("span.mw-headline") %>% html_text()

for(i in 1:6) {
  region_name <- gsub("\\s*\\(.*", "", region_info[i])
  region_code <- gsub(".*\\((.*)\\)", "\\1", region_info[i])
  
  # Extract countries for each region
  countries <- page %>% html_nodes(xpath = paste0('//h2[', i, ']/following-sibling::p[1]')) %>% html_text()
  countries_list <- strsplit(countries, ", ")[[1]]
  
  # Add to data frame
  data <- rbind(data, data.frame(Region = region_name, Code = region_code, Country = countries_list))
}

# Print the data
print(data)

unique(data$Code)

# Conclusion

# Here is what I learned in the process:

# 1. Do some homework about the work you want to give ChatGPT.
#    In my case I went to the website and did a view source to understand the structure of the source to be scraped.
#
# 2. Treat ChatGPT as an intelligent partner and provide detailed instructions, it will pay off.
#
# 3. Provide complete instructions to minimize chats and feedback. ChatGPT is very good in taking feedback and improving the result. 
#    But treat ChatGPT like a remote coworker in a different time zone; assume you are not be available when he/she is working on the code, so feedback may not be an option. 
#    Providing detailed and complete instructions is crucial.
#    You may be paying for the number of api calls, so minimizing the chats and feedback may be something to works towards.
# 


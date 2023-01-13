# options(tidyverse.quiet = TRUE)
# library(tidyverse, quietly = T, warn.conflicts = F)
#library(rvest, quietly = T, warn.conflicts = F)
#library(httr, quietly = T, warn.conflicts = F)

#library(tidyverse)
library(rvest)
library(dplyr)
library(readr)
library(stringr)


timestamp <- Sys.time()
datestamp <- Sys.time() %>% str_replace_all(":", "_") %>% str_replace_all(" ", "_")

page <- read_html("https://outagemap.mlgw.org/OutageSummary.php")

overall_outage <- page %>% html_elements(xpath = "//td//td//h2") %>% html_text()



events <- page %>%
  html_elements(xpath = '/html/head/script[not(@src)]') %>%
  as.character() %>%
  str_split(pattern = "\n") %>%
  unlist()


events_detail <- events[str_detect(events, regex("events\\[\\d*\\]"))] %>%
  str_replace_all('"', "") %>%
  str_trim() %>%
  str_split(",", simplify = T) %>%
  as.data.frame(stringsAsFactors = F) %>%
  mutate(outage_num = overall_outage[1],
         cust_affected = overall_outage[2],
         time = as.character(timestamp))


save(events_detail, file = paste0("data/", datestamp, ".RData"))


page %>%
  html_elements(xpath = '/html/head') %>%
  html_text() %>%
  write_lines(file = paste0("data/", datestamp, ".txt"))

readRDS("total_outages.rds") %>%
  bind_rows(events_detail) %>%
  saveRDS("total_outages.rds")



# options(tidyverse.quiet = TRUE)
# library(tidyverse, quietly = T, warn.conflicts = F)
#library(rvest, quietly = T, warn.conflicts = F)
#library(httr, quietly = T, warn.conflicts = F)

#library(tidyverse)
library(rvest)
library(dplyr)
library(readr)
library(stringr)
library(googlesheets4)
library(googledrive)
library(sodium)


googlesheets_key_raw <- Sys.getenv("SHEETS_KEY") %>% sodium::hex2bin()

googlesheets_nonce_raw <- "bbb2cbfef0e850069fc5d955b037f407cd490114e72067e3" %>% sodium::hex2bin()


readRDS("service.RDS") %>%
  sodium::data_decrypt(key = googlesheets_key_raw, nonce = googlesheets_nonce_raw) %>%
  writeBin(con = "service1.json")

gargle::with_gargle_verbosity("debug", gs4_auth(path = "service1.json"))



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

#write_csv(events_detail, file = paste0("data/", datestamp, ".csv"))
save(events_detail, file = paste0("data/", datestamp, ".RData"))


 #ss <- drive_get("mlgw.outage.log")
googledrive::as_id("https://docs.google.com/spreadsheets/d/1Z7oNPuq4NtzOl7Ljajmoyppj6Z22k0zQ_NywQUqBd8Y/edit#gid=0") %>%
 sheet_append(data = events_detail)

page %>%
  html_elements(xpath = '/html/head') %>%
  html_text() %>%
  write_lines(file = paste0("data/", datestamp, ".txt"))

file.remove("service1.json")

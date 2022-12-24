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

gs4_auth(path = "service1.json")



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



  sodium::hex2bin("123745133476d3cad3465cf35f4a399ef0e52c2a912b372f6a5376c9f39a81e4a5372f535dafb064a2925b37eaa2fe2fa9365ffa9c4dd5b3d7abf6f1") %>%
  sodium::data_decrypt(key = googlesheets_key_raw, googlesheets_nonce_raw) %>%
  rawToChar() %>%
  googledrive::as_id() %>%
  sheet_append(data = events_detail)


page %>%
  html_elements(xpath = '/html/head') %>%
  html_text() %>%
  write_lines(file = paste0("data/", datestamp, ".txt"))

file.remove("service1.json")

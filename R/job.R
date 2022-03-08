options(tidyverse.quiet = TRUE)
library(tidyverse, quietly = T, warn.conflicts = F)
#library(rvest, quietly = T, warn.conflicts = F)
#library(httr, quietly = T, warn.conflicts = F)

timestamp <- Sys.time()
datestamp <- Sys.time() %>% str_replace_all(":", "_") %>% str_replace_all(" ", "_")

page <- read_html("https://outagemap.mlgw.org/OutageSummary.php")

overall_outage <- page %>% html_elements(xpath = "//td//td//h2") %>% html_text()



events <- page %>%
  html_elements(xpath = '/html/head/script[not(@src)]') %>%
  str_split(pattern = "\n") %>%
  unlist()


events_detail <- events[str_detect(events, regex("events\\[\\d*\\]"))] %>%
  str_replace_all('"', "") %>%
  str_trim() %>%
  str_split(",", simplify = T) %>%
  as.data.frame(stringsAsFactors = F) %>%
  mutate(outage_num = overall_outage[1],
         cust_affected = overall_outage[2],
         time = timestamp)

write_csv(events_detail, file = paste0("data/", datestamp, ".csv"))

page %>%
  html_elements(xpath = '/html/head') %>%
  html_text() %>%
  write_lines(file = paste0("data/", datestamp, ".txt"))

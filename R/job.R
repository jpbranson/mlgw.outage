# options(tidyverse.quiet = TRUE)
# library(tidyverse, quietly = T, warn.conflicts = F)
#library(rvest, quietly = T, warn.conflicts = F)
#library(httr, quietly = T, warn.conflicts = F)

#library(tidyverse)
library(rvest)
library(dplyr)
library(purrr)
library(readr)
library(ggplot2)
library(stringr)
library(geofacet)
library(lubridate)


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

readRDS("total_outages.rds") %>%
  bind_rows(events_detail) %>%
  saveRDS("total_outages.rds")


page_text <- page %>%
  html_elements(xpath = '/html/head') %>%
  html_text()


page_text %>%
  write_lines(file = paste0("data/", datestamp, ".txt"))

####Polygon data -----
# parse_polygons_from_text <- function(x) {
#   filename = str_extract(x, pattern = "----------------- (.*)$", group = 1)
#
#   intermediate_poly <- map_dfr(.x = 0:84, .f = function(y){
#     #x = list element, the "text"
#     #y = polygon element
#
#     cust_affected_html <- x %>% str_extract(paste0('var cusAffected',y,' = \\\\"<center><h3>(Customers Affected: [0-9]*)</h3></center>\\\\"\\"'), group = 1)
#
#     if(is.na(cust_affected_html)) {
#       individual_poly <- data.frame(long = NA,
#                                     lat = NA,
#                                     polygon = paste0("polygon", y),
#                                     id = NA,
#                                     cust_affected_html = NA, custs_num = NA)
#
#       return(individual_poly)
#     }
#
#     event_id <- x %>% str_extract(paste0('var id',y,'= \\\\"([0-9]*)\\\\";'), group = 1)
#     custs_num <- x %>% str_extract(paste0('var custs',y,'= \\\\"([0-9]*)\\\\";'), group = 1)
#
#     individual_poly <- x %>%
#       str_replace_all("[\r\n]" , "") %>%
#       str_extract(paste0('var polygon', y, '(.*?)\\]\\}\\);\\", \\\"var fillSymbol', y), group = 1) %>%
#       str_extract(pattern = regex("new Polygon\\(\\{rings:\\[\\[(.*)\\]"), group = 1) %>%
#       str_split(pattern = "\\],\\[") %>%
#       .[[1]] %>%
#       as_tibble() %>%
#       mutate(long = as.numeric(str_extract(value, "parseFloat\\((.*)\\),", group =1 )),
#              lat = as.numeric(str_extract(value, ", parseFloat\\((.*)\\)", group =1 )),
#              polygon = paste0("polygon", y),
#              id = event_id,
#              cust_affected_html = cust_affected_html,
#              custs_num = custs_num, y = y, filename = filename)
#
#     return(individual_poly)
#
#
#   })
#
#   return(intermediate_poly)
#
# }
#
# new_polygon <- page_text %>%
#   paste(., "-----------------", ., collapse = "") %>%
#   parse_polygons_from_text()
#
# total_parsed_polygons <- readRDS("total_parsed_polygons.rds") %>%
#   bind_rows(new_polygon)
#
# saveRDS(total_parsed_polygons, "total_parsed_polygons.rds")
#
# mygrid <- data.frame(
#   row = c(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11),
#   col = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13),
#   code = c("", "", "", "002", "003", "004", "", "006", "007", "008", "009", "010", "011", "", "", "013", "014", "015", "016", "017", "018", "019", "020", "021", "022", "023", "", "", "025", "026", "027", "028", "029", "030", "031", "032", "033", "034", "035", "", "", "037", "038", "039", "040", "041", "042", "043", "044", "045", "046", "047", "", "", "048", "049", "050", "051", "052", "053", "054", "055", "056", "057", "058", "", "", "059", "060", "061", "062", "063", "064", "065", "066", "067", "068", "069", "", "", "070", "071", "072", "073", "074", "075", "076", "077", "078", "079", "080", "081", "082", "083", "084", "085", "086", "087", "088", "089", "090", "091", "092", "093", "095", "096", "097", "098", "099", "100", "101", "102", "103", "104", "105", "106", "107", "111", "112", "113", "114", "115", "116", "117", "118", "119", "120", "121", "122", "123", "127", "128", "129", "130", "131", "132", "133", "134", "135", "136", "137", "138", "139"),
#   name = c("", "", "", "002", "003", "004", "", "006", "007", "008", "009", "010", "011", "", "", "013", "014", "015", "016", "017", "018", "019", "020", "021", "022", "023", "", "", "025", "026", "027", "028", "029", "030", "031", "032", "033", "034", "035", "", "", "037", "038", "039", "040", "041", "042", "043", "044", "045", "046", "047", "", "", "048", "049", "050", "051", "052", "053", "054", "055", "056", "057", "058", "", "", "059", "060", "061", "062", "063", "064", "065", "066", "067", "068", "069", "", "", "070", "071", "072", "073", "074", "075", "076", "077", "078", "079", "080", "081", "082", "083", "084", "085", "086", "087", "088", "089", "090", "091", "092", "093", "095", "096", "097", "098", "099", "100", "101", "102", "103", "104", "105", "106", "107", "111", "112", "113", "114", "115", "116", "117", "118", "119", "120", "121", "122", "123", "127", "128", "129", "130", "131", "132", "133", "134", "135", "136", "137", "138", "139"),
#   stringsAsFactors = FALSE
# ) %>%
#   filter(code != "")
#
# plot1 <- total_parsed_polygons %>%
#   filter(!is.na(long)) %>%
#   mutate(timestamp = parse_date_time(exact = T,filename, orders = "./data/%Y-%m-%d_%H_%M_%S.txt") %>% with_tz("America/Chicago")) %>%
#   distinct(id, custs_num, timestamp) %>%
#   mutate(custs_num = as.numeric(custs_num)) %>%
#   #filter(timestamp >= Sys.time() - lubridate::days(10)) %>%
#   ggplot(aes(x = timestamp, y = custs_num)) +
#   geom_line(aes(col = id), linewidth = .08) +
#   scale_x_datetime(date_labels = "%m-%d", date_breaks = "5 months") +
#   facet_geo(~id, grid = mygrid) +
#   theme_minimal() +
#   theme(legend.position = "none",
#         strip.background = element_blank(),
#         strip.text.x = element_blank(),
#         panel.spacing.x=unit(0, "lines"),panel.spacing.y=unit(0, "lines"),
#         axis.title.x = element_blank(),
#         panel.background = element_blank(),
#         plot.background = element_blank(),
#         panel.grid.minor = element_blank(),
#         panel.grid = element_blank(),
#         panel.border = element_rect(color = rgb(235,235,235, 25, maxColorValue = 255), fill = NA),
#         axis.text.x = element_text(size = 3))
#
#
# ggsave(filename = "map_grid_linechart_total.png", plot = plot1, width = 8, height = 9, dpi = 1000)
#
#
# plot2 <- total_parsed_polygons %>%
#   filter(!is.na(long)) %>%
#   mutate(timestamp = parse_date_time(exact = T,filename, orders = "./data/%Y-%m-%d_%H_%M_%S.txt") %>% with_tz("America/Chicago")) %>%
#   distinct(id, custs_num, timestamp) %>%
#   mutate(custs_num = as.numeric(custs_num)) %>%
#   filter(timestamp >= Sys.time() - lubridate::days(10)) %>%
#   ggplot(aes(x = timestamp, y = custs_num)) +
#   geom_line(aes(col = id), linewidth = .08) +
#   scale_x_datetime(date_labels = "%m-%d", date_breaks = "5 months") +
#   facet_geo(~id, grid = mygrid) +
#   theme_minimal() +
#   theme(legend.position = "none",
#         strip.background = element_blank(),
#         strip.text.x = element_blank(),
#         panel.spacing.x=unit(0, "lines"),panel.spacing.y=unit(0, "lines"),
#         axis.title.x = element_blank(),
#         panel.background = element_blank(),
#         plot.background = element_blank(),
#         panel.grid.minor = element_blank(),
#         panel.grid = element_blank(),
#         panel.border = element_rect(color = rgb(235,235,235, 25, maxColorValue = 255), fill = NA),
#         axis.text.x = element_text(size = 3))
#
#
# ggsave(filename = "map_grid_linechart_tenday.png", plot = plot2, width = 8, height = 9, dpi = 1000)



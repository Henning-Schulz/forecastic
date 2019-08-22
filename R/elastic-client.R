# elastic-client.R
#' @author Henning Schulz

library(elasticsearchr)
library(tidyverse)
library(stringr)

read_intensities <- function(app_id, tailoring) {
  raw_data <- elastic(cluster_url = str_c("http://", opt$elastic, ":9200"), index = str_c(app_id, ".", tailoring, ".intensity")) %search%
    query('{
             "match_all": {}
           }') %>%
    as_tibble()
  
  intensities <- raw_data %>%
    select(timestamp, starts_with("intensity")) %>%
    left_join(transform_context(raw_data), by = "timestamp") %>%
    arrange(timestamp)
}

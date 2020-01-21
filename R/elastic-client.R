# elastic-client.R
#' @author Henning Schulz

library(elasticsearchr)
library(tidyverse)
library(stringr)

#' Reads the intensities from the elasticsearch.
#' The result will be formatted as tibble with the following columns:
#'   \code{timestamp} The timestamp in milliseconds
#'   \code{intensity.<group>} The workload intensity (one column per group)
#'   \code{<context_variable>} The values of a context variable (one column per variable / per value in the string case)
#' The tibble holds the data as they are in the elasticsearch, i.e., can contain \code{NA} and missing values.
#' 
#' @param app_id The app-id to be used in the query.
#' @param tailoring the tailoring to be used in the query.
#' 
#' @example read_intensities("my_app", "all")
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

#' Gets the latest timestamp stored in the elasticsearch for the passed app-id and tailoring.
#' 
#' @param app_id The app-id to be used in the query.
#' @param tailoring the tailoring to be used in the query.
#' 
#' @example get_latest_timestamp("my_app", "all")
get_latest_timestamp <- function(app_id, tailoring) {
  elastic(cluster_url = str_c("http://", opt$elastic, ":9200"), index = str_c(app_id, ".", tailoring, ".intensity")) %search%
    (
      query('{
            "range": { "timestamp": { "gte": 1 } }
      }', size = 0) +
      aggs('{
           "max_timestamp" : { "max" : { "field" : "timestamp" } }
      }')
    ) %>%
    .$value
}

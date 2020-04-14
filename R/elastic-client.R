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
read_intensities <- function(app_id, tailoring, perspective = NULL) {
  if (is.null(perspective)) {
    filtering_query = query('{ "match_all": {} }')
  } else {
    filtering_query = query(sprintf('{ "range": { "timestamp": { "lte": %s } } }', perspective))
  }
  
  raw_data <- elastic(cluster_url = str_c("http://", opt$elastic, ":9200"), index = str_c(app_id, ".", tailoring, ".intensity")) %search%
    filtering_query %>%
    as_tibble()
  
  intensities <- raw_data %>%
    select(timestamp, starts_with("intensity")) %>%
    arrange(timestamp) %>%
    left_join(transform_context(raw_data), by = "timestamp") %>%
    arrange(timestamp)
}

#' When used with the elastic client, returns the list of groups.
#' 
#' @param app_id The app-id to be used in the query.
#' @param tailoring the tailoring to be used in the query.
#' 
#' @example elastic(cluster_url = "localhost:9200", index = "my_app.all.intensity") %info% list_intensity_groups("my_app", "all")
list_intensity_groups <- function(app_id, tailoring) {
  endpoint <- str_c("/", app_id, ".", tailoring, ".intensity/_mapping")
  
  process_response <- function(response) {
    index_mapping <- httr::content(response, as = "parsed")
    names(index_mapping[[1]]$mappings$properties$intensity$properties)
  }
  
  structure(list("endpoint" = endpoint, "process_response" = process_response),
            class = c("elastic_info", "elastic_api", "elastic"))
}

#' Gets the latest timestamp stored in the elasticsearch for the passed app-id and tailoring.
#' 
#' @param app_id The app-id to be used in the query.
#' @param tailoring the tailoring to be used in the query.
#' 
#' @example get_latest_timestamp("my_app", "all")
get_latest_timestamp <- function(app_id, tailoring) {
  client <- elastic(cluster_url = str_c("http://", opt$elastic, ":9200"), index = str_c(app_id, ".", tailoring, ".intensity"))
  
  intensity_fields <- client %info%
    list_intensity_groups(app_id, tailoring) %>%
    str_c("\"intensity.", ., "\"") %>%
    paste(collapse = ", ")
  
  client %search%
    (
      query(sprintf('{
            "bool": {
              "filter": [
                { "range": { "timestamp": { "gte": 1 } } },
                {
                  "script": {
                    "script": {
                      "source": "for (field in params.fields) { if (doc[field].size() > 0) { return true } } return false",
                      "params": { "fields": [ %s ] },
                      "lang": "painless"
                    }
                  }
                }
              ]
            }
      }', intensity_fields), size = 0) +
      aggs('{
           "max_timestamp" : { "max" : { "field" : "timestamp" } }
      }')
    ) %>%
    .$value
}

# aggregation.R
#' @author Henning Schulz

library(tidyverse)

aggregation_logger <- Logger$new("aggregation")

#' Aggregates the intensities using the specified aggregations.
#' If required, it loads the behavior models from the elasticsearch and includes them in the aggregation.
#' 
#' @param intensities The (forecasted) intensities to be aggregated as tibble. It is required that the
#'                    first column is \code{timestamp} and the remaining ones are intensities.
#' @param aggregations The aggregations to be used as vector.
aggregate_workload <- function(intensities, aggregations) {
  aggregation_logger$info("Aggregating using ", paste(aggregations, collapse = ", "))
  
  for (agg in aggregations) {
    source(str_c("aggregations/", agg, ".R"))
    
    if (aggregation_requires_behavior) {
      # TODO
      stop("Aggregation with behavior is not implemented!")
    } else {
      behavior <- NULL
    }
    
    intensities <- do_aggregation(intensities, behavior)
  }
  
  formatted_intensities <- intensities %>%
    mutate(timestamp = timestamp - first(timestamp)) %>%
    rename_at(vars(starts_with("intensity")), funs(str_sub(., start = 11)))
  
  list(intensities = formatted_intensities)
}

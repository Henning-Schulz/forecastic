# aggregation.R
#' @author Henning Schulz

library(tidyverse)

aggregation_logger <- Logger$new("aggregation")

#' Aggregates the intensities using the specified aggregations.
#' If required, it loads the behavior models from the elasticsearch and includes them in the aggregation.
#' 
#' @param intensities The (forecasted) intensities to be aggregated as tibble. It is required that the
#'                    first column is \code{timestamp} and the remaining ones are intensities.
#' @param aggregation The aggregation to be used as vector.
aggregate_workload <- function(intensities, aggregation) {
  aggregation_logger$info("Aggregating using '", aggregation$type, "'")
  
  source(str_c("aggregations/", aggregation$type, ".R"))
  do_aggregation(intensities, behavior, aggregation$properties)
}

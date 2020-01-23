# adjustment.R
#' @author Henning Schulz

library(tidyverse)

adjustment_logger <- Logger$new("adjustment.R")

#' Adjusts the intensities using the specified adjustments
#' If required, it loads the behavior models from the elasticsearch and includes them in the adjustments
#' 
#' @param intensities The (forecasted) intensities to be adjusted as tibble. It is required that the
#'                    first column is \code{timestamp} and the remaining ones are intensities.
#' @param adjustments The aggregations to be used as adjustments
adjust_and_finalize_workload <- function(intensities, adjustments) {
  adjustment_logger$info("Adjusting using [", paste(adjustments, collapse = ", "), "]")
  
  behavior <- NULL
  
  for (adj in adjustments$type) {
    source(str_c("adjustments/", adj, ".R"))
    
    if (adjustment_requires_behavior) {
      # TODO: read
      behavior <- NULL
      break
    }
  }
  
  if (length(adj) > 0) {
    for (i in 1:nrow(adjustments)) {
      adj <- adjustments[i,]
      props <- adj$properties %>% select_if(~sum(!is.na(.)) > 0)
      
      source(str_c("adjustments/", adj$type, ".R"))
      intensities <- do_adjustment(intensities, behavior, props)
    }
  }
  
  formatted_intensities <- intensities %>%
    mutate(timestamp = timestamp - first(timestamp)) %>%
    rename_at(vars(starts_with("intensity")), list(~ str_sub(., start = 11)))
  
  list(intensities = formatted_intensities)
}

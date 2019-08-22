# forecaster.R
#' @author Henning Schulz

library(R6)
library(tidyverse)

Forecaster <- R6Class("Forecaster", list(
  
  logger = Logger$new("Forecaster"),
  
  past_intensities = NULL,
  end_past = NULL,
  resolution = NULL,
  forecast = NULL,
  # TODO: plots etc.
  
  initialize = function(app_id, tailoring, context_variables, resolution) {
    self$logger$info("Initializing data for forecasting...")
    
    # read intensities from elasticsearch
    intensities <- read_intensities(app_id, tailoring)
    
    # check resolution
    self$resolution <- resolution
    
    min_resolution <- intensities %>%
      arrange(timestamp) %>%
      mutate(time_diff = timestamp - lag(timestamp)) %>%
      drop_na(time_diff) %>%
      summarize(val = min(time_diff))
    
    if (resolution %% min_resolution != 0) {
      stop("The passed resolution ", resolution, " ms is not a multiple of the detected resolution ", min_resolution, " ms")
    }
    
    self$logger$info("Using context variables ", paste(context_variables, collapse = ", "))
    
    intensities <- intensities %>%
      select(timestamp, starts_with("intensity"), one_of(context_variables))
    
    # restrict to past and fill intensities
    start <- intensities %>%
      summarise(val = min(timestamp))
    
    end_past <- intensities %>%
      filter_at(vars(starts_with("intensity")), any_vars(!is.na(.))) %>%
      summarize(val = max(timestamp))
    self$end_past <- end_past$val
    
    self$past_intensities <- tibble(timestamp = seq(start$val, end_past$val, resolution)) %>%
      left_join(intensities, by = "timestamp") %>%
      fill(starts_with("intensity")) %>%
      replace(is.na(.), 0)
    
    self$logger$info("Initialization done.")
  },
  
  do_forecast = function(context, horizon) {
    stop("Not implemented!")
  }
  
))

# forecaster.R

library(R6)

Forecaster <- R6Class("Forecaster", list(
  intensities = NULL,
  horizon = NULL,
  resolution = NULL,
  forecast = NULL,
  # TODO: plots etc.
  
  initialize = function(app_id, tailoring, horizon, ignored_variables, context, resolution) {
    intensities <- read_intensities(app_id, tailoring)
    
    for (iv in ignored_variables) {
      intensities <- intensities %>%
        select(-matches(str_c("^", iv, "(?:\\..*)?$")))
    }
    
    self$resolution <- resolution
    
    min_resolution <- intensities %>%
      arrange(timestamp) %>%
      mutate(time_diff = timestamp - lag(timestamp)) %>%
      drop_na(time_diff) %>%
      summarize(val = min(time_diff))
    
    if (resolution %% min_resolution != 0) {
      stop("The passed resolution ", resolution, " ms is not a multiple of the detected resolution ", min_resolution, " ms")
    }
  },
  
  do_forecast = function(context, horizon) {
    stop("Not implemented!")
  }
  
))
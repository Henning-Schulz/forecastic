# perfect-forecaster.R
#' @author Henning Schulz

library(R6)

PerfectForecaster <- R6Class("PerfectForecaster", inherit = Forecaster,
  
  private = list(
    
    logger = Logger$new("PerfectForecaster")
    
  ),
  
  public = list(
    
    #' Extracts and formats the past intensities.
    do_forecast = function(context, horizon) {
      private$logger$info("Using the original intensities as 'forecast' to the past.")
      
      self$forecast <- self$past_intensities %>%
        select(timestamp, starts_with("intensity"))
    }
    
  )
)

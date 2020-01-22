# perfect-forecaster.R
#' @author Henning Schulz

library(R6)

PerfectForecaster <- R6Class("PerfectForecaster", inherit = Forecaster,
  
  private = list(
    
    logger = Logger$new("PerfectForecaster")
    
  ),
  
  public = list(
    
    #' Constructor ignoring any perspective, as it is irrelevant for this type of forecaster.
    initialize = function(app_id, tailoring, context_variables, resolution, forecast_total = F) {
      super$initialize(app_id, tailoring, context_variables, resolution, NULL, forecast_total)
    },
    
    #' Extracts and formats the past intensities.
    do_forecast = function(context, horizon) {
      private$logger$info("Using the original intensities as 'forecast' to the past.")
      
      self$forecast <- self$past_intensities %>%
        select(timestamp, starts_with("intensity"))
    }
    
  )
)

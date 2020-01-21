# prophet-forecaster.R
#' @author Henning Schulz

library(R6)
library(prophet)

#'
#' Forecaster implementation using the telescope tool.
#'
ProphetForecaster <- R6Class("ProphetForecaster", inherit = Forecaster,
                             
  private = list(
    
    logger = Logger$new("ProphetForecaster"),
    
    #' Forecasts one intensity group.
    #' 
    #' @param group The group name as string.
    #' @param past The past data as data frame (columns \code{ds}, one per group intensity, one per context variable).
    #' @param future The future data Needs to have the same columns as \code{past} (except for intensity).
    #' @param context_variables The context variables occurring in \code{past} and \code{future}.
    forecast_group = function(group, past, future, context_variables) {
      private$logger$info("Forecasting group ", group, "...")
      
      m <- prophet()
      
      for (variable in context_variables) {
        m <- add_regressor(m, variable)
      }
      
      m <- fit.prophet(m, past %>% select(ds, y = !!group, one_of(context_variables)))
      forecast <- predict(m, future)
      
      # plot(m, forecast)
      # prophet_plot_components(m, forecast)
      
      forecast %>%
        select(
          ds,
          !!group := yhat
        )
    }
  ),
                             
  public = list(
  
    #' Does the forecast using the prophet tool.
    do_forecast = function(context, horizon) {
      context_variables <- self$past_intensities %>%
        select(-timestamp, -starts_with("intensity")) %>%
        colnames()
      
      forecast_start <- self$end_past + self$resolution
      
      past <- self$past_intensities %>%
        mutate(ds = as_datetime(timestamp / 1000)) %>%
        select(-timestamp)
      
      future <- context %>%
        fill_context(forecast_start, horizon, self$resolution) %>%
        mutate(ds = as_datetime(timestamp / 1000)) %>%
        select(-timestamp)
      
      # forecast each group and join the results
      groups <- self$past_intensities %>%
        select(starts_with("intensity")) %>%
        names()
      
      private$logger$info("Warn message about \"Unknown or uninitialised column: 'y'\" is OK!")
      
      self$forecast <- groups %>%
        map(private$forecast_group,
            past = past, future = future,
            context_variables = context_variables) %>%
        reduce(left_join) %>%
        mutate(timestamp = as.numeric(ds) * 1000) %>%
        select(timestamp, starts_with("intensity"))
      
      private$logger$info("Forecasting done.")
    }
  )

)


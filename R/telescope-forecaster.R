# telescope-forecaster.R
#' @author Henning Schulz

library(telescope)
library(tidyverse)

#'
#' Forecaster implementation using the telescope tool.
#' 
TelescopeForecaster <- R6Class("TelescopeForecaster", inherit = Forecaster,
                               
  private = list(
    
    logger = Logger$new("TelescopeForecaster"),
    
    #' Forecasts one intensity group.
    #' 
    #' @param group The group name as string.
    #' @param past_context The past context as matrix (one context variable per column).
    #' @param future_context The future context. Needs to have the same columns as \code{past_context}.
    #' @param future_timestamps The future timestamps as vector. Needs to have the same length as \code{future_context}.
    forecast_group = function(group, past_context, future_context, future_timestamps) {
      private$logger$info("Forecasting group ", group, "...")
      
      tvp <- self$past_intensities[[group]]
      
      if (is_empty(past_context)) {
        forecast <- telescope.forecast(tvp, horizon = length(future_timestamps))
      } else {
        forecast <- telescope.forecast(tvp, horizon = length(future_timestamps),
                                       train.covariates = past_context,
                                       future.covariates = future_context)
      }
      
      private$logger$info("Forecasting of group ", group, " done.")
      
      tibble(
        timestamp = future_timestamps,
        !!group := forecast$mean
      )
    }
  ),                      

  public = list(
    
    #' Does the forecast using the telescope tool.
    do_forecast = function(context, horizon) {
      private$logger$info("Forecasting the intensities...")
      
      # calculating past context
      past_context <- self$past_intensities %>%
        select(-timestamp, -starts_with("intensity")) %>%
        as.matrix()
      
      # calculating the future context, removing the variables that do no occur in the past
      forecast_start <- self$end_past + self$resolution
      
      if (ncol(past_context) == 0) {
        context <- context %>%
          select(timestamp)
        
        past_only_context <- tibble(x__ = 0)
      } else {
        context <- context %>%
          select(timestamp, one_of(colnames(past_context)))
        
        # adding past contexts that are missing in the future context
        past_only_context <- setdiff(colnames(self$past_intensities %>% select(-starts_with("intensity"))), colnames(context)) %>%
          map(~ tibble(!!. := 0)) %>%
          reduce(bind_cols) %>%
          mutate(x__ = 0)
      }
      
      filled_context <- context %>%
        mutate(x__ = 0) %>%
        left_join(past_only_context, by = "x__") %>%
        select(-x__) %>%
        fill_context(forecast_start, horizon, self$resolution)
      
      future_context <- filled_context %>%
        select(-timestamp) %>%
        as.matrix()
      
      # forecast each group and join the results
      groups <- self$past_intensities %>%
        select(starts_with("intensity")) %>%
        names()
      
      self$forecast <- groups %>%
        map(private$forecast_group,
            past_context = past_context, future_context = future_context,
            future_timestamps = filled_context$timestamp) %>%
        reduce(left_join)
      
      private$logger$info("Forecasting done.")
    }
  )

)

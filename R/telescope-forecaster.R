# telescope-forecaster.R
#' @author Henning Schulz

library(R6)
library(xgboost)
library(cluster)
library(forecast)
library(e1071)
library(sparklyr)
library(tidyverse)

TelescopeForecaster <- R6Class("TelescopeForecaster", inherit = Forecaster, list(
  
  logger = Logger$new("TelescopeForecaster"),
  
  forecast_group = function(group, past_context, future_context, future_timestamps) {
    self$logger$info("Forecasting group ", group, "...")
    
    tvp <- self$past_intensities[[group]]
    
    if (is_empty(past_context)) {
      forecast <- telescope.forecast(tvp = tvp, horizon = length(future_timestamps))
    } else {
      forecast <- telescope.forecast(tvp = tvp, horizon = length(future_timestamps),
                                     hist.covar = past_context,
                                     future.covar = future_context)
    }
    
    tibble(
      timestamp = future_timestamps,
      !!group := forecast$mean
    )
  },
  
  do_forecast = function(context, horizon) {
    self$logger$info("Forecasting the intensities...")
    
    # calculating past context
    past_context <- self$past_intensities %>%
      select(-timestamp, -starts_with("intensity")) %>%
      as.matrix()
    
    # calculating the future context, removing the variables that do no occur in the past
    forecast_start <- self$end_past + self$resolution
    
    if (ncol(past_context) == 0) {
      context <- context %>%
        select(timestamp)
    } else {
      context <- context %>%
        select(timestamp, one_of(colnames(past_context)))
    }
    
    filled_context <- context %>%
      fill_context(forecast_start, horizon, self$resolution)
    
    future_context <- filled_context %>%
      select(-timestamp) %>%
      as.matrix()
    
    # forecast each group and join the results
    groups <- self$past_intensities %>%
      select(starts_with("intensity")) %>%
      names()
    
    self$forecast <- groups %>%
      map(self$forecast_group,
          past_context = past_context, future_context = future_context,
          future_timestamps = filled_context$timestamp) %>%
      reduce(left_join)
    
    self$logger$info("Forecasting done.")
  }
  
))

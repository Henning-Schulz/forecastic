# forecaster.R
#' @author Henning Schulz

library(R6)
library(tidyverse)

#'
#' Abstract forecaster class. Can be extended by forecaster implementations.
#' 
Forecaster <- R6Class("Forecaster",
                      
  private = list(
    logger = Logger$new("Forecaster")
  ),
                      
  public = list(
    
    past_intensities = NULL,
    end_past = NULL,
    resolution = NULL,
    forecast = NULL,
    # TODO: plots etc.
    
    #' Creates a new forecaster and initializes the past intensities by querying the elasticsearch.
    #' 
    #' @param app_id The app_id to be used for getting the intensities.
    #' @param tailoring The tailoring to be used for getting the intensities.
    #' @param context_variables The context variables to be considered. Should match to the variables of the future context.
    #' @param resolution The time difference between two subsequent intensity values in milliseconds.
    #' @param perspective The timestamp to be considered as the latest 'past' timestamp.
    initialize = function(app_id, tailoring, context_variables, resolution, perspective) {
      private$logger$info("Initializing data for forecasting...")
      
      # read intensities from elasticsearch
      intensities <- read_intensities(app_id, tailoring, perspective)
      
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
      
      private$logger$info("Using context variables ", paste(context_variables, collapse = ", "))
      
      intensities <- intensities %>%
        select(timestamp, starts_with("intensity"), one_of(context_variables))
      
      # restrict to past and fill intensities
      start <- intensities %>%
        summarise(val = min(timestamp))
      
      end_past <- intensities %>%
        filter_at(vars(starts_with("intensity")), any_vars(!is.na(.))) %>%
        summarize(val = max(timestamp))
      self$end_past <- end_past$val
      
      # replacing all missing values (intensities and context variables) with 0
      self$past_intensities <- tibble(timestamp = seq(start$val, end_past$val, as.double(resolution))) %>% # as.double prevents integer overflow
        left_join(intensities, by = "timestamp") %>%
        replace(is.na(.), 0)
      
      private$logger$info("Initialization done.")
    },
    
    #' Does the forecast. The implementation depends on the forecaster type.
    #' 
    #' @param context The future context to be considered.
    #' @param horizon The timestamp in milliseconds to which the forecast should reach.
    do_forecast = function(context, horizon) {
      stop("Not implemented!")
    },
    
    #' Gets the forecast in the provided ranges. Requires \code{do_forecast} to be called in advance.
    #' 
    #' @param ranges The ranges as data frame with columns \code{from} and \code{to}.
    range_forecast = function(ranges) {
      ranges %>%
        transpose() %>%
        map(function(range) {
          private$logger$info("Extracting range ", range$from, " - ", range$to)
          self$forecast %>%
            filter(timestamp >= range$from & timestamp <= range$to)
        }) %>%
        reduce(rbind)
    }
  )
  
)

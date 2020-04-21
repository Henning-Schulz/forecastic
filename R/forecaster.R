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
    
    app_id = NULL,
    tailoring = NULL,
    past_intensities = NULL,
    end_past = NULL,
    resolution = NULL,
    forecast = NULL,
    
    #' Creates a new forecaster and initializes the past intensities by querying the elasticsearch.
    #' 
    #' @param app_id The app_id to be used for getting the intensities.
    #' @param tailoring The tailoring to be used for getting the intensities.
    #' @param context_variables The context variables to be considered. Should match to the variables of the future context.
    #' @param resolution The time difference between two subsequent intensity values in milliseconds.
    #' @param perspective The timestamp to be considered as the latest 'past' timestamp.
    #' @param forecast_total Whether the intensities should be summarized and foreasted as total. Defaults to FALSE.
    initialize = function(app_id, tailoring, context_variables, resolution, perspective, forecast_total = F) {
      private$logger$info("Initializing data for forecasting...")
      
      self$app_id <- app_id
      self$tailoring <- tailoring
      
      intensity_buffer <- IntensityBuffer$new()
      intensities <- intensity_buffer$load_intensities(app_id, tailoring, perspective)
      
      if (is.null(intensities)) {
        # read intensities from elasticsearch
        intensities <- read_intensities(app_id, tailoring, perspective)
        intensity_buffer$store_intensities(app_id, tailoring, perspective, intensities)
      }
      
      if (forecast_total) {
        private$logger$info("Summing the intensities to a total one.")
        
        intensities <- intensities %>%
          mutate(total__ = rowSums(select(., starts_with("intensity")), na.rm = T)) %>%
          select(-starts_with("intensity"), intensity.total__ = total__)
      }
      
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
      
      private$logger$info("Using context variables [", paste(context_variables, collapse = ", "), "]")
      
      intensities <- intensities %>%
        select(timestamp, starts_with("intensity"), matches(paste(c(" ", context_variables), collapse = "|")))
      
      # restrict to past and fill intensities
      total_intensities <- intensities %>%
        mutate(intensity = rowSums(select(., starts_with("intensity")), na.rm = T)) %>%
        filter(intensity > 0)
      
      intensity_range <- total_intensities %>%
        summarise(start = min(timestamp), end = max(timestamp))
      
      self$end_past <- intensity_range$end
      
      # replacing all missing values (intensities and context variables) with 0
      self$past_intensities <- tibble(timestamp = seq(intensity_range$start, intensity_range$end, as.double(resolution))) %>% # as.double prevents integer overflow
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

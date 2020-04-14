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
    #' @param plot_dir A directory to store the forecast plot. Not storing the plot if it is \code{NULL} or \code{NA}.
    forecast_group = function(group, past_context, future_context, future_timestamps, plot_dir = NULL) {
      private$logger$info("Forecasting group ", group, "...")
      
      tvp <- self$past_intensities[[group]]
      
      do_plot <- !is.na(plot_dir) && !is.null(plot_dir)
      
      if (do_plot) {
        plot_file <- file.path(plot_dir, str_c(group, ".pdf"))
        private$logger$info("Storing forecasting plot to ", plot_file, ".")
        pdf(file = plot_file, width = 11.35, height = 6.88)
      }
      
      if (is_empty(past_context)) {
        forecast <- telescope.forecast(tvp, horizon = length(future_timestamps), plot = do_plot)
      } else {
        forecast <- telescope.forecast(tvp, horizon = length(future_timestamps), plot = do_plot,
                                       train.covariates = past_context,
                                       future.covariates = future_context)
      }
      
      if (do_plot) {
        dev.off()
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
      plotdir_set <- as.logical(opt$plotdir)
      
      if (is.na(plotdir_set) | plotdir_set) {
        plot_dir <- file.path(
          opt$plotdir,
          str_c("telescope-", self$app_id, ".", self$tailoring, "-", format(lubridate::now(), format = "%Y%m%d-%H%M%S"))
        )
        mkdirs(plot_dir)
      } else {
        plot_dir <- NULL
      }
      
      groups <- self$past_intensities %>%
        select(starts_with("intensity")) %>%
        names()
      
      self$forecast <- groups %>%
        map(private$forecast_group,
            past_context = past_context, future_context = future_context,
            future_timestamps = filled_context$timestamp,
            plot_dir = plot_dir) %>%
        reduce(left_join)
      
      private$logger$info("Forecasting done.")
    }
  )

)

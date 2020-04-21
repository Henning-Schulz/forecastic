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
    #' @param plot_dir A directory to store the forecast plot. Not storing the plot if it is \code{NULL} or \code{NA}.
    forecast_group = function(group, past, future, context_variables, plot_dir = NULL) {
      private$logger$info("Forecasting group ", group, "...")
      
      yearly_seasonality <- if(opt$force_yearly) T else "auto"
      
      m <- prophet(yearly.seasonality = yearly_seasonality, seasonality.mode = opt$seasonality_mode,
                   seasonality.prior.scale = opt$seasonality_prior_scale)
      
      for (variable in context_variables) {
        m <- add_regressor(m, variable, mode = opt$context_mode, prior.scale = opt$context_prior_scale)
      }
      
      m <- fit.prophet(m, past %>% select(ds, y = !!group, one_of(context_variables)))
      forecast <- predict(m, future)
      
      if (!is.na(plot_dir) && !is.null(plot_dir)) {
        plot_file <- file.path(plot_dir, str_c(group, ".pdf"))
        private$logger$info("Storing forecasting plots to ", plot_file, ".")
        
        pdf(file = plot_file, width = 11.35, height = 6.88)
        print(plot(m, forecast))
        prophet_plot_components(m, forecast)
        dev.off()
      }
      
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
      
      if (ncol(past %>% select(-ds, -starts_with("intensity"))) == 0) {
        past_only_context <- tibble(x__ = 0)
      } else {
        # adding past contexts that are missing in the future context
        past_only_context <- setdiff(colnames(self$past_intensities %>% select(-starts_with("intensity"))), colnames(context)) %>%
          map(~ tibble(!!. := 0)) %>%
          reduce(bind_cols) %>%
          mutate(x__ = 0)
      }
      
      future <- context %>%
        mutate(x__ = 0) %>%
        left_join(past_only_context, by = "x__") %>%
        select(-x__) %>%
        fill_context(forecast_start, horizon, self$resolution) %>%
        mutate(ds = as_datetime(timestamp / 1000)) %>%
        select(-timestamp)
      
      # forecast each group and join the results
      plotdir_set <- as.logical(opt$plotdir)
      
      if (is.na(plotdir_set) | plotdir_set) {
        plot_dir <- file.path(
          opt$plotdir,
          str_c("prophet-", self$app_id, ".", self$tailoring, "-", format(lubridate::now(), format = "%Y%m%d-%H%M%S"))
        )
        mkdirs(plot_dir)
      } else {
        plot_dir <- NULL
      }
      
      groups <- self$past_intensities %>%
        select(starts_with("intensity")) %>%
        names()
      
      private$logger$info("Warn message about \"Unknown or uninitialised column: 'y'\" is OK!")
      
      self$forecast <- groups %>%
        map(private$forecast_group,
            past = past, future = future,
            context_variables = context_variables,
            plot_dir = plot_dir) %>%
        reduce(left_join) %>%
        mutate(timestamp = as.numeric(ds) * 1000) %>%
        select(timestamp, starts_with("intensity"))
      
      if (!is.null(plot_dir)) {
        tryCatch(
          {
            private$logger$info("Storing forecast to ", plot_dir, "/forecast.csv.")
            write_csv(self$forecast, file.path(plot_dir, "forecast.csv"))
            
            p <- self$forecast %>%
              gather(starts_with("intensity"), key = "group", value = "intensity") %>%
              mutate(group = str_sub(group, start = 11)) %>%
              ggplot(aes(x = timestamp, y = intensity, color = group, fill = group)) +
              geom_area(position = "stack", alpha = 0.3)
            
            private$logger$info("Storing overall plot to ", plot_dir, "/overall.pdf.")
            ggsave(file.path(plot_dir, "overall.pdf"), plot = p, width = 11.35, height = 6.88, units = "in")
          },
          error = function(e) {
            warn(str_c("Error when saving the overall CSV and plot: ", e$message))
          }
        )
      }
      
      private$logger$info("Forecasting done.")
    }
  )

)


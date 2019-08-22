# plumber.R
#' @author Henning Schulz

logger <- Logger$new(name = "plumber API")

#' Simple health endpoint
#' @get /health
function() {
  "Forecastic is up and running!"
}

#' Create and return an intensity forecast using the passed parameters
#' @post /forecast
function(app_id, tailoring, ranges, context, resolution, approach, aggregation) {
  logger$info("Forecasting ", app_id, ".[", tailoring, "] to range ", min(ranges$from), " - ", max(ranges$to),
                " using ", approach, " and ", aggregation, "...")
  
  context_tibble <- transform_context(context %>% as_tibble())
  
  if (tolower(approach) == "telescope") {
    forecaster <- TelescopeForecaster$new(
      app_id = app_id, tailoring = tailoring, resolution = resolution,
      context_variables = context_tibble %>% select(-timestamp) %>% colnames()
    )
  } else if (tolower(approach) == "prophet") {
    # TODO
  }
  
  forecaster$do_forecast(context = context_tibble, horizon = max(ranges$to))
  
  # TODO: aggregation
  
  logger$info("Returning forecast result for ", app_id, ".[", tailoring, "] with range ", min(ranges$from), " - ", max(ranges$to),
              ", ", approach, ", and ", aggregation, ".")
  
  # TODO: return aggregation result
  forecaster$forecast
}

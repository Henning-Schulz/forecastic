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
function(app_id, tailoring, ranges, context, resolution, approach, aggregation, adjustments) {
  logger$info("Forecasting ", app_id, ".[", tailoring, "] to range ", min(ranges$from), " - ", max(ranges$to),
                " using ", approach, "aggregation ", aggregation$type, " and adjustments [", paste(adjustments$type, collapse = ", "), "]...")
  
  context_tibble <- transform_context(context %>% as_tibble())
  
  if (tolower(approach) == "telescope") {
    forecaster <- TelescopeForecaster$new(
      app_id = app_id, tailoring = tailoring, resolution = resolution,
      context_variables = context_tibble %>% select(-timestamp) %>% colnames()
    )
  } else if (tolower(approach) == "prophet") {
    forecaster <- ProphetForecaster$new(
      app_id = app_id, tailoring = tailoring, resolution = resolution,
      context_variables = context_tibble %>% select(-timestamp) %>% colnames()
    )
  }
  
  forecaster$do_forecast(context = context_tibble, horizon = max(ranges$to))
  
  range_forecast <- forecaster$range_forecast(ranges)
  aggregated_forecast <- aggregate_workload(range_forecast, aggregation)
  result <- adjust_and_finalize_workload(aggregated_forecast, adjustments)
  
  logger$info("Returning forecast result for ", app_id, ".[", tailoring, "].")
  
  result
}

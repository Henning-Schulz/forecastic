# plumber.R

logger <- Logger$new(name = "plumber API")

#' Simple health endpoint
#' @get /health
function() {
  "Forecastic is up and running!"
}

#' Create and return an intensity forecast using the passed parameters
#' @post /forecast
function(req, app_id, tailoring, ranges, ignored_variables, context, resolution, approach, aggregation) {
  logger$info("Forecasting ", app_id, ".[", tailoring, "] to range ", min(ranges$from), " - ", max(ranges$to),
                " using ", approach, " and ", aggregation, "...")
  
  if (tolower(approach) == "telescope") {
    forecaster <- TelescopeForecaster$new(
      app_id = app_id, tailoring = tailoring,
      ignored_variables = ignored_variables, resolution = resolution
    )
  } else if (tolower(approach) == "prophet") {
    # TODO
  }
  
  forecaster$do_forecast(context = context, horizon = max(ranges$to))
  
  forecaster$forecast
  
  # TODO: aggregation
}

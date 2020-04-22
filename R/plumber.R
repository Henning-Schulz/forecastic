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
function(app_id, tailoring, perspective, ranges, forecast_total, context, context_variables, resolution, approach, aggregation, adjustments) {
  logger$info("Forecasting ", app_id, ".[", tailoring, "] with perspective ", perspective, " to range ", min(ranges$from), " - ", max(ranges$to),
              " in resolution ", resolution, " with forecast_total = ", forecast_total,
              " using ", approach, " forecaster, aggregation ", aggregation$type, " and adjustments [", paste(adjustments$type, collapse = ", "), "]...")
  
  context_tibble <- transform_context(context %>% jsonlite::flatten() %>% as_tibble())
  
  if (is.null(context_variables) || length(context_variables) == 0) {
    context_variables <- context_tibble %>% select(-timestamp) %>% colnames()
  }
  
  latest_timestamp <- min(get_latest_timestamp(app_id, tailoring), perspective, na.rm = TRUE)
  horizon <- max(ranges$to)
  
  if (horizon <= latest_timestamp) {
    logger$info("Horizon ", horizon, " is before latest timestamp ", latest_timestamp, ". Defaulting to perfect forecast approach.")
    approach <- "perfect"
  }
  
  if (tolower(approach) == "telescope") {
    forecaster <- TelescopeForecaster$new(
      app_id = app_id, tailoring = tailoring, resolution = resolution,
      context_variables = context_variables,
      perspective, forecast_total
    )
  } else if (tolower(approach) == "prophet") {
    forecaster <- ProphetForecaster$new(
      app_id = app_id, tailoring = tailoring, resolution = resolution,
      context_variables = context_variables,
      perspective, forecast_total
    )
  } else if (tolower(approach) == "perfect") {
    forecaster <- PerfectForecaster$new(
      app_id = app_id, tailoring = tailoring, resolution = resolution,
      context_variables = context_variables,
      horizon, forecast_total
    )
  } else {
    stop("Unknown forecast approach: ", approach)
  }
  
  forecaster$do_forecast(context = context_tibble, horizon = horizon)
  
  range_forecast <- forecaster$range_forecast(ranges)
  aggregated_forecast <- aggregate_workload(range_forecast, aggregation)
  result <- adjust_and_finalize_workload(aggregated_forecast, adjustments)
  
  logger$info("Returning forecast result for ", app_id, ".[", tailoring, "].")
  
  result
}

#' Upload an R snippet as an aggregation
#' @post /aggregation/<name>
function(req, res, name, force = F) {
  force_l <- as.logical(force)
  
  if (is.na(force_l)) {
    res$status <- 400
    list(error=jsonlite::unbox(str_c("Cannot interpret force=", force)))
  } else if (name %in% str_sub(list.files("aggregations"), end = -3) && !force_l) {
    res$status <- 400
    list(error=jsonlite::unbox("Aggregation already exists! Use ?force=true to overwrite the existing one."))
  } else {
    logger$info("Storing new aggregation with name ", name, ".")
    
    write_lines(req$postBody, file.path("aggregations", str_c(name, ".R")))
    list(message=jsonlite::unbox("Aggregation can now be used."))
  }
}

#' Upload an R snippet as an adjustment
#' @post /adjustment/<name>
function(req, res, name, force = F) {
  force_l <- as.logical(force)
  
  if (is.na(force_l)) {
    res$status <- 400
    list(error=jsonlite::unbox(str_c("Cannot interpret force=", force)))
  } else if (name %in% str_sub(list.files("adjustments"), end = -3) && !force_l) {
    res$status <- 400
    list(error=jsonlite::unbox("Adjustment already exists! Use ?force=true to overwrite the existing one."))
  } else {
    logger$info("Storing new adjustment with name ", name, ".")
    
    write_lines(req$postBody, file.path("adjustments", str_c(name, ".R")))
    list(message=jsonlite::unbox("Adjustment can now be used."))
  }
}

# plumber.R

#' Simple health endpoint
#' @get /health
function() {
  "Forecastic is up and running!"
}

#' Forecast the passed intensities
#' @param foo part of the body
#' @post /forecast
function(req, app_id, tailoring, consider, forecast, approach, aggregation) {
  message(str_c("Forecasting ",
                app_id, ".[", tailoring,
                "] data in range ", consider$from, " - ", consider$to,
                " to range ", forecast$from, " - ", forecast$to,
                " using ", approach,
                " and ", aggregation, "..."))
  
  # TODO: list of timestamps + list of intensities per group + lists of comntext variables?
  
  list(
    "timestamps" = forecast$from,
    "0" = 42
  )
}
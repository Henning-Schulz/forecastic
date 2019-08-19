# telescope-forecaster.R

library(R6)

TelescopeForecaster <- R6Class("TelescopeForecaster", inherit = Forecaster, list(
  
  do_forecast = function(context, horizon) {
    # TODO
    self$forecast <- tibble(timestamp = horizon, intensity.0 = 42, intensity.1 = 73)
  }
  
))

function() {
  # for filling missing values:
  
  start_time <- raw_data %>% summarise(val = min(timestamp))
  end_time <- raw_data %>% summarize(val = max(timestamp))
  
  intensities <- tibble(timestamp = seq(start_time$val, end_time$val, resolution)) %>%
    left_join(intensities, by = "timestamp") %>%
    fill(starts_with("intensity"))
  
  # for getting all intensity columns
  intensities %>%
    select(starts_with("intensity")) %>%
    names()
}

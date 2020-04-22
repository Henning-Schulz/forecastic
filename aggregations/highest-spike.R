# highest-spike.R

library(tibbletime)
library(lubridate)

do_aggregation <- function(intensities, behavior = NULL, properties = NULL) {
  if (!is.null(properties) & !is.null(properties$window)) {
    window_duration <- as.duration(properties$window)
  } else {
    window_duration <- duration(31, "minutes")
  }
  
  resolution <- intensities %>%
    mutate(time_diff = timestamp - lag(timestamp)) %>%
    summarize(value = max(time_diff, na.rm = T)) %>%
    .$value
  
  rolling_window <- as.numeric(window_duration) * 1000 / resolution
  
  if (rolling_window %% 2 == 0) {
    message("[highest-spike.R] Using window size ", (rolling_window + 1), " instead of even size ", rolling_window, ".")
    rolling_window <- rolling_window + 1
  }
  
  prepared <- intensities %>%
    mutate(sum = rowSums(.[2:ncol(intensities)])) %>%
    mutate(rolling_mean = lead(rollify(mean, window = rolling_window)(sum), n = rolling_window %/% 2)) %>%
    mutate(derivative = rolling_mean - lag(rolling_mean)) %>%
    drop_na()
  
  changepoint <- prepared %>%
    filter(rolling_mean == max(rolling_mean)) %>%
    .$timestamp
  
  peak_area_start <- prepared %>%
    filter(timestamp < changepoint & derivative < 0) %>%
    summarize(max = max(timestamp)) %>%
    .$max
  
  peak_timestamp <- prepared %>%
    filter(timestamp >= peak_area_start & timestamp <= changepoint) %>%
    filter(derivative == max(derivative)) %>%
    .$timestamp
  
  threshold <- prepared %>%
    summarise(value = max(derivative) * 0.1) %>%
    .$value
  
  before_spike <- prepared %>%
    filter(timestamp < peak_timestamp & derivative <= threshold) %>%
    summarize(max = max(timestamp)) %>%
    .$max
  
  after_peak <- prepared %>%
    filter(timestamp > peak_timestamp & derivative < -threshold) %>%
    summarize(min = min(timestamp)) %>%
    .$min
  
  after_spike <- prepared %>%
    filter(timestamp > after_peak & derivative >= -threshold) %>%
    summarize(min = min(timestamp)) %>%
    .$min
  
  intensities %>%
    filter(timestamp > before_spike & timestamp < after_spike)
}

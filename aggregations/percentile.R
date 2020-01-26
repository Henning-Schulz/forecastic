# percentile.R

do_aggregation <- function(intensities, behavior = NULL, properties = NULL) {
  if (!is.null(properties) & !is.null(properties$p)) {
    p <- properties$p
  } else {
    message("[percentile.R] No percentile specified! Using default 0.9.")
    p <- 0.9
  }
  
  if (p > 1) {
    p <- p / 100
  }
  
  intensities %>%
    mutate(sum = rowSums(.[2:ncol(intensities)])) %>%
    mutate(
      perc = quantile(sum, p),
      diff_to_perc = abs(sum - perc)
    ) %>%
    filter(diff_to_perc == min(diff_to_perc)) %>%
    filter(row_number() == 1) %>%
    select(-sum, -perc, -diff_to_perc)
}

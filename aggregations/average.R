# average.R

aggregation_requires_behavior <- FALSE

do_aggregation <- function(intensities, behavior = NULL) {
  intensities %>%
    mutate(sum = rowSums(.[2:ncol(intensities)])) %>%
    mutate(
      avg = mean(sum),
      diff_to_avg = abs(sum - avg)
      ) %>%
    filter(diff_to_avg == min(diff_to_avg)) %>%
    filter(row_number() == 1) %>%
    mutate_at(vars(starts_with("intensity")), ~ . * avg / sum) %>%
    select(-sum, -avg, -diff_to_avg)
}

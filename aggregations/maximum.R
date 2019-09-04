# maximum.R

do_aggregation <- function(intensities, behavior = NULL, properties = NULL) {
  intensities %>%
    mutate(sum = rowSums(.[2:ncol(intensities)])) %>%
    filter(sum == max(sum)) %>%
    filter(row_number() == 1) %>%
    select(-sum)
}

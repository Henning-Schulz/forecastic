# maximum.R

adjustment_requires_behavior <- FALSE

do_adjustment <- function(intensities, behavior = NULL, properties) {
  amount <- properties$amount
  group <- properties$group
  
  add_fun <- function(x) (x + amount)
  
  if (is.null(group)) {
    intensities %>%
      mutate_at(vars(starts_with("intensity")), add_fun)
  } else {
    intensities %>%
      mutate_at(vars(matches(str_c("intensity\\.", group))), add_fun)
  }
}

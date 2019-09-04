# maximum.R

adjustment_requires_behavior <- FALSE

do_adjustment <- function(intensities, behavior = NULL, properties) {
  factor <- properties$factor
  group <- properties$group
  
  mult_fun <- function(x) (x * factor)
  
  if (is.null(group)) {
    intensities %>%
      mutate_at(vars(starts_with("intensity")), mult_fun)
  } else {
    intensities %>%
      mutate_at(vars(matches(str_c("intensity\\.", group))), mult_fun)
  }
}

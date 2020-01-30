# utils.R
#' @author Henning Schulz

#' Transforms a JSON formatted context (provided as tibble) into a clean tibble
#' with one column per context variable / value in the string case.
#' 
#' @param context_json The JSON formatted context.
transform_context <- function(context_json) {
  if (is_empty(context_json)) {
    tibble(timestamp = double())
  } else {
    context_json <- context_json %>%
      rename_at(vars(starts_with("context.")), list(~ str_sub(., start = 9)))
    
    message("Transforming numeric...")
    
    clean_context <- context_json %>%
      select(timestamp, starts_with("numeric")) %>%
      rename_at(vars(starts_with("numeric")), list(~ str_sub(., start = 9)))
    
    if (context_json %>% select(starts_with("string")) %>% ncol() > 0) {
      message("Transforming string...")
      
      string_context <- context_json %>%
        select(timestamp, starts_with("string")) %>%
        rename_at(vars(starts_with("string")), list(~ str_sub(., start = 8))) %>%
        gather(-timestamp, key = "name", value = "value") %>%
        drop_na() %>%
        unite("var", name, value, sep = ".") %>%
        mutate(tmp = 1) %>%
        spread(key = var, value = tmp)
      
      if (string_context %>% nrow() > 0) {
        clean_context <- clean_context %>%
          left_join(string_context, by = "timestamp")
      }
    }
    
    if ("boolean" %in% colnames(context_json)) {
      message("Transforming boolean...")
      
      boolean_context <- context_json %>%
        select(timestamp, boolean) %>%
        mutate_if(is.list, map, as_data_frame) %>%
        unnest_legacy() %>% # legacy is faster
        mutate(tmp = 1) %>%
        spread(key = value, value = tmp)
      
      clean_context <- clean_context %>%
        left_join(boolean_context, by = "timestamp")
    }
    
    message("Transformation done.")
    
    clean_context
  }
}

#' Fills the missing values of a clean context tibble (formatted using \code{transform_context}).
#' It will contain all timestamps in the provided ranges and all \code{NA}s will be replaced by 0.
#' 
#' @param context The context to be filled.
#' @param from The start timestamp in milliseconds.
#' @param to The end timestamp in milliseconds.
#' @param resolution The distance between two timestamps in milliseconds.
fill_context <- function(context, from, to, resolution) {
  tibble(timestamp = seq(from, to, as.double(resolution))) %>% # as.double prevents integer overflow
    left_join(context, by = "timestamp") %>%
    replace(is.na(.), 0)
}

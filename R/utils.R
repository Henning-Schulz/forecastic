# utils.R
#' @author Henning Schulz

transform_context <- function(context_json) {
  if (is_empty(context_json)) {
    tibble(timestamp = double())
  } else {
    clean_context <- context_json %>%
      select(timestamp)
    
    if ("numeric" %in% colnames(context_json)) {
      context_json <- context_json %>% rename(context.numeric = numeric)
    }
    
    if ("string" %in% colnames(context_json)) {
      context_json <- context_json %>% rename(context.string = string)
    }
    
    if ("boolean" %in% colnames(context_json)) {
      context_json <- context_json %>% rename(context.boolean = boolean)
    }
    
    if ("context.numeric" %in% colnames(context_json)) {
      numeric_context <- context_json %>%
        select(timestamp, context.numeric) %>%
        mutate_if(is.list, map, as_data_frame) %>%
        unnest() %>%
        spread(key = name, value = value)
      
      clean_context <- clean_context %>%
        left_join(numeric_context, by = "timestamp")
    }
    
    if ("context.string" %in% colnames(context_json)) {
      string_context <- context_json %>%
        select(timestamp, context.string) %>%
        mutate_if(is.list, map, as_data_frame) %>%
        unnest() %>%
        unite("var", name, value, sep = ".") %>%
        mutate(tmp = 1) %>%
        spread(key = var, value = tmp)
      
      clean_context <- clean_context %>%
        left_join(string_context, by = "timestamp")
    }
    
    if ("context.boolean" %in% colnames(context_json)) {
      boolean_context <- context_json %>%
        select(timestamp, context.boolean) %>%
        mutate_if(is.list, map, as_data_frame) %>%
        unnest() %>%
        mutate(tmp = 1) %>%
        spread(key = value, value = tmp)
      
      clean_context <- clean_context %>%
        left_join(boolean_context, by = "timestamp")
    }
    
    clean_context
  }
}

fill_context <- function(context, from, to, resolution) {
  tibble(timestamp = seq(from, to, resolution)) %>%
    left_join(context, by = "timestamp") %>%
    replace(is.na(.), 0)
}
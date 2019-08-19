# elastic-client.R

library(elasticsearchr)
library(stringr)

read_intensities <- function(app_id, tailoring) {
  raw_data <- elastic(cluster_url = str_c("http://", opt$elastic, ":9200"), index = str_c(app_id, ".", tailoring, ".intensity")) %search%
    query('{
             "match_all": {}
           }') %>%
    as_tibble()
  
  intensities <- raw_data %>%
    select(timestamp, starts_with("intensity"))
  
  if ("context.numeric" %in% colnames(raw_data)) {
    numeric_context <- raw_data %>%
      select(timestamp, context.numeric) %>%
      mutate_if(is.list, map, as_data_frame) %>%
      unnest() %>%
      spread(key = name, value = value)
    
    intensities <- intensities %>%
      left_join(numeric_context, by = "timestamp")
  }
  
  if ("context.string" %in% colnames(raw_data)) {
    string_context <- raw_data %>%
      select(timestamp, context.string) %>%
      mutate_if(is.list, map, as_data_frame) %>%
      unnest() %>%
      unite("var", name, value, sep = ".") %>%
      mutate(tmp = 1) %>%
      spread(key = var, value = tmp)
    
    intensities <- intensities %>%
      left_join(string_context, by = "timestamp")
  }
  
  if ("context.boolean" %in% colnames(raw_data)) {
    boolean_context <- raw_data %>%
      select(timestamp, context.boolean) %>%
      mutate_if(is.list, map, as_data_frame) %>%
      unnest() %>%
      mutate(tmp = 1) %>%
      spread(key = value, value = tmp)
    
    intensities <- intensities %>%
      left_join(boolean_context, by = "timestamp")
  }
  
  intensities %>%
    arrange(timestamp)
}

# logger.R

library(R6)

Logger <- R6Class("Logger", list(
  name = NULL,
  
  initialize = function(name) {
    self$name <- name
  },
  
  info = function(...) {
    message(now(), " INFO [", self$name, "] ", ...)
  },
  
  warn = function(...) {
    message(now(), " WARN [", self$name, "] ", ...)
  },
  
  error = function(...) {
    message(now(), " ERROR [", self$name, "] ", ...)
  }
  
))

generic_logger <- Logger$new("generic")
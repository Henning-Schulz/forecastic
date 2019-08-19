# logger.R
#' @author Henning Schulz

library(R6)

#'
#' A simple logger printing messages in the format
#' \code{timestamp SEVERITY [name] message}.
#'
Logger <- R6Class("Logger", list(
  name = NULL,
  
  #' Initializes the logger.
  #' 
  #' @param name The name to be printed in each log message.
  initialize = function(name) {
    self$name <- name
  },
  
  #' Prints an info message.
  info = function(...) {
    message(now(), " INFO [", self$name, "] ", ...)
  },
  
  #' Prints a warn message.
  warn = function(...) {
    message(now(), " WARN [", self$name, "] ", ...)
  },
  
  #' Prints an error message.
  error = function(...) {
    message(now(), " ERROR [", self$name, "] ", ...)
  }
  
))

generic_logger <- Logger$new("generic")
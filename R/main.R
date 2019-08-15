# main.R
# Assumes the working directory is the root folder of the forecastic project.
# If this is not the case, set it using setwd("/your/path/to/forecastic")

source("R/install-packages.R")
source("R/eureka-client.R")

library(plumber)
library(optparse)

dir.create("logs", showWarnings = FALSE)

option_list <- list(
  make_option(c("--port"), type = "integer", default = 7955),
  make_option(c("--host"), type = "character", default = "127.0.0.1"),
  make_option(c("--eureka"), type = "character", default = "localhost")
)

opt_parser = OptionParser(option_list = option_list)
opt = parse_args(opt_parser)

pr <- plumber::plumb("R/plumber.R")

eureka_set <- as.logical(opt$eureka)

if (is.na(eureka_set) | eureka_set)  {
  eureka <- EurekaClient$new(eureka_host = opt$eureka, local_host = opt$host, local_port = opt$port)
  
  pr$registerHook("exit", function() {
    eureka$unregister()
  })
  
  eureka$register()
} else {
  message("Not using Eureka")
}

pr$run(port = opt$port, host = opt$host, swagger = TRUE)

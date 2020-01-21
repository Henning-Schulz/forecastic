# main.R
# Assumes the working directory is the root folder of the forecastic project.
# If this is not the case, set it using setwd("/your/path/to/forecastic")
#' @author Henning Schulz

source("R/install-packages.R")
source("R/utils.R")
source("R/logger.R")
source("R/eureka-client.R")
source("R/elastic-client.R")
source("R/forecaster.R")
source("R/telescope-forecaster.R")
source("R/prophet-forecaster.R")
source("R/perfect-forecaster.R")
source("R/aggregation.R")
source("R/adjustment.R")

library(plumber)
library(optparse)

dir.create("logs", showWarnings = FALSE)

option_list <- list(
  make_option(c("--port"), type = "integer", default = 7955,
              help = "The port of the started Rest API."),
  make_option(c("--host"), type = "character", default = "127.0.0.1",
              help = "The host name or IP to be used to access the Rest API."),
  make_option(c("--eureka"), type = "character", default = FALSE,
              help = "The host name or IP of the Eureka server. Use F for not registering at Eureka (the default)."),
  make_option(c("--name"), type = "character", default = "127.0.0.1",
              help = "The name to use fore registering at Eureka."),
  make_option(c("--elastic"), type = "character", default = "localhost",
              help = "The host name or IP of the elasticsearch database.")
)

opt_parser = OptionParser(option_list = option_list)
opt = parse_args(opt_parser)

pr <- plumber::plumb("R/plumber.R")

eureka_set <- as.logical(opt$eureka)

if (is.na(eureka_set) | eureka_set)  {
  eureka <- EurekaClient$new(eureka_host = opt$eureka, local_host = opt$host, local_port = opt$port, name = opt$name)
  
  pr$registerHook("exit", eureka$unregister)
  
  eureka$register()
} else {
  generic_logger$info("Not using Eureka")
}

if (opt$host == "127.0.0.1") {
  plumber_ip <- "127.0.0.1"
} else {
  plumber_ip <- "0.0.0.0"
}

pr$run(port = opt$port, host = plumber_ip, swagger = TRUE)

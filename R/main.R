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
source("R/intensity-buffer.R")
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
              help = "The host name or IP of the elasticsearch database."),
  make_option(c("--plotdir"), type = "character", default = FALSE,
              help = "A directory where to store plots vizualizing the forecasts. Use F for not storing any plots (the default)."),
  make_option(c("--buffer"), type = "character", default = FALSE,
              help = "A directory where to buffer intensities. Use F for disabling the buffer (the default)."),
  make_option(c("--telescope-regressor"), type = "character", default = "XGBoost", dest = "telescope_regressor",
              help = "The regressor telescope should use for the covariates. Can be XGBoost (the default), RandomForest, or SVM."),
  make_option(c("--force-yearly-seasonality"), type = "logical", action = "store_true", default = FALSE, dest = "force_yearly",
              help = "Whether finding a yearly seasonality should be foced. Only available for prophet. Disabled by default."),
  make_option(c("--seasonality-mode"), type = "character", default = "additive", dest = "seasonality_mode",
              help = "The seasonality mode - additive (the default) or multiplicative. Only available for prophet."),
  make_option(c("--seasonality-prior-scale"), type = "double", default = 10, dest = "seasonality_prior_scale",
              help = "Modulates the strength of the seasonality model. Larger values allow the model to fit larger seasonal fluctuations, smaller values dampen the seasonality. Only available for prohpet."),
  make_option(c("--context-mode"), type = "character", default = "additive", dest = "context_mode",
              help = "Similar to --seasonality-mode, but for context variables. Only available for prophet."),
  make_option(c("--context-prior-scale"), type = "double", default = 10, dest = "context_prior_scale",
              help = "Similar to --seasonality-prior-scale, but for context variables. Only available for prohpet.")
)

opt_parser = OptionParser(option_list = option_list)
opt = parse_args(opt_parser)

message("Running with options ", paste(str_c(names(opt), opt, sep = "="), collapse = ", "))

if (!(opt$telescope_regressor %in% c("XGBoost", "RandomForest", "SVM"))) {
  stop("Unknown telescope regressor (", opt$telescope_regressor, ")! Needs to be one of XGBoost (the default), RandomForest, SVM.")
}

if (!(opt$seasonality_mode %in% c("additive", "multiplicative"))) {
  stop("Unknown seasonality mode (", opt$seasonality_mode, ")! Needs to be one of additive, multiplicative.")
}

if (!(opt$context_mode %in% c("additive", "multiplicative"))) {
  stop("Unknown context mode (", opt$seasonality_mode, ")! Needs to be one of additive, multiplicative.")
}

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

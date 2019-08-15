# erueka-heartbeat.R

suppressWarnings(suppressMessages(library(optparse)))
suppressWarnings(suppressMessages(library(httr)))
suppressWarnings(suppressMessages(library(stringr)))
suppressWarnings(suppressMessages(library(lubridate)))

option_list <- list(
  make_option(c("--port"), type = "integer", default = 7955),
  make_option(c("--host"), type = "character", default = "127.0.0.1"),
  make_option(c("--eureka"), type = "character", default = "localhost")
)

opt_parser = OptionParser(option_list = option_list)
opt = parse_args(opt_parser)

send_heartbeat <- function() {
  response <- PUT(url = str_c("http://", opt$eureka, ":8761/eureka/apps/forecastic/", opt$host, ":forecastic:", opt$port))
  message(str_c("[", now(), "] Sent heartbeat to Eureka (", opt$eureka, "). Response was: ", response$status_code))
}

send_heartbeat()

Sys.sleep(30)

send_heartbeat()
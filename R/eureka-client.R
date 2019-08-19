# eureka.R
#' @author Henning Schulz

library(R6)
library(httr)
library(stringr)
library(cronR)
library(lubridate)

#'
#' A simple Eureka client (de-) registering at a Eureka server.
#' It will use a cron job to send the heartbeats.
#'
EurekaClient <- R6Class("EurekaClient", list(
  host = NULL,
  local_host = NULL,
  local_port = NULL,
  template_file = "resources/eureka-register.json",
  cron_cmd = NULL,
  cron_id = NULL,
  logger = Logger$new(name = "EurekaClient"),
  
  #' Initializes the client.
  #' 
  #' @param eureka_host The host name of the Eureka server.
  #' @param local_host The host name of the process to register.
  #' @param local_port The port number of the process to register.
  initialize = function(eureka_host, local_host, local_port) {
    self$host <- eureka_host
    self$local_host <- local_host
    self$local_port <- as.character(local_port)
    self$cron_cmd <- cron_rscript(rscript = str_c(getwd(), "/R/eureka-heartbeat.R"),
                                  rscript_log = str_c(getwd(), "/logs/eureka-heartbeat.log"),
                                  rscript_args = str_c("--host ", local_host, " --port ", local_port, " --eureka ", eureka_host))
    self$cron_id <- str_c("eureka-heartbeat-", local_host, "-", local_port)
  },
  
  #' Registers at the Eureka server.
  register = function() {
    self$logger$info("Registering at Eureka: ", self$host, "...")
    
    pause_seconds <- (30 - second(now())) %% 60
    self$logger$info("Waiting for ", pause_seconds, " s to ensure the Eureka renewals will be on time...")
    Sys.sleep(pause_seconds)
    
    body <- readChar(self$template_file, file.info(self$template_file)$size)
    body <- str_replace_all(body, "\\$\\{host\\}", self$local_host)
    body <- str_replace_all(body, "\\$\\{port\\}", self$local_port)
    
    response <- POST(url = str_c("http://", self$host, ":8761/eureka/apps/forecastic"), body = body,
                     content_type("application/json"))
    
    if (response$status_code == 204) {
      self$logger$info("Eureka registration successful.")
      
      cron_add(self$cron_cmd, frequency = "minutely", id = self$cron_id,
               description = "Sending a Eureka heartbeat each 30 s for the forecastic service.")
    } else {
      self$logger$error("Could not properly register at Eureka! Response was ", response$status_code)
    }
  },
  
  #' Unregisters from the Eureka server.
  unregister = function() {
    self$logger$info("Unregistering from Eureka: ", self$host, "...")
    
    cron_rm(id = self$cron_id)
    
    response <- DELETE(url = str_c("http://", self$host, ":8761/eureka/apps/forecastic/", self$local_host, ":forecastic:", self$local_port))
    
    if (response$status_code == 200) {
      self$logger$info("Eureka unregistration successful.")
    } else {
      self$logger$error("Could not properly unregister from Eureka! Response was ", response$status_code)
    }
  }
))

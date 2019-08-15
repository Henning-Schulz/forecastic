# eureka.R

library(R6)
library(httr)
library(stringr)
library(cronR)

EurekaClient <- R6Class("EurekaClient", list(
  host = NULL,
  local_host = NULL,
  local_port = NULL,
  template_file = "resources/eureka-register.json",
  cron_cmd = NULL,
  cron_id = NULL,
  
  initialize = function(eureka_host, local_host, local_port) {
    self$host <- eureka_host
    self$local_host <- local_host
    self$local_port <- as.character(local_port)
    self$cron_cmd <- cron_rscript(rscript = str_c(getwd(), "/R/eureka-heartbeat.R"),
                                  rscript_log = str_c(getwd(), "/logs/eureka-heartbeat.log"),
                                  rscript_args = str_c("--host ", local_host, " --port ", local_port, " --eureka ", eureka_host))
    self$cron_id <- str_c("eureka-heartbeat-", local_host, "-", local_port)
  },
  
  register = function() {
    message(str_c("Registering at Eureka: ", self$host, "..."))
    
    body <- readChar(self$template_file, file.info(self$template_file)$size)
    body <- str_replace_all(body, "\\$\\{host\\}", self$local_host)
    body <- str_replace_all(body, "\\$\\{port\\}", self$local_port)
    
    response <- POST(url = str_c("http://", self$host, ":8761/eureka/apps/forecastic"), body = body,
                     content_type("application/json"))
    
    if (response$status_code == 204) {
      message("Eureka registration successful.")
      
      cron_add(self$cron_cmd, frequency = "minutely", id = self$cron_id,
               description = "Sending a Eureka heartbeat each 30 s for the forecastic service.")
    } else {
      message(str_c("ERROR Could not properly register at Eureka! Response was ", response$status_code))
    }
  },
  
  unregister = function() {
    message(str_c("Unregistering from Eureka: ", self$host, "..."))
    
    cron_rm(id = self$cron_id)
    
    response <- DELETE(url = str_c("http://", self$host, ":8761/eureka/apps/forecastic/", self$local_host, ":forecastic:", self$local_port))
    
    if (response$status_code == 200) {
      message("Eureka unregistration successful.")
    } else {
      message(str_c("ERROR Could not properly unregister from Eureka! Response was ", response$status_code))
    }
  }
))

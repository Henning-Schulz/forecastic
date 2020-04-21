# intensity-buffer.R
#' @author Henning Schulz

library(R6)

#'
#' Simple buffer storing intensities in CSV files on the local disk.
#'
IntensityBuffer <- R6Class("IntensityBuffer",
  
  private = list(
   logger = Logger$new("Forecaster"),
   
   format_perspective = function(perspective) {
     if (is.null(perspective) || is.na(perspective)) {
       "latest"
     } else {
       perspective
     }
   },
   
   as_filename = function(app_id, tailoring, perspective) {
     dir.create(self$buffer_dir, recursive = T)
     file.path(self$buffer_dir, str_c("intensity_", app_id, "_", tailoring, "_", perspective, ".csv"))
   }
  ),
  
  public = list(
    
    enabled = F,
    buffer_dir = NULL,
    
    #' Creates a new instance.
    #' 
    #' @param buffer_dir The directory where to buffer the data. Can be \code{F(ALSE)}, disabling buffering. Defaults to \code{opt$buffer}.
    initialize = function(buffer_dir = opt$buffer) {
      do_buffer <- as.logical(buffer_dir)
      self$enabled <- is.na(do_buffer) | do_buffer
      self$buffer_dir <- buffer_dir
    },
    
    #' Loads the intensities.
    #' 
    #' @param app_id The app_id used for getting the intensities from the elasticsearch.
    #' @param tailoring The tailoring used for getting the intensities from the elasticsearch.
    #' @param perspective The timestamp considered as the latest 'past' timestamp.
    #' @return The loaded intensities or \code{NULL} if no buffered intensities are available.
    load_intensities = function(app_id, tailoring, perspective) {
      if (self$enabled) {
        perspective <- private$format_perspective(perspective)
        
        private$logger$info("Trying to load buffered intensities for ", app_id, ".", tailoring, " with perspective ", perspective, "...")
        filename <- private$as_filename(app_id, tailoring, perspective)
        
        if (file.exists(filename)) {
          private$logger$info("Buffered intensities exist. Loading them.")
          read_csv(filename, col_types = cols(.default = col_double()))
        } else {
          private$logger$info("Could not find buffered intensities.")
          NULL
        }
      } else {
        private$logger$info("Buffering is disabled; therefore, returning NULL.")
        NULL
      }
    },
    
    #' Stores intensities.
    #' 
    #' @param app_id The app_id used for getting the intensities from the elasticsearch.
    #' @param tailoring The tailoring used for getting the intensities from the elasticsearch.
    #' @param perspective The timestamp considered as the latest 'past' timestamp.
    #' @param intensities The intensities to be stored.
    store_intensities = function(app_id, tailoring, perspective, intensities) {
      if (self$enabled) {
        perspective <- private$format_perspective(perspective)
        private$logger$info("Buffering intensities for ", app_id, ".", tailoring, " with perspective ", perspective, "...")
        write_csv(intensities, private$as_filename(app_id, tailoring, perspective))
      } else {
        private$logger$info("Buffering is disabled; therefore, not storing the intensities.")
      }
    }
    
  )
  
)
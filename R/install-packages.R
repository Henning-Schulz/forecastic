# install-packages.R
#' @author Henning Schulz

if (!require(plumber)) {
  install.packages("plumber", repos = "http://cran.us.r-project.org")
}

if (!require(optparse)) {
  install.packages("optparse", repos = "http://cran.us.r-project.org")
}

if (!require(jsonlite)) {
  install.packages("jsonlite", repos = "http://cran.us.r-project.org")
}

if (!require(tidyverse)) {
  install.packages("tidyverse", repos = "http://cran.us.r-project.org")
}

if (!require(cronR)) {
  install.packages("cronR", repos = "http://cran.us.r-project.org")
}

if (!require(elasticsearchr)) {
  install.packages("elasticsearchr", repos = "http://cran.us.r-project.org")
}

if (!require(xgboost)) {
  install.packages("xgboost", repos = "http://cran.us.r-project.org")
}

if (!require(cluster)) {
  install.packages("cluster", repos = "http://cran.us.r-project.org")
}

if (!require(forecast)) {
  install.packages("forecast", repos = "http://cran.us.r-project.org")
}

if (!require(e1071)) {
  install.packages("e1071", repos = "http://cran.us.r-project.org")
}

if (!require(sparklyr)) {
  install.packages("sparklyr", repos = "http://cran.us.r-project.org")
}

source("telescope/telescope.R")
source("telescope/cluster_periods.R")
source("telescope/detect_anoms.R")
source("telescope/fitting_models.R")
source("telescope/frequency.R")
source("telescope/outlier.R")
source("telescope/telescope_Utils.R")
source("telescope/vec_anom_detection.R")
source("telescope/xgb.R")

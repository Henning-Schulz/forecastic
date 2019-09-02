# install-packages.R
#' @author Henning Schulz

if (!require(plumber)) {
  install.packages("plumber", repos = "https://cloud.r-project.org/")
}

if (!require(optparse)) {
  install.packages("optparse", repos = "https://cloud.r-project.org/")
}

if (!require(jsonlite)) {
  install.packages("jsonlite", repos = "https://cloud.r-project.org/")
}

if (!require(tidyverse)) {
  install.packages("tidyverse", repos = "https://cloud.r-project.org/")
}

if (!require(cronR)) {
  install.packages("cronR", repos = "https://cloud.r-project.org/")
}

if (!require(elasticsearchr)) {
  install.packages("elasticsearchr", repos = "https://cloud.r-project.org/")
}

if (!require(xgboost)) {
  install.packages("xgboost", repos = "https://cloud.r-project.org/")
}

if (!require(cluster)) {
  install.packages("cluster", repos = "https://cloud.r-project.org/")
}

if (!require(forecast)) {
  install.packages("forecast", repos = "https://cloud.r-project.org/")
}

if (!require(e1071)) {
  install.packages("e1071", repos = "https://cloud.r-project.org/")
}

if (!require(sparklyr)) {
  install.packages("sparklyr", repos = "https://cloud.r-project.org/")
}

if (!require(prophet)) {
  install.packages("prophet", type = "source", repos = "https://cloud.r-project.org/")
}

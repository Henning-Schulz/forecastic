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

if (!require(devtools)) {
  install.packages("devtools", repos = "https://cloud.r-project.org/")
}

if (!require(telescope)) {
  devtools::install_github("DescartesResearch/telescope", ref="test_multivariate")
}

if (!require(prophet)) {
  install.packages("prophet", type = "source", repos = "https://cloud.r-project.org/")
}

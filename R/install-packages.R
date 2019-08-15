# install-packages.R

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
# This file is part of the standard setup for testthat.
# It is recommended that you do not modify it.
#
# Where should you do additional test configuration?
# Learn more about the roles of various files in:
# * https://r-pkgs.org/testing-design.html#sec-tests-files-overview
# * https://testthat.r-lib.org/articles/special-files.html

library(testthat)
library(gsm.kri)
library(gsm.mapping)
library(gsm.reporting)
library(gsm.kri)
library(dplyr)
library(purrr)
library(tidyr)
library(cli)
library(glue)
library(yaml)
library(stringr)

test_check("gsm.kri")

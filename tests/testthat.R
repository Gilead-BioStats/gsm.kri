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

source(system.file(
  "tests",
  "testthat",
  "qual_data.R",
  package = "gsm.kri"
))
source(system.file(
  "tests",
  "testthat",
  "helper-StudyInfo.R",
  package = "gsm.kri"
))
source(system.file(
  "tests",
  "testthat",
  "helper-qualification.R",
  package = "gsm.kri"
))

test_check("gsm.kri")

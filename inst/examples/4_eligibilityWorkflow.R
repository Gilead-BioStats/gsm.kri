library(gsm.datasim)
library(gsm.mapping)
library(gsm.reporting)
library(gsm.core)
library(gsm.kri)
library(purrr)
library(dplyr)
devtools::load_all(".")

# Single Study
example_lparams <- gsm.qtl:::example_lparams

example_lparams$dfResults <- example_lparams$dfResults %>%
  filter(MetricID %in% "Analysis_qtl0001") %>%
  mutate(MetricID = "CTQ_eligibility")

example_lparams$dfMetrics <- example_lparams$dfMetrics %>%
  filter(MetricID %in% "Analysis_qtl0001") %>%
  mutate(MetricID = "CTQ_eligibility")

example_lparams$lListings <- list(
  CTQ = example_lparams$lListings$qtl0001
)

gsm.kri::RenderRmd(
  lParams = example_lparams,
  strOutputDir = getwd(),
  strOutputFile = "test.html",
  strInputPath = system.file("report/eligibility.Rmd", package = "gsm.kri")
)

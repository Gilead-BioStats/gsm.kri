library(gsm.core)
library(gsm.kri)
library(here)


## Country Report
lCharts_country <- gsm.kri::MakeCharts(
  dfResults = gsm.core::reportingResults_country,
  dfGroups = gsm.core::reportingGroups_country,
  dfMetrics = gsm.core::reportingMetrics_country,
  dfBounds = gsm.core::reportingBounds_country
)

gsm.kri::Report_KRI(
  lCharts = lCharts_country,
  dfResults =  gsm.kri::FilterByLatestSnapshotDate(gsm.core::reportingResults_country),
  dfGroups =  gsm.core::reportingGroups_country,
  dfMetrics = gsm.core::reportingMetrics_country,
  strOutputDir = here::here("inst", "examples", "output"),
  strOutputFile = "report_kri_country.html"
)



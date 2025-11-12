library(gsm.core)
library(gsm.kri)
library(here)

lCharts <- gsm.kri::MakeCharts(
  dfResults = gsm.core::reportingResults,
  dfGroups = gsm.core::reportingGroups,
  dfMetrics = gsm.core::reportingMetrics,
  dfBounds = gsm.core::reportingBounds
)

gsm.kri::Report_KRI(
  lCharts = lCharts,
  dfResults =  gsm.kri::FilterByLatestSnapshotDate(gsm.core::reportingResults),
  dfGroups =  gsm.core::reportingGroups,
  dfMetrics = gsm.core::reportingMetrics,
  strOutputDir = here::here("inst", "examples", "output"),
  strOutputFile = "report_kri_site.html"
)


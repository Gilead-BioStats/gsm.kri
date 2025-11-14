# Load libraries
library(gsm.core)
library(gsm.kri)
library(here)

## Site Report
lCharts <- gsm.kri::MakeCharts(
  dfResults = gsm.core::reportingResults,
  dfGroups = gsm.core::reportingGroups,
  dfMetrics = gsm.core::reportingMetrics,
  dfBounds = gsm.core::reportingBounds
)

## Render example report
gsm.kri::Report_KRI(
  lCharts = lCharts,
  dfResults = gsm.kri::FilterByLatestSnapshotDate(gsm.core::reportingResults),
  dfGroups = gsm.core::reportingGroups,
  dfMetrics = gsm.core::reportingMetrics,
  strOutputDir = here::here("pkgdown", "assets", "examples"),
  strOutputFile = "report_kri_site.html"
)

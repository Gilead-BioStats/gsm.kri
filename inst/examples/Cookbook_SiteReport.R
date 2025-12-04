# Load libraries
library(gsm.core)
library(gsm.kri)
library(here)
lWorkflows <- MakeWorkflowList(
  strPath = "inst/workflow/2_metrics",
  strNames = "kri",
  strPackage = "gsm.kri"
)
dfMetrics <- gsm.reporting::MakeMetric(lWorkflows)
## Site Report
lCharts <- gsm.kri::MakeCharts(
  dfResults = gsm.core::reportingResults,
  dfGroups = gsm.core::reportingGroups,
  dfMetrics = dfMetrics,
  dfBounds = gsm.core::reportingBounds
)

## Render example report
gsm.kri::Report_KRI(
  lCharts = lCharts,
  dfResults = gsm.kri::FilterByLatestSnapshotDate(gsm.core::reportingResults),
  dfGroups = gsm.core::reportingGroups,
  dfMetrics = gsm.core::reportingMetrics,
  strOutputDir = here::here("pkgdown", "assets", "examples"),
  strOutputFile = "Report_KRI_Site.html"
)

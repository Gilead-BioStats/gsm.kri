library(gsm.datasim)
library(gsm.mapping)
library(gsm.reporting)
library(gsm.core) # fix-96
library(gsm.kri)
library(gsm.qtl) # fix-58
library(purrr)
library(dplyr)
devtools::load_all(".")

dfResults <- gsm.core::reportingResults_study %>%
  filter(MetricID %in% "Analysis_qtl0001") %>%
  mutate(MetricID = "CTQ_eligibility")

dfMetrics <- gsm.core::reportingMetrics_study %>%
  filter(MetricID %in% "Analysis_qtl0001") %>%
  mutate(MetricID = "CTQ_eligibility")

dfGroups <- gsm.core::reportingGroups_study

mappings_wf <- gsm.core::MakeWorkflowList(
  strNames =c("IE", "EXCLUSION", "ENROLL", "PD"),
  strPath = "workflow/1_mappings",
  strPackage = "gsm.mapping"
)
mappings_spec <- gsm.mapping::CombineSpecs(mappings_wf)
lRaw <- map_depth(list(gsm.core::lSource), 1, gsm.mapping::Ingest, mappings_spec)
mapped <- map_depth(lRaw, 1, ~ gsm.core::RunWorkflows(mappings_wf, .x))

lListings <- list(
  CTQ = mapped[[1]]$Mapped_EXCLUSION
)

lParams <- list(
  dfResults = dfResults,
  dfMetrics = dfMetrics,
  dfGroups = dfGroups,
  lListings = lListings
)

gsm.kri::RenderRmd(
  lParams = lParams ,
  strOutputDir = getwd(),
  strOutputFile = "test.html",
  strInputPath = system.file("report/eligibility.Rmd", package = "gsm.kri")
)

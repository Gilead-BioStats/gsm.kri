# library(gsm.datasim)
# library(gsm.mapping)
# library(gsm.reporting)
# library(gsm.core) # dev
# library(gsm.kri)
# library(gsm.qtl) # fix-60
# library(purrr)
# library(dplyr)
# devtools::load_all(".") # fix-96
# devtools::load_all("../gsm.qtl") # fix-60
# devtools::load_all("../gsm.kri") # fix-131

pak::pak("Gilead-BioStats/gsm.qtl@fix-60")
devtools::load_all()
pak::pak("Gilead-BioStats/gsm.core@fix-105")

dfResults <- gsm.core::reportingResults_study %>%
  filter(MetricID %in% "Analysis_qtl0001") %>%
  mutate(MetricID = "study_eligibility")

dfMetrics <- gsm.core::reportingMetrics_study %>%
  filter(MetricID %in% "Analysis_qtl0001") %>%
  mutate(MetricID = "study_eligibility")

dfGroups <- gsm.core::reportingGroups_study

mappings_wf <- gsm.core::MakeWorkflowList(
  strNames = c("IE", "EXCLUSION", "ENROLL", "PD"),
  strPath = "workflow/1_mappings",
  strPackage = "gsm.mapping"
)
mappings_spec <- gsm.mapping::CombineSpecs(mappings_wf)
lRaw <- map_depth(
  list(gsm.core::lSource),
  1,
  gsm.mapping::Ingest,
  mappings_spec
)
mapped <- map_depth(lRaw, 1, ~ gsm.core::RunWorkflows(mappings_wf, .x))

# test kri workflows
metrics_wf <- gsm.core::MakeWorkflowList(
  strNames = c("cou0014", "kri0014"),
  strPath = "inst/workflow/2_metrics",
)
IE_kris <- map_depth(mapped, 1, ~ gsm.core::RunWorkflows(metrics_wf, .x))


# test rendering of report
lListings <- list(
  IE = mapped[[1]]$Mapped_EXCLUSION
)

lParams <- list(
  dfResults = dfResults,
  dfMetrics = dfMetrics,
  dfGroups = dfGroups,
  lListings = lListings
)

# Local call to render function - run from pkg root
gsm.kri::RenderRmd(
  lParams = lParams,
  strOutputDir = file.path(getwd(), "pkgdown", "assets", "examples"),
  strOutputFile = "Example_Eligibility.html",
  strInputPath = system.file(
    "examples/Example_Eligibility.Rmd",
    package = "gsm.kri"
  )
)

# Via workflow

# eligibility_workflow <- gsm.core::MakeWorkflowList(strNames = "report_eligibility", strPath = "inst/workflow/4_modules")
# gsm.core::RunWorkflows(eligibility_workflow,
#                        lData = list(
#                          Reporting_Results = dfResults,
#                          Reporting_Metrics = dfMetrics,
#                          Reporting_Groups = dfGroups,
#                          Mapped_EXCLUSION = lListings$IE
#                        ))

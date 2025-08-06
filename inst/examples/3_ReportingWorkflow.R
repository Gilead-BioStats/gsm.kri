#### 3.1 - Create a KRI Report using 12 standard metrics in a step-by-step workflow
library(gsm.core)
library(gsm.mapping)
library(gsm.reporting)
library(gsm.kri)
library(yaml)


core_mappings <- c("AE", "COUNTRY", "DATACHG", "DATAENT", "ENROLL", "LB", "VISIT",
                   "PD", "PK", "QUERY", "STUDY", "STUDCOMP", "SDRGCOMP", "SITE", "SUBJ")

lRaw <- list(
  Raw_SUBJ = gsm.core::lSource$Raw_SUBJ,
  Raw_AE = gsm.core::lSource$Raw_AE,
  Raw_PD = gsm.core::lSource$Raw_PD %>%
    rename(subjid = subjectenrollmentnumber),
  Raw_LB = gsm.core::lSource$Raw_LB,
  Raw_PK = gsm.core::lSource$Raw_PK,
  Raw_STUDCOMP = gsm.core::lSource$Raw_STUDCOMP %>%
    select(subjid, compyn),
  Raw_SDRGCOMP = gsm.core::lSource$Raw_SDRGCOMP,
  Raw_DATACHG = gsm.core::lSource$Raw_DATACHG %>%
    rename(subject_nsv = subjectname),
  Raw_DATAENT = gsm.core::lSource$Raw_DATAENT %>%
    rename(subject_nsv = subjectname),
  Raw_QUERY = gsm.core::lSource$Raw_QUERY %>%
    rename(subject_nsv = subjectname),
  Raw_ENROLL = gsm.core::lSource$Raw_ENROLL,
  Raw_SITE = gsm.core::lSource$Raw_SITE %>%
    rename(studyid = protocol) %>%
    rename(invid = pi_number) %>%
    rename(InvestigatorFirstName = pi_first_name) %>%
    rename(InvestigatorLastName = pi_last_name) %>%
    rename(City = city) %>%
    rename(State = state) %>%
    rename(Country = country) %>%
    rename(Status = site_status),
  Raw_STUDY = gsm.core::lSource$Raw_STUDY %>%
    rename(studyid = protocol_number) %>%
    rename(Status = status)
)

# Step 1 - Create Mapped Data Layer - filter, aggregate and join raw data to create mapped data layer
mappings_wf <- MakeWorkflowList(strNames = core_mappings, strPath = "workflow/1_mappings", strPackage = "gsm.mapping")
mapped <- RunWorkflows(mappings_wf, lRaw)

# Step 2 - Create Metrics - calculate metrics using mapped data
metrics_wf <- MakeWorkflowList(strPath = "workflow/2_metrics", strPackage = "gsm.kri")
analyzed <- RunWorkflows(metrics_wf, mapped)

# Step 3 - Create Reporting Layer - create reports using metrics data
reporting_wf <- MakeWorkflowList(strPath = "workflow/3_reporting", strPackage = "gsm.reporting")
reporting <- RunWorkflows(reporting_wf, c(mapped, list(lAnalyzed = analyzed,
                                                       lWorkflows = metrics_wf)))

# Step 4 - Create KRI Reports - create KRI report using reporting data
module_wf <- MakeWorkflowList(strPath = "inst/workflow/4_modules", strPackage = "gsm.kri")
lReports <- RunWorkflows(module_wf, reporting)

#### 3.2 - Automate data ingestion using Ingest() and CombineSpecs()
# Step 0 - Data Ingestion - standardize tables/columns names
mappings_wf <- MakeWorkflowList(strNames = core_mappings, strPath = "workflow/1_mappings", strPackage = "gsm.mapping")
mappings_spec <- CombineSpecs(mappings_wf)
lRaw <- Ingest(gsm.core::lSource, mappings_spec)

# Step 1 - Create Mapped Data Layer - filter, aggregate and join raw data to create mapped data layer
mapped <- RunWorkflows(mappings_wf, lRaw)

# Step 2 - Create Metrics - calculate metrics using mapped data
metrics_wf <- MakeWorkflowList(strPath = "inst/workflow/2_metrics", strPackage = "gsm.kri")
analyzed <- RunWorkflows(metrics_wf, mapped)

# Step 3 - Create Reporting Layer - create reports using metrics data
reporting_wf <- MakeWorkflowList(strPath = "workflow/3_reporting", strPackage = "gsm.reporting")
reporting <- RunWorkflows(reporting_wf, c(mapped, list(lAnalyzed = analyzed,
                                                       lWorkflows = metrics_wf)))

# Step 4 - Create KRI Report - create KRI report using reporting data
module_wf <- MakeWorkflowList(strNames = "^report", strPath = "inst/workflow/4_modules", strPackage = "gsm.kri")
lReports <- RunWorkflows(module_wf, reporting)


#### 3.3 Site-Level KRI Report with multiple SnapshotDate
lCharts <- MakeCharts(
  dfResults = gsm.core::reportingResults,
  dfGroups = gsm.core::reportingGroups,
  dfMetrics = gsm.core::reportingMetrics,
  dfBounds = gsm.core::reportingBounds
)

kri_site <- Report_KRI(
  lCharts = lCharts,
  dfResults =  FilterByLatestSnapshotDate(gsm.core::reportingResults),
  dfGroups =  gsm.core::reportingGroups,
  dfMetrics = gsm.core::reportingMetrics
)


lCharts_country <- MakeCharts(
  dfResults = gsm.core::reportingResults_country,
  dfGroups = gsm.core::reportingGroups_country,
  dfMetrics = gsm.core::reportingMetrics_country,
  dfBounds = gsm.core::reportingBounds_country
)

kri_country <- Report_KRI(
  lCharts = lCharts_country,
  dfResults =  FilterByLatestSnapshotDate(gsm.core::reportingResults_country),
  dfGroups =  gsm.core::reportingGroups_country,
  dfMetrics = gsm.core::reportingMetrics_country
)

#### 3.4 Reporting Results with Changes from previous snapshot

# Prepare historical data
historical <- gsm.core::reportingResults %>% filter(SnapshotDate == "2025-03-01")

# Re-run reporting model and KRI report with historical data
reporting_long <- gsm.core::RunWorkflows(reporting_wf, c(mapped, list(lAnalyzed = analyzed, Reporting_Results_Longitudinal = historical, lWorkflows = metrics_wf)))
lReports_long <- gsm.core::RunWorkflows(module_wf, reporting_long)


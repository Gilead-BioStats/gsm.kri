#### Cross-Study KRI Report Example
#### This example demonstrates how to create a cross-study KRI report using the gsm.kri package
####
#### CROSS-STUDY KRI IMPLEMENTATION DOCUMENTATION
#### ==============================================
#### 
#### This script demonstrates the implementation of issue #71 - "Create a cross-study KRI report" 
#### for the gsm.kri package.
####
#### OVERVIEW
#### --------
#### The cross-study KRI report functionality allows users to analyze Key Risk Indicators (KRIs) 
#### and Site Risk Scores across multiple studies. The implementation provides:
####
#### 1. Unified Table Structure: Single table with one header and collapsible site sections
#### 2. Collapsible Site Rows: Click site summary rows to expand/collapse study-level KRI data
#### 3. Site Risk Score Badges: Color-coded badges showing average risk score per site
#### 4. Study Count Display: Badge showing number of studies each site participates in
#### 5. Clinical Weight System: Configurable risk scoring based on KRI importance
#### 6. gsmViz Integration: Leverages gsmViz.groupOverview for KRI flag rendering
####

# Load development version
devtools::load_all()

library(gsm.core)
library(dplyr)

# Load required libraries
library(htmlwidgets)

#### Step 1: Simulate Multi-Study Data ####

# Set seed for reproducibility
set.seed(123)

# Define parameters for simulation
study_ids <- sprintf("STUDY%03d", 1:5)
snapshot_date <- as.Date("2025-06-01")  # Single snapshot date
metric_ids <- sprintf("Analysis_kri%04d", 1:12)
group_levels <- "Site"
site_ids <- gsm.core::reportingGroups %>%
  dplyr::filter(Param == "invid") %>%
  dplyr::pull(Value) %>%
  sample(25)

# Simulate cross-study reporting results
sim_reportingResults <- lapply(study_ids, function(study) {
  n_sites <- sample(8:15, 1)  # Each study has 8-15 sites
  study_sites <- sample(site_ids, n_sites, replace = FALSE)
  
  expand.grid(
    StudyID = study,
    SnapshotDate = snapshot_date,  # Use single snapshot date
    GroupLevel = group_levels,
    GroupID = study_sites,
    MetricID = metric_ids,
    stringsAsFactors = FALSE
  )
}) %>%
  dplyr::bind_rows() %>%
  dplyr::mutate(
    Numerator = sample(1:100, n(), replace = TRUE),
    Denominator = sample(100:200, n(), replace = TRUE),
    Metric = Numerator / Denominator,
    Score = round(runif(n(), -3, 3), 2),  # Z-scores
    Flag = dplyr::case_when(
      Score <= -2 ~ -2,
      Score <= -1 ~ -1,
      Score >= 2 ~ 2,
      Score >= 1 ~ 1,
      TRUE ~ 0
    )
  )

# Create weight table from gsm.core::reportingMetrics
weight_table <- gsm.core::reportingMetrics %>%
  dplyr::filter(!is.na(Flag) & !is.na(RiskScoreWeight)) %>%
  dplyr::select(MetricID, Flag, RiskScoreWeight) %>%
  # Parse the comma-separated Flag and RiskScoreWeight values
  dplyr::mutate(
    flags_list = strsplit(Flag, ","),
    weights_list = strsplit(RiskScoreWeight, ",")
  ) %>%
  # Expand to one row per flag-weight combination
  tidyr::unnest_longer(c(flags_list, weights_list)) %>%
  dplyr::mutate(
    Flag = as.numeric(flags_list),
    Weight = as.numeric(weights_list)
  ) %>%
  # Calculate WeightMax by metric
  dplyr::group_by(MetricID) %>%
  dplyr::mutate(WeightMax = max(Weight, na.rm = TRUE)) %>%
  dplyr::ungroup()

sim_reportingResults <- sim_reportingResults %>%
  dplyr::left_join(weight_table, by = c("MetricID", "Flag"))


cat("Generated", nrow(sim_reportingResults), "simulated records across", 
    length(unique(sim_reportingResults$StudyID)), "studies and", 
    length(unique(sim_reportingResults$GroupID)), "sites.\n")

#### Step 1.5: Create Study Groups Data ####

# Create dfGroups data for our simulated studies
dfGroups_studies <- lapply(study_ids, function(study_id) {
  # Generate realistic study metadata
  study_number <- as.numeric(gsub("STUDY", "", study_id))
  
  data.frame(
    Index = 1:22,
    GroupID = study_id,
    Param = c("studyid", "nickname", "protocol_title", "status", "num_plan_site", 
              "num_plan_subj", "act_fpfv", "est_fpfv", "est_lplv", "est_lpfv",
              "therapeutic_area", "protocol_indication", "phase", "product",
              "SiteTarget", "ParticipantTarget", "ParticipantCount", "SiteCount",
              "PercentSitesActivated", "SiteActivation", "PercentParticipantsEnrolled", 
              "ParticipantEnrollment"),
    Value = c(
      study_id,
      paste0("Protocol-", study_number),
      paste("Protocol Title for Study", study_number),
      sample(c("Active", "Completed", "Enrolling"), 1),
      as.character(sample(100:200, 1)),
      as.character(sample(800:1200, 1)),
      as.character(as.Date("2024-01-01") + sample(0:365, 1)),
      as.character(as.Date("2024-01-01") + sample(0:30, 1)),
      as.character(as.Date("2024-12-31") + sample(0:365, 1)),
      as.character(as.Date("2024-06-01") + sample(0:180, 1)),
      sample(c("Oncology", "Virology", "Cardiology", "Neurology", "Immunology"), 1),
      sample(c("Hematology", "Solid Tumors", "Respiratory", "Dermatology"), 1),
      sample(c("P1", "P2", "P3"), 1),
      paste("Product", LETTERS[study_number]),
      as.character(sample(100:200, 1)),
      as.character(sample(800:1200, 1)),
      as.character(sample(600:1000, 1)),
      as.character(sample(80:150, 1)),
      as.character(round(runif(1, 85, 98), 1)),
      paste0(sample(80:150, 1), " / ", sample(100:200, 1), " (", round(runif(1, 85, 98), 1), "%)"),
      as.character(round(runif(1, 70, 90), 1)),
      paste0(sample(600:1000, 1), " / ", sample(800:1200, 1), " (", round(runif(1, 70, 90), 1), "%)")
    ),
    GroupLevel = "Study",
    stringsAsFactors = FALSE
  )
}) %>%
  dplyr::bind_rows()

# Combine with existing site groups data from gsm.core
dfGroups_combined <- dplyr::bind_rows(
  gsm.core::reportingGroups,  # Original site-level groups
  dfGroups_studies            # New study-level groups
)

cat("Created study metadata for", length(study_ids), "studies with", nrow(dfGroups_studies), "total metadata records.\n")

# Show sample of generated study metadata
cat("Sample study metadata:\n")
sample_study <- dfGroups_studies %>% filter(GroupID == study_ids[1])
print(sample_study %>% select(Param, Value) %>% head(8))

#dfFlaggedWeights <- sim_reportingResults %>% filter(StudyID =="STUDY001")

#### Step 2: Calculate Site Risk Scores ####

# Now calculate risk scores using the CalculateRiskScore function
RiskScores <- sim_reportingResults %>%
  split(.$StudyID) %>%
  purrr::map(~ {
    df <- CalculateRiskScore(.x)
    df$StudyID <- .x$StudyID[1]
    df
  }) %>%
  dplyr::bind_rows()

# Combine the Site-level risk scores with original KRI data 
dfResults_WithRiskScore <- dplyr::bind_rows(
  sim_reportingResults,
  RiskScores
)

cat("Added risk scores. Dataset now has", nrow(dfResults_WithRiskScore), "records.\n")

# Debug: Check what metrics we have
cat("Unique MetricIDs in data:", paste(unique(dfResults_WithRiskScore$MetricID), collapse = ", "), "\n")
cat("Analysis_srs0001 present:", "Analysis_srs0001" %in% dfResults_WithRiskScore$MetricID, "\n")

# Check risk score data specifically
risk_score_records <- dfResults_WithRiskScore %>% filter(MetricID == "Analysis_srs0001")
cat("Risk score records (Analysis_srs0001):", nrow(risk_score_records), "\n")

#### Step 3: Create Cross-Study Summary ####

# Create the cross-study summary data
dfCrossStudySummary <- SummarizeCrossStudy(
  dfResults = dfResults_WithRiskScore,
  dfGroups = dfGroups_combined
)
cat("Cross-study summary created with", nrow(dfCrossStudySummary), "sites.\n")

#### Step 4: Create Cross-Study Widgets ####

# Create the cross-study risk score widget
cat("Creating cross-study widget...\n")
cat("Summary data has", nrow(dfCrossStudySummary), "rows\n")

# Debug the SummarizeCrossStudy output
cat("Summary columns:", paste(names(dfCrossStudySummary), collapse = ", "), "\n")
cat("First few summary rows:\n")
print(head(dfCrossStudySummary, 3))

cross_study_widget <- Widget_CrossStudyRiskScore(
  dfResults = dfResults_WithRiskScore,
  dfMetrics = gsm.core::reportingMetrics,
  dfGroups = dfGroups_combined
  )

# Save widget to file in /inst/examples folder
htmlwidgets::saveWidget(
  cross_study_widget,
  file = "inst/examples/cross_study_risk_score_widget.html",
  selfcontained = TRUE
)

cat("Cross-study widget saved to cross_study_risk_score_widget.html\n")

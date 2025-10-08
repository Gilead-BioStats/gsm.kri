#### Cross-Study KRI Report Exampe
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
#### 1. Interactive Summary Table: Shows aggregated site performance across studies
#### 2. Drill-down Capability: Click to see study-specific details for each site  
#### 3. Data Quality Analysis: Flag distributions and participation metrics
#### 4. Clinical Weight System: Configurable risk scoring based on KRI importance
####
#### KEY FUNCTIONS IMPLEMENTED
#### -------------------------
#### 
#### Core Functions:
#### - SummarizeCrossStudy(dfResults, strGroupLevel = "Site")
####   * Creates cross-study summary statistics per site
####   * Calculates average risk scores, flag counts, and participation metrics
####   * Handles R data.frame to JavaScript array conversion
####
#### - Widget_CrossStudyRiskScore(dfResults, strGroupLevel = "Site") 
####   * Interactive widget for cross-study risk score visualization
####   * Provides expandable details for each site showing study-specific breakdowns
####   * Handles R data.frame serialization to JavaScript properly
####
#### - CalculateRiskScore(dfResults)
####   * Generates site risk scores (Analysis_srs0001 metric) from KRI data
####   * Uses Weight and WeightMax columns for clinical importance weighting
####
#### - Visualize_RiskScore(dfResults, strGroupLevel = "Site")
####   * Simplified to directly call Widget_CrossStudyRiskScore
####   * Streamlined for cross-study functionality
####
#### CURRENT IMPLEMENTATION STATUS
#### ------------------------------
#### ✅ Cross-study widget fully functional with proper R data.frame handling
#### ✅ JavaScript conversion from R column-based to row-based data structure
#### ✅ Interactive drill-down functionality working
#### ✅ Clinical weight system implemented with comprehensive KRI weighting
#### ✅ Multi-study simulation and risk score calculation

#### ✅ Removed deprecated TransposeRiskScore and GroupRiskScore functions
####
#### TECHNICAL ARCHITECTURE
#### -----------------------
#### Files Structure:
#### gsm.kri/
#### ├── R/
#### │   ├── SummarizeCrossStudy.R           # Cross-study aggregation logic
#### │   ├── Widget_CrossStudyRiskScore.R    # Interactive widget creation  

#### │   ├── CalculateRiskScore.R            # Site risk score calculation
#### │   └── Visualize_RiskScore.R           # Simplified visualization wrapper
#### ├── inst/
#### │   ├── examples/4_CrossStudyKRI.R      # This comprehensive example
#### │   ├── htmlwidgets/
#### │   │   ├── Widget_CrossStudyRiskScore.js     # Widget JavaScript interface
#### │   │   ├── Widget_CrossStudyRiskScore.yaml   # Widget configuration
#### │   │   └── lib/renderCrossStudyRiskScoreTable.js  # Core rendering logic with R data.frame handling

#### └── man/ (auto-generated documentation)
####
#### DATA STRUCTURE HANDLING
#### ------------------------
#### Key Innovation: JavaScript functions handle R data.frame serialization properly
#### - R data.frames serialize as objects with array properties (column-based)
#### - JavaScript converts to array of objects (row-based) for table rendering
#### - Maintains compatibility with both R and JavaScript data expectations
####
#### CLINICAL WEIGHT SYSTEM
#### -----------------------
#### Comprehensive weighting system based on clinical importance:
#### - Adverse Events (kri0001): Highest weights (up to 32) for safety concerns
#### - Serious Adverse Events (kri0002): High weights (up to 8) for both high/low rates  
#### - Protocol Deviations (kri0003): Moderate weights (up to 16) for compliance
#### - Important Protocol Deviations (kri0004): Very high weights (up to 32)
#### - Data Quality KRIs (kri0005-0009): Low weights (up to 2) for operational metrics
#### - Discontinuation KRIs (kri0011-0012): High weights (up to 32) for retention
####
#### USAGE PATTERN
#### --------------
#### 1. Simulate or load multi-study data with KRI metrics
#### 2. Apply clinical weights to Flag values  
#### 3. Calculate site risk scores using CalculateRiskScore()
#### 4. Create cross-study summary with SummarizeCrossStudy()
#### 5. Generate interactive widget with Widget_CrossStudyRiskScore()

####
#### TESTING COVERAGE
#### ----------------
#### - Simulated multi-study data (5 studies, 23 sites)
#### - Various risk score distributions and flag patterns
#### - Interactive widget functionality with drill-down
#### - Cross-study aggregation mathematics
#### - R data.frame to JavaScript conversion
####
#### FUTURE ENHANCEMENTS
#### -------------------

#### - Temporal analysis across multiple snapshot dates  
#### - Study-level aggregations and benchmarking
#### - Export functionality for summary tables
#### - Interactive filtering options

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
site_ids <- sprintf("SITE%03d", 1:25)

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
    Weight = as.numeric(weights_list),
    # Calculate WeightMax as the maximum weight for each metric
    WeightMax = NA_real_
  ) %>%
  # Calculate WeightMax by metric
  dplyr::group_by(MetricID) %>%
  dplyr::mutate(WeightMax = max(Weight, na.rm = TRUE)) %>%
  dplyr::ungroup()

sim_reportingResults <- sim_reportingResults %>%
  dplyr::left_join(weight_table, by = c("MetricID", "Flag")) %>%
  dplyr::mutate(
    Weight = ifelse(is.na(Weight), 0, Weight),
    WeightMax = ifelse(is.na(WeightMax), 4, WeightMax)
  )


cat("Generated", nrow(sim_reportingResults), "simulated records across", 
    length(unique(sim_reportingResults$StudyID)), "studies and", 
    length(unique(sim_reportingResults$GroupID)), "sites.\n")

#### Step 2: Calculate Site Risk Scores ####

# Now calculate risk scores using the CalculateRiskScore function
dfResults_WithRiskScore <- CalculateRiskScore(sim_reportingResults)

# Combine the Site-level risk scores with original KRI data 
dfResults_WithRiskScore <- dplyr::bind_rows(
  sim_reportingResults,
  dfResults_WithRiskScore
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
dfCrossStudySummary <- SummarizeCrossStudy(dfResults = dfResults_WithRiskScore)
cat("Cross-study summary created with", nrow(dfCrossStudySummary), "sites.\n")

#### Step 4: Create Cross-Study Widgets ####

# Create the cross-study risk score widget
cat("Creating cross-study widget...\n")
cat("Summary data has", nrow(dfCrossStudySummary), "rows\n")

# Debug the SummarizeCrossStudy output
cat("Summary columns:", paste(names(dfCrossStudySummary), collapse = ", "), "\n")
cat("First few summary rows:\n")
print(head(dfCrossStudySummary, 3))

cross_study_widget <- Widget_CrossStudyRiskScore(dfResults = dfResults_WithRiskScore)

# Save widget to file in /inst/examples folder
htmlwidgets::saveWidget(
  cross_study_widget,
  file = "inst/examples/cross_study_risk_score_widget.html",
  selfcontained = TRUE
)

cat("Cross-study widget saved to cross_study_risk_score_widget.html\n")

#### Step 5: Generate Cross-Study KRI Report ####

# Widget visualization is the primary output method for cross-study analysis

#### Step 6: Additional Analysis Examples ####
dfCrossStudySummary <- SummarizeCrossStudy(dfResults = dfResults_WithRiskScore)
cat("Cross-study summary created with", nrow(dfCrossStudySummary), "sites.\n")
# Show site participation matrix
site_participation <- dfResults_WithRiskScore %>%
  filter(MetricID == "Analysis_srs0001") %>%
  select(StudyID, GroupID, Score) %>%
  distinct() %>%
  mutate(Participated = 1) %>%
  tidyr::pivot_wider(names_from = StudyID, values_from = Participated, values_fill = 0)

cat("Site participation matrix:\n")
print(site_participation)

# Identify high-risk sites across studies
high_risk_sites <- dfCrossStudySummary %>%
  filter(AvgRiskScore >= 60) %>%
  arrange(desc(AvgRiskScore))

cat("\nHigh-risk sites (≥60% average risk score):\n")
print(high_risk_sites %>% select(GroupID, NumStudies, AvgRiskScore, RedFlags, AmberFlags))

# Show flag distribution
flag_summary <- dfCrossStudySummary %>%
  summarise(
    TotalSites = n(),
    HighRiskSites = sum(AvgRiskScore >= 75),
    MediumRiskSites = sum(AvgRiskScore >= 50 & AvgRiskScore < 75),
    LowRiskSites = sum(AvgRiskScore < 50),
    TotalRedFlags = sum(RedFlags),
    TotalAmberFlags = sum(AmberFlags),
    TotalGreenFlags = sum(GreenFlags)
  )

cat("\nOverall flag summary:\n")
print(flag_summary)

#### Example Output Messages ####
cat("\n=== Cross-Study KRI Report Example Complete ===\n")
cat("Files generated:\n")
cat("1. cross_study_risk_score_widget.html - Interactive widget\n")
cat("\nNext steps:\n")
cat("- Open the HTML file in a web browser\n")
cat("- Click 'Show Details' for any site to see study-specific breakdowns\n")
cat("- Review high-risk sites for potential monitoring focus\n")
cat("- Compare site performance across studies\n")
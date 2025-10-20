#### Cross-Study KRI Report Example
# Load development version
devtools::load_all()

library(gsm.core)
library(dplyr)
library(htmlwidgets)

# Source utility functions
source("inst/examples/4_util_Sim_Studies.R")

#### Step 1: Simulate Multi-Study Results and Group Data ####

# Simulate multi-study data using Sim_Studies function
sim_data <- Sim_Studies(
  dfMetrics = gsm.core::reportingMetrics,
  n_studies = 5,
  n_sites = 30,
  n_sites_per_study = c(8, 15),
  snapshot_date = as.Date("2025-06-01"),
  seed = 123
)

#### Step 2: Create Cross-Study Summary ####

# Create the cross-study summary data
dfCrossStudySummary <- SummarizeCrossStudy(
  dfResults = sim_data$dfResults,
  dfGroups = sim_data$dfGroups
)

#### Step 3: Create Cross-Study Widgets ####
cross_study_widget <- Widget_CrossStudyRiskScore(
  dfResults = sim_data$dfResults,
  dfMetrics = gsm.core::reportingMetrics,
  dfGroups = sim_data$dfGroups
)

widget_file <- "inst/examples/cross_study_risk_score_widget.html"
htmlwidgets::saveWidget(
  cross_study_widget,
  file = widget_file,
  selfcontained = TRUE
)

# Clean up the temporary _files directory created during widget building
widget_files_dir <- "inst/examples/cross_study_risk_score_widget_files"
if (dir.exists(widget_files_dir)) {
  unlink(widget_files_dir, recursive = TRUE)
  cat("Cleaned up temporary directory:", widget_files_dir, "\n")
}

cat("Widget saved to:", widget_file, "\n")

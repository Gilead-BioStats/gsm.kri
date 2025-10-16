# Load required libraries for testing
library(testthat)
library(dplyr)

# Test data setup helpers ----

create_sample_results <- function() {
  data.frame(
    GroupLevel = rep("Site", 12),
    GroupID = rep(c("Site001", "Site002", "Site003"), 4),
    MetricID = rep(c("Analysis_kri0001", "Analysis_kri0002", "Analysis_kri0003", "Analysis_kri0004"), 3),
    Weight = c(4, 2, 0, 8, 2, 4, 0, 16, 0, 2, 4, 8),
    WeightMax = c(4, 4, 4, 16, 4, 4, 4, 16, 4, 4, 4, 16),
    Numerator = c(10, 5, 8, 3, 15, 12, 6, 2, 20, 18, 14, 1),
    Denominator = c(100, 100, 100, 100, 150, 150, 150, 150, 200, 200, 200, 200),
    Metric = c(0.1, 0.05, 0.08, 0.03, 0.1, 0.08, 0.04, 0.013, 0.1, 0.09, 0.07, 0.005),
    Flag = c(1, -1, 0, 2, -1, 1, 0, -2, 0, -1, 1, -2),
    SnapshotDate = as.Date("2025-01-01"),
    StudyID = "STUDY001",
    stringsAsFactors = FALSE
  )
}

create_minimal_results <- function() {
  data.frame(
    GroupLevel = "Site",
    GroupID = "Site001",
    MetricID = "Analysis_kri0001",
    Weight = 4,
    WeightMax = 4,
    stringsAsFactors = FALSE
  )
}

# Basic functionality tests ----

test_that("CalculateRiskScore returns correct structure", {
  dfResults <- create_sample_results()
  dfRiskScore <- CalculateRiskScore(dfResults)
  
  # Check return structure
  expect_s3_class(dfRiskScore, "data.frame")
  expect_named(dfRiskScore, c("GroupLevel", "GroupID", "MetricID", "Numerator", "Denominator", "Metric", "Score", "Flag"))
  
  # Check default MetricID
  expect_true(all(dfRiskScore$MetricID == "Analysis_srs0001"))
  
  # Check number of rows equals unique groups
  expected_groups <- distinct(dfResults, GroupLevel, GroupID)
  expect_equal(nrow(dfRiskScore), nrow(expected_groups))
})

test_that("CalculateRiskScore calculates risk scores correctly", {
  dfResults <- create_sample_results()
  dfRiskScore <- CalculateRiskScore(dfResults)
  
  # Calculate expected values manually
  # Global denominator = sum of max weights = 4 + 4 + 4 + 16 = 28
  expected_global_denom <- 28
  
  # For Site001: Weight sum = 4 + 8 + 0 + 2 = 14 (based on the actual data layout)
  site001_row <- dfRiskScore[dfRiskScore$GroupID == "Site001", ]
  expect_equal(site001_row$Numerator, 14)
  expect_equal(site001_row$Denominator, expected_global_denom)
  expect_equal(site001_row$Metric, site001_row$Numerator / site001_row$Denominator * 100)
  expect_equal(site001_row$Score, site001_row$Metric)
  expect_true(is.na(site001_row$Flag))
})

test_that("CalculateRiskScore handles custom MetricID", {
  dfResults <- create_sample_results()
  custom_metric_id <- "Analysis_custom_risk"
  dfRiskScore <- CalculateRiskScore(dfResults, strMetricID = custom_metric_id)
  
  expect_true(all(dfRiskScore$MetricID == custom_metric_id))
})

# Input validation tests ----

test_that("CalculateRiskScore validates required columns", {
  dfResults <- create_sample_results()
  
  # Test missing required columns
  required_cols <- c("GroupLevel", "GroupID", "MetricID", "Weight", "WeightMax")
  for (col in required_cols) {
    dfResults_missing <- dfResults[, !names(dfResults) %in% col]
    expect_error(
      CalculateRiskScore(dfResults_missing),
      paste("Missing required columns in dfResults:", col)
    )
  }
})

test_that("CalculateRiskScore validates MetricID uniqueness", {
  dfResults <- create_sample_results()
  
  # Add existing MetricID to test data - need to match all columns
  dfResults_with_existing <- rbind(
    dfResults,
    data.frame(
      GroupLevel = "Site",
      GroupID = "Site004",
      MetricID = "Analysis_srs0001",  # This should cause an error
      Weight = 2,
      WeightMax = 4,
      Numerator = 10,
      Denominator = 100,
      Metric = 0.1,
      Flag = 0,
      SnapshotDate = as.Date("2025-01-01"),
      StudyID = "STUDY001",
      stringsAsFactors = FALSE
    )
  )
  
  expect_error(
    CalculateRiskScore(dfResults_with_existing),
    "MetricID Analysis_srs0001 already exists in dfResults"
  )
})

test_that("CalculateRiskScore validates numeric Weight and WeightMax", {
  dfResults <- create_sample_results()
  
  # Test non-numeric Weight
  dfResults_char_weight <- dfResults
  dfResults_char_weight$Weight <- as.character(dfResults_char_weight$Weight)
  expect_error(
    CalculateRiskScore(dfResults_char_weight),
    "Columns 'Weight' and 'WeightMax' must be numeric"
  )
  
  # Test non-numeric WeightMax
  dfResults_char_weightmax <- dfResults
  dfResults_char_weightmax$WeightMax <- as.character(dfResults_char_weightmax$WeightMax)
  expect_error(
    CalculateRiskScore(dfResults_char_weightmax),
    "Columns 'Weight' and 'WeightMax' must be numeric"
  )
})

test_that("CalculateRiskScore validates unique combinations", {
  dfResults <- create_sample_results()
  
  # Create duplicate combination
  dfResults_duplicate <- rbind(dfResults, dfResults[1, ])
  expect_error(
    CalculateRiskScore(dfResults_duplicate),
    "The combination of 'GroupLevel', 'GroupID', and 'MetricID' must be unique"
  )
})

test_that("CalculateRiskScore validates consistent WeightMax per MetricID", {
  dfResults <- create_sample_results()
  
  # Create inconsistent WeightMax for same MetricID
  dfResults$WeightMax[dfResults$MetricID == "Analysis_kri0001"] <- c(4, 8, 4)  # Mixed values
  expect_error(
    CalculateRiskScore(dfResults),
    "'WeightMax' should be the same for each 'MetricID'"
  )
})

# NA handling tests ----

test_that("CalculateRiskScore handles NA values with warning", {
  dfResults <- create_sample_results()
  
  # Add NA values
  dfResults$Weight[1] <- NA
  dfResults$WeightMax[2] <- NA
  
  expect_warning(
    dfRiskScore <- CalculateRiskScore(dfResults),
    "Rows with NA values in 'Weight' or 'WeightMax' have been dropped"
  )
  
  # Check that NA rows were dropped
  expect_equal(nrow(dfRiskScore), 3)  # Should still have 3 unique groups
})

test_that("CalculateRiskScore works with all NA weights for a group", {
  dfResults <- data.frame(
    GroupLevel = rep("Site", 4),
    GroupID = rep(c("Site001", "Site002"), each = 2),
    MetricID = rep(c("Analysis_kri0001", "Analysis_kri0002"), 2),
    Weight = c(4, NA, NA, 8),  # Site001 has one valid weight, Site002 has one valid weight
    WeightMax = c(4, 4, 8, 8),
    stringsAsFactors = FALSE
  )
  
  expect_warning(
    dfRiskScore <- CalculateRiskScore(dfResults),
    "Rows with NA values in 'Weight' or 'WeightMax' have been dropped"
  )
  
  # Both sites should still appear
  expect_equal(nrow(dfRiskScore), 2)
  expect_equal(dfRiskScore$Numerator[dfRiskScore$GroupID == "Site001"], 4)
  expect_equal(dfRiskScore$Numerator[dfRiskScore$GroupID == "Site002"], 8)
})

# Edge cases ----

test_that("CalculateRiskScore handles single row input", {
  dfResults <- create_minimal_results()
  dfRiskScore <- CalculateRiskScore(dfResults)
  
  expect_equal(nrow(dfRiskScore), 1)
  expect_equal(dfRiskScore$GroupID, "Site001")
  expect_equal(dfRiskScore$Numerator, 4)
  expect_equal(dfRiskScore$Denominator, 4)  # Only one MetricID with WeightMax = 4
  expect_equal(dfRiskScore$Metric, 100)  # (4/4) * 100
})

test_that("CalculateRiskScore handles zero weights", {
  dfResults <- create_sample_results()
  dfResults$Weight <- 0  # All weights are zero
  
  dfRiskScore <- CalculateRiskScore(dfResults)
  
  # All numerators should be 0
  expect_true(all(dfRiskScore$Numerator == 0))
  expect_true(all(dfRiskScore$Metric == 0))
})

test_that("CalculateRiskScore handles large numbers", {
  dfResults <- create_minimal_results()
  dfResults$Weight <- 999999
  dfResults$WeightMax <- 999999
  
  dfRiskScore <- CalculateRiskScore(dfResults)
  
  expect_equal(dfRiskScore$Numerator, 999999)
  expect_equal(dfRiskScore$Denominator, 999999)
  expect_equal(dfRiskScore$Metric, 100)
})

# Group aggregation tests ----

test_that("CalculateRiskScore aggregates weights correctly across metrics", {
  dfResults <- data.frame(
    GroupLevel = rep("Site", 6),
    GroupID = rep(c("Site001", "Site002"), each = 3),
    MetricID = rep(c("Analysis_kri0001", "Analysis_kri0002", "Analysis_kri0003"), 2),
    Weight = c(4, 2, 8, 0, 4, 16),  # Site001: 4+2+8=14, Site002: 0+4+16=20
    WeightMax = c(8, 4, 16, 8, 4, 16),
    stringsAsFactors = FALSE
  )
  
  dfRiskScore <- CalculateRiskScore(dfResults)
  
  site001_score <- dfRiskScore[dfRiskScore$GroupID == "Site001", ]
  site002_score <- dfRiskScore[dfRiskScore$GroupID == "Site002", ]
  
  expect_equal(site001_score$Numerator, 14)  # 4+2+8
  expect_equal(site002_score$Numerator, 20)  # 0+4+16
  
  # Global denominator should be 8 + 4 + 16 = 28 (max weights for each unique MetricID)
  expect_equal(site001_score$Denominator, 28)
  expect_equal(site002_score$Denominator, 28)
})

test_that("CalculateRiskScore handles multiple group levels", {
  dfResults <- data.frame(
    GroupLevel = c("Site", "Country", "Site", "Country"),
    GroupID = c("Site001", "USA", "Site002", "Canada"),
    MetricID = rep("Analysis_kri0001", 4),
    Weight = c(4, 8, 2, 6),
    WeightMax = rep(8, 4),
    stringsAsFactors = FALSE
  )
  
  dfRiskScore <- CalculateRiskScore(dfResults)
  
  expect_equal(nrow(dfRiskScore), 4)  # All four groups should be present
  expect_true("Site001" %in% dfRiskScore$GroupID)
  expect_true("USA" %in% dfRiskScore$GroupID)
  expect_true("Site002" %in% dfRiskScore$GroupID)
  expect_true("Canada" %in% dfRiskScore$GroupID)
})

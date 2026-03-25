## Test Setup
library(testthat)

## Test Code
test_that("Visualize_RiskScore is a wrapper for Widget_CrossStudyRiskScore", {
  # Create minimal test data
  dfResults <- data.frame(
    GroupID = c("Site1", "Site2", "Site3"),
    StudyID = c("Study1", "Study1", "Study2"),
    Score = c(0.8, 0.6, 0.9),
    stringsAsFactors = FALSE
  )
  
  dfMetrics <- data.frame(
    MetricID = c("metric1", "metric2"),
    MetricName = c("Metric 1", "Metric 2"),
    stringsAsFactors = FALSE
  )
  
  dfGroups <- data.frame(
    GroupID = c("Site1", "Site2", "Site3"),
    GroupLevel = c("Site", "Site", "Site"),
    stringsAsFactors = FALSE
  )
  
  # Test that Visualize_RiskScore calls Widget_CrossStudyRiskScore
  # We can't easily mock the function, but we can test that it doesn't error
  # and that it returns the expected type
  expect_no_error({
    result <- Visualize_RiskScore(
      dfResults = dfResults,
      dfMetrics = dfMetrics,
      dfGroups = dfGroups,
      strGroupLevel = "Site"
    )
  })
  
  # The result should be an htmlwidget (from Widget_CrossStudyRiskScore)
  result <- Visualize_RiskScore(
    dfResults = dfResults,
    dfMetrics = dfMetrics,
    dfGroups = dfGroups,
    strGroupLevel = "Site"
  )
  
  expect_s3_class(result, "htmlwidget")
})

test_that("Visualize_RiskScore passes parameters correctly to Widget_CrossStudyRiskScore", {
  # Create test data
  dfResults <- data.frame(
    GroupID = c("Country1", "Country2"),
    StudyID = c("Study1", "Study1"),
    Score = c(0.7, 0.8),
    stringsAsFactors = FALSE
  )
  
  dfMetrics <- data.frame(
    MetricID = c("metric1"),
    MetricName = c("Test Metric"),
    stringsAsFactors = FALSE
  )
  
  dfGroups <- data.frame(
    GroupID = c("Country1", "Country2"),
    GroupLevel = c("Country", "Country"),
    stringsAsFactors = FALSE
  )
  
  # Test with custom strGroupLevel
  result_country <- Visualize_RiskScore(
    dfResults = dfResults,
    dfMetrics = dfMetrics,
    dfGroups = dfGroups,
    strGroupLevel = "Country"
  )
  
  expect_s3_class(result_country, "htmlwidget")
  expect_equal(result_country$name, "Widget_CrossStudyRiskScore")
  
  # Test with default strGroupLevel
  result_default <- Visualize_RiskScore(
    dfResults = dfResults,
    dfMetrics = dfMetrics,
    dfGroups = dfGroups
  )
  
  expect_s3_class(result_default, "htmlwidget")
})

test_that("Visualize_RiskScore handles different data types", {
  # Test with minimal data
  dfResults <- data.frame(
    GroupID = "Site1",
    StudyID = "Study1",
    Score = 0.5,
    stringsAsFactors = FALSE
  )
  
  dfMetrics <- data.frame(
    MetricID = "metric1",
    MetricName = "Single Metric",
    stringsAsFactors = FALSE
  )
  
  dfGroups <- data.frame(
    GroupID = "Site1",
    GroupLevel = "Site",
    stringsAsFactors = FALSE
  )
  
  result <- Visualize_RiskScore(
    dfResults = dfResults,
    dfMetrics = dfMetrics,
    dfGroups = dfGroups
  )
  
  expect_s3_class(result, "htmlwidget")
  expect_equal(result$name, "Widget_CrossStudyRiskScore")
})

test_that("Visualize_RiskScore works with various group levels", {
  dfResults <- data.frame(
    GroupID = c("Group1", "Group2", "Group3"),
    StudyID = c("Study1", "Study1", "Study2"),
    Score = c(0.1, 0.5, 0.9),
    stringsAsFactors = FALSE
  )
  
  dfMetrics <- data.frame(
    MetricID = c("metric1", "metric2"),
    MetricName = c("Metric A", "Metric B"),
    stringsAsFactors = FALSE
  )
  
  dfGroups <- data.frame(
    GroupID = c("Group1", "Group2", "Group3"),
    GroupLevel = c("Custom", "Custom", "Custom"),
    stringsAsFactors = FALSE
  )
  
  # Test different group levels
  group_levels <- c("Site", "Country", "Region", "Custom")
  
  for (level in group_levels) {
    expect_no_error({
      result <- Visualize_RiskScore(
        dfResults = dfResults,
        dfMetrics = dfMetrics,
        dfGroups = dfGroups,
        strGroupLevel = level
      )
    })
  }
})
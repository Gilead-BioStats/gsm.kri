## Test Setup
library(testthat)

## Test Code
test_that("MakeChartConfig handles input validation correctly", {
  # Test invalid lMetric (data.frame instead of list)
  expect_error(
    MakeChartConfig(
      lMetric = data.frame(x = 1),
      strChartFunction = "plot"
    ),
    "lMetric must be a list, but not a data.frame"
  )
  
  # Test invalid strChartFunction (not character)
  expect_error(
    MakeChartConfig(
      lMetric = list(),
      strChartFunction = 123
    ),
    "strChartFunction is not character"
  )
  
  # Test invalid strChartFunction (not a valid function)
  expect_error(
    MakeChartConfig(
      lMetric = list(),
      strChartFunction = "nonexistent_function"
    ),
    "strChartFunction is not a valid function"
  )
})

test_that("MakeChartConfig works with valid inputs", {
  # Test with NULL lMetric
  result_null <- MakeChartConfig(
    lMetric = NULL,
    strChartFunction = "plot"  # base R function
  )
  
  expect_true(is.list(result_null))
  
  # Test with empty lMetric
  result_empty <- MakeChartConfig(
    lMetric = list(),
    strChartFunction = "plot"
  )
  
  expect_true(is.list(result_empty))
  
  # Test with populated lMetric
  lMetric <- list(
    MetricID = "test_metric",
    MetricName = "Test Metric",
    Domain = "Test Domain"
  )
  
  result_populated <- MakeChartConfig(
    lMetric = lMetric,
    strChartFunction = "plot"
  )
  
  expect_true(is.list(result_populated))
  expect_equal(result_populated$MetricID, "test_metric")
  expect_equal(result_populated$MetricName, "Test Metric")
  expect_equal(result_populated$Domain, "Test Domain")
})

test_that("MakeChartConfig handles additional configuration settings", {
  lMetric <- list(
    MetricID = "test_metric",
    MetricName = "Test Metric"
  )
  
  # Test with additional settings
  result_with_settings <- MakeChartConfig(
    lMetric = lMetric,
    strChartFunction = "plot",
    width = 800,
    height = 600,
    color = "blue"
  )
  
  expect_true(is.list(result_with_settings))
  expect_equal(result_with_settings$MetricID, "test_metric")
  expect_equal(result_with_settings$MetricName, "Test Metric")
  expect_equal(result_with_settings$width, 800)
  expect_equal(result_with_settings$height, 600)
  expect_equal(result_with_settings$color, "blue")
})

test_that("MakeChartConfig works with various R functions", {
  lMetric <- list(MetricID = "test")
  
  # Test with different valid R functions
  base_functions <- c("plot", "summary", "mean", "sum", "length")
  
  for (func in base_functions) {
    expect_no_error({
      result <- MakeChartConfig(
        lMetric = lMetric,
        strChartFunction = func
      )
    })
    
    result <- MakeChartConfig(
      lMetric = lMetric,
      strChartFunction = func
    )
    expect_true(is.list(result))
    expect_equal(result$MetricID, "test")
  }
})

test_that("MakeChartConfig handles complex configuration hierarchies", {
  lMetric <- list(
    MetricID = "metric1",
    MetricName = "Metric 1"
  )
  
  # Test with nested configuration settings
  # This tests the configuration precedence logic
  result_complex <- MakeChartConfig(
    lMetric = lMetric,
    strChartFunction = "plot",
    metric1 = list(
      plot = list(width = 500, height = 400)
    ),
    plot = list(width = 600, color = "red"),
    global_setting = "applied_everywhere"
  )
  
  expect_true(is.list(result_complex))
  expect_equal(result_complex$MetricID, "metric1")
  expect_equal(result_complex$global_setting, "applied_everywhere")
})

test_that("MakeChartConfig preserves original metric data", {
  lMetric <- list(
    MetricID = "preserve_test",
    MetricName = "Preservation Test",
    CustomField = "custom_value",
    NumericField = 42,
    LogicalField = TRUE
  )
  
  result <- MakeChartConfig(
    lMetric = lMetric,
    strChartFunction = "plot"
  )
  
  # All original fields should be preserved
  expect_equal(result$MetricID, "preserve_test")
  expect_equal(result$MetricName, "Preservation Test")
  expect_equal(result$CustomField, "custom_value")
  expect_equal(result$NumericField, 42)
  expect_equal(result$LogicalField, TRUE)
})
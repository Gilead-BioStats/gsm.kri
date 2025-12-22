test_that("Widget_TimeSeries creates a valid HTML widget", {
  reportingResults_filter <- gsm.core::reportingResults %>%
    dplyr::filter(MetricID == "Analysis_kri0001")

  reportingMetrics_filter <- gsm.core::reportingMetrics %>%
    dplyr::filter(MetricID == "Analysis_kri0001") %>%
    as.list()

  widget <- Widget_TimeSeries(
    dfResults = reportingResults_filter,
    lMetric = reportingMetrics_filter,
    dfGroups = gsm.core::reportingGroups,
    vThreshold = reportingMetrics_filter$Threshold
  )

  expect_s3_class(widget, c("Widget_TimeSeries", "htmlwidget"))
})

test_that("Widget_TimeSeries works with custom vOutcomeOptions", {
  reportingResults_filter <- gsm.core::reportingResults %>%
    dplyr::filter(MetricID == "Analysis_kri0001") %>%
    dplyr::mutate(CustomMetric = Numerator * 2)

  reportingMetrics_filter <- gsm.core::reportingMetrics %>%
    dplyr::filter(MetricID == "Analysis_kri0001") %>%
    as.list()

  widget <- Widget_TimeSeries(
    dfResults = reportingResults_filter,
    lMetric = reportingMetrics_filter,
    dfGroups = gsm.core::reportingGroups,
    vThreshold = reportingMetrics_filter$Threshold,
    strOutcome = "CustomMetric",
    vOutcomeOptions = c("Score", "Metric", "CustomMetric")
  )

  expect_s3_class(widget, c("Widget_TimeSeries", "htmlwidget"))
})

test_that("Widget_TimeSeries assertions work", {
  reportingResults_filter <- gsm.core::reportingResults %>%
    dplyr::filter(MetricID == "Analysis_kri0001")

  reportingMetrics_filter <- gsm.core::reportingMetrics %>%
    dplyr::filter(MetricID == "Analysis_kri0001") %>%
    as.list()

  reportingResults_modified <- as.list(reportingResults_filter)

  expect_error(
    Widget_TimeSeries(
      dfResults = reportingResults_modified,
      lMetric = reportingMetrics_filter
    ),
    "dfResults is not a data.frame"
  )

  expect_error(
    Widget_TimeSeries(
      dfResults = reportingResults_filter,
      lMetric = reportingMetrics_filter,
      strOutcome = "InvalidOutcome"
    ),
    "strOutcome must be one of vOutcomeOptions"
  )

  expect_error(
    Widget_TimeSeries(
      dfResults = reportingResults_filter,
      lMetric = reportingMetrics_filter,
      vOutcomeOptions = 123
    ),
    "vOutcomeOptions is not a character vector"
  )

  expect_error(
    Widget_TimeSeries(
      dfResults = reportingResults_filter,
      lMetric = reportingMetrics_filter,
      bAddGroupSelect = "TRUE"
    ),
    "bAddGroupSelect is not a logical"
  )
})

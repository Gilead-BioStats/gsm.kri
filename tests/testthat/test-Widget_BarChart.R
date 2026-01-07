test_that("Widget_BarChart creates a valid HTML widget {#166}", {
  reportingResults_filter <- gsm.core::reportingResults %>%
    dplyr::filter(MetricID == "Analysis_kri0001" & SnapshotDate == max(SnapshotDate))

  reportingMetrics_filter <- gsm.core::reportingMetrics %>%
    dplyr::filter(MetricID == "Analysis_kri0001") %>%
    as.list()

  widget <- Widget_BarChart(
    dfResults = reportingResults_filter,
    dfGroups = gsm.core::reportingGroups,
    lMetric = reportingMetrics_filter,
    vThreshold = reportingMetrics_filter$Threshold
  )

  expect_s3_class(widget, c("Widget_BarChart", "htmlwidget"))
})

test_that("Widget_BarChart works with custom vOutcomeOptions {#166}", {
  reportingResults_filter <- gsm.core::reportingResults %>%
    dplyr::filter(MetricID == "Analysis_kri0001" & SnapshotDate == max(SnapshotDate)) %>%
    dplyr::mutate(CustomMetric = Numerator * 2)

  reportingMetrics_filter <- gsm.core::reportingMetrics %>%
    dplyr::filter(MetricID == "Analysis_kri0001") %>%
    as.list()

  widget <- Widget_BarChart(
    dfResults = reportingResults_filter,
    dfGroups = gsm.core::reportingGroups,
    lMetric = reportingMetrics_filter,
    vThreshold = reportingMetrics_filter$Threshold,
    strOutcome = "CustomMetric",
    vOutcomeOptions = c("Score", "Metric", "CustomMetric", "Numerator")
  )

  expect_s3_class(widget, c("Widget_BarChart", "htmlwidget"))
})

test_that("Widget_BarChart assertions work {#166}", {
  reportingResults_filter <- gsm.core::reportingResults %>%
    dplyr::filter(MetricID == "Analysis_kri0001" & SnapshotDate == max(SnapshotDate))

  reportingMetrics_filter <- gsm.core::reportingMetrics %>%
    dplyr::filter(MetricID == "Analysis_kri0001") %>%
    as.list()

  reportingResults_modified <- as.list(reportingResults_filter)

  expect_error(
    Widget_BarChart(
      dfResults = reportingResults_modified,
      lMetric = reportingMetrics_filter
    ),
    "dfResults is not a data.frame"
  )

  expect_error(
    Widget_BarChart(
      dfResults = reportingResults_filter,
      lMetric = reportingMetrics_filter,
      strOutcome = "InvalidOutcome"
    ),
    "strOutcome must be one of vOutcomeOptions"
  )

  expect_error(
    Widget_BarChart(
      dfResults = reportingResults_filter,
      lMetric = reportingMetrics_filter,
      vOutcomeOptions = 123
    ),
    "vOutcomeOptions is not a character vector"
  )

  expect_error(
    Widget_BarChart(
      dfResults = reportingResults_filter,
      lMetric = reportingMetrics_filter,
      bAddGroupSelect = "TRUE"
    ),
    "bAddGroupSelect is not a logical"
  )
})

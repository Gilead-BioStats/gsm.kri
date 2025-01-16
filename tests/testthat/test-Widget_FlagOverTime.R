test_that("Widget_FlagOverTime creates a valid HTML widget", {
  widget <- Widget_FlagOverTime(
    gsm::reportingResults,
    gsm::reportingMetrics,
    strGroupLevel = "Site"
  )
  expect_s3_class(widget, c("WidgetGroupOverview", "htmlwidget"))
  expect_true(
    stringr::str_detect(
      widget$x$gtFlagOverTime,
      "<table class=\"gt_table\""
    )
  )
})

test_that("Widget_FlagOverTime assertions works", {
  reportingResults_modified <- as.list(gsm::reportingResults)
  reportingMetrics_modified <- as.list(gsm::reportingMetrics)
  expect_error(
    Widget_FlagOverTime(reportingResults_modified, gsm::reportingMetrics, strGroupLevel = "Site"),
    "dfResults is not a data.frame"
  )
  expect_error(
    Widget_FlagOverTime(gsm::reportingResults, reportingMetrics_modified, strGroupLevel = "Site"),
    "dfMetrics is not a data.frame"
  )
  expect_error(
    Widget_FlagOverTime(gsm::reportingResults, gsm::reportingMetrics, strGroupLevel = 1),
    "strGroupLevel is not a character"
  )
})

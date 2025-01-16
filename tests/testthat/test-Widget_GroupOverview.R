test_that("Widget_GroupOverview creates a valid HTML widget", {
  widget <- Widget_GroupOverview(gsm::reportingResults, gsm::reportingMetrics, gsm::reportingGroups, strGroupLevel = "Site")
  expect_s3_class(widget, c("WidgetGroupOverview", "htmlwidget"))
})

test_that("Widget_GroupOverview returns expected data", {
  widget <- Widget_GroupOverview(gsm::reportingResults, gsm::reportingMetrics, gsm::reportingGroups, strGroupLevel = "Site")

  expect_named(
    fromJSON(widget$x$dfResults),
    c(
      "GroupID", "GroupLevel", "Numerator", "Denominator", "Metric", "Score",
      "Flag", "MetricID", "SnapshotDate", "StudyID"
    )
  )

  expect_s3_class(fromJSON(widget$x$dfGroups), "data.frame")
  expect_equal(fromJSON(widget$x$strGroupSubset), "red")
})

test_that("Widget_GroupOverview returns correct class", {
  widgetOutput <- Widget_GroupOverviewOutput("test")
  expect_s3_class(widgetOutput, c("shiny.tag.list", "list"))
})

test_that("Widget_GroupOverview uses correct Group or errors out when strGroupLevel is NULL", {
  widget <- Widget_GroupOverview(gsm::reportingResults, gsm::reportingMetrics, gsm::reportingGroups)
  sampleGroupLevel <- gsm::reportingMetrics$GroupLevel %>%
    unique() %>%
    jsonlite::toJSON(na = "string", auto_unbox = T)
  expect_equal(widget$x$strGroupLevel, sampleGroupLevel)
})

test_that("Widget_GroupOverview assertions works", {
  reportingResults_modified <- as.list(gsm::reportingResults)
  reportingMetrics_modified <- as.list(gsm::reportingMetrics)
  reportingGroups_modified <- as.list(gsm::reportingGroups)
  expect_error(
    Widget_GroupOverview(reportingResults_modified, gsm::reportingMetrics, gsm::reportingGroups),
    "dfResults is not a data.frame"
  )
  expect_error(
    Widget_GroupOverview(gsm::reportingResults, reportingMetrics_modified, gsm::reportingGroups),
    "dfMetrics is not a data.frame"
  )
  expect_error(
    Widget_GroupOverview(gsm::reportingResults, gsm::reportingMetrics, reportingGroups_modified),
    "dfGroups is not a data.frame"
  )
  expect_error(
    Widget_GroupOverview(gsm::reportingResults, gsm::reportingMetrics, gsm::reportingGroups, strGroupSubset = 1),
    "strGroupSubset is not a character"
  )
  expect_error(
    Widget_GroupOverview(gsm::reportingResults, gsm::reportingMetrics, gsm::reportingGroups, strGroupLabelKey = 1),
    "strGroupLabelKey is not a character"
  )
  expect_error(
    Widget_GroupOverview(gsm::reportingResults, gsm::reportingMetrics, gsm::reportingGroups, bDebug = 1),
    "bDebug is not a logical"
  )
})

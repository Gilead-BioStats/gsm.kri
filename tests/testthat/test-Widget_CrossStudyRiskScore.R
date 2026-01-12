testthat::test_that("Widget_CrossStudyRiskScore creates an htmlwidget (#71)", {

  dfResults <- data.frame(
    MetricID = "Analysis_srs0001",
    Value = 0.75
  )

  dfMetrics <- data.frame(
    MetricID = "Analysis_srs0001",
    MetricName = "Risk Score"
  )

  dfGroups <- data.frame(
    GroupID = "SiteA",
    Site = "SiteA"
  )

  mock_summary <- data.frame(
    GroupID = "SiteA",
    RiskScore = 0.75
  )

  testthat::local_mocked_bindings(
    SummarizeCrossStudy = function(dfResults, strGroupLevel, dfGroups) {
      mock_summary
    }
  )

  widget <- Widget_CrossStudyRiskScore(
    dfResults = dfResults,
    dfMetrics = dfMetrics,
    dfGroups = dfGroups,
    strGroupLevel = "Site"
  )

  expect_s3_class(widget, "htmlwidget")
})

testthat::test_that("Widget_CrossStudyRiskScore errors if Analysis_srs0001 is missing (#71)", {

  dfResults <- data.frame(
    MetricID = "OtherMetric",
    Value = 1
  )

  dfMetrics <- data.frame(
    MetricID = "OtherMetric",
    MetricName = "Other"
  )

  dfGroups <- data.frame(
    GroupID = "SiteA",
    Site = "SiteA"
  )

  expect_error(
    Widget_CrossStudyRiskScore(
      dfResults = dfResults,
      dfMetrics = dfMetrics,
      dfGroups = dfGroups
    ),
    "Analysis_srs0001"
  )
})

testthat::test_that("Widget_CrossStudyRiskScore validates inputs (#71)", {

  dfResults <- data.frame(
    MetricID = "Analysis_srs0001",
    Value = 0.5
  )

  dfMetrics <- data.frame(
    MetricID = "Analysis_srs0001",
    MetricName = "Risk Score"
  )

  dfGroups <- data.frame(
    GroupID = "SiteA",
    Site = "SiteA"
  )

  expect_error(
    Widget_CrossStudyRiskScore(
      dfResults = "not a data frame",
      dfMetrics = dfMetrics,
      dfGroups = dfGroups
    ),
    class = "simpleError"
  )

  expect_error(
    Widget_CrossStudyRiskScore(
      dfResults = dfResults,
      dfMetrics = "not a data frame",
      dfGroups = dfGroups
    ),
    class = "simpleError"
  )

  expect_error(
    Widget_CrossStudyRiskScore(
      dfResults = dfResults,
      dfMetrics = dfMetrics,
      dfGroups = "not a data frame"
    ),
    class = "simpleError"
  )
})


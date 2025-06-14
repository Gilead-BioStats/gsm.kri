test_that("Empty dfs return empty dfs", {
  dfResults_empty <- head(gsm.core::reportingResults, 0)
  dfGroups_empty <- head(gsm.core::reportingGroups, 0)
  expect_equal(
    MakeMetricTable(dfResults_empty, dfGroups_empty),
    data.frame(
      StudyID = character(), GroupID = character(), MetricID = character(),
      Group = character(), SnapshoteDate = as.Date(integer()),
      Enrolled = integer(), Numerator = integer(),
      Denominator = integer(), Metric = double(), Score = double(),
      Flag = character()
    )
  )
})

test_that("Correct data structure when proper dataframe is passed", {
  reportingResults_filt <- gsm.core::reportingResults %>%
    dplyr::filter(MetricID == unique(gsm.core::reportingResults$MetricID)[[1]])
  result <- MakeMetricTable(reportingResults_filt, gsm.core::reportingGroups)
  expect_s3_class(result, "data.frame")
  expect_setequal(
    colnames(result),
    c(
      "StudyID", "GroupID", "MetricID", "Group", "SnapshotDate", "Enrolled",
      "Numerator", "Denominator", "Metric", "Score", "Flag"
    )
  )
})

test_that("Flag filtering works correctly", {
  # Verify that our test user is still in sample data.
  expect_gt(
    length(grep("Joanne", gsm.core::reportingGroups$Value)),
    0
  )
  reportingResults_filt <- gsm.core::reportingResults %>%
    dplyr::filter(MetricID == unique(gsm.core::reportingResults$MetricID)[[1]])
  result <- MakeMetricTable(reportingResults_filt, gsm.core::reportingGroups)
  expect_s3_class(result, "data.frame")
  expect_length(
    grep("Joanne", result$Group),
    0
  )
})

test_that("Score rounding works correctly", {
  reportingResults_filt <- gsm.core::reportingResults %>%
    dplyr::filter(MetricID == unique(gsm.core::reportingResults$MetricID)[[1]])
  result <- MakeMetricTable(reportingResults_filt, gsm.core::reportingGroups)
  expect_true(any(grepl("^-\\d+\\.\\d{2}$", as.character(result$Score))))
})

test_that("Errors informatively when multiple MetricIDs passed in", {
  expect_error(
    MakeMetricTable(gsm.core::reportingResults, gsm.core::reportingGroups)
  )
})

test_that("Enrolled is an integer", {
  reportingResults_filt <- gsm.core::reportingResults %>%
    dplyr::filter(MetricID == unique(gsm.core::reportingResults$MetricID)[[1]])
  result <- MakeMetricTable(reportingResults_filt, gsm.core::reportingGroups)
  expect_type(result$Enrolled, "integer")
})

test_that("Output is expected object", {
  zero_flags <- c("0X4629", "0X2532")
  flags <- c("0X9360", "0X5895", "0X9737")

  reportingResults_filt <- gsm.core::reportingResults %>%
    FilterByLatestSnapshotDate() %>%
    dplyr::filter(
      MetricID == unique(gsm.core::reportingResults$MetricID)[[1]],
      GroupID %in% c(zero_flags, flags)
    ) %>%
    # Add an NA row back for representation.
    dplyr::bind_rows(
      tibble::tibble(
        GroupID = "0X000",
        GroupLevel = "Site",
        Numerator = 4L,
        Denominator = 8L,
        Metric = 0.5,
        Score = NA,
        Flag = NA,
        MetricID = "Analysis_kri0001",
        SnapshotDate = as.Date("2012-12-31"),
        StudyID = "AA-AA-000-0000"
      )
    )
  expect_snapshot({
    MakeMetricTable(reportingResults_filt, gsm.core::reportingGroups)
  })
})

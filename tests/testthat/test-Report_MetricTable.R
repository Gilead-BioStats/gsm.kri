test_that("Empty data frames return default message", {
  dfResults_empty <- gsm.core::reportingResults[-c(1:nrow(gsm.core::reportingResults)), ]
  dfGroups_empty <- gsm.core::reportingGroups[-c(1:nrow(gsm.core::reportingGroups)), ]
  expect_equal(
    Report_MetricTable(dfResults_empty, dfGroups_empty),
    htmltools::tags$p("Nothing flagged for this KRI.")
  )
})

test_that("Default message when nothing flagged", {
  dfResults <- dplyr::filter(
    gsm.core::reportingResults,
    MetricID == "kri0001",
    Flag == 0
  )
  dfGroups <- gsm.core::reportingGroups
  expect_equal(
    Report_MetricTable(dfResults, dfGroups),
    htmltools::tags$p("Nothing flagged for this KRI.")
  )
})

test_that("Correct data structure when proper dataframe is passed", {
  reportingResults_filt <- gsm.core::reportingResults %>%
    dplyr::filter(MetricID == unique(gsm.core::reportingResults$MetricID)[1])
  result <- Report_MetricTable(reportingResults_filt, gsm.core::reportingGroups)
  expect_s3_class(result, "gt_tbl")
  expect_true(is.character(result$`_data`$Group))
  expect_true(all(result$`_data`$Metric >= 0 & result$`_data`$Metric < 1))
})

test_that("Flag filtering works correctly", {
  reportingResults_filt <- gsm.core::reportingResults %>%
    dplyr::filter(MetricID == unique(gsm.core::reportingResults$MetricID)[1])
  result <- Report_MetricTable(reportingResults_filt, gsm.core::reportingGroups)
  expect_s3_class(result, "gt_tbl")
  expect_true(all(result$`_data`$Flag != 0))
})

test_that("Score rounding works correctly", {
  reportingResults_filt <- gsm.core::reportingResults %>%
    dplyr::filter(MetricID == unique(gsm.core::reportingResults$MetricID)[1])
  result <- Report_MetricTable(reportingResults_filt, gsm.core::reportingGroups)
  expect_true(any(grepl("0.05", result)))
})

test_that("Errors out when multiple MetricIDs passed in", {
  expect_error(Report_MetricTable(gsm.core::reportingResults, gsm.core::reportingGroups))
})

test_that("Runs with just results with NULL group argument", {
  reportingResults_filt <- gsm.core::reportingResults %>%
    dplyr::filter(MetricID == unique(gsm.core::reportingResults$MetricID)[1])
  result <- Report_MetricTable(reportingResults_filt)
  expect_s3_class(result, "gt_tbl")
})

test_that("Output is expected object", {
  zero_flags <- c("0X003", "0X039")
  red_flags <- c("0X113", "0X025")
  amber_flags <- c("0X119", "0X046")

  reportingResults_filt <- gsm.core::reportingResults %>%
    FilterByLatestSnapshotDate() %>%
    dplyr::filter(
      MetricID == unique(gsm.core::reportingResults$MetricID)[[1]],
      GroupID %in% c(zero_flags, red_flags, amber_flags)
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
        MetricID = "kri0001",
        SnapshotDate = as.Date("2012-12-31"),
        StudyID = "ABC-123"
      )
    )
  expect_snapshot({
    x <- Report_MetricTable(reportingResults_filt, gsm.core::reportingGroups)
    str(x, max.level = 2)
  })
})

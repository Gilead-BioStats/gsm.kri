## Test Setup
kri_workflows <- MakeWorkflowList(
  strNames = c("kri", "srs"),
  strPath = "inst/workflow/2_metrics",
  strPackage = "gsm.kri"
)
reporting_workflows <- MakeWorkflowList(strPackage = "gsm.reporting")
analyzed <- RunWorkflows(
  kri_workflows,
  lData = c(mapped_data, list(lWorkflows = kri_workflows))
) %>%
  suppressWarnings()
outputs <- map(reporting_workflows, \(x) x$steps[[length(x$steps)]]$output)

## Test Code
testthat::test_that("Qual: Given summarized analytics data, a properly specified reporting workflow creates cross-sectional results data set with one record per metric per group  (#159)", {
  test <- RunWorkflows(
    reporting_workflows,
    lData = c(
      mapped_data,
      list(lAnalyzed = analyzed, lWorkflows = kri_workflows)
    )
  ) %>%
    suppressWarnings()

  # test output stucture
  expect_true(all(map_lgl(test, \(x) is.data.frame(x))))
  expect_equal(nrow(test$Reporting_Metrics), length(analyzed))
  expect_equal(
    nrow(test$Reporting_Results),
    analyzed %>%
      map(\(x) {
        nrow(x$Analysis_Summary)
      }) %>%
      do.call(sum, .)
  )

  # test output content
  expect_true(all(outputs %in% names(test)))
  expect_equal(
    unique(test$Reporting_Results$GroupID),
    analyzed %>%
      map(\(x) {
        x$Analysis_Summary$GroupID
      }) %>%
      do.call(c, .) %>%
      unique()
  )
  ## construct metrics df with kri_workflows meta and compare to output
  metrics_df <- kri_workflows %>%
    purrr::map(function(wf) {
      return(tibble::as_tibble(wf$meta))
    }) %>%
    purrr::list_rbind() %>%
    mutate(
      MetricID = paste0(
        .data$Type,
        "_",
        .data$ID
      )
    )
  expect_equal(test$Reporting_Metrics, metrics_df)
  expect_equal(
    test$Reporting_Groups,
    bind_rows(
      mapped_data$Mapped_STUDY,
      mapped_data$Mapped_SITE,
      mapped_data$Mapped_COUNTRY
    )
  )
})

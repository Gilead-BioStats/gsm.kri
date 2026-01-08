## Test Setup
kri_workflows <- MakeWorkflowList(
  strNames = c("kri", "srs"),
  strPath = GetDefaultKRIPath()
)
reporting_workflows <- MakeWorkflowList(strPackage = "gsm.reporting")
analyzed <- RunWorkflows(
  kri_workflows,
  lData = c(mapped_data, list(lWorkflows = kri_workflows))
) %>%
  suppressWarnings()
outputs <- map(reporting_workflows, \(x) x$steps[[length(x$steps)]]$output)
historical_reporting_results <- gsm.core::reportingResults %>%
  dplyr::filter(SnapshotDate < max(.data$SnapshotDate))
## Test Code
testthat::test_that("Qual: Given summarized analytics data and historical reporting results data, a properly specified reporting workflow creates cross-sectional results data set including changes from previous snapshot with one record per metric per group (#159)", {
  test <- RunWorkflows(
    reporting_workflows,
    lData = c(
      mapped_data,
      list(
        lAnalyzed = analyzed,
        lWorkflows = kri_workflows,
        Reporting_Results_Longitudinal = historical_reporting_results
      )
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

  # test output content basics
  expect_true(all(outputs %in% names(test)))
  expect_true(all(
    unique(test$Reporting_Results$GroupID) %in%
      (analyzed %>%
        map(\(x) {
          x$Analysis_Summary$GroupID
        }) %>%
        do.call(c, .) %>%
        unique())
  ))
  expect_true(all(
    apply(
      expand.grid(
        c("Numerator", "Denominator", "Metric", "Score", "Flag"),
        c("Previous", "Change", "PercentChange")
      ),
      1,
      paste,
      collapse = "_"
    ) %in%
      names(test$Reporting_Results)
  ))
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

  # manually construct delta output and compare with test output
  dfResults_combined <- dplyr::bind_rows(
    historical_reporting_results,
    test$Reporting_Results
  ) %>%
    select(
      StudyID,
      GroupLevel,
      GroupID,
      MetricID,
      SnapshotDate,
      Numerator,
      Denominator,
      Metric,
      Score,
      Flag
    )

  dfChanges <- dfResults_combined %>%
    tidyr::pivot_longer(
      cols = all_of(c("Numerator", "Denominator", "Metric", "Score", "Flag")),
      names_to = "Param",
      values_to = "Value"
    ) %>%
    dplyr::mutate(
      Param = factor(
        .data$Param,
        levels = c("Numerator", "Denominator", "Metric", "Score", "Flag")
      )
    ) %>%
    dplyr::group_by(across(all_of(c(
      "StudyID",
      "GroupLevel",
      "GroupID",
      "MetricID",
      "Param"
    )))) %>%
    dplyr::arrange("SnapshotDate", .by_group = TRUE) %>%
    dplyr::mutate(
      Previous = dplyr::lag(.data$Value),
      Change = Value - dplyr::lag(.data$Value),
      PercentChange = .data$Change / dplyr::lag(.data$Value) * 100,
      SnapshotDate_Previous = dplyr::lag(.data$SnapshotDate)
    ) %>%
    dplyr::ungroup() %>%
    dplyr::arrange(across(all_of(
      c(
        "StudyID",
        "GroupLevel",
        "GroupID",
        "MetricID",
        "SnapshotDate_Previous",
        "Param",
        "SnapshotDate"
      )
    ))) %>%
    tidyr::pivot_wider(
      names_from = Param,
      values_from = c(Value, Previous, Change, PercentChange),
      names_glue = "{Param}_{.value}",
    ) %>%
    dplyr::rename_with(~ gsub("_Value", "", .x), tidyr::ends_with("_Value"))

  dfChanges <- gsm.kri::FilterByLatestSnapshotDate(dfChanges)

  expect_equal(test$Reporting_Results, dfChanges)

  # test individual columns by hand
  ## join with historical results to check previous values
  results_joined <- left_join(
    test$Reporting_Results,
    historical_reporting_results[
      historical_reporting_results$SnapshotDate ==
        max(historical_reporting_results$SnapshotDate),
    ],
    by = c("StudyID", "GroupLevel", "GroupID", "MetricID")
  )
  expect_equal(
    sort(test$Reporting_Results$Numerator_Change),
    sort(results_joined$Numerator.x - results_joined$Numerator.y)
  )
  expect_equal(
    sort(test$Reporting_Results$Denominator_Change),
    sort(results_joined$Denominator.x - results_joined$Denominator.y)
  )
  expect_equal(
    sort(test$Reporting_Results$Metric_Change),
    sort(results_joined$Metric.x - results_joined$Metric.y)
  )
  expect_equal(
    sort(test$Reporting_Results$Score_Change),
    sort(results_joined$Score.x - results_joined$Score.y)
  )
  expect_equal(
    sort(test$Reporting_Results$Flag_Change),
    sort(results_joined$Flag.x - results_joined$Flag.y)
  )
  expect_equal(
    sort(test$Reporting_Results$Numerator_PercentChange),
    sort(
      (results_joined$Numerator.x - results_joined$Numerator.y) /
        results_joined$Numerator.y *
        100
    )
  )
  expect_equal(
    sort(test$Reporting_Results$Denominator_PercentChange),
    sort(
      (results_joined$Denominator.x - results_joined$Denominator.y) /
        results_joined$Denominator.y *
        100
    )
  )
  expect_equal(
    sort(test$Reporting_Results$Metric_PercentChange),
    sort(
      (results_joined$Metric.x - results_joined$Metric.y) /
        results_joined$Metric.y *
        100
    )
  )
  expect_equal(
    sort(test$Reporting_Results$Score_PercentChange),
    sort(
      (results_joined$Score.x - results_joined$Score.y) /
        results_joined$Score.y *
        100
    )
  )
  expect_equal(
    sort(test$Reporting_Results$Flag_PercentChange),
    sort(
      (results_joined$Flag.x - results_joined$Flag.y) /
        results_joined$Flag.y *
        100
    )
  )
})

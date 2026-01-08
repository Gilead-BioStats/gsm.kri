## Test Setup
kri_workflows <- MakeWorkflowList(
  strNames = c(paste0("kri000", 1:9), paste0("kri00", 10:12), "srs"),
  strPath = GetDefaultKRIPath()
)
analyzed <- RunWorkflows(
  kri_workflows,
  lData = c(mapped_data, list(lWorkflows = kri_workflows))
) %>%
  suppressWarnings()
# Exclude pk/pd since thats not counting to SRS

## Test Code
testthat::test_that("Qual: Given summarized analytics data, all appropriate aspects of site risk score are available to calculate it correctly (#159)", {
  # Check all kri workflows have 1:1 mapped flags and respective weights, exclude PK-PD and SRS
  expect_equal(
    map(kri_workflows[-13], function(x) {
      length(strsplit(x$meta$Flag, ",")[[1]])
    }),
    map(kri_workflows[-13], function(x) {
      length(strsplit(x$meta$RiskScoreWeight, ",")[[1]])
    })
  )

  # Check that all Analysis_Flagged data frames contain columns for Weight and WeightMax
  expect_true(all(unlist(map(analyzed[-13], function(x) {
    all(c("Weight", "WeightMax") %in% names(x$Analysis_Flagged))
  }))))

  # Check Site Risk Score matches by hand vs using gsm.kri functions
  global_weight <- map2(
    analyzed[-13],
    names(analyzed)[-13],
    function(x, y) {
      x$Analysis_Flagged %>%
        mutate(MetricID = y)
    }
  ) %>%
    bind_rows() %>%
    summarize(
      GlobalDenominator = sum(max(WeightMax), na.rm = TRUE),
      .by = MetricID
    ) %>%
    pull(GlobalDenominator) %>%
    sum

  SRS_by_hand <- map2(
    analyzed[-13],
    names(analyzed)[-13],
    function(x, y) {
      x$Analysis_Flagged %>%
        mutate(MetricID = y)
    }
  ) %>%
    bind_rows() %>%
    filter(!is.na(.data$Weight) & !is.na(.data$WeightMax)) %>%
    group_by(GroupID) %>%
    summarize(
      Numerator = sum(Weight, na.rm = TRUE),
      Denominator = global_weight,
      Metric = Numerator / Denominator * 100,
      Score = Metric
    ) %>%
    ungroup() %>%
    mutate(GroupLevel = "Site", MetricID = "Analysis_srs0001", Flag = NA) %>%
    select(
      GroupLevel,
      GroupID,
      MetricID,
      Numerator,
      Denominator,
      Metric,
      Score,
      Flag
    )

  SRS_auto <- analyzed[[13]]$Analysis_Summary
  expect_equal(SRS_by_hand, SRS_auto)
})

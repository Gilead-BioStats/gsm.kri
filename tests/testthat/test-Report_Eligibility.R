dfResults <- tibble::tibble(
  GroupID = c("Study01", "Study01", "Study01"),
  GroupLevel = rep("Study", 3),
  Numerator = c(5),
  Denominator = c(20),
  Metric = c(0.25),
  Score = c(5),
  Flag = c(2),
  MetricID = rep("study_eligibility", 3),
  SnapshotDate = rep(as.Date("2025-01-01"), 3)
)

dfMetrics <- tibble::tibble(
  MetricID = "study_eligibility",
  nPropRate = 0.3,
  nNumDeviations = 3
)

dfGroups <- tibble::tibble(
  GroupID = "Study01",
  Param = "studyid",
  Value = "Study01",
  GroupLevel = "Study"
)

dfEXCLUSION <- tibble::tibble(
  studyid = "Study01",
  invid = "Site01",
  country = "US",
  subjid = "Participant01",
  Source = "Eligibility IPD",
  ietestcd_concat = NA,
  dvdtm = "2025-01-01 00:00:00",
  eligibility_criteria = "Inclusion/Exclusion description"
)

lListings <- list(
  IE = dfEXCLUSION
)

test_that("Ensure report renders normally", {
  expect_output(
    Report_Eligibility(
      dfResults = dfResults,
      dfMetrics = dfMetrics,
      dfGroups = dfGroups,
      lListings = lListings,
      strOutputDir = tempdir()
    ) %>% grepl(getwd(), .),
    fixed = TRUE
  )
})

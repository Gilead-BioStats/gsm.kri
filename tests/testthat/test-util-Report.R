test_that("[ FilterByFlags ] returns group/metric combinations with a flag at any snapshot.", {
  dfResultsFlaggedActual <- FilterByFlags(gsm::reportingResults)

  strRiskSignals <- gsm::reportingResults %>%
    filter(
      .data$Flag != 0
    ) %>%
    mutate(
      riskSignalID = paste(.data$GroupID, .data$MetricID, sep = "_")
    ) %>%
    distinct(
      riskSignalID
    ) %>%
    pull(
      riskSignalID
    )

  dfResultsFlaggedExpected <- gsm::reportingResults %>%
    filter(
      paste(.data$GroupID, .data$MetricID, sep = "_") %in% strRiskSignals
    ) %>%
    as_tibble()

  expect_equal(
    dfResultsFlaggedActual,
    dfResultsFlaggedExpected
  )
})

test_that("[ FilterByFlags ] returns group/metric combinations with a flag at most recent snapshot.", {
  dfResultsFlaggedActual <- FilterByFlags(gsm::reportingResults, bCurrentlyFlagged = TRUE)

  strRiskSignals <- gsm::reportingResults %>%
    FilterByLatestSnapshotDate() %>%
    filter(
      .data$Flag != 0
    ) %>%
    mutate(
      riskSignalID = paste(.data$GroupID, .data$MetricID, sep = "_")
    ) %>%
    distinct(
      riskSignalID
    ) %>%
    pull(
      riskSignalID
    )

  dfResultsFlaggedExpected <- gsm::reportingResults %>%
    filter(
      paste(.data$GroupID, .data$MetricID, sep = "_") %in% strRiskSignals
    ) %>%
    as_tibble()

  expect_equal(
    dfResultsFlaggedActual,
    dfResultsFlaggedExpected
  )
})

create_po_test_results <- function() {
  # Two studies, two sites each, two metrics. Includes risk score metric so
  # the helper handles "all metrics" per Q1.
  tibble::tibble(
    StudyID = rep(c("STUDY001", "STUDY002"), each = 4),
    SnapshotDate = as.Date("2025-06-01"),
    GroupLevel = "Site",
    GroupID = rep(c("SITE0001", "SITE0002"), times = 4),
    MetricID = rep(c("kri0001", "kri0002"), times = 4),
    Numerator = c(10, 5, 20, 4, 30, 6, 40, 8),
    Denominator = c(100, 100, 100, 100, 200, 200, 200, 200),
    Score = 0
  )
}

create_po_test_groups <- function() {
  tibble::tibble(
    StudyID = c("STUDY001", "STUDY001", "STUDY002", "STUDY002"),
    GroupID = c("STUDY001", "STUDY001", "STUDY002", "STUDY002"),
    GroupLevel = "Study",
    Param = c("therapeutic_area", "phase", "therapeutic_area", "phase"),
    Value = c("Oncology", "P2", "Virology", "P3")
  )
}

testthat::test_that("SummarizePortfolioOverview returns required columns (#212)", {
  result <- SummarizePortfolioOverview(
    dfResults = create_po_test_results(),
    dfGroups = create_po_test_groups()
  )

  testthat::expect_true(is.data.frame(result))
  testthat::expect_true(all(
    c(
      "GroupCategory",
      "GroupValue",
      "MetricID",
      "Numerator",
      "Denominator",
      "Rate",
      "NumStudies"
    ) %in%
      names(result)
  ))
})

testthat::test_that("SummarizePortfolioOverview totals roll up across all studies (#212)", {
  result <- SummarizePortfolioOverview(
    dfResults = create_po_test_results(),
    dfGroups = create_po_test_groups()
  )

  total_kri0001 <- result[
    result$GroupCategory == "Total" & result$MetricID == "kri0001",
  ]
  # STUDY001: 10+20=30 num, 100+100=200 den. STUDY002: 30+40=70 num, 200+200=400 den.
  testthat::expect_equal(total_kri0001$Numerator, 100)
  testthat::expect_equal(total_kri0001$Denominator, 600)
  testthat::expect_equal(round(total_kri0001$Rate, 4), round(100 / 600, 4))
  testthat::expect_equal(total_kri0001$NumStudies, 2)
})

testthat::test_that("SummarizePortfolioOverview drill-down by therapeutic_area (#212)", {
  result <- SummarizePortfolioOverview(
    dfResults = create_po_test_results(),
    dfGroups = create_po_test_groups()
  )

  onc <- result[
    result$GroupCategory == "therapeutic_area" &
      result$GroupValue == "Oncology" &
      result$MetricID == "kri0001",
  ]
  # STUDY001 only: 10+20=30 num, 100+100=200 den.
  testthat::expect_equal(onc$Numerator, 30)
  testthat::expect_equal(onc$Denominator, 200)
  testthat::expect_equal(onc$NumStudies, 1)
})

testthat::test_that("SummarizePortfolioOverview returns Rate=NA when denominator is 0 (#212)", {
  dfResults <- create_po_test_results()
  dfResults$Denominator <- 0

  result <- SummarizePortfolioOverview(
    dfResults = dfResults,
    dfGroups = create_po_test_groups()
  )

  testthat::expect_true(all(is.na(result$Rate)))
})

testthat::test_that("SummarizePortfolioOverview keeps only the latest snapshot (#212, Q5)", {
  dfA <- create_po_test_results()
  dfA$SnapshotDate <- as.Date("2025-05-01")
  dfA$Numerator <- 999  # should be excluded
  dfB <- create_po_test_results()
  dfResults <- dplyr::bind_rows(dfA, dfB)

  result <- SummarizePortfolioOverview(
    dfResults = dfResults,
    dfGroups = create_po_test_groups()
  )

  total_kri0001 <- result[
    result$GroupCategory == "Total" & result$MetricID == "kri0001",
  ]
  # Should match the single-snapshot total (100 / 600), not the inflated number.
  testthat::expect_equal(total_kri0001$Numerator, 100)
  testthat::expect_equal(total_kri0001$Denominator, 600)
})

testthat::test_that("SummarizePortfolioOverview keeps the latest snapshot per study (#212, Q5)", {
  # Studies snapshot on independent cadences. STUDY001's latest is 2025-04-01;
  # STUDY002's latest is 2025-06-01. A global max would drop STUDY001 entirely.
  base <- create_po_test_results()
  s1_old <- base[base$StudyID == "STUDY001", ]
  s1_old$SnapshotDate <- as.Date("2025-03-01")
  s1_old$Numerator <- 999 # excluded by per-study latest
  s1_new <- base[base$StudyID == "STUDY001", ]
  s1_new$SnapshotDate <- as.Date("2025-04-01")
  s2_old <- base[base$StudyID == "STUDY002", ]
  s2_old$SnapshotDate <- as.Date("2025-05-01")
  s2_old$Numerator <- 999 # excluded by per-study latest
  s2_new <- base[base$StudyID == "STUDY002", ]
  s2_new$SnapshotDate <- as.Date("2025-06-01")
  dfResults <- dplyr::bind_rows(s1_old, s1_new, s2_old, s2_new)

  result <- SummarizePortfolioOverview(
    dfResults = dfResults,
    dfGroups = create_po_test_groups()
  )

  total_kri0001 <- result[
    result$GroupCategory == "Total" & result$MetricID == "kri0001",
  ]
  # Both studies should contribute their own latest snapshot, matching the
  # single-snapshot baseline (100 / 600).
  testthat::expect_equal(total_kri0001$Numerator, 100)
  testthat::expect_equal(total_kri0001$Denominator, 600)
  testthat::expect_equal(total_kri0001$NumStudies, 2)
})

testthat::test_that("SummarizePortfolioOverview includes all metrics, sorted by MetricID (#212, Q1, Q2)", {
  result <- SummarizePortfolioOverview(
    dfResults = create_po_test_results(),
    dfGroups = create_po_test_groups()
  )

  total_metrics <- result[result$GroupCategory == "Total", "MetricID", drop = TRUE]
  testthat::expect_equal(total_metrics, sort(unique(create_po_test_results()$MetricID)))
})

testthat::test_that("SummarizePortfolioOverview errors with missing required columns (#212)", {
  bad <- create_po_test_results()
  bad$Numerator <- NULL

  testthat::expect_error(
    SummarizePortfolioOverview(dfResults = bad),
    "missing required columns"
  )
})

testthat::test_that("Widget_PortfolioOverview creates an htmlwidget (#212)", {
  widget <- Widget_PortfolioOverview(
    dfResults = create_po_test_results(),
    dfMetrics = data.frame(
      MetricID = c("kri0001", "kri0002"),
      MetricName = c("KRI 1", "KRI 2")
    ),
    dfGroups = create_po_test_groups()
  )

  testthat::expect_s3_class(widget, "htmlwidget")
})

testthat::test_that("Widget_PortfolioOverview validates inputs (#212)", {
  testthat::expect_error(
    Widget_PortfolioOverview(
      dfResults = "not a data frame",
      dfMetrics = data.frame(),
      dfGroups = data.frame()
    )
  )
})

# D2: filter bar tests. The filter UI lives in JS, but the R wrapper is
# responsible for assembling the per-study attribute lookup table that backs
# it. These tests pin down that R-side contract.

testthat::test_that("Widget_PortfolioOverview prepares dfStudyAttrs for the filter bar (#212, D2)", {
  # Capture the input sent to htmlwidgets::createWidget by mocking the
  # serializer so we can inspect the assembled lookup table.
  captured <- NULL
  testthat::local_mocked_bindings(
    createWidget = function(name, x, ...) {
      captured <<- x
      structure(list(), class = "htmlwidget")
    },
    .package = "htmlwidgets"
  )

  Widget_PortfolioOverview(
    dfResults = create_po_test_results(),
    dfMetrics = data.frame(
      MetricID = c("kri0001", "kri0002"),
      MetricName = c("KRI 1", "KRI 2")
    ),
    dfGroups = create_po_test_groups()
  )

  testthat::expect_false(is.null(captured))
  # The widget should expose a study-attributes payload covering both the
  # group-by params (for D4) and the filter params (for D2).
  testthat::expect_true("dfStudyAttrs" %in% names(captured))
  testthat::expect_true("vFilterParams" %in% names(captured))
})

testthat::test_that("Widget_PortfolioOverview filter params default to therapeutic_area, phase, status (#212, D2)", {
  captured <- NULL
  testthat::local_mocked_bindings(
    createWidget = function(name, x, ...) {
      captured <<- x
      structure(list(), class = "htmlwidget")
    },
    .package = "htmlwidgets"
  )

  Widget_PortfolioOverview(
    dfResults = create_po_test_results(),
    dfMetrics = data.frame(
      MetricID = c("kri0001", "kri0002"),
      MetricName = c("KRI 1", "KRI 2")
    ),
    dfGroups = create_po_test_groups()
  )

  filter_params <- jsonlite::fromJSON(captured$vFilterParams)
  testthat::expect_setequal(
    filter_params,
    c("therapeutic_area", "phase", "status")
  )
})

# D4: expandable rows. The expand/collapse rendering happens in JS, but the R
# wrapper builds the per-study contribution table the JS uses to populate the
# expanded rows. These tests pin down that contract.

testthat::test_that("Widget_PortfolioOverview ships per-study contributions for expand rows (#212, D4)", {
  captured <- NULL
  testthat::local_mocked_bindings(
    createWidget = function(name, x, ...) {
      captured <<- x
      structure(list(), class = "htmlwidget")
    },
    .package = "htmlwidgets"
  )

  Widget_PortfolioOverview(
    dfResults = create_po_test_results(),
    dfMetrics = data.frame(
      MetricID = c("kri0001", "kri0002"),
      MetricName = c("KRI 1", "KRI 2")
    ),
    dfGroups = create_po_test_groups()
  )

  testthat::expect_true("dfPerStudy" %in% names(captured))
  per_study <- jsonlite::fromJSON(captured$dfPerStudy)
  testthat::expect_true(all(
    c("StudyID", "MetricID", "Numerator", "Denominator", "Rate") %in%
      names(per_study)
  ))
  # One row per (StudyID, MetricID) at the latest snapshot.
  expected_rows <- length(unique(create_po_test_results()$StudyID)) *
    length(unique(create_po_test_results()$MetricID))
  testthat::expect_equal(nrow(per_study), expected_rows)
})

testthat::test_that("Widget_PortfolioOverview per-study Rate matches Numerator/Denominator (#212, D4)", {
  captured <- NULL
  testthat::local_mocked_bindings(
    createWidget = function(name, x, ...) {
      captured <<- x
      structure(list(), class = "htmlwidget")
    },
    .package = "htmlwidgets"
  )

  Widget_PortfolioOverview(
    dfResults = create_po_test_results(),
    dfMetrics = data.frame(
      MetricID = c("kri0001", "kri0002"),
      MetricName = c("KRI 1", "KRI 2")
    ),
    dfGroups = create_po_test_groups()
  )

  per_study <- jsonlite::fromJSON(captured$dfPerStudy)
  computed_rate <- ifelse(
    per_study$Denominator > 0,
    per_study$Numerator / per_study$Denominator,
    NA_real_
  )
  testthat::expect_equal(per_study$Rate, computed_rate)
})

testthat::test_that("Widget_PortfolioOverview per-study uses latest snapshot only (#212, D4, Q5)", {
  dfA <- create_po_test_results()
  dfA$SnapshotDate <- as.Date("2025-05-01")
  dfA$Numerator <- 999
  dfB <- create_po_test_results()

  captured <- NULL
  testthat::local_mocked_bindings(
    createWidget = function(name, x, ...) {
      captured <<- x
      structure(list(), class = "htmlwidget")
    },
    .package = "htmlwidgets"
  )

  Widget_PortfolioOverview(
    dfResults = dplyr::bind_rows(dfA, dfB),
    dfMetrics = data.frame(
      MetricID = c("kri0001", "kri0002"),
      MetricName = c("KRI 1", "KRI 2")
    ),
    dfGroups = create_po_test_groups()
  )

  per_study <- jsonlite::fromJSON(captured$dfPerStudy)
  testthat::expect_false(any(per_study$Numerator == 999))
})

testthat::test_that("Widget_PortfolioOverview per-study latest is computed per StudyID (#212, D4, Q5)", {
  # STUDY001 latest = 2025-04-01; STUDY002 latest = 2025-06-01. A global max
  # would drop STUDY001 from dfPerStudy entirely.
  base <- create_po_test_results()
  s1_old <- base[base$StudyID == "STUDY001", ]
  s1_old$SnapshotDate <- as.Date("2025-03-01")
  s1_old$Numerator <- 999
  s1_new <- base[base$StudyID == "STUDY001", ]
  s1_new$SnapshotDate <- as.Date("2025-04-01")
  s2 <- base[base$StudyID == "STUDY002", ]
  s2$SnapshotDate <- as.Date("2025-06-01")
  dfResults <- dplyr::bind_rows(s1_old, s1_new, s2)

  captured <- NULL
  testthat::local_mocked_bindings(
    createWidget = function(name, x, ...) {
      captured <<- x
      structure(list(), class = "htmlwidget")
    },
    .package = "htmlwidgets"
  )

  Widget_PortfolioOverview(
    dfResults = dfResults,
    dfMetrics = data.frame(
      MetricID = c("kri0001", "kri0002"),
      MetricName = c("KRI 1", "KRI 2")
    ),
    dfGroups = create_po_test_groups()
  )

  per_study <- jsonlite::fromJSON(captured$dfPerStudy)
  testthat::expect_setequal(per_study$StudyID, c("STUDY001", "STUDY002"))
  testthat::expect_false(any(per_study$Numerator == 999))
})

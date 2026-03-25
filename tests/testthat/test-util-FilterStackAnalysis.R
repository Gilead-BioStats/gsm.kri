## Test Setup
library(testthat)

## Test Code
test_that("FilterAnalysis filters analysis outputs correctly", {
  # Create test data
  analysisFlagged <- data.frame(
    GroupID = c("Site1", "Site2", "Site3"),
    Flag = c(0, 1, -1),
    Weight = c(0, 2, 2)
  )
  
  # Create test analysis list with different ID patterns
  lAnalysis <- list(
    "Analysis_kri0001" = list(
      Analysis_Flagged = analysisFlagged,
      ID = "Analysis_kri0001"
    ),
    "Analysis_qtl0001" = list(
      Analysis_Flagged = analysisFlagged,
      ID = "Analysis_qtl0001"
    ),
    "Other_analysis" = list(
      Analysis_Flagged = analysisFlagged,
      ID = "Other_analysis"
    ),
    "No_ID_analysis" = list(
      Analysis_Flagged = analysisFlagged
    )
  )
  
  # Test default filtering (should keep only "kri" pattern)
  result_default <- FilterAnalysis(lAnalysis)
  expect_equal(length(result_default), 1)
  expect_equal(names(result_default), "Analysis_kri0001")
  expect_equal(result_default$Analysis_kri0001$ID, "Analysis_kri0001")
  
  # Test custom pattern filtering
  result_qtl <- FilterAnalysis(lAnalysis, strFilterIDPattern = "qtl")
  expect_equal(length(result_qtl), 1)
  expect_equal(names(result_qtl), "Analysis_qtl0001")
  
  # Test pattern that matches multiple
  result_analysis <- FilterAnalysis(lAnalysis, strFilterIDPattern = "Analysis")
  expect_equal(length(result_analysis), 2)
  expect_true("Analysis_kri0001" %in% names(result_analysis))
  expect_true("Analysis_qtl0001" %in% names(result_analysis))
  
  # Test pattern that matches none
  result_none <- FilterAnalysis(lAnalysis, strFilterIDPattern = "nonexistent")
  expect_equal(length(result_none), 0)
  
  # Test empty input
  result_empty <- FilterAnalysis(list())
  expect_equal(length(result_empty), 0)
})

test_that("StackAnalysis stacks analysis outputs correctly", {
  # Create test data
  analysisFlagged1 <- data.frame(
    GroupID = c("Site1", "Site2"),
    Flag = c(0, 1),
    Weight = c(0, 2)
  )
  
  analysisFlagged2 <- data.frame(
    GroupID = c("Site3", "Site4"),
    Flag = c(-1, 2),
    Weight = c(2, 4)
  )
  
  # Create test analysis list
  lAnalysis <- list(
    "Analysis_kri0001" = list(
      Analysis_Flagged = analysisFlagged1,
      ID = "Analysis_kri0001"
    ),
    "Analysis_kri0002" = list(
      Analysis_Flagged = analysisFlagged2,
      ID = "Analysis_kri0002"
    )
  )
  
  # Test default stacking (Analysis_Flagged)
  result_default <- StackAnalysis(lAnalysis)
  
  expect_equal(nrow(result_default), 4) # 2 + 2 rows
  expect_equal(ncol(result_default), 4) # original 3 columns + MetricID
  expect_true("MetricID" %in% colnames(result_default))
  expect_equal(sort(unique(result_default$MetricID)), c("Analysis_kri0001", "Analysis_kri0002"))
  expect_equal(sort(result_default$GroupID), c("Site1", "Site2", "Site3", "Site4"))
  
  # Test custom stacking with different data frame name
  lAnalysis_custom <- list(
    "Analysis_kri0001" = list(
      Custom_Data = analysisFlagged1,
      ID = "Analysis_kri0001"
    ),
    "Analysis_kri0002" = list(
      Custom_Data = analysisFlagged2,
      ID = "Analysis_kri0002"
    )
  )
  
  result_custom <- StackAnalysis(lAnalysis_custom, strName = "Custom_Data")
  expect_equal(nrow(result_custom), 4)
  expect_true("MetricID" %in% colnames(result_custom))
  
  # Test with empty input
  result_empty <- StackAnalysis(list())
  expect_equal(nrow(result_empty), 0)
  expect_equal(ncol(result_empty), 1) # just MetricID column
  expect_true("MetricID" %in% colnames(result_empty))
  
  # Test with single analysis
  result_single <- StackAnalysis(lAnalysis[1])
  expect_equal(nrow(result_single), 2)
  expect_equal(unique(result_single$MetricID), "Analysis_kri0001")
})

test_that("FilterAnalysis and StackAnalysis work together", {
  # Create comprehensive test scenario
  analysisFlagged <- data.frame(
    GroupID = c("Site1", "Site2", "Site3"),
    Flag = c(0, 1, -1),
    Weight = c(0, 2, 2),
    stringsAsFactors = FALSE
  )
  
  lAnalysis <- list(
    "Analysis_kri0001" = list(
      Analysis_Flagged = analysisFlagged,
      ID = "Analysis_kri0001"
    ),
    "Analysis_qtl0001" = list(
      Analysis_Flagged = analysisFlagged,
      ID = "Analysis_qtl0001"
    ),
    "Other_metric" = list(
      Analysis_Flagged = analysisFlagged,
      ID = "Other_metric"
    )
  )
  
  # Filter and then stack
  lFiltered <- FilterAnalysis(lAnalysis, strFilterIDPattern = "kri")
  dfStacked <- StackAnalysis(lFiltered)
  
  expect_equal(nrow(dfStacked), 3) # 3 sites from filtered analysis
  expect_equal(unique(dfStacked$MetricID), "Analysis_kri0001")
  expect_equal(sort(dfStacked$GroupID), c("Site1", "Site2", "Site3"))
})
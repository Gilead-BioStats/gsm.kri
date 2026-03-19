df_results_basic <- data.frame(
  GroupID = c("A", "B", "C"),
  Denominator = c(100, 200, 300),
  Numerator = c(10, 20, 30),
  Flag = c(0, 1, -1),
  Category = c("X", "X", "Y")
)

df_results_all_na_flag <- data.frame(
  GroupID = c("A", "B"),
  Denominator = c(100, 200),
  Numerator = c(10, 20),
  Flag = c(NA, NA)
)

df_bounds_basic <- data.frame(
  Threshold = c(-1, 1),
  LogDenominator = log(c(100, 200)),
  Numerator = c(15, 25)
)

testthat::test_that("Visualize_Scatter returns NULL if all Flags are NA", {
  p <- Visualize_Scatter(df_results_all_na_flag)

  expect_null(p)
})
testthat::test_that("Visualize_Scatter returns a ggplot object with basic input", {
  p <- Visualize_Scatter(df_results_basic)

  testthat::expect_s3_class(p, "ggplot")
})

testthat::test_that("Visualize_Scatter includes tooltip text aesthetic", {
  p <- Visualize_Scatter(df_results_basic)

  aes_names <- names(p$mapping)

  expect_true("text" %in% aes_names)
})

testthat::test_that("Visualize_Scatter maps color to absolute Flag", {
  p <- Visualize_Scatter(df_results_basic)

  expect_equal(
    ggplot2::as_label(p$mapping$colour),
    "as.factor(.data$FlagAbs)"
  )
})


testthat::test_that("Visualize_Scatter facets when strGroupCol is provided", {
  p <- Visualize_Scatter(
    dfResults = df_results_basic,
    strGroupCol = "Category"
  )

  expect_true(inherits(p$facet, "FacetWrap"))
})

testthat::test_that("Visualize_Scatter uses correct axis labels", {
  p <- Visualize_Scatter(
    dfResults = df_results_basic,
    strGroupLabel = "Site",
    strUnit = "hours"
  )

  expect_match(p$labels$x, "Site.*hours")
  expect_match(p$labels$y, "Site")
})

testthat::test_that("Visualize_Scatter handles zero denominators", {
  df_results_zero_denom <- data.frame(
    GroupID = c("A", "B"),
    Denominator = c(0, 200),
    Numerator = c(0, 20),
    Flag = c(0, 1)
  )

  p <- Visualize_Scatter(df_results_zero_denom)

  testthat::expect_s3_class(p, "ggplot")
})

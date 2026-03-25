## Test Setup
library(testthat)

## Test Code
test_that("Widget_ScatterPlot handles input validation correctly", {
  # Test invalid dfResults
  expect_error(
    Widget_ScatterPlot(dfResults = "not_a_dataframe"),
    "dfResults is not a data.frame"
  )
  
  # Test invalid lMetric (data.frame instead of list)
  expect_error(
    Widget_ScatterPlot(
      dfResults = data.frame(x = 1),
      lMetric = data.frame(y = 1)
    ),
    "lMetric must be a list, but not a data.frame"
  )
  
  # Test invalid dfGroups
  expect_error(
    Widget_ScatterPlot(
      dfResults = data.frame(x = 1),
      dfGroups = "not_a_dataframe"
    ),
    "dfGroups is not a data.frame"
  )
  
  # Test invalid dfBounds
  expect_error(
    Widget_ScatterPlot(
      dfResults = data.frame(x = 1),
      dfBounds = "not_a_dataframe"
    ),
    "dfBounds is not a data.frame"
  )
  
  # Test invalid bAddGroupSelect
  expect_error(
    Widget_ScatterPlot(
      dfResults = data.frame(x = 1),
      bAddGroupSelect = "not_logical"
    ),
    "bAddGroupSelect is not a logical"
  )
  
  # Test invalid strShinyGroupSelectID
  expect_error(
    Widget_ScatterPlot(
      dfResults = data.frame(x = 1),
      strShinyGroupSelectID = 123
    ),
    "strShinyGroupSelectID is not a character"
  )
  
  # Test invalid bDebug
  expect_error(
    Widget_ScatterPlot(
      dfResults = data.frame(x = 1),
      bDebug = "not_logical"
    ),
    "bDebug is not a logical"
  )
})

test_that("Widget_ScatterPlot creates widget with valid inputs", {
  # Create test data
  dfResults <- data.frame(
    GroupID = c("Site1", "Site2", "Site3"),
    Numerator = c(10, 15, 8),
    Denominator = c(100, 120, 80),
    Metric = c(0.1, 0.125, 0.1),
    Flag = c(0, 1, 0),
    stringsAsFactors = FALSE
  )
  
  lMetric <- list(
    MetricID = "test_metric",
    MetricName = "Test Metric",
    Domain = "Test Domain"
  )
  
  dfGroups <- data.frame(
    GroupID = c("Site1", "Site2", "Site3"),
    GroupLevel = c("Site", "Site", "Site"),
    stringsAsFactors = FALSE
  )
  
  dfBounds <- data.frame(
    GroupID = c("Site1", "Site2", "Site3"),
    LowerBound = c(0.05, 0.05, 0.05),
    UpperBound = c(0.15, 0.15, 0.15),
    stringsAsFactors = FALSE
  )
  
  # Test basic widget creation
  widget <- Widget_ScatterPlot(
    dfResults = dfResults,
    lMetric = lMetric,
    dfGroups = dfGroups,
    dfBounds = dfBounds
  )
  
  # Check that widget is created and has expected structure
  expect_s3_class(widget, "htmlwidget")
  expect_equal(widget$name, "Widget_ScatterPlot")
  expect_true(is.list(widget$x))
  expect_true("dfResults" %in% names(widget$x))
  expect_true("lMetric" %in% names(widget$x))
  expect_true("dfGroups" %in% names(widget$x))
  expect_true("dfBounds" %in% names(widget$x))
})

test_that("Widget_ScatterPlot works with minimal inputs", {
  # Test with just dfResults (minimal requirement)
  dfResults <- data.frame(
    GroupID = c("Site1", "Site2"),
    Numerator = c(10, 15),
    Denominator = c(100, 120),
    stringsAsFactors = FALSE
  )
  
  widget <- Widget_ScatterPlot(dfResults = dfResults)
  
  expect_s3_class(widget, "htmlwidget")
  expect_equal(widget$name, "Widget_ScatterPlot")
  expect_true(is.list(widget$x))
})

test_that("Widget_ScatterPlot respects configuration options", {
  dfResults <- data.frame(
    GroupID = c("Site1", "Site2"),
    Numerator = c(10, 15),
    Denominator = c(100, 120),
    stringsAsFactors = FALSE
  )
  
  # Test with bAddGroupSelect = FALSE
  widget_no_select <- Widget_ScatterPlot(
    dfResults = dfResults,
    bAddGroupSelect = FALSE
  )
  
  expect_false(fromJSON(widget_no_select$x$bAddGroupSelect))
  
  # Test with custom strShinyGroupSelectID
  widget_custom_id <- Widget_ScatterPlot(
    dfResults = dfResults,
    strShinyGroupSelectID = "CustomID"
  )
  
  expect_equal(fromJSON(widget_custom_id$x$strShinyGroupSelectID), "CustomID")
  
  # Test with custom output label
  custom_label <- "Custom Label"
  widget_custom_label <- Widget_ScatterPlot(
    dfResults = dfResults,
    strOutputLabel = custom_label
  )
  
  expect_equal(attr(widget_custom_label, "output_label"), custom_label)
})

test_that("Widget_ScatterPlotOutput creates proper output binding", {
  output <- Widget_ScatterPlotOutput("test_output")
  
  expect_s3_class(output, "shiny.tag")
  # The output should contain the outputId
  expect_true(grepl("test_output", as.character(output)))
  
  # Test with custom dimensions
  output_custom <- Widget_ScatterPlotOutput(
    "test_output2", 
    width = "500px", 
    height = "300px"
  )
  
  expect_s3_class(output_custom, "shiny.tag")
})

test_that("renderWidget_ScatterPlot creates proper render function", {
  # Test basic render function creation
  render_func <- renderWidget_ScatterPlot({
    Widget_ScatterPlot(data.frame(x = 1))
  })
  
  expect_true(is.function(render_func))
  
  # Test quoted expression
  expr <- quote(Widget_ScatterPlot(data.frame(x = 1)))
  render_func_quoted <- renderWidget_ScatterPlot(expr, quoted = TRUE)
  
  expect_true(is.function(render_func_quoted))
})
#' Time Series Widget
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' A widget that generates a time series of group-level metric results over time, plotting snapshot
#' date on the x-axis and the outcome (numerator, denominator, metric, or score) on the y-axis.
#'
#' @inheritParams shared-params
#' @param vThreshold `numeric` Threshold value(s).
#' @param strOutcome `character` Outcome variable. Default: 'Score'.
#' @param bAddGroupSelect `logical` Add a dropdown to highlight sites? Default: `TRUE`.
#' @param strShinyGroupSelectID `character` Element ID of group select in Shiny context. Default: `'GroupID'`.
#' @param ... `any` Additional chart configuration settings.
#'
#' @examples
#' ## Filter data to one metric
#' reportingResults_filter <- gsm.core::reportingResults %>%
#'   dplyr::filter(MetricID == "Analysis_kri0001")
#'
#' reportingMetrics_filter <- gsm.core::reportingMetrics %>%
#'   dplyr::filter(MetricID == "Analysis_kri0001") %>%
#'   as.list()
#'
#' Widget_TimeSeries(
#'   dfResults = reportingResults_filter,
#'   lMetric = reportingMetrics_filter,
#'   dfGroups = gsm.core::reportingGroups,
#'   vThreshold = reportingMetrics_filter$Threshold
#' )
#'
#' @export

Widget_TimeSeries <- function(
  dfResults,
  lMetric = NULL,
  dfGroups = NULL,
  vThreshold = NULL,
  strOutcome = "Score",
  bAddGroupSelect = TRUE,
  strShinyGroupSelectID = "GroupID",
  strOutputLabel = paste0(
      fontawesome::fa("chart-line", fill = "#337ab7"),
      "  Time Series"
  ),
  bDebug = FALSE,
  ...
) {
  gsm.core::stop_if(cnd = !is.data.frame(dfResults), "dfResults is not a data.frame")
  gsm.core::stop_if(cnd = !(is.null(lMetric) || (is.list(lMetric) && !is.data.frame(lMetric))), "lMetric must be a list, but not a data.frame")
  gsm.core::stop_if(cnd = !(is.null(dfGroups) || is.data.frame(dfGroups)), "dfGroups is not a data.frame")
  gsm.core::stop_if(cnd = length(strOutcome) != 1, "strOutcome must be length 1")
  gsm.core::stop_if(cnd = !is.character(strOutcome), "strOutcome is not a character")
  gsm.core::stop_if(cnd = !is.logical(bAddGroupSelect), "bAddGroupSelect is not a logical")
  gsm.core::stop_if(cnd = !is.character(strShinyGroupSelectID), "strShinyGroupSelectID is not a character")
  gsm.core::stop_if(cnd = !is.logical(bDebug), "bDebug is not a logical")

  # Parse `vThreshold` from comma-delimited character string to numeric vector.
  if (!is.null(vThreshold)) {
    if (is.character(vThreshold)) {
      vThreshold <- strsplit(vThreshold, ",")[[1]] %>% as.numeric()
    }
  }

  # Disable threshold if outcome is not 'Score'.
  if (strOutcome != "Score") {
    vThreshold <- NULL
  }

  # define widget inputs
  lChartConfig <- do.call(
      'MakeChartConfig',
      list(
          lMetric = lMetric,
          strChartFunction = 'Widget_TimeSeries',
          y = strOutcome,
          ...
        )
    )

  # define widget inputs
  lInput <- list(
    dfResults = dfResults,
    lMetric = lMetric,
    dfGroups = dfGroups,
    vThreshold = vThreshold,
    lChartConfig = lChartConfig,
    strOutcome = strOutcome,
    bAddGroupSelect = bAddGroupSelect,
    strShinyGroupSelectID = strShinyGroupSelectID,
    bDebug = bDebug
  )

  # create widget
  lWidget <- htmlwidgets::createWidget(
    name = "Widget_TimeSeries",
    purrr::map(
      lInput,
      ~ jsonlite::toJSON(
        .x,
        null = "null",
        na = "string",
        auto_unbox = TRUE
      )
    ),
    package = "gsm.kri"
  )

  base::attr(lWidget, "output_label") <- strOutputLabel

  if (bDebug) {
    viewer <- getOption("viewer")
    options(viewer = NULL)
    print(lWidget)
    options(viewer = viewer)
  }

  return(lWidget)
}

#' Shiny bindings for Widget_TimeSeries
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' Output and render functions for using Widget_TimeSeries within Shiny
#' applications and interactive Rmd documents.
#'
#' @param outputId output variable to read from
#' @param width,height Must be a valid CSS unit (like \code{'100\%'},
#'   \code{'400px'}, \code{'auto'}) or a number, which will be coerced to a
#'   string and have \code{'px'} appended.
#' @param expr An expression that generates a Widget_TimeSeries
#' @param env The environment in which to evaluate \code{expr}.
#' @param quoted Is \code{expr} a quoted expression (with \code{quote()})? This
#'   is useful if you want to save an expression in a variable.
#'
#' @name Widget_TimeSeries-shiny
#'
#' @export
Widget_TimeSeriesOutput <- function(outputId, width = "100%", height = "400px") {
  htmlwidgets::shinyWidgetOutput(outputId, "Widget_TimeSeries", width, height, package = "gsm.kri")
}

#' @rdname Widget_TimeSeries-shiny
#' @export
renderWidget_TimeSeries <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) {
    expr <- substitute(expr)
  } # force quoted
  htmlwidgets::shinyRenderWidget(expr, Widget_TimeSeriesOutput, env, quoted = TRUE)
}

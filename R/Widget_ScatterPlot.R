#' Scatter Plot Widget
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' A widget that generates a scatter plot of group-level metric results, plotting the denominator
#' on the x-axis and the numerator on the y-axis.
#'
#' @inheritParams shared-params
#' @param bAddGroupSelect `logical` Add a dropdown to highlight sites? Default: `TRUE`.
#' @param strShinyGroupSelectID `character` Element ID of group select in Shiny context. Default: `'GroupID'`.
#' @param ... `any` Additional chart configuration settings.
#'
#' @examples
#' ## Filter data to one metric and snapshot
#' reportingResults_filter <- gsm.core::reportingResults %>%
#'   dplyr::filter(MetricID == "Analysis_kri0001" & SnapshotDate == max(SnapshotDate))
#'
#' reportingMetrics_filter <- gsm.core::reportingMetrics %>%
#'   dplyr::filter(MetricID == "Analysis_kri0001") %>%
#'   as.list()
#'
#' reportingBounds_filter <- gsm.core::reportingBounds %>%
#'   dplyr::filter(MetricID == "Analysis_kri0001" & SnapshotDate == max(SnapshotDate))
#'
#' Widget_ScatterPlot(
#'   dfResults = reportingResults_filter,
#'   lMetric = reportingMetrics_filter,
#'   dfGroups = gsm.core::reportingGroups,
#'   dfBounds = reportingBounds_filter
#' )
#'
#' @export

Widget_ScatterPlot <- function(
  dfResults,
  lMetric = NULL,
  dfGroups = NULL,
  dfBounds = NULL,
  bAddGroupSelect = TRUE,
  strShinyGroupSelectID = "GroupID",
  strOutputLabel <- paste0(
      fontawesome::fa("arrow-up-right-dots", fill = "#337ab7"),
      "  Scatter Plot"
  ),
  bDebug = FALSE,
  ...
) {
  gsm.core::stop_if(cnd = !is.data.frame(dfResults), "dfResults is not a data.frame")
  gsm.core::stop_if(cnd = !(is.null(lMetric) || (is.list(lMetric) && !is.data.frame(lMetric))), "lMetric must be a list, but not a data.frame")
  gsm.core::stop_if(cnd = !(is.null(dfGroups) || is.data.frame(dfGroups)), "dfGroups is not a data.frame")
  gsm.core::stop_if(cnd = !(is.null(dfBounds) || is.data.frame(dfBounds)), "dfBounds is not a data.frame")
  gsm.core::stop_if(cnd = !is.logical(bAddGroupSelect), "bAddGroupSelect is not a logical")
  gsm.core::stop_if(cnd = !is.character(strShinyGroupSelectID), "strShinyGroupSelectID is not a character")
  gsm.core::stop_if(cnd = !is.logical(bDebug), "bDebug is not a logical")

  # define widget inputs
  lChartConfig <- do.call(
      'MakeChartConfig',
      list(
          lMetric = lMetric,
          strChartFunction = sys.call()[[1]] %>% as.character(),
          ...
        )
    )

  lWidgetInput <- list(
    dfResults = dfResults,
    lMetric = lMetric,
    dfGroups = dfGroups,
    dfBounds = dfBounds,
    lChartConfig = lChartConfig,
    bAddGroupSelect = bAddGroupSelect,
    strShinyGroupSelectID = strShinyGroupSelectID,
    strFootnote = ifelse(!is.null(dfGroups), "Point size is relative to the number of enrolled participants.", ""),
    bDebug = bDebug
  )

  # create widget
  lWidget <- htmlwidgets::createWidget(
    name = "Widget_ScatterPlot",
    purrr::map(
      lWidgetInput,
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

#' Shiny bindings for Widget_ScatterPlot
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' Output and render functions for using Widget_ScatterPlot within Shiny
#' applications and interactive Rmd documents.
#'
#' @param outputId output variable to read from
#' @param width,height Must be a valid CSS unit (like \code{'100\%'},
#'   \code{'400px'}, \code{'auto'}) or a number, which will be coerced to a
#'   string and have \code{'px'} appended.
#' @param expr An expression that generates a Widget_ScatterPlot
#' @param env The environment in which to evaluate \code{expr}.
#' @param quoted Is \code{expr} a quoted expression (with \code{quote()})? This
#'   is useful if you want to save an expression in a variable.
#'
#' @name Widget_ScatterPlot-shiny
#'
#' @export
Widget_ScatterPlotOutput <- function(outputId, width = "100%", height = "400px") {
  htmlwidgets::shinyWidgetOutput(outputId, "Widget_ScatterPlot", width, height, package = "gsm.kri")
}

#' @rdname Widget_ScatterPlot-shiny
#' @export
renderWidget_ScatterPlot <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) {
    expr <- substitute(expr)
  } # force quoted
  htmlwidgets::shinyRenderWidget(expr, Widget_ScatterPlotOutput, env, quoted = TRUE)
}

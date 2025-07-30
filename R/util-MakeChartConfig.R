#' Make Chart Config
#'
#' Helper function to create chart configuration for a specific metric and chart type.
#'
#' @inheritParams shared-params
#' @param strChartFunction `character` Name of chart function.
#' @param ... `any` Additional chart configuration settings.
#'
#' @return `list` Chart configuration.
#'
#' @export

MakeChartConfig <- function(
  lMetric,
  strChartFunction,
  ...
) {
  if (is.null(lMetric)) {
    lMetric <- list()
  }

  gsm.core::stop_if(
    cnd = !(is.list(lMetric) && !is.data.frame(lMetric)),
    "lMetric must be a list, but not a data.frame"
  )

  gsm.core::stop_if(
    cnd = !is.character(strChartFunction),
    "strChartFunction is not character"
  )

  gsm.core::stop_if(
    cnd = !exists(strChartFunction, mode = "function"),
    "strChartFunction is not a valid function"
  )

  # Pass additional settings from most specific to least specific.
  lChartConfig <- c(
    lMetric,
    # metric-specific chart settings
    list(...)[[coalesce(lMetric$MetricID, "")]][[strChartFunction]],
    # cross-metric chart settings
    list(...)[[strChartFunction]],
    # cross-metric, cross-chart settings
    list(...)
  )

  return(lChartConfig)
}

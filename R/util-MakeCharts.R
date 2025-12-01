#' Helper function to create charts for multiple metrics
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' @inheritParams shared-params
#' @param ... Additional chart configuration settings.
#'
#' @return A list of charts for each metric.
#'
#' @export

MakeCharts <- function(
  dfResults,
  dfMetrics,
  dfGroups,
  dfBounds,
  bDebug = FALSE,
  ...
) {
  strMetrics <- unique(dfMetrics$MetricID)

  lArgs <- list(
    dfResults = dfResults,
    dfMetrics = dfMetrics,
    dfGroups = dfGroups,
    dfBounds = dfBounds,
    bDebug = bDebug,
    ...
  )

  lCharts <- strMetrics %>%
    purrr::map(
      ~ {
        lArgs$strMetricID <- .x

        do.call(
          "Visualize_Metric",
          lArgs
        )
      }
    ) %>%
    stats::setNames(strMetrics)

  return(lCharts)
}

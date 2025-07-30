#' Visualize_Metric Function
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' The function creates all available charts for a metric using the data provided
#'
#' @inheritParams shared-params
#' @param strMetricID `character` MetricID to subset the data.
#' @param strSnapshotDate `character` Snapshot date to subset the data.
#' @param bDebug `logical` Display console in html viewer for debugging. Default is `FALSE`.
#' @param ... Additional chart configuration settings.
#'
#' @return A list containing the following charts:
#' - scatterPlot: A scatter plot using JavaScript.
#' - barChart: A bar chart using JavaScript with metric on the y-axis.
#' - timeSeries: A time series chart using JavaScript with score on the y-axis.
#' - metricTable: A table containing all
#'
#' @examples
#' lCharts <- Visualize_Metric(
#'   dfResults = gsm.core::reportingResults,
#'   dfBounds = gsm.core::reportingBounds,
#'   dfGroups = gsm.core::reportingGroups,
#'   dfMetrics = gsm.core::reportingMetrics,
#'   strMetricID = "Analysis_kri0001"
#' )
#'
#' @export

Visualize_Metric <- function(
  dfResults = dfResults,
  dfMetrics = NULL,
  dfGroups = NULL,
  dfBounds = NULL,
  strMetricID = NULL,
  strSnapshotDate = NULL,
  bDebug = FALSE,
  ...
) {
  # Check for multiple snapshots --------------------------------------------
  # if SnapshotDate is missing set it to today for all records
  if (!"SnapshotDate" %in% colnames(dfResults)) {
    dfResults$SnapshotDate <- as.Date(Sys.Date())
  }

  if (!"SnapshotDate" %in% colnames(dfBounds) & !is.null(dfBounds)) {
    dfBounds$SnapshotDate <- as.Date(Sys.Date())
  }

  # get number of snapshots
  number_of_snapshots <- length(unique(dfResults$SnapshotDate))

  # use most recent snapshot date if strSnapshotDate is missing
  if (is.null(strSnapshotDate)) {
    strSnapshotDate <- max(dfResults$SnapshotDate)
  }

  # Filter to selected MetricID ----------------------------------------------
  if (!is.null(strMetricID)) {
    if (!(strMetricID %in% unique(dfResults$MetricID))) {
      gsm.core::LogMessage(
        level = "info",
        message = "MetricID not found in dfResults. No charts will be generated.",
        cli_detail = "alert_info"
      )
      return(NULL)
    } else {
      dfResults <- dfResults %>% filter(.data$MetricID == strMetricID)
    }
  }
  if (!is.null(strMetricID)) {
    if (!(strMetricID %in% unique(dfBounds$MetricID))) {
      gsm.core::LogMessage(
        level = "info",
        message = "MetricID not found in dfBounds. Please double check input data if intentional.",
        cli_detail = "inform"
      )
      dfBounds <- NULL
    } else {
      dfBounds <- dfBounds %>% filter(.data$MetricID == strMetricID)
    }
  }

  if (!is.null(strMetricID)) {
    if (!(strMetricID %in% unique(dfMetrics$MetricID))) {
      gsm.core::LogMessage(
        level = "info",
        message = "MetricID not found in dfMetrics. Please double check input data if intentional.",
        cli_detail = "inform"
      )
      dfMetrics <- NULL
    } else {
      dfMetrics <- dfMetrics %>% filter(.data$MetricID == strMetricID)
    }
  }

  if (
    length(unique(dfResults$MetricID)) > 1 |
      length(unique(dfBounds$MetricID)) > 1 |
      length(unique(dfMetrics$MetricID)) > 1
  ) {
    gsm.core::LogMessage(
      level = "fatal",
      message = "Multiple MetricIDs found in dfResults, dfBounds or dfMetrics. Specify `MetricID` to subset. No charts will be generated."
    )
    return(NULL)
  }

  # Prep chart inputs ---------------------------------------------------------
  if (is.null(dfMetrics)) {
    lMetric <- NULL
    vThreshold <- NULL
  } else {
    lMetric <- as.list(dfMetrics)
    vThreshold <- gsm.core::ParseThreshold(lMetric$Threshold, bSort = FALSE)
  }

  # Cross-sectional Charts using most recent snapshot ------------------------
  lCharts <- list()
  dfResults_latest <- FilterByLatestSnapshotDate(dfResults, strSnapshotDate)
  if (is.null(dfBounds)) {
    dfBounds_latest <- NULL
  } else {
    dfBounds_latest <- FilterByLatestSnapshotDate(dfBounds, strSnapshotDate)
  }

  if (nrow(dfResults_latest) == 0) {
    gsm.core::LogMessage(
      level = "warn",
      message = "No data found for specified snapshot date: {strSnapshotDate}. No charts will be generated."
    )
  } else {
    lCharts$scatterPlot <- do.call(
      "Widget_ScatterPlot",
      list(
        dfResults = dfResults_latest,
        lMetric = lMetric,
        dfGroups = dfGroups,
        dfBounds = dfBounds_latest,
        bDebug = bDebug,
        ...
      )
    )

    lCharts$barChart <- do.call(
      "Widget_BarChart",
      list(
        dfResults = dfResults_latest,
        lMetric = lMetric,
        dfGroups = dfGroups,
        vThreshold = vThreshold,
        bDebug = bDebug,
        ...
      )
    )

    if (!is.null(lMetric)) {
      lCharts$metricTable <- Report_MetricTable(
        dfResults = dfResults_latest,
        dfGroups = dfGroups,
        strGroupLevel = lMetric$GroupLevel
      )
    } else {
      lCharts$metricTable <- Report_MetricTable(dfResults_latest)
    }
  }
  # Continuous Charts -------------------------------------------------------
  if (number_of_snapshots <= 1) {
    gsm.core::LogMessage(
      level = "info",
      message = "Only one snapshot found. Time series charts will not be generated.",
      cli_detail = "alert_info"
    )
  } else {
    lCharts$timeSeries <- do.call(
      "Widget_TimeSeries",
      list(
        dfResults = dfResults,
        lMetric = lMetric,
        dfGroups = dfGroups,
        vThreshold = vThreshold,
        bDebug = bDebug,
        ...
      )
    )
  }

  return(lCharts)
}

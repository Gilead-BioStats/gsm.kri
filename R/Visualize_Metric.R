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
    dfBounds = NULL,
    dfGroups = NULL,
    dfMetrics = NULL,
    strMetricID = NULL,
    strSnapshotDate = NULL,
    bDebug = FALSE
) {

  if (! is.null(dfBounds)) {
    if (nrow(dfBounds) == 0) {
      dfBounds <- NULL
    }
  }

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

  # horizontal binding of results with different column sets creates empty columns
  # here we remove those empty columns, so that they do not appear in tooltips as NA
  dfResults <- dfResults %>%
    select(where(~ ! all(is.na(.))))

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

  # Select chart functions ---------------------------------------------------

  if (! is.null(lMetric) && ! (is.null(lMetric$ChartsMetricFunction) || is.na(lMetric$ChartsMetricFunction))) {
    ChartsMetricFunction <- eval(parse(text = lMetric$ChartsMetricFunction))
  } else {
    ChartsMetricFunction <- ChartsMetricDefault
  }

  if (! is.null(lMetric) && ! (is.null(lMetric$ChartsContinousFuntion) || is.na(lMetric$ChartsContinousFuntion))) {
    ChartsContinousFuntion <- parse(text = lMetric$ChartsContinousFuntion)
  } else {
    ChartsContinousFuntion <- ChartsContinousDefault
  }

  if (nrow(dfResults_latest) == 0) {
    gsm.core::LogMessage(
      level = "warn",
      message = "No data found for specified snapshot date: {strSnapshotDate}. No charts will be generated."
    )
  } else {

    lCharts <- lCharts %>%
        ChartsMetricFunction(
          dfResults = dfResults_latest,
          lMetric = lMetric,
          dfGroups = dfGroups,
          dfBounds = dfBounds_latest,
          vThreshold = vThreshold,
          bDebug = bDebug
      )
  }

  # Continuous Charts -------------------------------------------------------
  if (number_of_snapshots <= 1) {
    gsm.core::LogMessage(
      level = "info",
      message = "Only one snapshot found. Time series charts will not be generated.",
      cli_detail = "alert_info"
    )
  } else {
    lCharts <- lCharts %>%
      ChartsContinousFuntion(
        dfResults = dfResults,
        lMetric = lMetric,
        dfGroups = dfGroups,
        vThreshold = vThreshold,
        bDebug = bDebug
      )
  }

  return(lCharts)
}


#' Charts Metric Default Function
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' The function creates all metric charts for a default metric using the data provided
#'
#' @inheritParams shared-params
#' @param lCharts `list`
#' @param vThreshold `numeric` Threshold values for metric.
#' 
#' @return A list containing the following charts:
#' - scatterPlot: A scatter plot using JavaScript.
#' - barChart: A bar chart using JavaScript with metric on the y-axis.
#' - metricTable: Table using JavaScript with metric scores.
#' 
#' @examples
#' lCharts <- list()
#' strMetricID = "Analysis_kri0001"
#' 
#' dfResults_latest <-  gsm.core::reportingResults %>%
#'  dplyr::filter(MetricID == strMetricID) %>%
#'  FilterByLatestSnapshotDate()
#' 
#' dfBounds_latest <- gsm.core::reportingBounds %>%
#'  dplyr::filter(MetricID == strMetricID) %>%
#'  FilterByLatestSnapshotDate()
#' 
#' dfGroups <- gsm.core::reportingGroups
#' 
#' lMetric <- gsm.core::reportingMetrics %>%
#'  dplyr::filter(MetricID == strMetricID) %>%
#'  as.list()
#' 
#' vThreshold = gsm.core::ParseThreshold(lMetric$Threshold, bSort = FALSE)
#' 
#' lCharts <- lCharts %>%
#'   ChartsMetricDefault(
#'     dfResults= dfResults_latest,
#'     lMetric = lMetric,
#'     dfGroups = dfGroups,
#'     dfBounds = dfBounds_latest,
#'     vThreshold = vThreshold,
#'     bDebug = FALSE
#'   )
#' 
#' lCharts
#' @export
ChartsMetricDefault <- function(
    lCharts,
    dfResults,
    lMetric,
    dfGroups,
    dfBounds,
    vThreshold,
    bDebug
) {                              
    lCharts$scatterPlot <- Widget_ScatterPlot(
      dfResults = dfResults,
      lMetric = lMetric,
      dfGroups = dfGroups,
      dfBounds = dfBounds,
      bDebug = bDebug
    )
    scatterPlotName <- paste0(fontawesome::fa("arrow-up-right-dots", fill = "#337ab7"), "  Scatter Plot")
    attr(lCharts$scatterPlot, "chart_name") <- scatterPlotName

    lCharts$barChart <- Widget_BarChart(
      dfResults = dfResults,
      lMetric = lMetric,
      dfGroups = dfGroups,
      vThreshold = vThreshold,
      strOutcome = "Score",
      bDebug = bDebug
    )

    barChartName <- paste0(fontawesome::fa("chart-simple", fill = "#337ab7"), "  Bar Chart")
    attr(lCharts$barChart, "chart_name") <- barChartName

    if (!is.null(lMetric)) {
      lCharts$metricTable <- Report_MetricTable(
        dfResults = dfResults,
        dfGroups = dfGroups,
        strGroupLevel = lMetric$GroupLevel
      )
    } else {
      lCharts$metricTable <- Report_MetricTable(dfResults)
    }

    metricTableName <- paste0(fontawesome::fa("table", fill = "#337ab7"), "  Metric Table")
    attr(lCharts$metricTable, "chart_name") <- metricTableName

    return(lCharts)
} 

#' Charts Continous Default Function
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' The function creates all continous charts for a default metric using the data provided
#'
#' @inheritParams ChartsMetricDefault
#'
#' @return A list containing the following charts:
#' - timeSeries: A time series chart using JavaScript with score on the y-axis.
#' 
#' @examples
#' lCharts <- list()
#' strMetricID = "Analysis_kri0001"
#' 
#' dfResults <-  gsm.core::reportingResults %>%
#'  dplyr::filter(MetricID == strMetricID)
#' 
#' dfGroups <- gsm.core::reportingGroups
#' 
#' lMetric <- gsm.core::reportingMetrics %>%
#'  dplyr::filter(MetricID == strMetricID) %>%
#'  as.list()
#' 
#' vThreshold = gsm.core::ParseThreshold(lMetric$Threshold, bSort = FALSE)
#' 
#' lCharts <- lCharts %>%
#'   ChartsContinousDefault(
#'     dfResults = dfResults,
#'     lMetric = lMetric,
#'     dfGroups = dfGroups,
#'     vThreshold = vThreshold,
#'     bDebug = FALSE
#'   )
#' 
#' lCharts
#' 
#' @export
ChartsContinousDefault <- function(
    lCharts = list(),
    dfResults,
    lMetric,
    dfGroups,
    vThreshold,
    bDebug
) {

  lCharts$timeSeries <- Widget_TimeSeries(
    dfResults = dfResults,
    lMetric = lMetric,
    dfGroups = dfGroups,
    vThreshold = vThreshold,
    strOutcome = "Score",
    bDebug = bDebug
  )

  timeSeriesName <- paste0(fontawesome::fa("chart-line", fill = "#337ab7"), "  Time Series")
  attr(lCharts$timeSeries, "chart_name") <- timeSeriesName

  return(lCharts)
}

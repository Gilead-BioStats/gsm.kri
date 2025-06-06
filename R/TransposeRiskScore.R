#' Transpose Risk Score
#'
#' Transposes the risk score data frame so that each `MetricID` becomes a column, structuring the
#' data for reporting.
#'
#' @param dfRiskScore `data.frame` The risk score data to be transposed.
#' @param strValuesFrom `character` The column name from which to take values in the transposed data.
#'
#' @return `data.frame` The transposed risk score data with `MetricID` as columns.
#'
#' @examples
#' dfRiskScoreTransposed <- gsm.core::reportingResults %>%
#'     CalculateRiskScore(gsm.kri::metricWeights) %>%
#'     TransposeRiskScore()
#'
#' @export

TransposeRiskScore <- function(
    dfResults,
    dfMetrics,
    strValuesFrom = 'flag_icon'
) {
    wide <- dfResults %>%
        # Merge in metric label from dfMetrics
        left_join(dfMetrics %>% select(MetricID, MetricLabel = Abbreviation), by = "MetricID") %>%
        mutate(Label = paste0(Report_FormatFlag(Flag), ' <sup>', RiskScore, '</sup>')) %>%
        arrange(MetricID) %>%
        pivot_wider(
            id_cols= c("StudyID","SnapshotDate","GroupID", "GroupLevel"),
            names_from = 'MetricLabel',
            values_from = c("Flag","RiskScore","Label")
        )
    return(wide)
}

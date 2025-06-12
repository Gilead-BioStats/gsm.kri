#' Transpose Risk Score
#'
#' Transposes the risk score data frame so that each metric (by `MetricID`) becomes a set of columns, structuring the data for reporting. Merges in metric labels from `dfMetrics` and creates a formatted label column. The result is a wide-format data frame suitable for reporting or visualization.
#'
#' @param dfResults `data.frame` The risk score data to be transposed. Should include columns such as `MetricID`, `Flag`, `RiskScore`, and grouping columns like `StudyID`, `SnapshotDate`, `GroupID`, `GroupLevel`.
#' @param dfMetrics `data.frame` The metrics reference table. Must include `MetricID` and `Abbreviation` (used as `MetricLabel`).
#' @param strValuesFrom `character` The column name from which to take values in the transposed data. (Currently not used, reserved for future flexibility.)
#'
#' @return `data.frame` The transposed risk score data with metric labels as column groups (Flag, RiskScore, Label for each metric).
#'
#' @examples
#' dfRiskScoreTransposed <- gsm.core::reportingResults %>%
#'     CalculateRiskScore(gsm.kri::metricWeights) %>%
#'     TransposeRiskScore(dfMetrics = gsm.core::reportingMetrics)
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

#' @keywords internal
NULL

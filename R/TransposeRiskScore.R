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
    dfRiskScore,
    strValuesFrom = 'Weight'
) {
    dfRiskScore %>%
        select(
            StudyID,
            SnapshotMonth,
            SnapshotDate,
            GroupLevel,
            GroupID,
            RiskScore,
            RiskScoreMax,
            RiskScoreNormalized,
            nRed,
            nAmber,
            MetricID,
            !!strValuesFrom
        ) %>%
        arrange(MetricID) %>%
        pivot_wider(
            names_from = 'MetricID',
            values_from = !!strValuesFrom
        )
}

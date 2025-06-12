#' Calculate Risk Score
#'
#' Calculates the risk score for each group in the provided results data frame.
#'
#' @inheritParams shared-params
#' @param dfMetricWeights `data.frame` Combinations of metric ID and flag value, each with a
#' corresponding weight.
#'
#' @return `data.frame` `dfResults` with the following additional columns:
#' - `SnapshotMonth`: The month of the snapshot, formatted as "YYYY-MM".
#' - `RiskScore`: The total risk score for the group.
#' - `RiskScoreMax`: The maximum possible risk score for the group.
#' - `RiskScoreNormalized`: The normalized risk score as a percentage of the maximum.
#' - `nRed`: The count of metrics flagged as red.
#' - `nAmber`: The count of metrics flagged as amber.
#'
#' @examples
#' dfRiskScore <- CalculateRiskScore(gsm.core::reportingResults)
#'
#' @export

CalculateRiskScore <- function(
    dfResults,
    dfMetricWeights = gsm.kri::metricWeights
) {
    dfRiskScore <- dfResults %>%
        inner_join(
            dfMetricWeights,
            c('MetricID', 'Flag')
        ) %>%
        group_by(
            StudyID,
            SnapshotDate,
            GroupLevel,
            GroupID
        ) %>%
        mutate(
            SnapshotMonth = SnapshotDate %>%
                as.character %>%
                substr(1, 7),
            RiskScore = sum(Weight, na.rm = TRUE),
            RiskScoreMax = sum(WeightMax, na.rm = TRUE),
            RiskScoreNormalized = RiskScore / RiskScoreMax * 100,
            nRed = sum(abs(Flag) == 2, na.rm = TRUE),
            nAmber = sum(abs(Flag) == 1, na.rm = TRUE),
        ) %>%
        ungroup()

    return(dfRiskScore)
}

#' @keywords internal
NULL

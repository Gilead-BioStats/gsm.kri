#' Summarize Risk Score
#'
#' Summarizes group-level risk score across studies, returning the aggregate risk score.
#'
#' @param dfRiskScoreTransposed `data.frame` The transposed risk score data to be summarized.
#' @param fnSummarize `function` A function to summarize risk score. Default: `mean`.
#'
#' @return `data.frame` A summarized risk score data frame with aggregated values.
#'
#' @examples
#' dfRiskScoreSummarized <- gsm.core::reportingResults %>%
#'     CalculateRiskScore(gsm.kri::metricWeights) %>%
#'     TransposeRiskScore() %>%
#'     SummarizeRiskScore()
#'
#' @export

SummarizeRiskScore <- function(
    dfRiskScoreTransposed,
    fnSummarize = mean
) {
    dfRiskScoreTransposed %>%
        group_by(
            StudyID,
            SnapshotDate,
            GroupLevel,
            GroupID
        ) %>%
        summarize(
            StudyID = 'Overall',
            nStudies = n(),
            RiskScore = fnSummarize(RiskScore, na.rm = TRUE),
            RiskScoreMax = fnSummarize(RiskScoreMax, na.rm = TRUE),
            RiskScoreNormalized = fnSummarize(RiskScoreNormalized, na.rm = TRUE),
            nRed = fnSummarize(nRed, na.rm = TRUE),
            nAmber = fnSummarize(nAmber, na.rm = TRUE),
            across(
                starts_with('Analysis_'),
                ~ sum(.x, na.rm = TRUE)
            )
        ) %>%
        ungroup()
}

#' @keywords internal
NULL

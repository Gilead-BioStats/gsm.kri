#' Calculate Risk Score
#'
#' Calculates the risk score for each group in the provided results data frame.
#'
#' @param dfFlaggedWeights `data.frame` Dataframe of stacked analysis outputs from the metrics calculated in the
#' `workflow/2_metrics` workflows. Must contain the columns `GroupLevel`, `GroupID`, `Weight`, and `WeightMax`.
#'
#' @return `data.frame` that has the same features as Analysis_Summary.
#'
#' @examples
#' analysisFlagged <- gsm.core::analyticsSummary %>%
#'   dplyr::mutate(Weight = dplyr::case_when(abs(Flag) == 1 ~ 2,
#'                                           abs(Flag) == 2 ~ 4,
#'                                           Flag == 0 ~ 0,
#'                                           TRUE ~ NA),
#'                 WeightMax = 4)
#'
#' lAnalysis <- list("Analysis_kri0001" = list(Analysis_Flagged = analysisFlagged,
#'                                 ID = "Analysis_kri0001"))
#' lAnalysis_filtered <- FilterAnalysis(lAnalysis)
#' dfFlaggedWeights <- StackAnalysis(lAnalysis_filtered)
#' dfRiskScore <- CalculateRiskScore(dfFlaggedWeights)
#'
#' @export

CalculateRiskScore <- function(
    dfFlaggedWeights
) {

    dfRiskScore <- dfFlaggedWeights %>%
        group_by(
            GroupLevel,
            GroupID
        ) %>%
        summarize(
            MetricID = "Analysis_srs0001",
            Numerator = sum(Weight, na.rm = TRUE),
            Denominator = sum(WeightMax, na.rm = TRUE),
            Metric = Numerator / Denominator * 100,
            Score = Metric
        ) %>%
        ungroup()

    return(dfRiskScore)
}

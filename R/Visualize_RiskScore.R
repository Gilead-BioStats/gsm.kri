#' Visualize Risk Score
#'
#' Generates a color-coded HTML table using htmlwidgets, mimicking the DT table but without DT dependencies.
#'
#' @param dfRiskScoreTransposed `data.frame` The summarized risk score data to be visualized.
#' @param strGroupLevel `character` The group level to filter the risk score data. Default is 'Site'.
#'
#' @examples
#' gsm.core::reportingResults %>%
#'     CalculateRiskScore(gsm.kri::metricWeights) %>%
#'     TransposeRiskScore() %>%
#'     Visualize_RiskScore()
#'
#' @rdname Widget_RiskScore
#' @export

Visualize_RiskScore <- function(
    dfResults,
    strGroupLevel = 'Site'
) {
    # Ensure RiskScoreNormalized column exists
    if (!"RiskScoreNormalized" %in% names(dfResults)) {
        stop("Input data frame must contain a 'RiskScoreNormalized' column. Please run CalculateRiskScore and TransposeRiskScore first.")
    }
    Widget_RiskScore(dfResults, strGroupLevel)
}

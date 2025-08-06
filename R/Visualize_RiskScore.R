#' Visualize Risk Score
#'
#' Generates a color-coded HTML table using htmlwidgets, mimicking the DT table but without DT dependencies.
#'
#' @param dfRiskScoreTransposed `data.frame` The summarized risk score data to be visualized.
#' @param strGroupLevel `character` The group level to filter the risk score data. Default is 'Site'.
#'
#'
#' @rdname Widget_RiskScore
#' @export

Visualize_RiskScore <- function(
    dfResults,
    dfMetrics,
    strGroupLevel = 'Site'
) {
    # Ensure RiskScore column exists
    if (!"RiskScore" %in% names(dfResults)) {
        stop("Input data frame must contain a 'RiskScore' column. Please run CalculateRiskScore on Reporting Results first.")
    }

    dfRiskScores <- dfResults %>% GroupRiskScore(strGroupLevel = "Site")

    Widget_RiskScore(dfResults, dfRiskScores, dfMetrics)
}

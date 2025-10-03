#' Visualize Risk Score
#'
#' Creates an interactive risk score widget for cross-study visualization.
#'
#' @param dfResults `data.frame` Analysis results containing RiskScore column
#' @param strGroupLevel `character` The group level to filter the risk score data. Default is 'Site'.
#'
#' @examples
#' # Cross-study risk score visualization
#' dfResults %>%
#'     Visualize_RiskScore()
#'
#' @export

Visualize_RiskScore <- function(
    dfResults,
    strGroupLevel = 'Site'
) {
    # Ensure RiskScore column exists
    if (!"RiskScore" %in% names(dfResults)) {
        stop("Input data frame must contain a 'RiskScore' column. Please run CalculateRiskScore on Reporting Results first.")
    }

    # For cross-study functionality, use the cross-study widget
    Widget_CrossStudyRiskScore(dfResults, strGroupLevel)
}
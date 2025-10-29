#' Create Weight Table from Metrics Metadata
#'
#' Generates a weight table by parsing comma-separated Flag and RiskScoreWeight values
#' from a metrics metadata data frame. This table can be joined to KRI results to add
#' weight information for risk score calculations.
#'
#' @param dfMetrics `data.frame` Metrics metadata containing at least `MetricID`, `Flag`,
#'   and `RiskScoreWeight` columns. The `Flag` and `RiskScoreWeight` columns should contain
#'   comma-separated values that will be parsed into individual rows.
#'
#' @return `data.frame` Weight table with one row per MetricID-Flag combination, containing:
#'   \describe{
#'     \item{MetricID}{Unique metric identifier}
#'     \item{Flag}{Individual flag value (numeric)}
#'     \item{Weight}{Weight associated with the flag (numeric)}
#'     \item{WeightMax}{Maximum weight for the metric (numeric)}
#'   }
#'
#' @details
#' The function performs the following steps:
#' \enumerate{
#'   \item Filters to rows with non-NA Flag and RiskScoreWeight values
#'   \item Splits comma-separated Flag and RiskScoreWeight strings into lists
#'   \item Expands to one row per flag-weight combination
#'   \item Converts Flag and Weight to numeric values
#'   \item Calculates WeightMax as the maximum Weight per MetricID
#' }
#'
#' @examples
#' # Create weight table from gsm.core::reportingMetrics
#' dfWeights <- MakeWeights(gsm.core::reportingMetrics)
#' 
#' # Join to KRI results
#' library(dplyr)
#' dfResults <- gsm.core::reportingResults %>%
#'   left_join(dfWeights, by = c("MetricID", "Flag"))
#'
#' @export
MakeWeights <- function(dfMetrics) {
  
  # Input validation
  required_cols <- c("MetricID", "Flag", "RiskScoreWeight")
  if (!all(required_cols %in% colnames(dfMetrics))) {
    missing_cols <- required_cols[!required_cols %in% colnames(dfMetrics)]
    stop("Missing required columns in dfMetrics: ", paste(missing_cols, collapse = ", "))
  }
  
  # Create weight table from dfMetrics
  weight_table <- dfMetrics %>%
    dplyr::filter(!is.na(.data$Flag) & !is.na(.data$RiskScoreWeight)) %>%
    dplyr::select("MetricID", "Flag", "RiskScoreWeight")
  
  # Return empty data frame with correct structure if no valid rows
  if (nrow(weight_table) == 0) {
    warning("No valid rows found in dfMetrics with non-NA Flag and RiskScoreWeight values. Returning dfWeights data.frame with 0 rows.")
    return(data.frame(
      MetricID = character(0),
      Flag = numeric(0),
      Weight = numeric(0),
      WeightMax = numeric(0),
      stringsAsFactors = FALSE
    ))
  }
  
  weight_table <- weight_table %>%
    # Parse the comma-separated Flag and RiskScoreWeight values
    dplyr::mutate(
      flags_list = strsplit(.data$Flag, ","),
      weights_list = strsplit(.data$RiskScoreWeight, ",")
    ) %>%
    # Expand to one row per flag-weight combination
    tidyr::unnest_longer(c(.data$flags_list, .data$weights_list)) %>%
    dplyr::mutate(
      Flag = as.numeric(.data$flags_list),
      Weight = as.numeric(.data$weights_list)
    ) %>%
    # Calculate WeightMax by metric
    dplyr::group_by(.data$MetricID) %>%
    dplyr::mutate(WeightMax = max(.data$Weight, na.rm = TRUE)) %>%
    dplyr::ungroup() %>%
    # Keep only the necessary columns
    dplyr::select("MetricID", "Flag", "Weight", "WeightMax")
  
  return(weight_table)
}

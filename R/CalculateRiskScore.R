#' Calculate Risk Score
#'
#' Calculates the risk score for each group in the provided results data frame.
#' The function aggregates weighted flag values across all metrics for each group,
#' creating a composite risk score as a percentage of the total possible risk.
#'
#' @param dfResults `data.frame` Dataframe of stacked analysis outputs from the metrics calculated in the
#' `workflow/2_metrics` workflows. Must contain the columns `GroupLevel`, `GroupID`, `MetricID`, `Weight`, and `WeightMax`.
#' @param strMetricID `character` The MetricID to assign to the calculated risk scores. Default is "Analysis_srs0001".
#'
#' @return `data.frame` with risk score data containing columns: `GroupLevel`, `GroupID`, `MetricID`, 
#' `Numerator` (sum of weights), `Denominator` (sum of max weights across all metrics), 
#' `Metric` (risk score percentage), `Score` (same as Metric), and `Flag` (set to NA).
#'
#' @details
#' The function calculates risk scores by:
#' \enumerate{
#'   \item Summing the `Weight` values for each group across all metrics
#'   \item Calculating a global denominator as the sum of `WeightMax` values across all unique metrics
#'   \item Computing the risk score as (Numerator / Denominator) * 100
#' }
#' 
#' Risk scores represent the percentage of total possible risk that each group exhibits,
#' allowing for comparison across groups and identification of high-risk sites or entities.
#'
#' @examples
#' # Prepare data with weights from gsm.core::reportingResults
#' library(dplyr)
#' 
#' # Filter to remove any existing risk scores and add weight columns
#' dfResults <- gsm.core::reportingResults %>%
#'   dplyr::filter(!grepl("srs0001", MetricID)) %>%
#'   dplyr::mutate(
#'     Weight = dplyr::case_when(
#'       abs(Flag) == 1 ~ 2,
#'       abs(Flag) == 2 ~ 4,
#'       Flag == 0 ~ 0,
#'       TRUE ~ 0
#'     ),
#'     WeightMax = dplyr::case_when(
#'       grepl("kri0001", MetricID) ~ 4,
#'       grepl("kri0002", MetricID) ~ 8,
#'       grepl("kri0003", MetricID) ~ 4,
#'       TRUE ~ 4
#'     )
#'   )
#' 
#' # Calculate risk scores
#' dfRiskScore <- CalculateRiskScore(dfResults)
#' 
#' # View summary of risk scores
#' summary(dfRiskScore$Metric)
#'
#' @export

CalculateRiskScore <- function(
  dfResults,
  strMetricID = "Analysis_srs0001"
) {

  # Check that required columns are present
  required_cols <- c("GroupLevel","GroupID","MetricID", "Weight", "WeightMax")
  if (!all(required_cols %in% colnames(dfResults))) {
    missing_cols <- required_cols[!required_cols %in% colnames(dfResults)]
    stop("Missing required columns in dfResults: ", paste(missing_cols, collapse = ", "))
    }
  
  # Check that MetricID is not present in dfResults$MetricID
  
  if (strMetricID %in% dfResults$MetricID) {
    stop(paste("MetricID", strMetricID, "already exists in dfResults. Did you already calculate a site risk score?"))
  }

  # Check that Weight and WeightMax are numeric
  if (!is.numeric(dfResults$Weight) || !is.numeric(dfResults$WeightMax)) {
    stop("Columns 'Weight' and 'WeightMax' must be numeric.")
  }

  # Check that the combination of GroupLevel + GroupID + MetricID is unique
  if (any(duplicated(dfResults[, c("GroupLevel", "GroupID", "MetricID")]))) {
    stop("The combination of 'GroupLevel', 'GroupID', and 'MetricID' must be unique in dfResults. Do you have multiple Snapshots or Studies in your data?")
  }

  # Drop row that have NA values of Weight or WeightMax and throw a warning
  if (any(is.na(dfResults$Weight)) || any(is.na(dfResults$WeightMax))) {
    warning("Rows with NA values in 'Weight' or 'WeightMax' have been dropped.")
    dfResults <- dfResults %>%
      filter(!is.na(Weight) & !is.na(WeightMax))
  }

  # Check that WeightMax is the same within each MetricID
  dfMaxWeights <- dfResults %>% 
  group_by(MetricID) %>%
  summarize(
    distinct = n_distinct(WeightMax),
    min_WeightMax = min(WeightMax),
    max_WeightMax = max(WeightMax)
  ) %>% 
  ungroup() 

  if (any(dfMaxWeights$distinct > 1)) {
    stop("'WeightMax' should be the same for each 'MetricID'.")
  }

  # calculate global denominator
  GlobalDenominator <- sum(dfMaxWeights$max_WeightMax) 

  dfRiskScore <- dfResults %>%
    group_by(
      GroupLevel,
      GroupID
    ) %>%
    summarize(
      MetricID = strMetricID,
      Numerator = sum(Weight, na.rm = TRUE),
      Denominator = GlobalDenominator,
      Metric = Numerator / Denominator * 100,
      Score = Metric
    ) %>%
    mutate(
      Flag = NA
    ) %>%
    ungroup()

  return(dfRiskScore)
}

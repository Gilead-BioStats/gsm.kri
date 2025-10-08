#' Calculate Risk Score
#'
#' Calculates the risk score for each group in the provided results data frame.
#'
#' @param dfResults `data.frame` Dataframe of stacked analysis outputs from the metrics calculated in the
#' `workflow/2_metrics` workflows. Must contain the columns `GroupLevel`, `GroupID`, `MetricID`, `Weight`, and `WeightMax`.
#'
#' @return `data.frame` that has the same features as Analysis_Summary.
#'
#' @examples
#' analysisFlagged <- gsm.core::analyticsSummary %>%
#'   dplyr::mutate(
#'     Weight = dplyr::case_when(
#'       abs(Flag) == 1 ~ 2,
#'       abs(Flag) == 2 ~ 4,
#'       Flag == 0 ~ 0,
#'       TRUE ~ NA
#'     ),
#'     WeightMax = 4
#'   )
#'
#' lAnalysis <- list("Analysis_kri0001" = list(
#'   Analysis_Flagged = analysisFlagged,
#'   ID = "Analysis_kri0001"
#' ))
#' lAnalysis_filtered <- FilterAnalysis(lAnalysis)
#' dfResults <- StackAnalysis(lAnalysis_filtered)
#' dfRiskScore <- CalculateRiskScore(dfResults)
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

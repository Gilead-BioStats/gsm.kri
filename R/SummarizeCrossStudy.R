#' Summarize Cross-Study Risk Scores
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Creates a summary table showing cross-study metrics for each site, including
#' number of studies, average risk scores, and aggregated flag counts.
#'
#' @param dfResults `data.frame` A data frame containing results from multiple studies.
#' @param strGroupLevel `character` The group level to summarize. Default is 'Site'.
#'
#' @return `data.frame` Summary table with cross-study metrics per site.
#'
#' @examples
#' \dontrun{
#' # Simulate multi-study data
#' dfMultiStudy <- sim_reportingResults %>%
#'   CalculateRiskScore(gsm.kri::metricWeights)
#'
#' dfSummary <- SummarizeCrossStudy(dfMultiStudy)
#' }
#'
#' @export
SummarizeCrossStudy <- function(dfResults, strGroupLevel = "Site") {
  stopifnot(is.data.frame(dfResults))
  stopifnot(is.character(strGroupLevel) && length(strGroupLevel) == 1)
  
  # Filter to specified group level
  group_results <- dfResults %>%
    dplyr::filter(.data$GroupLevel == strGroupLevel)
  
  if (nrow(group_results) == 0) {
    stop(paste("No data found for GroupLevel:", strGroupLevel))
  }
  
  # Get risk score data
  risk_score_data <- group_results %>%
    dplyr::filter(.data$MetricID == "Analysis_srs0001") %>%
    dplyr::group_by(.data$GroupID) %>%
    dplyr::summarise(
      NumStudies = dplyr::n_distinct(.data$StudyID),
      AvgRiskScore = round(mean(.data$Score, na.rm = TRUE), 2),
      MaxRiskScore = round(max(.data$Score, na.rm = TRUE), 2),
      MinRiskScore = round(min(.data$Score, na.rm = TRUE), 2),
      .groups = "drop"
    )
  
  # Get KRI flag summaries (excluding risk score metric)
  kri_results <- group_results %>%
    dplyr::filter(.data$MetricID != "Analysis_srs0001")
  
  flag_summary <- kri_results %>%
    dplyr::group_by(.data$GroupID) %>%
    dplyr::summarise(
      TotalFlags = dplyr::n(),
      RedFlags = sum(abs(.data$Flag) == 2, na.rm = TRUE),
      AmberFlags = sum(abs(.data$Flag) == 1, na.rm = TRUE),
      GreenFlags = sum(.data$Flag == 0, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Combine summaries
  cross_study_summary <- risk_score_data %>%
    dplyr::left_join(flag_summary, by = "GroupID") %>%
    dplyr::mutate(
      GroupLevel = strGroupLevel,
      FlagRate_Red = round(.data$RedFlags / .data$TotalFlags * 100, 1),
      FlagRate_Amber = round(.data$AmberFlags / .data$TotalFlags * 100, 1),
      FlagRate_Green = round(.data$GreenFlags / .data$TotalFlags * 100, 1)
    ) %>%
    dplyr::arrange(dplyr::desc(.data$AvgRiskScore))
  
  return(cross_study_summary)
}
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
#' @param dfGroups `data.frame` Optional. A data frame containing group metadata (for InvestigatorName lookup).
#' @param strNameCol `character` The column name in dfGroups to use for investigator names. Default is 'InvestigatorLastName'.
#'
#' @return `data.frame` Summary table with cross-study metrics per site, including per-study details.
#'
#' @examples
#' \dontrun{
#' # See inst/examples/Example_CrossStudySRS.Rmd
#'
#' @export
SummarizeCrossStudy <- function(dfResults, strGroupLevel = "Site", dfGroups = NULL, strNameCol = "InvestigatorLastName") {
  stopifnot(is.data.frame(dfResults))
  stopifnot(is.character(strGroupLevel) && length(strGroupLevel) == 1)
  stopifnot(is.null(dfGroups) || is.data.frame(dfGroups))
  
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
  
  # Get per-study details for each site
  per_study_details <- group_results %>%
    dplyr::filter(.data$MetricID == "Analysis_srs0001") %>%
    dplyr::select(.data$GroupID, .data$StudyID, SiteRiskScore = .data$Score)
  
  # Combine summaries
  cross_study_summary <- risk_score_data %>%
    dplyr::left_join(flag_summary, by = "GroupID") %>%
    dplyr::mutate(
      GroupLevel = strGroupLevel,
      FlagRate_Red = round(.data$RedFlags / .data$TotalFlags * 100, 1),
      FlagRate_Amber = round(.data$AmberFlags / .data$TotalFlags * 100, 1),
      FlagRate_Green = round(.data$GreenFlags / .data$TotalFlags * 100, 1)
    )
  
  # Add InvestigatorName if dfGroups provided
  if (!is.null(dfGroups)) {
    # check that required columns are included in dfGroups
    required_cols <- c("GroupID", "StudyID", "Param", "Value")
    missing_cols <- setdiff(required_cols, colnames(dfGroups))
    if (length(missing_cols) > 0) {
      warning(paste("Can't add group metadata since dfGroups is missing required columns:", paste(missing_cols, collapse = ", ")))
    } else{ 

      # Get all investigator names for each site
      investigator_names_all <- dfGroups %>%
        dplyr::filter(.data$Param == strNameCol) %>%
        dplyr::select(GroupID = .data$GroupID, InvestigatorName = .data$Value)
      
      # Check for multiple investigator names per site
      investigator_counts <- investigator_names_all %>%
        dplyr::group_by(.data$GroupID) %>%
        dplyr::summarise(
          UniqueNames = dplyr::n_distinct(.data$InvestigatorName),
          AllNames = paste(unique(.data$InvestigatorName), collapse = ", "),
          InvestigatorName = dplyr::first(.data$InvestigatorName),
          .groups = "drop"
        )
      
      # Warn about sites with multiple investigator names
      multiple_names <- investigator_counts %>%
        dplyr::filter(.data$UniqueNames > 1)
      
      if (nrow(multiple_names) > 0) {
        warning_msg <- paste0(
          "Found ", nrow(multiple_names), " site(s) with multiple investigator names across studies:\n",
          paste(sapply(1:min(5, nrow(multiple_names)), function(i) {
            paste0("  - ", multiple_names$GroupID[i], ": ", multiple_names$AllNames[i])
          }), collapse = "\n"),
          if (nrow(multiple_names) > 5) paste0("\n  ... and ", nrow(multiple_names) - 5, " more")
        )
        warning(warning_msg)
        
        # Set to "Multiple" for sites with different names
        investigator_counts <- investigator_counts %>%
          dplyr::mutate(
            InvestigatorName = ifelse(.data$UniqueNames > 1, "Multiple", .data$InvestigatorName)
          )
      }
      
      # Select final columns
      investigator_names <- investigator_counts %>%
        dplyr::select(.data$GroupID, .data$InvestigatorName)

      cross_study_summary <- cross_study_summary %>%
        dplyr::left_join(investigator_names, by = "GroupID")
    }
  }

  
  # Add per-study details as nested column
  cross_study_summary <- cross_study_summary %>%
    dplyr::mutate(
      StudyDetails = purrr::map(.data$GroupID, function(gid) {
        per_study_details %>%
          dplyr::filter(.data$GroupID == gid)
      })
    ) %>%
    dplyr::arrange(dplyr::desc(.data$AvgRiskScore))
  
  return(cross_study_summary)
}
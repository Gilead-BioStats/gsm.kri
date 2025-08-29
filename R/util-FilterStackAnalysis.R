#' Filter Analysis Outputs
#'
#' @param lAnalysis `list` List of analysis outputs from the metrics calculated in the `workflow/2_metrics` workflows.
#' @param strFilterIDPattern `character` Pattern to filter the analysis IDs. Default is "kri".
#'
#' @returns `list` Filtered list of analysis outputs from the metrics calculated in the `workflow/2_metrics` workflows.
#' @export
#'
#' @examples
#' analysisFlagged <- gsm.core::analyticsSummary %>%
#'  dplyr::mutate(Weight = dplyr::case_when(abs(Flag) == 1 ~ 2,
#'                                        abs(Flag) == 2 ~ 4,
#'                                        Flag == 0 ~ 0,
#'                                        TRUE ~ NA),
#'                WeightMax = 4)
#' lAnalysis <- list("Analysis_kri0001" = list(Analysis_Flagged = analysisFlagged,
#'                                ID = "Analysis_kri0001"))
#' lAnalysis_filtered <- FilterAnalysis(lAnalysis)
FilterAnalysis <- function(lAnalysis,
                           strFilterIDPattern = "kri") {
##filter to site-level analysis output only and stack results
lAnalysis_filtered <-  purrr::keep(lAnalysis, \(.x) "ID" %in% names(.x) && grepl(strFilterIDPattern, .x$ID))

return(lAnalysis_filtered)
}

#' Stack Analysis Outputs
#'
#' @param lAnalysis `list` List of analysis outputs from the metrics calculated in the `workflow/2_metrics` workflows.
#'       May be filtered via `FilterAnalysis()`
#' @param strName `character` Name of the analysis output data.frame to stack. Default is "Analysis_Flagged".
#'
#' @returns `data.frame` Stacked analysis outputs from the metrics calculated in the `workflow/2_metrics` workflows.
#' @export
#'
#' @examples
#' analysisFlagged <- gsm.core::analyticsSummary %>%
#'  dplyr::mutate(Weight = dplyr::case_when(abs(Flag) == 1 ~ 2,
#'                                        abs(Flag) == 2 ~ 4,
#'                                        Flag == 0 ~ 0,
#'                                        TRUE ~ NA),
#'                WeightMax = 4)
#' lAnalysis <- list("Analysis_kri0001" = list(Analysis_Flagged = analysisFlagged,
#'                                ID = "Analysis_kri0001"))
#' lAnalysis_filtered <- FilterAnalysis(lAnalysis)
#' dfFlaggedWeights <- StackAnalysis(lAnalysis_filtered)
#'
StackAnalysis <- function(lAnalysis,
                          strName = "Analysis_Flagged") {
  output <- lAnalysis %>%
    purrr::imap(function(result, metric) {
      subResult <- result[[strName]]
      return(subResult %>% dplyr::mutate(MetricID = metric))
    }) %>%
    purrr::list_rbind()

  return(output)
}

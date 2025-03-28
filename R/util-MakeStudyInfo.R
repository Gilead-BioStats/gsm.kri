#' Generate a study information data.frame for use in reports
#'
#' @description `r lifecycle::badge("stable")`
#'
#' Generate a study info table summarizing study metadata.
#'
#' @inheritParams Report_StudyInfo
#'
#' @return A data.frame containing study metadata.
#'
#' @examples
#' MakeStudyInfo(gsm.core::reportingGroups)
#' MakeStudyInfo(gsm.core::reportingGroups, list(SiteCount = "# Sites"))
#'
#' @export
MakeStudyInfo <- function(
  dfGroups,
  lStudyLabels = NULL,
  lStudy = deprecated()
) {
  # Default values for labels.
  lStudyLabels <- lStudyLabels %||% list(
    SiteCount = "Sites Enrolled",
    ParticipantCount = "Participants Enrolled",
    Status = "Study Status"
  )

  dfGroups <- Choose_dfGroups(dfGroups, lStudy) %>%
    dplyr::filter(.data$GroupLevel == "Study") %>%
    dplyr::select(-"GroupLevel") %>%
    MakeParamLabels(lStudyLabels) %>%
    dplyr::select("Param", "Value", "Description" = "Label")
  return(dfGroups)
}

Choose_dfGroups <- function(dfGroups, lStudy = deprecated()) {
  # If they *specify* `lStudy` as the arg, we warn and then use it. If they just
  # pass by position, we convert it if necessary.
  if (missing(dfGroups) && lifecycle::is_present(lStudy)) {
    lifecycle::deprecate_warn("2.2.0", "MakeStudyInfo(lStudy)")
    dfGroups <- lStudy
  }
  if (!is.data.frame(dfGroups)) {
    dfGroups <- data.frame(
      Param = names(dfGroups),
      Value = unname(unlist(dfGroups)),
      GroupLevel = "Study"
    )
  }
  dfGroups
}

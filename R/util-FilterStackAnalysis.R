#' Title
#'
#' @param lAnalysis
#' @param strFilterIDPattern
#'
#' @returns
#' @export
#'
#' @examples
FilterAnalysis <- function(lAnalysis,
                           strFilterIDPattern = "kri") {
##filter to site-level analysis output only and stack results
lAnalysis_filtered <-  purrr::keep(lAnalysis, \(.x) "ID" %in% names(.x) && grepl(strFilterIDPattern, .x$ID))

return(lAnalysis_filtered)
}

#' Title
#'
#' @param lAnalysis
#' @param strName
#'
#' @returns
#' @export
#'
#' @examples
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

#' Calculate Risk Score
#'
#' Calculates the risk score for each group in the provided results data frame.
#'
#' @param lAnalysis `list` List of analysis outputs from the metrics calculated in the
#' `workflow/2_metrics` workflows
#' @param dfMetricWeights `data.frame` Combinations of metric ID and flag value, each with a
#' corresponding weight.
#' @param dSnapshotDate `Date` The date of the snapshot. Default is the current date.
#' @param vThreshold `numeric` A vector of two numeric values representing the thresholds for flagging
#'
#' @return `data.frame` That has the same features as Analysis_Summary, but with the following additional columns:
#' - `SnapshotMonth`: The month of the snapshot in "YYYY-MM" format.
#' - `nAmber`: The count of metrics flagged as Amber.
#' - `nRed`: The count of metrics flagged as Red.
#'
#' @examples
#' lAnalysis <- list("Analysis_kri0001" = list(Analysis_Summary = gsm.core::analyticsSummary,
#'                                 ID = "Analysis_kri0001"))
#' dfRiskScore <- CalculateRiskScore(lAnalysis)
#'
#' @export

CalculateRiskScore <- function(
    lAnalysis,
    dfMetricWeights = gsm.kri::metricWeights,
    dSnapshotDate = Sys.Date(),
    vThreshold = c(60,30)
) {
  ##filter to site-level analysis output only and stack results
  dfAnalysis_site <- purrr::keep(lAnalysis, \(.x) "ID" %in% names(.x) && grepl("kri", .x$ID)) %>%
    purrr::imap(function(result, metric) {
      subResult <- result$Analysis_Summary
      return(subResult %>% dplyr::mutate(MetricID = metric))
    }) %>%
    purrr::list_rbind() %>%
    mutate(SnapshotDate = dSnapshotDate)

    if (!"Weight" %in% names(dfAnalysis_site)) {
      dfAnalysis_site <- dfAnalysis_site %>%
        inner_join(
          dfMetricWeights,
          c('MetricID', 'Flag')
        )
    }

    dfRiskScore <- dfAnalysis_site %>%
        group_by(
            GroupLevel,
            GroupID
        ) %>%
        summarize(
            SnapshotMonth = first(SnapshotDate) %>%
                as.character %>%
                substr(1, 7),
            MetricID = "Analysis_srs0001",
            Numerator = sum(Weight, na.rm = TRUE),
            Denominator = sum(WeightMax, na.rm = TRUE),
            Metric = Numerator / Denominator * 100,
            Score = Metric,
            nRed = sum(abs(Flag) == 2, na.rm = TRUE),
            nAmber = sum(abs(Flag) == 1, na.rm = TRUE)#,
            # Flag = case_when(Score >= vThreshold[1] ~ 2,  # Red
            #                 Score >= vThreshold[2] ~ 1,  # Amber
            #                 TRUE ~ 0),       # Green
        ) %>%
        ungroup()

    return(dfRiskScore)
}

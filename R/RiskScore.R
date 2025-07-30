#' Calculate Risk Score
#'
#' Calculates the risk score for each group in the provided results data frame.
#'
#' @param dfResults `data.frame` The results data to calculate risk scores for.
#' @param dfMetricWeights `data.frame` Combinations of metric ID and flag value, each with a corresponding weight. Default: `gsm.kri::metricWeights`.
#'
#' @return `data.frame` `dfResults` with additional columns: `SnapshotMonth`, `RiskScore`, `RiskScoreMax`, `RiskScoreNormalized`, `nRed`, `nAmber`.
#'
#' @examples
#' dfRiskScore <- CalculateRiskScore(gsm.core::reportingResults)
#'
#' @export
#' @importFrom dplyr %>% group_by ungroup summarize mutate arrange left_join select across
#' @importFrom tidyr pivot_wider
#' @importFrom stringr str_detect
#' @importFrom magrittr %>%

RiskScore <- function(
    dfResults,
    dfMetricWeights = gsm.kri::metricWeights
) {
    dfRiskScore <- dfResults %>%
        inner_join(
            dfMetricWeights,
            c('MetricID', 'Flag'),
            na_matches = "na",
            unmatched = "drop"
        ) %>%
        rename(
            RiskScore = Weight,
            RiskScore_Max = WeightMax
        )

        return(dfRiskScore)
}

#' Group Risk Score
#'
#' Calculates group-level risk scores for a specified group level (default: "Site").
#' Filters the input data to the specified `GroupLevel`, then groups and summarizes risk scores and their percent of maximum.
#'
#' @param dfResults `data.frame` The results data to group and summarize. Must include columns: StudyID, SnapshotDate, GroupLevel, GroupID, RiskScore, RiskScore_Max.
#' @param strGroupLevel `character` The group level to filter by (default: "Site").
#'
#' @return `data.frame` The grouped results with columns: RiskScore, RiskScore_Max, RiskScore_Percent.
#'
#' @examples
#' grouped <- GroupRiskScore(dfResults, strGroupLevel = "Site")
#'
#' @export
GroupRiskScore <- function(dfResults, strGroupLevel = "Site") {
    GroupResults <- dfResults %>%
        filter(str_detect(GroupLevel, strGroupLevel)) %>%
        group_by(
            StudyID,
            SnapshotDate,
            GroupLevel,
            GroupID
        ) %>%
        summarize(
            RiskScore = sum(RiskScore, na.rm = TRUE),
            RiskScore_Max = sum(RiskScore_Max, na.rm = TRUE),
            RiskScore_Percent = RiskScore / RiskScore_Max * 100,
            .groups = 'drop'
        )

    return(GroupResults)
}

#' Transpose Risk Score
#'
#' Transposes the risk score data frame so that each metric (by `MetricID`) becomes a set of columns, structuring the data for reporting. Merges in metric labels from `dfMetrics` and creates a formatted label column. The result is a wide-format data frame suitable for reporting or visualization.
#'
#' @param dfResults `data.frame` The risk score data to be transposed. Should include columns such as `MetricID`, `Flag`, `RiskScore`, and grouping columns like `StudyID`, `SnapshotDate`, `GroupID`, `GroupLevel`.
#' @param dfMetrics `data.frame` The metrics reference table. Must include `MetricID` and `Abbreviation` (used as `MetricLabel`).
#' @param strValuesFrom `character` The column name from which to take values in the transposed data. (Currently not used, reserved for future flexibility.)
#'
#' @return `data.frame` The transposed risk score data with metric labels as column groups (Flag, RiskScore, Label for each metric).
#'
#' @examples
#' dfRiskScoreTransposed <- gsm.core::reportingResults %>%
#'     CalculateRiskScore(gsm.kri::metricWeights) %>%
#'     TransposeRiskScore(dfMetrics = gsm.core::reportingMetrics)
#'
#' @export
TransposeRiskScore <- function(
    dfResults,
    dfMetrics,
    strValuesFrom = 'flag_icon'
) {
    wide <- dfResults %>%
        # Merge in metric label from dfMetrics
        left_join(dfMetrics %>% select(MetricID, MetricLabel = Abbreviation), by = "MetricID") %>%
        mutate(
            FlagIcon = Report_FormatFlag(Flag),
            Label = paste0(FlagIcon, ' <sup>', RiskScore, '</sup>'),
            Details = paste0(
                'Metric: ', MetricLabel, '\n',
                'Group: ', GroupID, '\n',
                'Group Level: ', GroupLevel, '\n',
                'Snapshot Date: ', SnapshotDate, '\n',
                'Numerator: ', ifelse(!is.na(Numerator), Numerator, ''), '\n',
                'Denominator: ', ifelse(!is.na(Denominator), Denominator, ''), '\n',
                'Metric: ', round(Metric, 2), '\n',
                'Score: ', ifelse(!is.na(Score), round(Score, 2), ''), '\n',
                'Flag: ', ifelse(!is.na(Flag), Flag, ''), '\n',
                "Raw Risk Score: ", ifelse(!is.na(RiskScore), RiskScore, ''), '\n',
                'Max Risk Score: ', ifelse(!is.na(RiskScore_Max), RiskScore_Max, '')
            )
        ) %>%
        arrange(MetricID) %>%
        pivot_wider(
            id_cols= c("StudyID","SnapshotDate","GroupID", "GroupLevel"),
            names_from = 'MetricLabel',
            values_from = c("Label", "Details"),
            values_fill = list(Label = '', Details = 'Metric Not Found')
        )
    return(wide)
}


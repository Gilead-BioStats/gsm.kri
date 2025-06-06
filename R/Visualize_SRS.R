#' Visualize Risk Score
#'
#' Visualizes the risk score data in a table format, allowing for easy comparison of risk scores across studies.
#' TODO: apply color palette to metric columns
#'
#' @param dfRiskScoreTransposed `data.frame` The summarized risk score data to be visualized.
#' @param strGroupLevel `character` The group level to filter the risk score data. Default is 'Site'.
#'
#' @examples
#' gsm.core::reportingResults %>%
#'     CalculateRiskScore(gsm.kri::metricWeights) %>%
#'     TransposeRiskScore() %>%
#'     Visualize_RiskScore()
#'
#' @importFrom DT datatable formatStyle styleInterval
#' @import htmlwidgets
#' @export

Visualize_SRS <- function(
    dfRiskScoreTransposed,
    # dfMetrics = gsm.core::reportingMetrics, # TODO: merge metric metadata on to grab abbreviations
    strGroupLevel = 'Site'
) {
    dfRiskScoreSubset <- dfRiskScoreTransposed %>%
        filter(
            .data$GroupLevel == !!strGroupLevel
        ) %>%
        select(
            GroupID,
            #nStudies,
            #StudyID,
            RiskScoreNormalized,
            starts_with('Analysis_')
        ) %>%
        mutate(
            RiskScoreNormalized = round(.data$RiskScoreNormalized, 1),
        )

    lRiskScoreTable <- dfRiskScoreSubset %>%
        DT::datatable(
            colnames = c(
                strGroupLevel, # TODO: comment out when rendering risk score across multiple studies
                # '# Studies',
                # 'Study',
                'Risk Score (%)',
                'AE',
                'SAE',
                'PD',
                'IPD',
                'LB',
                'SDSC',
                'TDSC',
                'QRY',
                'OQRY',
                'ODAT',
                'CDAT',
                'SF'
            ),
            extensions = c('FixedHeader', 'RowGroup'),
            filter = 'top',
            options = list(
                autowidth = TRUE,
                # TODO: enable when rendering risk score across multiple studies
                #columnDefs = list(
                #    list(targets = 0, visible = FALSE)
                #),
                dom = 'ftipr',
                fixedHeader = TRUE,
                pageLength = 25
                # TODO: enable when rendering risk score across multiple studies
                #rowGroup = list(
                #    rowGroup = list(
                #        dataSrc = 1
                #    )
                #)
            ),
            rownames = FALSE
        ) %>%
        DT::formatStyle(
            'RiskScoreNormalized',
            backgroundColor = DT::styleInterval(
                cuts = c(2, 4, 6, 8, 10, 12.5, 15, 20, 25),
                values = c(
                    '#00683777',
                    '#1a985077',
                    '#66bd6377',
                    '#a6d96a77',
                    '#d9ef8b77',
                    '#ffffbf77',
                    '#fee08b77',
                    '#fdae6177',
                    '#f46d4377',
                    '#d7302777'
                )
            )
        )# %>%
        # TODO: enable when rendering risk score across multiple studies
        #formatStyle(
        #    c('GroupLabel', 'StudyLabel'),
        #    "white-space" = "nowrap"
        #)
    
    return(lRiskScoreTable)
}

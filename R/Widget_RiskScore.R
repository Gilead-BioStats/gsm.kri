#' Risk Score Table Widget
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' A widget that generates a color-coded HTML table of risk scores, mimicking the DT table but without DT dependencies.
#'
#' @param dfRiskScoreTransposed `data.frame` The summarized risk score data to be visualized.
#' @param strGroupLevel `character` The group level to filter the risk score data. Default is 'Site'.
#'
#' @examples
#' gsm.core::reportingResults %>%
#'     CalculateRiskScore(gsm.kri::metricWeights) %>%
#'     TransposeRiskScore() %>%
#'     Widget_RiskScore()
#'
#' @export
Widget_RiskScore <- function(
    dfResults,
    dfMetrics,
    strGroupLevel = 'Site',
    bDebug= FALSE
) {
    stopifnot(is.data.frame(dfResults))
    stopifnot(is.character(strGroupLevel) && length(strGroupLevel) == 1)
    if (!"RiskScoreNormalized" %in% names(dfResults)) {
        stop("Input data frame must contain a 'RiskScoreNormalized' column. Please run CalculateRiskScore and TransposeRiskScore first.")
    }

    # Transpose and Summarize the data for easier JS rendering
    dfSRS <- TransposeRiskScore(dfResults, dfMetrics) 
    #%>% SummarizeRiskScore()

    # Pass the transposed data and group level to the widget
    widget <- htmlwidgets::createWidget(
        name = "Widget_RiskScore",
        list(
            data = jsonlite::toJSON(
                dfSRS,
                null = "null",
                na = "string",
                auto_unbox = TRUE
            ),
            strGroupLevel = strGroupLevel
        ),
        package = "gsm.kri"
    )

    if (bDebug) {
        viewer <- getOption("viewer")
        options(viewer = NULL)
        print(widget)
        options(viewer = viewer)
    }

    return(widget)
}

#' Shiny bindings for Widget_RiskScore
#'
#' Output and render functions for using Widget_RiskScore within Shiny applications and interactive Rmd documents.
#'
#' @param outputId output variable to read from
#' @param width,height Must be a valid CSS unit (like '100%', '400px', 'auto') or a number, which will be coerced to a string and have 'px' appended.
#' @param expr An expression that generates a Widget_RiskScore
#' @param env The environment in which to evaluate expr.
#' @param quoted Is expr a quoted expression (with quote())? This is useful if you want to save an expression in a variable.
#'
#' @name Widget_RiskScore-shiny
#' @export
Widget_RiskScoreOutput <- function(outputId, width = "100%", height = "400px") {
  htmlwidgets::shinyWidgetOutput(outputId, "Visualize_RiskScore", width, height, package = "gsm.kri")
}

#' @rdname Widget_RiskScore-shiny
#' @export
renderWidget_RiskScore <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) {
    expr <- substitute(expr)
  } # force quoted
  htmlwidgets::shinyRenderWidget(expr, Widget_RiskScoreOutput, env, quoted = TRUE)
}

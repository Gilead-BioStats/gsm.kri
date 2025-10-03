#' Cross-Study Risk Score Widget
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' A widget that generates an interactive cross-study risk score table.
#' Shows a summary view with click-to-expand details for each site.
#'
#' @param dfResults `data.frame` Full results data for details.
#' @param strGroupLevel `character` The group level. Default is 'Site'.
#'
#' @return An htmlwidget for cross-study risk score visualization.
#'
#' @examples
#' \dontrun{
#' dfSummary <- SummarizeCrossStudy(dfMultiStudy)
#' Widget_CrossStudyRiskScore(dfMultiStudy)
#' }
#'
#' @export
Widget_CrossStudyRiskScore <- function(
    dfResults,
    strGroupLevel = "Site"
) {
  stopifnot(is.data.frame(dfResults))
  #Check that Analysis_srs0001 is present
  stopifnot("Analysis_srs0001" %in% dfResults$MetricID)

  dfCrossStudySummary <- SummarizeCrossStudy( 
    dfResults = dfResults,  
    strGroupLevel = strGroupLevel
  )
  
  # Create the widget data structure
  widget_data <- list(
    summary = dfCrossStudySummary,
    details = dfResults
  )
  
  # Create the htmlwidget
  widget <- htmlwidgets::createWidget(
    name = "Widget_CrossStudyRiskScore",
    x = list(
      data = widget_data
    ),
    package = "gsm.kri"
  )
  
  return(widget)
}

#' Shiny bindings for Widget_CrossStudyRiskScore
#'
#' @param outputId output variable to read from
#' @param width,height Must be a valid CSS unit
#' @param expr An expression that generates a Widget_CrossStudyRiskScore
#' @param env The environment in which to evaluate expr.
#' @param quoted Is expr a quoted expression?
#'
#' @name Widget_CrossStudyRiskScore-shiny
#' @export
Widget_CrossStudyRiskScoreOutput <- function(outputId, width = "100%", height = "600px") {
  htmlwidgets::shinyWidgetOutput(outputId, "Widget_CrossStudyRiskScore", width, height, package = "gsm.kri")
}

#' @rdname Widget_CrossStudyRiskScore-shiny
#' @export
renderWidget_CrossStudyRiskScore <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) {
    expr <- substitute(expr)
  }
  htmlwidgets::shinyRenderWidget(expr, Widget_CrossStudyRiskScoreOutput, env, quoted = TRUE)
}
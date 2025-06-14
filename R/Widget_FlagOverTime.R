#' Flag Over Time Widget
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' A widget that generates a table of flags over time using
#' [Report_FlagOverTime()].
#'
#' @inheritParams shared-params
#' @param strGroupLevel `character` Value for the group level. Default: "Site".
#' @param strFootnote `character` Text to insert for figure
#' @param bExcludeEver `logical` Exclude options in widget dropdown that include the string "ever".
#' Default: `FALSE`.
#'
#' @examples
#' # Include all risk signals, irrespective flag value.
#' Widget_FlagOverTime(
#'   dfResults = gsm.core::reportingResults,
#'   dfMetrics = gsm.core::reportingMetrics
#' )
#'
#' # Include risk signals that were ever flagged.
#' Widget_FlagOverTime(
#'   dfResults = FilterByFlags(
#'     gsm.core::reportingResults
#'   ),
#'   dfMetrics = gsm.core::reportingMetrics
#' )
#'
#' # Include risk signals that were only flagged in the most recent snapshot.
#' Widget_FlagOverTime(
#'   dfResults = FilterByFlags(
#'     gsm.core::reportingResults,
#'     bCurrentlyFlagged = TRUE
#'   ),
#'   dfMetrics = gsm.core::reportingMetrics,
#'   bExcludeEver = TRUE
#' )
#'
#' @export

Widget_FlagOverTime <- function(
  dfResults,
  dfMetrics,
  strGroupLevel = c("Site", "Study", "Country"),
  strFootnote = NULL,
  bExcludeEver = FALSE,
  strOutputLabel = paste0(
      fontawesome::fa("table", fill = "#337ab7"),
      "  Flags over Time"
  ),
  bDebug = FALSE
) {
  gsm.core::stop_if(cnd = !is.data.frame(dfResults), message = "dfResults is not a data.frame")
  gsm.core::stop_if(cnd = !is.data.frame(dfMetrics), "dfMetrics is not a data.frame")
  gsm.core::stop_if(cnd = !is.character(strGroupLevel), "strGroupLevel is not a character")
  gsm.core::stop_if(cnd = !is.character(strFootnote) && !is.null(strFootnote), "strFootnote is not a character or NULL")
  gsm.core::stop_if(cnd = !is.logical(bDebug), "bDebug is not a logical")

  gtFlagOverTime <- Report_FlagOverTime(
    dfResults,
    dfMetrics,
    strGroupLevel = strGroupLevel
  ) %>%
    gt::tab_options(table.align = "left") %>%
    gt::as_raw_html(inline_css = FALSE)

  x <- list(
    gtFlagOverTime = gtFlagOverTime,
    strFootnote = strFootnote,
    bExcludeEver = bExcludeEver,
    bDebug = bDebug
  )

  lWidget <- htmlwidgets::createWidget(
    name = "Widget_FlagOverTime",
    x,
    width = "100%",
    package = "gsm.kri"
  )

  base::attr(lWidget, "output_label") <- strOutputLabel

  if (bDebug) {
    viewer <- getOption("viewer")
    options(viewer = NULL)
    print(lWidget)
    options(viewer = viewer)
  }

  return(lWidget)
}

#' Shiny bindings for Widget_FlagOverTime
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' Output and render functions for using Widget_FlagOverTime within
#' Shiny applications and interactive Rmd documents.
#'
#' @param outputId output variable to read from
#' @param width,height Must be a valid CSS unit (like \code{'100\%'},
#'   \code{'400px'}, \code{'auto'}) or a number, which will be coerced to a
#'   string and have \code{'px'} appended.
#'
#' @name Widget_FlagOverTime-shiny
#'
#' @export
Widget_FlagOverTimeOutput <- function(
  outputId,
  width = "100%",
  height = "400px"
) {
  htmlwidgets::shinyWidgetOutput(
    outputId,
    "Widget_FlagOverTime",
    width,
    height,
    package = "gsm.kri"
  )
}

#' @rdname Widget_FlagOverTime-shiny
#' @inheritParams Widget_FlagOverTime
#' @export
renderWidget_FlagOverTime <- function(
  dfResults,
  dfMetrics,
  strGroupLevel = c("Site", "Study", "Country")
) {
  htmlwidgets::shinyRenderWidget(
    {
      Widget_FlagOverTime(dfResults, dfMetrics, strGroupLevel)
    },
    Widget_FlagOverTimeOutput,
    env = rlang::current_env(),
    quoted = FALSE
  )
}

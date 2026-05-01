#' Study Scatter Matrix Widget
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Renders a faceted scatter plot with one panel per metric. Each panel shows
#' all studies as points at (Denominator, Numerator) for that metric. Hovering
#' a point highlights the same study across every facet. A "Color by" control
#' recolors points based on a study-level attribute (therapeutic area, phase,
#' etc.) sourced from `dfGroups`.
#'
#' @param dfResults `data.frame` Cross-study KRI results with `StudyID`,
#'   `MetricID`, `GroupLevel`, `Numerator`, `Denominator`. May include
#'   `SnapshotDate`; if so, only the latest snapshot is used.
#' @param dfMetrics `data.frame` Metric metadata. Used for facet labels
#'   (Abbreviation column).
#' @param dfGroups `data.frame` Study-level group metadata in long format
#'   (`StudyID`, `Param`, `Value`).
#' @param strGroupLevel `character` GroupLevel to summarize across. Default
#'   `"Site"`.
#' @param vColorParams `character` Study-level params exposed in the color-by
#'   dropdown.
#'
#' @return An htmlwidget rendering the study scatter matrix.
#'
#' @export
Widget_StudyScatterMatrix <- function(
  dfResults,
  dfMetrics,
  dfGroups,
  strGroupLevel = "Site",
  vColorParams = c(
    "therapeutic_area",
    "protocol_indication",
    "phase",
    "status",
    "product"
  )
) {
  stopifnot(is.data.frame(dfResults))
  stopifnot(is.data.frame(dfMetrics))
  stopifnot(is.data.frame(dfGroups))
  stopifnot(is.character(vColorParams))

  if ("SnapshotDate" %in% colnames(dfResults)) {
    latest_snapshot <- max(dfResults$SnapshotDate, na.rm = TRUE)
    dfResults <- dfResults %>%
      dplyr::filter(.data$SnapshotDate == latest_snapshot)
  }

  dfSiteResults <- dfResults %>%
    dplyr::filter(.data$GroupLevel == strGroupLevel)

  dfPerStudy <- dfSiteResults %>%
    dplyr::group_by(.data$StudyID, .data$MetricID) %>%
    dplyr::summarise(
      Numerator = sum(.data$Numerator, na.rm = TRUE),
      Denominator = sum(.data$Denominator, na.rm = TRUE),
      .groups = "drop"
    )

  has_flag <- "Flag" %in% colnames(dfSiteResults)
  dfPerSite <- dfSiteResults %>%
    dplyr::group_by(.data$StudyID, .data$GroupID, .data$MetricID) %>%
    dplyr::summarise(
      Numerator = sum(.data$Numerator, na.rm = TRUE),
      Denominator = sum(.data$Denominator, na.rm = TRUE),
      Flag = if (has_flag) {
        f <- .data$Flag[!is.na(.data$Flag)]
        if (length(f) == 0) NA_real_ else f[which.max(abs(f))]
      } else NA_real_,
      .groups = "drop"
    )

  if (all(c("StudyID", "Param", "Value") %in% colnames(dfGroups))) {
    dfStudyAttrs <- dfGroups %>%
      dplyr::filter(.data$Param %in% vColorParams) %>%
      dplyr::select("StudyID", "Param", "Value") %>%
      dplyr::distinct()
  } else {
    dfStudyAttrs <- data.frame(
      StudyID = character(0),
      Param = character(0),
      Value = character(0)
    )
  }

  vMetricOrder <- sort(unique(dfPerStudy$MetricID))

  lInput <- list(
    dfPerStudy = dfPerStudy,
    dfPerSite = dfPerSite,
    dfStudyAttrs = dfStudyAttrs,
    dfMetrics = dfMetrics,
    vMetricOrder = vMetricOrder,
    vColorParams = vColorParams,
    strGroupLevel = strGroupLevel
  )

  htmlwidgets::createWidget(
    name = "Widget_StudyScatterMatrix",
    purrr::map(
      lInput,
      ~ jsonlite::toJSON(
        .x,
        null = "null",
        na = "string",
        auto_unbox = TRUE
      )
    ),
    width = "100%",
    package = "gsm.kri"
  )
}

#' Shiny bindings for Widget_StudyScatterMatrix
#'
#' @param outputId output variable to read from
#' @param width,height Must be a valid CSS unit
#' @param expr An expression that generates a Widget_StudyScatterMatrix
#' @param env The environment in which to evaluate expr.
#' @param quoted Is expr a quoted expression?
#'
#' @name Widget_StudyScatterMatrix-shiny
#' @export
Widget_StudyScatterMatrixOutput <- function(
  outputId,
  width = "100%",
  height = "800px"
) {
  htmlwidgets::shinyWidgetOutput(
    outputId,
    "Widget_StudyScatterMatrix",
    width,
    height,
    package = "gsm.kri"
  )
}

#' @rdname Widget_StudyScatterMatrix-shiny
#' @export
renderWidget_StudyScatterMatrix <- function(
  expr,
  env = parent.frame(),
  quoted = FALSE
) {
  if (!quoted) {
    expr <- substitute(expr)
  }
  htmlwidgets::shinyRenderWidget(
    expr,
    Widget_StudyScatterMatrixOutput,
    env,
    quoted = TRUE
  )
}

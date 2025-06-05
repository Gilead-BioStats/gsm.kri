#' Render charts for a given metric to markdown
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' This function generates a markdown framework for charts
#
#' @param lCharts A list of charts for the selected metric.
#' @param strMetricID `character` Metric ID, wich is added as a class to each rendered chart to
#' uniquely identify it within the report.
#'
#' @return Markdown content with charts and a summary table for the metric
#'
#' @export
#'
Report_MetricCharts <- function(
    lCharts,
    strMetricID = ""
) {
  #### charts tabset /
  cat("#### Summary Charts {.tabset} \n")

  for (i in seq_along(lCharts)) {
    lChart <- lCharts[[i]]
    strChartKey <- names(lCharts)[i]

    # Check that chart object has [ output_label ] attribute.
    if (is.null(base::attr(lChart, "output_label", exact = TRUE))) {
      LogMessage(
        level = "info",
        message = "No attribute named `output_label` detected on chart object named `{strChartKey}`.",
        cli_detail = "alert"
      )

      # If not, set it to the chart key.
      base::attr(lChart, "output_label") <- strChartKey
    }

    strOutputLabel <- base::attr(lChart, "output_label", exact = TRUE)

    ##### lChart tab /
    cat(paste("#####", strOutputLabel, "\n"))

    # need to initialize JS dependencies within loop in order to print correctly
    # see here: https://github.com/rstudio/rmarkdown/issues/1877#issuecomment-678996452
    purrr::map(
      lCharts,
      ~ .x %>%
        knitr::knit_print() %>%
        attr("knit_meta") %>%
        knitr::knit_meta_add() %>%
        invisible()
    )

    # Display chart.
    cat(glue::glue("<div class='gsm-widget {strMetricID} {strChartKey}'>"))
    cat(knitr::knit_print(htmltools::tagList(lChart)))
    cat("</div>")
    ##### / lChart tab
  }

  cat("#### {-} \n")
  #### / charts tabset
}

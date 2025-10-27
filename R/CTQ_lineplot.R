#' CTQ Time Series Lineplot
#'
#' @param dfResults A results `data.frame` from the output of `gsm.reporting::BindResults()` used
#' to create a variety of visualizations like the line plot, bar plot.
#' @param strCTQ A `string` to label the QTL being measured
#'
#' @returns A `plotly` object
#' @export
CTQ_lineplot <- function(dfResults, strCTQ) {
  df_plot <- dfResults %>%
    filter(GroupLevel == "Study" &  !(GroupID %in% c("Upper_funnel", "Flatline"))) %>%
    mutate(
      group_type = strCTQ,
      point_color = case_when(
        Flag == 2 | Metric > `Upper_funnel` ~ "Above CTQ Threshold",
        Flag == 0 ~ "Below CTQ Threshold",
        TRUE ~ "Below CTQ Threshold"
      ),
      tooltip_text = paste0("Study: ", GroupID, "\nDate: ", SnapshotDate, "\nMetric: ", round(Metric, 2), "\nNumerator: ", Numerator, "\nDenominator: ", Denominator)
    )

  # Build ggplot
  p <- ggplot(
    df_plot,
    aes(x = SnapshotDate, y = Metric, group = GroupID, text = tooltip_text)
  ) +
    # Line with custom linetype
    geom_line(
      aes(color = group_type),
      linetype = 2,
      linewidth = 1,
      show.legend = FALSE
    ) +

    # Colored points for Ineligibility Rate
    geom_point(
      aes(color = point_color),
      size = 2
    ) +
    scale_color_manual(
      values = c(
        strCTQ = "grey50",
        "Above CTQ Threshold" = "#FF5859",
        "Below CTQ Threshold" = "#3DAF06"
      ),
      breaks = c(strCTQ, "Above QTL Threshold", "Below QTL Threshold"),
      name = NULL
    ) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 30),
      legend.position = "right"
    ) +
    labs(
      y = strCTQ,
      x = "Snapshot Date"
    )

    g <- ggplotly(p, tooltip = "text")
    # # hide legend entries for any marker traces
    # g$x$data <- purrr::map(g$x$data, ~{
    #   if (!is.null(.x$name)) {
    #     .x$name <- gsub(",.*|\\(", "", .x$name)  # remove ",1,NA"
    #   }
    #   .x
    # })
    g
}

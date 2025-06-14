% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Report_FlagChange.R
\name{Report_FlagChange}
\alias{Report_FlagChange}
\title{Report Flag Changes}
\usage{
Report_FlagChange(dfResults)
}
\arguments{
\item{dfResults}{A data.frame generated by gsm.reporting::CalculateChange(), containing both current and previous snapshot columns. Optionally, may include custom `GroupLabel` and `MetricLabel` columns for display.}
}
\value{
HTML (character) containing a nested unordered list of newly changed flags, grouped by absolute flag value and color-coded. Each entry includes the flag transition, score/metric/numerator/denominator changes, and snapshot details.
}
\description{
Generate an HTML summary of newly changed risk flags between snapshots.
}
\details{
This function compares the current and previous snapshot for each group/metric and lists all changes in flag status, including the direction and magnitude of change. It provides a detailed breakdown for each change, including the group, metric, flag transition, score and metric changes, and numerator/denominator details. Optionally, if `GroupLabel` or `MetricLabel` columns are present, they will be used for display; otherwise, `GroupID` and `MetricID` are used.



- Only rows where the flag value has changed (including NA transitions) are included.
- Rows where the flag went from NA to green (0) are excluded.
- Results are grouped and color-coded by the absolute value of the new flag (red, amber, green).
- For each change, the function displays:
  - Group and metric (using labels if available)
  - Flag transition (with icon)
  - Score and metric changes (\eqn{\Delta} Score, \eqn{\Delta} Metric, etc.`)
  - Previous and current snapshot details (flag, score, rate, numerator/denominator)
}

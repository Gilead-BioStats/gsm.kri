% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Report_Setup.R
\name{Report_Setup}
\alias{Report_Setup}
\title{Calculate needed values for report}
\usage{
Report_Setup(dfGroups = NULL, dfMetrics = NULL, dfResults = NULL)
}
\arguments{
\item{dfGroups}{`data.frame` Group-level metadata dictionary. Created by
passing CTMS site and study data to [MakeLongMeta()]. Expected columns:
`GroupID`, `GroupLevel`, `Param`, `Value`.}

\item{dfMetrics}{`data.frame` Metric-specific metadata for use in charts and
reporting. Created by passing an `lWorkflow` object to [MakeMetric()].
Expected columns: `File`, `MetricID`, `Group`, `Abbreviation`, `Metric`,
`Numerator`, `Denominator`, `Model`, `Score`, and `Threshold`. For more
details see the Data Model vignette: `vignette("DataModel", package =
"gsm.core")`.}

\item{dfResults}{`data.frame` A stacked summary of analysis pipeline output.
Created by passing a list of results returned by [Summarize()] to
[BindResults()]. Expected columns: `GroupID`, `GroupLevel`, `Numerator`,
`Denominator`, `Metric`, `Score`, `Flag`, `MetricID`, `StudyID`,
`SnapshotDate`.}
}
\value{
`list` with the following elements:
- `GroupLevel` (character): The group level of the report.
- `SnapshotDate` (Date): The date of the snapshot.
- `lStudy` (list): Study-level metadata.
- `StudyID` (character): The study ID.
- `red_kris` (numeric): The number of red flags.
- `amber_kris` (numeric): The number of amber flags.
}
\description{
`r lifecycle::badge("stable")`
}
\keyword{internal}

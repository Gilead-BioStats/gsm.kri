# Summarize Cross-Study Risk Scores

\`r lifecycle::badge("experimental")\`

Creates a summary table showing cross-study metrics for each site,
including number of studies, average risk scores, and aggregated flag
counts.

## Usage

``` r
SummarizeCrossStudy(
  dfResults,
  strGroupLevel = "Site",
  dfGroups = NULL,
  strNameCol = "InvestigatorLastName"
)
```

## Arguments

- dfResults:

  \`data.frame\` A data frame containing results from multiple studies.

- strGroupLevel:

  \`character\` The group level to summarize. Default is 'Site'.

- dfGroups:

  \`data.frame\` Optional. A data frame containing group metadata (for
  InvestigatorName lookup).

- strNameCol:

  \`character\` The column name in dfGroups to use for investigator
  names. Default is 'InvestigatorLastName'.

## Value

\`data.frame\` Summary table with cross-study metrics per site,
including per-study details.

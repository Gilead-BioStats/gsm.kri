# Generate a Summary data.frame for use in reports

\`r lifecycle::badge("stable")\`

Generate a summary table for a report by joining the provided results
data frame with the site-level metadata from dfGroups, and filter and
arrange the data based on provided conditions.

## Usage

``` r
MakeMetricTable(
  dfResults,
  dfGroups = NULL,
  strGroupLevel = c("Site", "Country", "Study"),
  strGroupDetailsParams = NULL,
  vFlags = c(-2, -1, 1, 2)
)
```

## Arguments

- dfResults:

  \`r gloss_param("dfResults")\` \`r gloss_extra("dfResults_filtered")\`

- dfGroups:

  \`data.frame\` Group-level metadata dictionary. Created by passing
  CTMS site and study data to \[MakeLongMeta()\]. Expected columns:
  \`GroupID\`, \`GroupLevel\`, \`Param\`, \`Value\`.

- strGroupLevel:

  group level for the table

- strGroupDetailsParams:

  one or more parameters from dfGroups to be added as columns in the
  table

- vFlags:

  \`integer\` List of flag values to include in output table. Default:
  \`c(-2, -1, 1, 2)\`.

## Value

A data.frame containing the summary table

## Examples

``` r
# site-level report
MakeMetricTable(
  dfResults = gsm.core::reportingResults %>%
    dplyr::filter(.data$MetricID == "Analysis_kri0001") %>%
    FilterByLatestSnapshotDate(),
  dfGroups = gsm.core::reportingGroups
)
#>           StudyID GroupID         MetricID          Group SnapshotDate Enrolled
#> 1  AA-AA-000-0000  0X7749 Analysis_kri0001  0X7749 (Deer)   2025-04-01        3
#> 2  AA-AA-000-0000  0X1996 Analysis_kri0001 0X1996 (Smith)   2025-04-01        7
#> 3  AA-AA-000-0000  0X7289 Analysis_kri0001 0X7289 (Smith)   2025-04-01        6
#> 4  AA-AA-000-0000  0X1982 Analysis_kri0001 0X1982 (Smith)   2025-04-01       11
#> 5  AA-AA-000-0000  0X4485 Analysis_kri0001   0X4485 (Doe)   2025-04-01       11
#> 6  AA-AA-000-0000  0X5458 Analysis_kri0001  0X5458 (Deer)   2025-04-01        4
#> 7  AA-AA-000-0000  0X7106 Analysis_kri0001 0X7106 (Smith)   2025-04-01        2
#> 8  AA-AA-000-0000  0X4415 Analysis_kri0001 0X4415 (Smith)   2025-04-01        7
#> 9  AA-AA-000-0000  0X8713 Analysis_kri0001   0X8713 (Doe)   2025-04-01       11
#> 10 AA-AA-000-0000  0X6403 Analysis_kri0001   0X6403 (Doe)   2025-04-01        6
#> 11 AA-AA-000-0000  0X7753 Analysis_kri0001   0X7753 (Doe)   2025-04-01        6
#> 12 AA-AA-000-0000  0X5967 Analysis_kri0001 0X5967 (Smith)   2025-04-01        7
#> 13 AA-AA-000-0000  0X6900 Analysis_kri0001  0X6900 (Deer)   2025-04-01        7
#> 14 AA-AA-000-0000   0X958 Analysis_kri0001   0X958 (Deer)   2025-04-01       11
#> 15 AA-AA-000-0000  0X3560 Analysis_kri0001   0X3560 (Doe)   2025-04-01        2
#> 16 AA-AA-000-0000  0X6954 Analysis_kri0001 0X6954 (Smith)   2025-04-01        4
#> 17 AA-AA-000-0000  0X8351 Analysis_kri0001  0X8351 (Deer)   2025-04-01        6
#>    Numerator Denominator Metric Score Flag
#> 1         10          48   0.21  2.19    1
#> 2         14          79   0.18  2.10    1
#> 3         18         111   0.16  2.08    1
#> 4         25         465   0.05 -1.73   -1
#> 5         28         502   0.06 -1.68   -1
#> 6          5         150   0.03 -1.63   -1
#> 7          0          47   0.00 -1.50   -1
#> 8         13         259   0.05 -1.44   -1
#> 9         17         310   0.05 -1.37   -1
#> 10        12         229   0.05 -1.27   -1
#> 11         8         169   0.05 -1.26   -1
#> 12        13         237   0.05 -1.19   -1
#> 13        19         311   0.06 -1.09   -1
#> 14        29         444   0.07 -1.07   -1
#> 15         3          77   0.04 -1.04   -1
#> 16         2          59   0.03 -1.01   -1
#> 17        25         384   0.07 -1.00   -1
```

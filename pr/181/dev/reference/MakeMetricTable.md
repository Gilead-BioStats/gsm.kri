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
#> 1  AA-AA-000-0000  0X3601 Analysis_kri0001   0X3601 (Doe)   2025-04-01        5
#> 2  AA-AA-000-0000  0X6603 Analysis_kri0001 0X6603 (Smith)   2025-04-01        4
#> 3  AA-AA-000-0000  0X7514 Analysis_kri0001  0X7514 (Deer)   2025-04-01        5
#> 4  AA-AA-000-0000   0X101 Analysis_kri0001   0X101 (Deer)   2025-04-01        5
#> 5  AA-AA-000-0000  0X9346 Analysis_kri0001   0X9346 (Doe)   2025-04-01        9
#> 6  AA-AA-000-0000  0X4264 Analysis_kri0001  0X4264 (Deer)   2025-04-01        9
#> 7  AA-AA-000-0000  0X2005 Analysis_kri0001  0X2005 (Deer)   2025-04-01        5
#> 8  AA-AA-000-0000  0X1750 Analysis_kri0001 0X1750 (Smith)   2025-04-01        6
#> 9  AA-AA-000-0000  0X2901 Analysis_kri0001   0X2901 (Doe)   2025-04-01        5
#> 10 AA-AA-000-0000  0X6865 Analysis_kri0001 0X6865 (Smith)   2025-04-01        3
#> 11 AA-AA-000-0000  0X4485 Analysis_kri0001   0X4485 (Doe)   2025-04-01       11
#> 12 AA-AA-000-0000   0X958 Analysis_kri0001   0X958 (Deer)   2025-04-01        5
#> 13 AA-AA-000-0000   0X554 Analysis_kri0001   0X554 (Deer)   2025-04-01        3
#> 14 AA-AA-000-0000  0X8764 Analysis_kri0001 0X8764 (Smith)   2025-04-01        3
#> 15 AA-AA-000-0000   0X213 Analysis_kri0001  0X213 (Smith)   2025-04-01       10
#> 16 AA-AA-000-0000  0X3973 Analysis_kri0001   0X3973 (Doe)   2025-04-01        6
#> 17 AA-AA-000-0000  0X9569 Analysis_kri0001   0X9569 (Doe)   2025-04-01        4
#> 18 AA-AA-000-0000  0X4629 Analysis_kri0001   0X4629 (Doe)   2025-04-01        6
#> 19 AA-AA-000-0000  0X2970 Analysis_kri0001  0X2970 (Deer)   2025-04-01        7
#> 20 AA-AA-000-0000  0X9737 Analysis_kri0001   0X9737 (Doe)   2025-04-01        7
#> 21 AA-AA-000-0000   0X187 Analysis_kri0001  0X187 (Smith)   2025-04-01        6
#> 22 AA-AA-000-0000  0X8274 Analysis_kri0001 0X8274 (Smith)   2025-04-01        4
#>    Numerator Denominator Metric Score Flag
#> 1         11          51   0.22  2.74    1
#> 2         31         236   0.13  2.14    1
#> 3         18         120   0.15  2.12    1
#> 4         25         183   0.14  2.09    1
#> 5         21         422   0.05 -1.97   -1
#> 6         17         339   0.05 -1.75   -1
#> 7          2          89   0.02 -1.65   -1
#> 8         13         267   0.05 -1.62   -1
#> 9         10         216   0.05 -1.56   -1
#> 10         1          64   0.02 -1.56   -1
#> 11        33         537   0.06 -1.44   -1
#> 12        15         280   0.05 -1.42   -1
#> 13         4         110   0.04 -1.41   -1
#> 14         7         154   0.05 -1.35   -1
#> 15        46         689   0.07 -1.23   -1
#> 16         9         173   0.05 -1.18   -1
#> 17         3          80   0.04 -1.18   -1
#> 18        24         381   0.06 -1.13   -1
#> 19        12         213   0.06 -1.12   -1
#> 20        26         404   0.06 -1.08   -1
#> 21         8         151   0.05 -1.07   -1
#> 22         1          40   0.03 -1.06   -1
```

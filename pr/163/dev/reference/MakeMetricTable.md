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
#> 1  AA-AA-000-0000  0X7983 Analysis_kri0001 0X7983 (Smith)   2025-04-01        4
#> 2  AA-AA-000-0000   0X213 Analysis_kri0001  0X213 (Smith)   2025-04-01       15
#> 3  AA-AA-000-0000  0X9580 Analysis_kri0001  0X9580 (Deer)   2025-04-01        5
#> 4  AA-AA-000-0000  0X4323 Analysis_kri0001 0X4323 (Smith)   2025-04-01       12
#> 5  AA-AA-000-0000  0X1137 Analysis_kri0001  0X1137 (Deer)   2025-04-01        5
#> 6  AA-AA-000-0000  0X5048 Analysis_kri0001 0X5048 (Smith)   2025-04-01        2
#> 7  AA-AA-000-0000  0X2865 Analysis_kri0001 0X2865 (Smith)   2025-04-01        2
#> 8  AA-AA-000-0000  0X3989 Analysis_kri0001 0X3989 (Smith)   2025-04-01        5
#> 9  AA-AA-000-0000  0X4707 Analysis_kri0001  0X4707 (Deer)   2025-04-01        3
#> 10 AA-AA-000-0000  0X9520 Analysis_kri0001   0X9520 (Doe)   2025-04-01        4
#> 11 AA-AA-000-0000  0X4959 Analysis_kri0001   0X4959 (Doe)   2025-04-01        6
#> 12 AA-AA-000-0000  0X8786 Analysis_kri0001  0X8786 (Deer)   2025-04-01        7
#> 13 AA-AA-000-0000   0X958 Analysis_kri0001   0X958 (Deer)   2025-04-01        7
#> 14 AA-AA-000-0000  0X5362 Analysis_kri0001   0X5362 (Doe)   2025-04-01        5
#> 15 AA-AA-000-0000  0X6405 Analysis_kri0001   0X6405 (Doe)   2025-04-01       10
#> 16 AA-AA-000-0000  0X2123 Analysis_kri0001  0X2123 (Deer)   2025-04-01        3
#> 17 AA-AA-000-0000  0X4264 Analysis_kri0001  0X4264 (Deer)   2025-04-01        7
#> 18 AA-AA-000-0000  0X2513 Analysis_kri0001  0X2513 (Deer)   2025-04-01        2
#> 19 AA-AA-000-0000  0X4629 Analysis_kri0001   0X4629 (Doe)   2025-04-01        8
#> 20 AA-AA-000-0000  0X7228 Analysis_kri0001 0X7228 (Smith)   2025-04-01        7
#> 21 AA-AA-000-0000  0X3574 Analysis_kri0001   0X3574 (Doe)   2025-04-01        4
#> 22 AA-AA-000-0000  0X5137 Analysis_kri0001 0X5137 (Smith)   2025-04-01        2
#> 23 AA-AA-000-0000  0X9834 Analysis_kri0001  0X9834 (Deer)   2025-04-01        5
#> 24 AA-AA-000-0000  0X6301 Analysis_kri0001   0X6301 (Doe)   2025-04-01        3
#>    Numerator Denominator Metric Score Flag
#> 1         31         243   0.13  2.24    1
#> 2         80         742   0.11  2.22    1
#> 3         30         238   0.13  2.14    1
#> 4         39         675   0.06 -1.99   -1
#> 5          8         196   0.04 -1.82   -1
#> 6          0          42   0.00 -1.68   -1
#> 7          2          71   0.03 -1.43   -1
#> 8          7         150   0.05 -1.37   -1
#> 9          4          97   0.04 -1.27   -1
#> 10         4          97   0.04 -1.27   -1
#> 11        18         304   0.06 -1.26   -1
#> 12        25         401   0.06 -1.25   -1
#> 13        19         316   0.06 -1.23   -1
#> 14         5         110   0.05 -1.21   -1
#> 15        34         521   0.07 -1.21   -1
#> 16         7         140   0.05 -1.20   -1
#> 17        23         369   0.06 -1.20   -1
#> 18         1          41   0.02 -1.17   -1
#> 19        28         435   0.06 -1.17   -1
#> 20        13         225   0.06 -1.15   -1
#> 21         9         166   0.05 -1.13   -1
#> 22         1          39   0.03 -1.11   -1
#> 23         8         149   0.05 -1.09   -1
#> 24         4          86   0.05 -1.04   -1
```

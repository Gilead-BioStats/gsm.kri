# Generate a study information data.frame for use in reports

\`r lifecycle::badge("stable")\`

Generate a study info table summarizing study metadata.

## Usage

``` r
MakeStudyInfo(dfGroups, lStudyLabels = NULL, lStudy = deprecated())
```

## Arguments

- dfGroups:

  \`data.frame\` Group-level metadata dictionary. Created by passing
  CTMS site and study data to \[MakeLongMeta()\]. Expected columns:
  \`GroupID\`, \`GroupLevel\`, \`Param\`, \`Value\`.

- lStudyLabels:

  \`list\` A list containing study labels. Default is NULL.

- lStudy:

  \`deprecated\` Study information as a named list.

## Value

A data.frame containing study metadata.

## Examples

``` r
MakeStudyInfo(gsm.core::reportingGroups)
#>                          Param              Value                   Description
#> 1                      studyid     AA-AA-000-0000                       Studyid
#> 2                     nickname             OAK-38                      Nickname
#> 3               protocol_title   Protocol Title P                Protocol Title
#> 4                       status             Active                        Status
#> 5                num_plan_site                150                 Num Plan Site
#> 6                num_plan_subj               1000                 Num Plan Subj
#> 7                     act_fpfv         2012-01-02                      Act Fpfv
#> 8                     est_fpfv         2012-01-07                      Est Fpfv
#> 9                     est_lplv         2012-07-24                      Est Lplv
#> 10                    est_lpfv         2012-03-26                      Est Lpfv
#> 11            therapeutic_area           Virology              Therapeutic Area
#> 12         protocol_indication         Hematology           Protocol Indication
#> 13                       phase                 P2                         Phase
#> 14                     product    Product Name 14                       Product
#> 15                  SiteTarget                150                   Site Target
#> 16           ParticipantTarget               1000            Participant Target
#> 17            ParticipantCount                764         Participants Enrolled
#> 18                   SiteCount                145                Sites Enrolled
#> 19       PercentSitesActivated               96.7       Percent Sites Activated
#> 20              SiteActivation  145 / 150 (96.7%)               Site Activation
#> 21 PercentParticipantsEnrolled               76.4 Percent Participants Enrolled
#> 22       ParticipantEnrollment 764 / 1000 (76.4%)        Participant Enrollment
MakeStudyInfo(gsm.core::reportingGroups, list(SiteCount = "# Sites"))
#>                          Param              Value                   Description
#> 1                      studyid     AA-AA-000-0000                       Studyid
#> 2                     nickname             OAK-38                      Nickname
#> 3               protocol_title   Protocol Title P                Protocol Title
#> 4                       status             Active                        Status
#> 5                num_plan_site                150                 Num Plan Site
#> 6                num_plan_subj               1000                 Num Plan Subj
#> 7                     act_fpfv         2012-01-02                      Act Fpfv
#> 8                     est_fpfv         2012-01-07                      Est Fpfv
#> 9                     est_lplv         2012-07-24                      Est Lplv
#> 10                    est_lpfv         2012-03-26                      Est Lpfv
#> 11            therapeutic_area           Virology              Therapeutic Area
#> 12         protocol_indication         Hematology           Protocol Indication
#> 13                       phase                 P2                         Phase
#> 14                     product    Product Name 14                       Product
#> 15                  SiteTarget                150                   Site Target
#> 16           ParticipantTarget               1000            Participant Target
#> 17            ParticipantCount                764             Participant Count
#> 18                   SiteCount                145                       # Sites
#> 19       PercentSitesActivated               96.7       Percent Sites Activated
#> 20              SiteActivation  145 / 150 (96.7%)               Site Activation
#> 21 PercentParticipantsEnrolled               76.4 Percent Participants Enrolled
#> 22       ParticipantEnrollment 764 / 1000 (76.4%)        Participant Enrollment
```

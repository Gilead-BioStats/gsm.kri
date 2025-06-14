library(gsm.core)
library(gsm.mapping)
library(yaml)
devtools::load_all()
#### Example 2.1 - Configurable Adverse Event Workflow

# Define YAML workflow
AE_workflow <- yaml::read_yaml(text=
'meta:
  Type: Analysis
  ID: kri0001
  GroupLevel: Site
  Abbreviation: AE
  Metric: Adverse Event Rate
  Numerator: Adverse Events
  Denominator: Days on Study
  Model: Normal Approximation
  Score: Adjusted Z-Score
  AnalysisType: rate
  Threshold: -2,-1,2,3
  AccrualThreshold: 30
  AccrualMetric: Denominator
spec:
  Mapped_AE:
    subjid:
      type: character
  Mapped_SUBJ:
    subjid:
      type: character
    invid:
      type: character
    timeonstudy:
      type: integer
steps:
  - output: vThreshold
    name: ParseThreshold
    params:
      strThreshold: Threshold
  - output: Analysis_Input
    name: Input_Rate
    params:
      dfSubjects: Mapped_SUBJ
      dfNumerator: Mapped_AE
      dfDenominator: Mapped_SUBJ
      strSubjectCol: subjid
      strGroupCol: invid
      strGroupLevel: GroupLevel
      strNumeratorMethod: Count
      strDenominatorMethod: Sum
      strDenominatorCol: timeonstudy
  - output: Analysis_Transformed
    name: Transform_Rate
    params:
      dfInput: Analysis_Input
  - output: Analysis_Analyzed
    name: Analyze_NormalApprox
    params:
      dfTransformed: Analysis_Transformed
      strType: AnalysisType
  - output: Analysis_Flagged
    name: Flag
    params:
      dfAnalyzed: Analysis_Analyzed
      vThreshold: vThreshold
      nAccrualThreshold: AccrualThreshold
      strAccrualMetric: AccrualMetric
  - output: Analysis_Summary
    name: Summarize
    params:
      dfFlagged: Analysis_Flagged
  - output: lAnalysis
    name: list
    params:
      ID: ID
      Analysis_Input: Analysis_Input
      Analysis_Transformed: Analysis_Transformed
      Analysis_Analyzed: Analysis_Analyzed
      Analysis_Flagged: Analysis_Flagged
      Analysis_Summary: Analysis_Summary
')

# Grab simulated data
dm <- gsm.core::lSource$Raw_SUBJ
ae <- gsm.core::lSource$Raw_AE

# Run the workflow
AE_data <-list(
  Mapped_SUBJ= dm,
  Mapped_AE= ae
)
AE_KRI <- RunWorkflow(lWorkflow = AE_workflow, lData = AE_data)

# Create Barchart from workflow
Widget_BarChart(dfResults = AE_KRI$Analysis_Summary)

# Visualize Metric distribution using Bar Charts and Scatterplots using provided htmlwidgets
labels <- list(
  Metric= "Adverse Event Rate",
  Numerator= "Adverse Events",
  Denominator= "Days on Study"
)

Widget_BarChart(dfResults = AE_KRI, lMetric=labels, strOutcome="Metric")
Widget_BarChart(dfResults = AE_KRI, lMetric=labels, strOutcome="Score")
Widget_BarChart(dfResults = AE_KRI, lMetric=labels, strOutcome="Numerator")

dfBounds <- Analyze_NormalApprox_PredictBounds(AE_KRI, vThreshold = c(-3,-2,2,3))
Widget_ScatterPlot(AE_KRI, lMetric = labels, dfBounds = dfBounds)


#### Example 2.2 - Run Country-Level Metric
AE_country_workflow <- AE_workflow
AE_country_workflow$meta$GroupLevel <- "Country"
AE_country_workflow$steps[[2]]$params$strGroupCol <- "country"

AE_country_KRI <- RunWorkflow(lWorkflow = AE_country_workflow, lData = AE_data)
Widget_BarChart(dfResults = AE_country_KRI$Analysis_Summary, lMetric = AE_country_workflow$meta)

#### Example 2.3 - Create SAE workflow

# Tweak AE workflow metadata
SAE_workflow <- AE_workflow
SAE_workflow$meta$File <- "SAE_KRI"
SAE_workflow$meta$Metric <- "Serious Adverse Event Rate"
SAE_workflow$meta$Numerator <- "Serious Adverse Events"

# Add a step to filter out non-serious AEs `RunQuery`
filterStep <- list(list(
  name = "RunQuery",
  output = "Mapped_AE",
  params= list(
    df= "Mapped_AE",
    strQuery = "SELECT * FROM df WHERE aeser = 'Y'"
  ))
)
SAE_workflow$steps <- SAE_workflow$steps %>% append(filterStep, after=0)

# Run the updated workflow and visualize
SAE_KRI <- RunWorkflow(lWorkflow = SAE_workflow, lData = AE_data)
Widget_BarChart(dfResults = SAE_KRI$Analysis_Summary, lMetric = SAE_workflow$meta)




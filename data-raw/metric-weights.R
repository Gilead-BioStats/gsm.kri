# read in metric-weights.csv and store as package data
metricWeights <- 'data-raw/metric-weights.csv' %>%
  read.csv(na.strings="NA") %>%
  group_by(MetricID) %>%
  mutate(
    WeightMax = max(Weight)
  )

usethis::use_data(
  metricWeights,
  overwrite = TRUE
)

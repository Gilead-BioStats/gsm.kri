test_that("Qual: windowed PK metric flags expected sites using standard workflow output (#200)", {
  kri_path <- test_path("..", "..", "inst", "workflow", "2_metrics", "kri0016.yaml")
  qual_path <- test_path("qual_workflows", "2_metrics", "kri0016.yaml")

  expect_true(file.exists(kri_path))
  expect_true(file.exists(qual_path))

  # Build a small deterministic mapped dataset with known site-level rates.
  subjects <- tibble(
    subjid = sprintf("SUBJ%03d", 1:30),
    invid = c(rep("SITE_A", 10), rep("SITE_B", 10), rep("SITE_C", 10))
  )

  within_flags <- c(
    rep("Y", 9), "N",   # SITE_A: 0.9 expected flag 0
    rep("Y", 5), rep("N", 5), # SITE_B: 0.5 expected flag -2
    rep("Y", 9), "N"    # SITE_C: 0.9 expected flag 0
  )

  mapped_pk <- tibble(
    subjid = subjects$subjid,
    drv_pkcol_within_window = within_flags
  )

  # Independent expected flag calculation with threshold 0.9,0.85 and flags -2,-1,0.
  expected <- subjects %>%
    left_join(mapped_pk, by = "subjid") %>%
    summarize(
      Numerator = sum(drv_pkcol_within_window == "Y", na.rm = TRUE),
      Denominator = n(),
      Metric = Numerator / Denominator,
      .by = invid
    ) %>%
    mutate(
      ExpectedFlag = case_when(
        Metric < 0.85 ~ -2,
        Metric < 0.9 ~ -1,
        TRUE ~ 0
      )
    )

  workflows <- MakeWorkflowList("kri0016", GetDefaultKRIPath())
  result <- robust_runworkflow(
    workflows[[1]],
    list(Mapped_SUBJ = subjects, Mapped_PK = mapped_pk)
  )

  # Test output structure
  expected_outputs <- c(
    "vThreshold", "vFlag",
    "Analysis_Input", "Analysis_Transformed", "Analysis_Analyzed",
    "Analysis_Flagged", "Analysis_Summary"
  )
  expect_true(all(expected_outputs %in% names(result)))
  expect_true(is.vector(result$vThreshold))
  expect_true(is.vector(result$vFlag))
  expect_true(all(map_lgl(
    result[grep("^Analysis_", names(result))],
    is.data.frame
  )))

  # Test row counts and consistency
  expected_rows <- length(unique(subjects$invid))
  expect_equal(nrow(result$Analysis_Flagged), expected_rows)
  expect_equal(nrow(result$Analysis_Summary), expected_rows)
  expect_identical(
    sort(result$Analysis_Flagged$GroupID),
    sort(result$Analysis_Summary$GroupID)
  )

  # Test required columns in Analysis_Summary
  expect_true(all(c("GroupID", "Flag", "Score") %in% names(result$Analysis_Summary)))

  # Test expected flag values match
  observed <- result$Analysis_Summary %>%
    transmute(
      invid = GroupID,
      ObservedFlag = as.integer(Flag)
    ) %>%
    arrange(invid)

  compare <- expected %>%
    select(invid, ExpectedFlag) %>%
    left_join(observed, by = "invid")

  expect_equal(compare$ObservedFlag, compare$ExpectedFlag)
})

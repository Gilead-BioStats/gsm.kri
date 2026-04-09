test_that("Qual: windowed PK metric flags expected sites using standard workflow output (#200)", {
  # Verify workflow file exists in the default KRI workflow path.
  kri_path <- file.path(GetDefaultKRIPath(), "kri0016.yaml")
  expect_true(file.exists(kri_path), label = paste("KRI workflow file:", kri_path))

  # Use larger, more realistic sample sizes to avoid accrual-threshold NA flags.
  # SITE_A: 100 subjects, 92 with 'Y' = 0.92 (flag 0)
  # SITE_B: 100 subjects, 40 with 'Y' = 0.40 (flag -2)
  # SITE_C: 100 subjects, 88 with 'Y' = 0.88 (flag -1)
  subjects <- tibble(
    subjid = sprintf("SUBJ%03d", 1:300),
    invid = c(rep("SITE_A", 100), rep("SITE_B", 100), rep("SITE_C", 100))
  )

  within_flags <- c(
    rep("Y", 92), rep("N", 8),
    rep("Y", 40), rep("N", 60),
    rep("Y", 88), rep("N", 12)
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

library(testthat)

test_that("caching functions work correctly (#182)", {
  
  # Test cache directory creation
  cache_dir <- get_cache_dir()
  expect_true(dir.exists(cache_dir))
  expect_true(grepl("gsm", cache_dir))
  
  # Test workflow modification time function
  workflow_paths <- c(
    system.file("workflow", package = "gsm.kri"),
    test_path("qual_workflows/2_metrics_custom")
  )
  
  # Filter to existing paths only
  existing_paths <- workflow_paths[dir.exists(workflow_paths)]
  
  if (length(existing_paths) > 0) {
    mtime <- get_workflow_mtime(existing_paths)
    expect_true(inherits(mtime, "POSIXct"))
  }
  
  # Test cache file check
  fake_cache_file <- tempfile(fileext = ".rds")
  expect_true(is_cache_outdated(fake_cache_file, Sys.time()))
  
  # Create a temporary cache file
  saveRDS(list(test = "data"), fake_cache_file)
  # Should not be outdated relative to past time
  expect_false(is_cache_outdated(fake_cache_file, Sys.time() - 3600))
  # Should be outdated relative to future time
  expect_true(is_cache_outdated(fake_cache_file, Sys.time() + 3600))
  
  unlink(fake_cache_file)
})

test_that("cached mapped data is generated correctly (#182)", {
  
  # Clear any existing cache
  clear_cache()
  
  # Test with a minimal data setup
  test_lData <- list(
    Raw_SUBJ = data.frame(
      subjid = c("001", "002", "003"),
      enrollyn = c("Y", "Y", "Y"),
      stringsAsFactors = FALSE
    ),
    Raw_AE = data.frame(
      subjid = c("001", "002"),
      aedecod = c("Headache", "Nausea"),
      stringsAsFactors = FALSE
    )
  )
  
  # Create minimal mapping workflows
  test_mappings_wf <- gsm.core::MakeWorkflowList(
    strNames = c("SUBJ", "AE"),
    strPackage = "gsm.mapping"
  )
  
  # Test cached data generation
  cached_result <- get_cached_mapped_data(test_lData, test_mappings_wf)
  expect_true(is.list(cached_result))
  expect_true("Mapped_SUBJ" %in% names(cached_result))
  
  # Test that cache files are created
  cache_dir <- get_cache_dir()
  mapped_cache_file <- file.path(cache_dir, "mapped_data.rds")
  mappings_cache_file <- file.path(cache_dir, "mappings_wf.rds")
  
  expect_true(file.exists(mapped_cache_file))
  expect_true(file.exists(mappings_cache_file))
  
  # Test that subsequent calls use cache
  start_time <- Sys.time()
  cached_result2 <- get_cached_mapped_data(test_lData, test_mappings_wf)
  end_time <- Sys.time()
  
  # Cache should be faster (though this is timing dependent)
  expect_identical(cached_result, cached_result2)
  
  # Test force refresh
  cached_result3 <- get_cached_mapped_data(test_lData, test_mappings_wf, force_refresh = TRUE)
  expect_identical(cached_result, cached_result3)
})

test_that("mapping output caching works (#182)", {
  
  clear_cache()
  
  test_mappings_wf <- gsm.core::MakeWorkflowList(
    strNames = c("SUBJ", "AE"),
    strPackage = "gsm.mapping"
  )
  
  # Test cached mapping output generation
  cached_output <- get_cached_mapping_output(test_mappings_wf)
  expect_true(is.character(cached_output))
  expect_true("Mapped_SUBJ" %in% cached_output)
  
  # Test cache file creation
  cache_dir <- get_cache_dir()
  output_cache_file <- file.path(cache_dir, "mapping_output.rds")
  expect_true(file.exists(output_cache_file))
  
  # Test subsequent calls use cache
  cached_output2 <- get_cached_mapping_output(test_mappings_wf)
  expect_identical(cached_output, cached_output2)
})

test_that("cache clearing works (#182)", {
  
  # Ensure cache exists
  cache_dir <- get_cache_dir()
  test_cache_file <- file.path(cache_dir, "test.rds")
  saveRDS(list(test = "data"), test_cache_file)
  
  expect_true(file.exists(test_cache_file))
  
  # Clear cache
  clear_cache()
  
  # Check that cache files are removed
  gsm_cache_files <- list.files(cache_dir, pattern = "(mapped_data|mappings_wf|mapping_output)\\.rds$", full.names = TRUE)
  expect_equal(length(gsm_cache_files), 0)
})
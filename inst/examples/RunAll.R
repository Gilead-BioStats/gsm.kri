#!/usr/bin/env Rscript

#' Run All RMD Examples
#'
#' This script renders all .Rmd files in the gsm.kri/inst/examples directory
#' and saves the outputs to the ./output subdirectory.
#'
#' @examples
#' # Run from the command line:
#' # Rscript RunAll.R
#'
#' # Or source from R:
#' # source("RunAll.R")

# Load required packages
if (!require("rmarkdown")) {
  stop("Package 'rmarkdown' is required. Please install it with: install.packages('rmarkdown')")
}

# Get the directory where this script is located
script_dir <- if (interactive()) {
  getwd()
} else {
  # Get script path from command line args
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    dirname(normalizePath(sub("^--file=", "", file_arg)))
  } else {
    getwd()
  }
}

# Define paths
examples_dir <- script_dir
output_dir <- file.path(examples_dir, "output")

# Create output directory if it doesn't exist
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
  cat("Created output directory:", output_dir, "\n")
}

# Find all .Rmd files in the examples directory
rmd_files <- list.files(
  path = examples_dir,
  pattern = "\\.Rmd$",
  full.names = TRUE,
  recursive = FALSE
)

if (length(rmd_files) == 0) {
  cat("No .Rmd files found in", examples_dir, "\n")
  quit(status = 0)
}

cat("\nFound", length(rmd_files), ".Rmd file(s) to render:\n")
cat(paste0("  - ", basename(rmd_files), "\n"), sep = "")

# Initialize results tracking
results <- data.frame(
  file = basename(rmd_files),
  status = character(length(rmd_files)),
  output = character(length(rmd_files)),
  stringsAsFactors = FALSE
)

# Render each .Rmd file
cat("\n========================================\n")
cat("Starting rendering process...\n")
cat("========================================\n\n")

for (i in seq_along(rmd_files)) {
  rmd_file <- rmd_files[i]
  file_name <- basename(rmd_file)
  
  cat(sprintf("[%d/%d] Rendering: %s\n", i, length(rmd_files), file_name))
  
  # Define output file name (html by default)
  output_file <- file.path(output_dir, gsub("\\.Rmd$", ".html", file_name))
  
  # Try to render the file
  tryCatch({
    rmarkdown::render(
      input = rmd_file,
      output_file = basename(output_file),
      output_dir = output_dir,
      quiet = FALSE,
      envir = new.env()
    )
    
    results$status[i] <- "SUCCESS"
    results$output[i] <- output_file
    cat(sprintf("  ✓ Successfully rendered to: %s\n\n", output_file))
    
  }, error = function(e) {
    results$status[i] <- "FAILED"
    results$output[i] <- NA
    cat(sprintf("  ✗ Failed to render: %s\n", e$message))
    cat("\n")
  })
}

# Print summary
cat("\n========================================\n")
cat("Rendering Summary\n")
cat("========================================\n")

success_count <- sum(results$status == "SUCCESS")
failed_count <- sum(results$status == "FAILED")

cat(sprintf("Total files: %d\n", nrow(results)))
cat(sprintf("Successful: %d\n", success_count))
cat(sprintf("Failed: %d\n", failed_count))

if (failed_count > 0) {
  cat("\nFailed files:\n")
  failed_files <- results$file[results$status == "FAILED"]
  cat(paste0("  - ", failed_files, "\n"), sep = "")
}

cat("\nOutput directory:", output_dir, "\n")

# Return results invisibly
invisible(results)

#!/usr/bin/env Rscript

#' Run All Examples
#'
#' This script renders all example files to the output directory.
#' Run from the gsm.kri package root directory.

# Render each RMD file
rmarkdown::render("inst/examples/Cookbook_AdverseEventKRI.Rmd", output_dir = "inst/examples/output")
rmarkdown::render("inst/examples/Cookbook_AdverseEventWorkflow.Rmd", output_dir = "inst/examples/output")
rmarkdown::render("inst/examples/Cookbook_ReportingWorkflow.Rmd", output_dir = "inst/examples/output")
rmarkdown::render("inst/examples/Example_CrossStudySRS.Rmd", output_dir = "inst/examples/output")
source('inst/examples/Example_Eligibility.R')

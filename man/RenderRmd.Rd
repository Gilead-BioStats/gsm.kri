% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/util-RenderRmd.R
\name{RenderRmd}
\alias{RenderRmd}
\title{Custom Rmarkdown render function}
\usage{
RenderRmd(
  strInputPath,
  strOutputFile = basename(strInputPath),
  strOutputDir = getwd(),
  lParams
)
}
\arguments{
\item{strInputPath}{`string` or `fs_path` Path to the template `Rmd` file.}

\item{strOutputFile}{`string` Filename for the output.}

\item{strOutputDir}{`string` or `fs_path` Path to the directory where the output will be saved.}

\item{lParams}{`list` Parameters to pass to the template `Rmd` file.}
}
\value{
Rendered Rmarkdown file
}
\description{
Rmarkdown render function that defaults to rendering intermediate rmd files in a temporary directory
}

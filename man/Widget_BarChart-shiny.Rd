% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Widget_BarChart.R
\name{Widget_BarChart-shiny}
\alias{Widget_BarChart-shiny}
\alias{Widget_BarChartOutput}
\alias{renderWidget_BarChart}
\title{Shiny bindings for Widget_BarChart}
\usage{
Widget_BarChartOutput(outputId, width = "100\%", height = "400px")

renderWidget_BarChart(expr, env = parent.frame(), quoted = FALSE)
}
\arguments{
\item{outputId}{output variable to read from}

\item{width, height}{Must be a valid CSS unit (like \code{'100\%'},
\code{'400px'}, \code{'auto'}) or a number, which will be coerced to a
string and have \code{'px'} appended.}

\item{expr}{An expression that generates a Widget_BarChart}

\item{env}{The environment in which to evaluate \code{expr}.}

\item{quoted}{Is \code{expr} a quoted expression (with \code{quote()})? This
is useful if you want to save an expression in a variable.}
}
\description{
`r lifecycle::badge("stable")`

Output and render functions for using Widget_BarChart within Shiny
applications and interactive Rmd documents.
}

#' @importFrom utils globalVariables

NULL

globalVariables(c("."))

# Default logger object
# Initialize a default logger at package load
.onLoad <- function(libname, pkgname) {
  logger <- logger("DEBUG", appenders = console_appender(layout = gsm::cli_fmt))
  gsm::SetLogger(logger)
}

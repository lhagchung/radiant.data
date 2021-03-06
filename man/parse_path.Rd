% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/radiant.R
\name{parse_path}
\alias{parse_path}
\title{Parse file path into useful components}
\usage{
parse_path(path, chr = "", pdir = getwd())
}
\arguments{
\item{path}{Path to be parsed}

\item{chr}{Character to wrap around path for display}

\item{pdir}{Project directory if available}
}
\description{
Parse file path into useful components
}
\details{
Parse file path into useful components (i.e., file name, file extension, relative path, etc.)
}
\examples{
list.files(".", full.names = TRUE)[1] \%>\% parse_path()
}

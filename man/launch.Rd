% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/radiant.R
\name{launch}
\alias{launch}
\title{Launch radiant apps}
\usage{
launch(package = "radiant.data", run = "viewer")
}
\arguments{
\item{package}{Radiant package to start. One of "radiant.data", "radiant.design", "radiant.basics", "radiant.model", "radiant.multivariate", or "radiant"}

\item{run}{Run a radiant app in an external browser ("browser"), an Rstudio window ("window"), or in the Rstudio viewer ("viewer")}
}
\description{
Launch radiant apps
}
\details{
See \url{https://radiant-rstats.github.io/docs} for radiant documentation and tutorials
}
\examples{
\dontrun{
launch()
launch(run = "viewer")
launch(run = "window")
launch(run = "browser")
}

}

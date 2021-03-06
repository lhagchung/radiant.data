% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/explore.R
\name{dtab.explore}
\alias{dtab.explore}
\title{Make a table of summary statistics in DT}
\usage{
\method{dtab}{explore}(object, dec = 3, searchCols = NULL, order = NULL,
  pageLength = NULL, ...)
}
\arguments{
\item{object}{Return value from \code{\link{explore}}}

\item{dec}{Number of decimals to show}

\item{searchCols}{Column search and filter}

\item{order}{Column sorting}

\item{pageLength}{Page length}

\item{...}{further arguments passed to or from other methods}
}
\description{
Make a table of summary statistics in DT
}
\details{
See \url{https://radiant-rstats.github.io/docs/data/explore.html} for an example in Radiant
}
\examples{
\dontrun{
tab <- explore(diamonds, "price:x") \%>\% dtab()
tab <- explore(diamonds, "price", byvar = "cut", fun = c("n_obs", "skew"), top = "byvar") \%>\%
  dtab()
}

}
\seealso{
\code{\link{pivotr}} to create a pivot table

\code{\link{summary.pivotr}} to show summaries
}

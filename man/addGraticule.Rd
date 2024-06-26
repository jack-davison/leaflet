% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plugin-graticule.R
\name{addGraticule}
\alias{addGraticule}
\title{Add a Graticule on the map}
\usage{
addGraticule(
  map,
  interval = 20,
  sphere = FALSE,
  style = list(color = "#333", weight = 1),
  layerId = NULL,
  group = NULL,
  options = pathOptions(pointerEvents = "none", clickable = FALSE)
)
}
\arguments{
\item{map}{a map widget object}

\item{interval}{The spacing in map units between horizontal and vertical lines.}

\item{sphere}{boolean. Default `FALSE`}

\item{style}{path options for the generated lines. See \url{https://web.archive.org/web/20220702182250/https://leafletjs.com/reference-1.3.4.html#path-option}}

\item{layerId}{the layer id}

\item{group}{the name of the group this layer belongs to.}

\item{options}{the path options for the graticule layer}
}
\description{
Add a Graticule on the map
}
\examples{
leaf <- leaflet() \%>\%
  addTiles() \%>\%
  addGraticule()
leaf

}
\seealso{
\url{https://github.com/turban/Leaflet.Graticule}
}

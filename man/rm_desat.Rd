% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/methods_dive.R
\name{rm_desat}
\alias{rm_desat}
\title{rm_desat}
\usage{
rm_desat(dive)
}
\arguments{
\item{dive}{\code{\link[DiveR]{dive}} object.}
}
\description{
Remove all desaturation stop.
}
\examples{
d1 <- dive(20, 40)
d2 <- rm_desat(d1)
plot(d1)
plot(d2, add = TRUE, col = "darkred")

# When there is other desat stops
d1 <- dive(39, 22)
d2 <- rm_desat(d1)
plot(d1)
plot(d2, add = TRUE, col = "darkred")

}
\author{
Jaunatre Maxime <maxime.jaunatre@yahoo.fr>
}

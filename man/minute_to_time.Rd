% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dive_utils.R
\name{minute_to_time}
\alias{minute_to_time}
\title{minute_to_time}
\usage{
minute_to_time(time, sec = TRUE, sep = c(":", "h"), day = TRUE)
}
\arguments{
\item{time}{positive numeric value in minute}

\item{sec}{add the sec part of the string.}

\item{sep}{':' by default, choice between ':' and 'h'. Only affect only the
first separator character}

\item{day}{TRUE by default, allow to set time in a day period (betwwen 00h00 
and 23:59)}
}
\value{
character string
}
\description{
Transform minute variable into a character string in hour format.
}
\examples{
minute_to_time(130.5, sec = TRUE)
minute_to_time(130.5, sec = FALSE)
minute_to_time(130.5, sec = TRUE, sep = 'h')
minute_to_time(130.5, sec = FALSE, sep = 'h')
minute_to_time(1440, sec = FALSE, sep = 'h')
minute_to_time(1664, sec = FALSE, sep = 'h')

}
\author{
Jaunatre Maxime <maxime.jaunatre@yahoo.fr>
}

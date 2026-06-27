#' Venezuela 2026 seismic sequence
#'
#' Earthquakes of magnitude 2.5 or greater within 200 km of the
#' 24 June 2026 Mw 7.5 mainshock near Yumare, Venezuela.
#' Downloaded on 27 June 2026 from the USGS Earthquake Catalog API.
#'
#' @format A data frame with columns:
#' \describe{
#'   \item{lon}{Longitude (degrees, WGS84)}
#'   \item{lat}{Latitude (degrees, WGS84)}
#'   \item{depth_km}{Depth in kilometres}
#'   \item{magnitude}{Moment magnitude}
#'   \item{time}{Event time (POSIXct, UTC)}
#' }
#' @source \url{https://earthquake.usgs.gov/fdsnws/event/1/}
"venezuela_2026"

#' Amatrice 2016 seismic sequence
#'
#' Earthquakes of magnitude 2.5 or greater within 100 km of the
#' 24 August 2016 Mw 6.2 mainshock near Amatrice, Italy.
#' The sequence includes a second major event of Mw 6.5 on
#' 30 October 2016. Downloaded from the USGS Earthquake Catalog API.
#'
#' @format A data frame with columns:
#' \describe{
#'   \item{lon}{Longitude (degrees, WGS84)}
#'   \item{lat}{Latitude (degrees, WGS84)}
#'   \item{depth_km}{Depth in kilometres}
#'   \item{magnitude}{Moment magnitude}
#'   \item{time}{Event time (POSIXct, UTC)}
#' }
#' @source \url{https://earthquake.usgs.gov/fdsnws/event/1/}
"amatrice_2016"

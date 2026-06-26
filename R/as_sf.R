#' Convert a spatio-temporal event pattern to an sf object
#'
#' Converts an `stevents` object to an `sf` point layer, making it
#' compatible with the broader `sf` ecosystem for visualisation,
#' spatial joins, and further analysis.
#'
#' @param x An `stevents` object.
#' @param ... Currently unused.
#'
#' @return An `sf` object with columns `time` and `n_recent_neighbors`
#'   (if present), and a `POINT` geometry column carrying the CRS of `x`.
#' @export
#'
#' @examples
#' set.seed(1)
#' ev <- stevents(
#'   x    = runif(50, 0, 100),
#'   y    = runif(50, 0, 100),
#'   time = as.POSIXct("2023-01-01") + runif(50, 0, 365 * 86400)
#' )
#' sf_ev <- as_sf(ev)
#' class(sf_ev)
as_sf <- function(x, ...) UseMethod("as_sf")

#' @export
as_sf.stevents <- function(x, ...) {
  sf::st_as_sf(
    x$data,
    coords = c("x", "y"),
    crs    = x$crs
  )
}

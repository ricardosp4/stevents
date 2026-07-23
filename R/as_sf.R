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

#' Convert a space-time tessellation to an sf object
#'
#' Extracts the spatial cells of an `stgrid` object as a standalone `sf`
#' polygon layer, making it compatible with the broader `sf` ecosystem for
#' visualisation, spatial joins, and further analysis. If `count_events()`
#' has already been run, the total event count per cell (summed across all
#' temporal bins) is attached as a column `n_events`.
#'
#' @param x An `stgrid` object.
#' @param ... Currently unused.
#'
#' @return An `sf` object with columns `cell_id` (and `n_events` if
#'   available), and a `POLYGON` geometry column carrying the CRS of `x`.
#' @export
#'
#' @examples
#' g <- stgrid(
#'   bbox      = c(0, 0, 100, 100),
#'   cell_size = 20,
#'   t_window  = as.POSIXct(c("2023-01-01", "2023-12-31")),
#'   t_step    = "1 month"
#' )
#' sf_g <- as_sf(g)
#' class(sf_g)
as_sf.stgrid <- function(x, ...) {
  cells <- x$cells

  if (!is.null(x$counts) && nrow(x$counts) > 0) {
    totals <- stats::aggregate(
      list(n_events = x$counts$n_events),
      by  = list(cell_id = x$counts$cell_id),
      FUN = sum
    )
    cells <- merge(cells, totals, by = "cell_id", all.x = TRUE)
    cells$n_events[is.na(cells$n_events)] <- 0L
    cells <- cells[order(cells$cell_id), ]
    rownames(cells) <- NULL
  }

  cells
}

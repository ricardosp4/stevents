#' Dimensions of a space-time tessellation
#'
#' Returns the size of the underlying space-time data cube: the number of
#' spatial cells and the number of temporal bins.
#'
#' @param x An `stgrid` object.
#'
#' @return An integer vector of length 2: `c(n_cells, n_bins)`.
#' @export
#'
#' @examples
#' g <- stgrid(
#'   bbox      = c(0, 0, 100, 100),
#'   cell_size = 20,
#'   t_window  = as.POSIXct(c("2023-01-01", "2023-12-31")),
#'   t_step    = "1 month"
#' )
#' dim(g)
dim.stgrid <- function(x) {
  c(n_cells = nrow(x$cells), n_bins = length(x$t_breaks) - 1L)
}

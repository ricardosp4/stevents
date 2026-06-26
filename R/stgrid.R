#' Create a space-time tessellation
#'
#' Constructs an `stgrid` object: a regular tessellation of a rectangular
#' study region combined with a regular tessellation of time. This is the
#' basic space-time vector data cube structure used to aggregate or model
#' spatio-temporal point patterns.
#'
#' Spatial cells are built with [sf::st_make_grid()]. Temporal bins are
#' left-closed, right-open intervals (the convention also used by raster
#' tessellations and `xts`-style time series), so that an event falling
#' exactly on a break is assigned to the *later* bin.
#'
#' @param bbox Numeric vector of length 4: `c(xmin, ymin, xmax, ymax)`.
#' @param cell_size Numeric scalar: spatial cell side length, in the units
#'   of the supplied CRS.
#' @param t_window Length-2 vector (`POSIXct` or `Date`) giving the time
#'   window `c(t_start, t_end)`.
#' @param t_step Character scalar passed to [base::seq.POSIXt()],
#'   e.g. `"1 day"`, `"1 week"`, `"1 month"`.
#' @param crs Optional CRS, passed to [sf::st_crs()].
#'
#' @return An object of class `stgrid`: a list with an `sf` object of cells,
#'   the vector of temporal breakpoints, and bookkeeping metadata.
#' @export
#'
#' @examples
#' g <- stgrid(
#'   bbox      = c(0, 0, 100, 100),
#'   cell_size = 20,
#'   t_window  = as.POSIXct(c("2023-01-01", "2023-12-31")),
#'   t_step    = "1 month"
#' )
#' print(g)
stgrid <- function(bbox, cell_size, t_window, t_step, crs = NA) {
  # --- Validate bbox ---
  if (!is.numeric(bbox) || length(bbox) != 4) {
    stop("`bbox` must be a numeric vector of length 4: c(xmin, ymin, xmax, ymax).")
  }
  if (bbox[3] <= bbox[1] || bbox[4] <= bbox[2]) {
    stop("`bbox` must satisfy xmax > xmin and ymax > ymin.")
  }
  names(bbox) <- c("xmin", "ymin", "xmax", "ymax")

  # --- Validate cell_size ---
  if (!is.numeric(cell_size) || length(cell_size) != 1 || cell_size <= 0) {
    stop("`cell_size` must be a single positive number.")
  }

  # --- Validate t_window ---
  if (!inherits(t_window, c("POSIXct", "Date")) || length(t_window) != 2) {
    stop("`t_window` must be a length-2 POSIXct or Date vector.")
  }
  if (inherits(t_window, "Date")) {
    t_window <- as.POSIXct(t_window)
  }
  if (t_window[2] <= t_window[1]) {
    stop("`t_window[2]` must be strictly later than `t_window[1]`.")
  }

  # --- Validate t_step ---
  if (!is.character(t_step) || length(t_step) != 1) {
    stop("`t_step` must be a single character string like '1 week'.")
  }

  # --- Parse CRS once via sf ---
  parsed_crs <- sf::st_crs(crs)

  # --- Build spatial cells using sf::st_make_grid() ---
  # Strip any incoming names from `bbox` to avoid double-naming issues
  # when we re-label its elements for st_bbox().
  b <- unname(bbox)
  bbox_sf <- sf::st_bbox(
    c(xmin = b[1], ymin = b[2], xmax = b[3], ymax = b[4]),
    crs = parsed_crs
  )
  cell_geoms <- sf::st_make_grid(bbox_sf, cellsize = cell_size)
  cells <- sf::st_sf(cell_id = seq_along(cell_geoms), geometry = cell_geoms)

  # --- Build temporal breaks ---
  # seq() with character `by` produces left-closed, right-open bins when
  # combined with cut() / findInterval() downstream. We ensure the final
  # break covers t_window[2].
  t_breaks <- seq(from = t_window[1], to = t_window[2], by = t_step)
  if (t_breaks[length(t_breaks)] < t_window[2]) {
    t_breaks <- c(t_breaks, t_window[2])
  }

  structure(
    list(
      cells     = cells,
      t_breaks  = t_breaks,
      cell_size = cell_size,
      t_step    = t_step,
      bbox      = bbox,
      crs       = parsed_crs
    ),
    class = "stgrid"
  )
}

#' @export
print.stgrid <- function(x, ...) {
  cat("<stgrid> space-time tessellation\n")
  cat("  Spatial cells   : ", nrow(x$cells),
      " (", x$cell_size, " x ", x$cell_size, " units)\n", sep = "")
  cat("  Temporal bins   : ", length(x$t_breaks) - 1,
      " (step = '", x$t_step, "')\n", sep = "")
  cat("  Time range      : ", format(x$t_breaks[1]), " -> ",
      format(x$t_breaks[length(x$t_breaks)]), "\n", sep = "")
  cat("  Bounding box    : [", x$bbox["xmin"], ", ", x$bbox["ymin"], ", ",
      x$bbox["xmax"], ", ", x$bbox["ymax"], "]\n", sep = "")
  cat("  CRS             : ", format(x$crs$input), "\n", sep = "")
  invisible(x)
}

#' @export
summary.stgrid <- function(object, ...) {
  # Derived sizes: total cube cells = spatial cells * temporal bins
  n_cells <- nrow(object$cells)
  n_bins  <- length(object$t_breaks) - 1
  total   <- n_cells * n_bins

  span_days <- as.numeric(
    difftime(object$t_breaks[length(object$t_breaks)],
             object$t_breaks[1], units = "days")
  )

  cat("Summary of <stgrid>\n")
  cat("  Spatial cells          : ", n_cells, "\n", sep = "")
  cat("  Temporal bins          : ", n_bins, "\n", sep = "")
  cat("  Total space-time cells : ", total, "\n", sep = "")
  cat("  Cell size              : ", object$cell_size, "\n", sep = "")
  cat("  Temporal step          : ", object$t_step, "\n", sep = "")
  cat("  Time span (days)       : ", round(span_days, 2), "\n", sep = "")
  invisible(object)
}

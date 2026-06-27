#' Create a spatio-temporal event pattern
#'
#' Constructs an `stevents` object representing a set of events located in
#' space and time. Events are sorted by time on construction.
#'
#' @param x Numeric vector of x-coordinates (e.g., easting or longitude).
#' @param y Numeric vector of y-coordinates (e.g., northing or latitude).
#'   Must be the same length as `x`.
#' @param time A vector of timestamps, either `POSIXct` or `Date`, the same
#'   length as `x`. `Date` input is coerced to `POSIXct`.
#' @param crs Optional coordinate reference system, passed to [sf::st_crs()].
#'   Can be an EPSG code (integer), a string (e.g., `"EPSG:25830"`), or
#'   `NA` (default) when CRS is unknown.
#'
#' @return An object of class `stevents`, which is a list with elements
#'   `data` (data.frame of x, y, time), `crs`, `bbox`, and `t_range`.
#' @export
#'
#' @examples
#' set.seed(1)
#' ev <- stevents(
#'   x = runif(50, 0, 100),
#'   y = runif(50, 0, 100),
#'   time = as.POSIXct("2023-01-01") + runif(50, 0, 365 * 86400)
#' )
#' print(ev)
stevents <- function(x, y, time, crs = NA) {
  # --- Input validation ---
  if (!is.numeric(x) || !is.numeric(y)) {
    stop("`x` and `y` must be numeric vectors.")
  }
  if (length(x) != length(y) || length(x) != length(time)) {
    stop("`x`, `y`, and `time` must all have the same length.")
  }
  if (length(x) == 0) {
    stop("At least one event is required.")
  }
  if (!inherits(time, c("POSIXct", "Date"))) {
    stop("`time` must be a POSIXct or Date vector.")
  }
  if (any(is.na(x)) || any(is.na(y)) || any(is.na(time))) {
    stop("NAs are not allowed in `x`, `y`, or `time`.")
  }

  # --- Normalise time to POSIXct for consistent downstream behaviour ---
  if (inherits(time, "Date")) {
    time <- as.POSIXct(time)
  }

  # --- Build the underlying data.frame and sort by time ---
  # Sorting at construction makes later operations (e.g. computing neighbour
  # histories with respect to *past* events) much simpler and faster.
  data <- data.frame(x = x, y = y, time = time)
  data <- data[order(data$time), ]
  rownames(data) <- NULL

  # --- Compute metadata once, store on the object ---
  bbox <- c(xmin = min(x), ymin = min(y), xmax = max(x), ymax = max(y))
  t_range <- c(min(time), max(time))

  # --- Validate CRS via sf if a value was supplied ---
  # sf::st_crs() accepts NA gracefully and returns a CRS object either way.
  parsed_crs <- sf::st_crs(crs)

  structure(
    list(
      data    = data,
      crs     = parsed_crs,
      bbox    = bbox,
      t_range = t_range
    ),
    class = "stevents"
  )
}

#' @export
print.stevents <- function(x, ...) {
  # Compact, scannable header
  cat("<stevents> spatio-temporal event pattern\n")
  cat("  Events    : ", nrow(x$data), "\n", sep = "")
  cat("  Time range: ", format(x$t_range[1]), " -> ",
      format(x$t_range[2]), "\n", sep = "")
  cat("  Bounding box:\n")
  cat(sprintf("    x: [%g, %g]\n", x$bbox["xmin"], x$bbox["xmax"]))
  cat(sprintf("    y: [%g, %g]\n", x$bbox["ymin"], x$bbox["ymax"]))
  cat("  CRS       : ", format(x$crs$input), "\n", sep = "")
  invisible(x)
}

#' @export
summary.stevents <- function(object, ...) {
  # Derived statistics: useful to see at a glance whether a pattern
  # is dense or sparse in space and time.
  n <- nrow(object$data)
  span_days <- as.numeric(
    difftime(object$t_range[2], object$t_range[1], units = "days")
  )
  area <- (object$bbox["xmax"] - object$bbox["xmin"]) *
    (object$bbox["ymax"] - object$bbox["ymin"])

  cat("Summary of <stevents>\n")
  cat("  Number of events     : ", n, "\n", sep = "")
  cat("  Time span (days)     : ", round(span_days, 2), "\n", sep = "")
  cat("  Mean events per day  : ",
      if (span_days > 0) round(n / span_days, 4) else NA, "\n", sep = "")
  cat("  Bounding-box area    : ", format(area, digits = 4), "\n", sep = "")
  cat("  Mean events per area : ",
      if (area > 0) format(n / area, digits = 4) else NA, "\n", sep = "")
  invisible(object)
}

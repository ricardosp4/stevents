#' Subset a spatio-temporal event pattern
#'
#' Filters an `stevents` object by a temporal window, a spatial bounding
#' box, or both. Returns a new `stevents` object containing only the
#' events that satisfy all supplied constraints.
#'
#' @param x An `stevents` object.
#' @param t_from Optional. Start of temporal window (`POSIXct` or `Date`,
#'   inclusive). If `NULL`, no lower time bound is applied.
#' @param t_to Optional. End of temporal window (`POSIXct` or `Date`,
#'   inclusive). If `NULL`, no upper time bound is applied.
#' @param bbox Optional. Numeric vector of length 4
#'   `c(xmin, ymin, xmax, ymax)` for spatial filtering. If `NULL`, no
#'   spatial filter is applied.
#' @param ... Currently unused.
#'
#' @return A new `stevents` object with the filtered events.
#' @export
#'
#' @examples
#' set.seed(1)
#' ev <- stevents(
#'   x    = runif(100, 0, 100),
#'   y    = runif(100, 0, 100),
#'   time = as.POSIXct("2023-01-01") + runif(100, 0, 365 * 86400)
#' )
#'
#' # Filter by time window
#' ev_summer <- subset(ev,
#'   t_from = as.POSIXct("2023-06-01"),
#'   t_to   = as.POSIXct("2023-08-31")
#' )
#'
#' # Filter by bounding box
#' ev_nw <- subset(ev, bbox = c(0, 50, 50, 100))
#'
#' # Both at once
#' ev_sub <- subset(ev,
#'   t_from = as.POSIXct("2023-06-01"),
#'   t_to   = as.POSIXct("2023-08-31"),
#'   bbox   = c(0, 50, 50, 100)
#' )
subset.stevents <- function(x, t_from = NULL, t_to = NULL, bbox = NULL, ...) {
  # --- Validate temporal arguments ---
  if (!is.null(t_from)) {
    if (!inherits(t_from, c("POSIXct", "Date"))) {
      stop("`t_from` must be a POSIXct or Date value.")
    }
    if (inherits(t_from, "Date")) t_from <- as.POSIXct(t_from)
  }
  if (!is.null(t_to)) {
    if (!inherits(t_to, c("POSIXct", "Date"))) {
      stop("`t_to` must be a POSIXct or Date value.")
    }
    if (inherits(t_to, "Date")) t_to <- as.POSIXct(t_to)
  }
  if (!is.null(t_from) && !is.null(t_to) && t_to < t_from) {
    stop("`t_to` must be later than `t_from`.")
  }

  # --- Validate bbox ---
  if (!is.null(bbox)) {
    if (!is.numeric(bbox) || length(bbox) != 4) {
      stop("`bbox` must be a numeric vector of length 4: c(xmin, ymin, xmax, ymax).")
    }
    if (bbox[3] <= bbox[1] || bbox[4] <= bbox[2]) {
      stop("`bbox` must satisfy xmax > xmin and ymax > ymin.")
    }
  }

  data <- x$data

  # --- Apply temporal filter ---
  if (!is.null(t_from)) data <- data[data$time >= t_from, ]
  if (!is.null(t_to))   data <- data[data$time <= t_to,   ]

  # --- Apply spatial filter ---
  if (!is.null(bbox)) {
    data <- data[
      data$x >= bbox[1] & data$x <= bbox[3] &
        data$y >= bbox[2] & data$y <= bbox[4],
    ]
  }

  if (nrow(data) == 0) {
    stop("No events remain after filtering. Try relaxing the time or bbox constraints.")
  }

  # Reconstruct a valid stevents from the filtered rows.
  # We call the constructor to recompute bbox, t_range, and sorting.
  stevents(
    x    = data$x,
    y    = data$y,
    time = data$time,
    crs  = x$crs$input
  )
}

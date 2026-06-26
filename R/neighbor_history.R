#' Compute recent spatial neighbour counts for each event
#'
#' For each event `i`, counts how many *previous* events occurred within
#' spatial radius `radius` and within the time lag `[t_i - lag, t_i)`.
#' This is the simplest version of the Hawkes "excitation history" feature:
#' a high count suggests the current event may have been triggered by
#' recent nearby activity.
#'
#' @param events An `stevents` object. Events must already be sorted by
#'   time (the constructor guarantees this).
#' @param radius Positive numeric: spatial search radius, in the same units
#'   as the coordinates.
#' @param lag Look-back window. Either a [difftime] object or a positive
#'   numeric scalar interpreted as **days**.
#'
#' @return The `stevents` object with an additional column `n_recent_neighbors`
#'   appended to `events$data`.
#' @export
#'
#' @examples
#' set.seed(42)
#' ev <- stevents(
#'   x    = runif(100, 0, 100),
#'   y    = runif(100, 0, 100),
#'   time = as.POSIXct("2023-01-01") + sort(runif(100, 0, 30 * 86400))
#' )
#' ev2 <- neighbor_history(ev, radius = 10, lag = 7)   # 7 days
#' summary(ev2$data$n_recent_neighbors)
neighbor_history <- function(events, radius, lag) {
  if (!inherits(events, "stevents")) stop("`events` must be an `stevents` object.")
  if (!is.numeric(radius) || length(radius) != 1 || radius <= 0) {
    stop("`radius` must be a single positive number.")
  }
  # Accept either a difftime (any unit) or a positive numeric (interpreted as days).
  if (inherits(lag, "difftime")) {
    lag_secs <- as.numeric(lag, units = "secs")
  } else if (is.numeric(lag) && length(lag) == 1 && lag > 0) {
    lag_secs <- lag * 86400  # numeric input = days
  } else {
    stop("`lag` must be a positive difftime, or a positive numeric (days).")
  }

  data  <- events$data
  n     <- nrow(data)
  x     <- data$x
  y     <- data$y
  t_num <- as.numeric(data$time)   # seconds since epoch

  n_neighbors <- integer(n)

  # --- O(n^2) scan, suitable for n up to a few thousand ---
  # For the thesis prototype this is fine; production code would use
  # a k-d tree (e.g. RANN::nn2) or a spatial index.
  #
  # Events are time-sorted, so for event i we only need to look at
  # events j < i (strict past). We stop as soon as t[j] < t[i] - lag.
  for (i in seq_len(n)) {
    if (i == 1L) next

    t_i   <- t_num[i]
    t_low <- t_i - lag_secs

    # Walk backward; break as soon as we're outside the lag window.
    count <- 0L
    j <- i - 1L
    while (j >= 1L && t_num[j] >= t_low) {
      dx <- x[j] - x[i]
      dy <- y[j] - y[i]
      if (sqrt(dx * dx + dy * dy) <= radius) {
        count <- count + 1L
      }
      j <- j - 1L
    }
    n_neighbors[i] <- count
  }

  events$data$n_recent_neighbors <- n_neighbors
  events
}

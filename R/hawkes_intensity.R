#' Compute the Hawkes process conditional intensity for each event
#'
#' For each event `i`, computes the cumulative excitation contribution
#' from all previous events using a separable spatio-temporal kernel
#' with exponential decay in both time and space:
#'
#' \deqn{\Lambda_i = \sum_{j: t_j < t_i} \alpha \cdot e^{-\beta (t_i - t_j)}
#'   \cdot e^{-\gamma \, d_{ij}}}
#'
#' where \eqn{d_{ij}} is the Euclidean distance between events \eqn{i}
#' and \eqn{j}. The result approximates the self-excitation component of
#' the Hawkes intensity at each observed event location and time.
#'
#' @param events An `stevents` object. Events must be sorted by time
#'   (the constructor guarantees this).
#' @param alpha Positive numeric: branching ratio / excitation magnitude.
#'   Controls how strongly each past event excites future ones.
#' @param beta Positive numeric: temporal decay rate (units: 1/second).
#'   A value of `1/(7*86400)` means the excitation halves roughly every
#'   week. Larger values = faster decay.
#' @param gamma Positive numeric: spatial decay rate (units: 1/metre if
#'   coordinates are in metres). A value of `1/50000` means excitation
#'   decays over ~50 km. Larger values = faster spatial decay.
#'
#' @return The `stevents` object with an additional column
#'   `hawkes_intensity` in `events$data` giving the conditional
#'   intensity contribution at each event from its entire past history.
#'   The first event always receives a value of 0 (no past history).
#' @export
#'
#' @examples
#' set.seed(42)
#' ev <- stevents(
#'   x    = runif(100, 0, 100),
#'   y    = runif(100, 0, 100),
#'   time = as.POSIXct("2023-01-01") + sort(runif(100, 0, 90 * 86400))
#' )
#' ev2 <- hawkes_intensity(ev, alpha = 0.5, beta = 1 / (7 * 86400), gamma = 1 / 30)
#' summary(ev2$data$hawkes_intensity)
hawkes_intensity <- function(events, alpha, beta, gamma) {
  # --- Input validation ---
  if (!inherits(events, "stevents")) {
    stop("`events` must be an `stevents` object.")
  }
  if (!is.numeric(alpha) || length(alpha) != 1 || alpha <= 0) {
    stop("`alpha` must be a single positive number.")
  }
  if (!is.numeric(beta) || length(beta) != 1 || beta <= 0) {
    stop("`beta` must be a single positive number.")
  }
  if (!is.numeric(gamma) || length(gamma) != 1 || gamma <= 0) {
    stop("`gamma` must be a single positive number.")
  }

  n     <- nrow(events$data)
  x     <- events$data$x
  y     <- events$data$y
  t_num <- as.numeric(events$data$time)  # seconds since epoch

  # --- Vectorised kernel evaluation ---
  # outer() builds full n x n matrices of pairwise differences.
  # This avoids an explicit double loop and lets R's C backend do the
  # heavy lifting. Memory cost is O(n^2) — fine for n up to ~5000.

  # Temporal differences: dt[i, j] = t_i - t_j
  # Positive values mean i is later than j (i.e. j is in i's past).
  dt <- outer(t_num, t_num, "-")

  # Spatial distances: Euclidean in the coordinate units of the object.
  dx <- outer(x, x, "-")
  dy <- outer(y, y, "-")
  D  <- sqrt(dx^2 + dy^2)

  # Kernel matrix: alpha * exp(-beta * dt) * exp(-gamma * D)
  # We zero out the upper triangle (dt <= 0) so that event i only
  # receives contributions from strictly earlier events j.
  K        <- alpha * exp(-beta * dt) * exp(-gamma * D)
  K[dt <= 0] <- 0

  # Row sums give the total excitation arriving at each event i
  # from its entire past. First event is always 0 by construction.
  events$data$hawkes_intensity <- rowSums(K)
  events
}

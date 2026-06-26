#' Count events per space-time cell
#'
#' Assigns each event in an `stevents` object to a cell in an `stgrid`
#' tessellation and returns the grid with an `n_events` column giving the
#' count per spatial cell × temporal bin combination.
#'
#' @importFrom stats aggregate
#'
#' @param events An `stevents` object.
#' @param grid An `stgrid` object whose bounding box and time window cover
#'   (or at least overlap) the events.
#'
#' @return The `stgrid` object with an additional data frame `grid$counts`,
#'   a long-format table with columns `cell_id`, `t_bin` (integer index of
#'   the temporal bin), `t_start`, `t_end`, and `n_events`.
#' @export
#'
#' @examples
#' set.seed(1)
#' ev <- stevents(
#'   x    = runif(200, 0, 100),
#'   y    = runif(200, 0, 100),
#'   time = as.POSIXct("2023-01-01") + runif(200, 0, 365 * 86400)
#' )
#' g <- stgrid(
#'   bbox      = c(0, 0, 100, 100),
#'   cell_size = 20,
#'   t_window  = as.POSIXct(c("2023-01-01", "2023-12-31")),
#'   t_step    = "1 month"
#' )
#' result <- count_events(ev, g)
#' head(result$counts)
count_events <- function(events, grid) {
  if (!inherits(events, "stevents")) stop("`events` must be an `stevents` object.")
  if (!inherits(grid, "stgrid"))     stop("`grid` must be an `stgrid` object.")

  # --- Spatial join: find which cell each event falls in ---
  # Build an sf point layer from the events data frame.
  pts <- sf::st_as_sf(
    events$data,
    coords = c("x", "y"),
    crs    = grid$crs
  )

  # sf::st_join does a left join: each point gets the cell_id of the cell
  # that contains it. Points outside all cells get NA.
  joined <- sf::st_join(pts, grid$cells, join = sf::st_within)

  # Drop events that fell outside the grid's bbox (NA cell_id).
  joined <- joined[!is.na(joined$cell_id), ]

  # --- Temporal binning: assign each event to a t_bin index ---
  # findInterval() returns the index of the left break for each value,
  # i.e. it implements the left-closed, right-open convention we promised.
  joined$t_bin <- findInterval(
    as.numeric(joined$time),
    as.numeric(grid$t_breaks),
    rightmost.closed = FALSE
  )

  # Drop events outside the time window (t_bin == 0 or beyond last break).
  n_bins <- length(grid$t_breaks) - 1
  joined <- joined[joined$t_bin >= 1 & joined$t_bin <= n_bins, ]

  # --- Aggregate: count events per (cell_id, t_bin) pair ---
  # Use base R tabulate approach for speed and no extra dependencies.
  if (nrow(joined) == 0) {
    counts <- data.frame(
      cell_id  = integer(0),
      t_bin    = integer(0),
      t_start  = grid$t_breaks[integer(0)],
      t_end    = grid$t_breaks[integer(0)],
      n_events = integer(0)
    )
  } else {
    agg <- aggregate(
      list(n_events = rep(1L, nrow(joined))),
      by  = list(cell_id = joined$cell_id, t_bin = joined$t_bin),
      FUN = sum
    )

    # Attach human-readable bin start/end times.
    agg$t_start <- grid$t_breaks[agg$t_bin]
    agg$t_end   <- grid$t_breaks[agg$t_bin + 1]
    agg <- agg[order(agg$t_bin, agg$cell_id), ]
    rownames(agg) <- NULL
    counts <- agg[, c("cell_id", "t_bin", "t_start", "t_end", "n_events")]
  }

  # Return a modified copy of the grid with counts attached.
  grid$counts <- counts
  grid
}

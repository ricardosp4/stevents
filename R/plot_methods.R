#' Plot a spatio-temporal event pattern
#'
#' Produces a two-panel figure: a spatial scatter of event locations (left)
#' and a temporal intensity histogram (right).
#'
#' @importFrom graphics par hist axis
#' @importFrom grDevices adjustcolor
#'
#' @param x An `stevents` object.
#' @param bins Integer: number of histogram bins for the temporal plot.
#'   Default 20.
#' @param col Point colour for the spatial scatter. Default `"#E05A2B"`.
#' @param pch Point symbol. Default `16` (filled circle).
#' @param cex Point size. Default `0.6`.
#' @param ... Further graphical parameters passed to [graphics::plot()].
#'
#' @return Invisibly returns `x`.
#' @export
#'
#' @examples
#' set.seed(1)
#' ev <- stevents(
#'   x    = runif(200, 0, 100),
#'   y    = runif(200, 0, 100),
#'   time = as.POSIXct("2023-01-01") + runif(200, 0, 365 * 86400)
#' )
#' plot(ev)
plot.stevents <- function(x, bins = 20, col = "#E05A2B", pch = 16, cex = 0.6, ...) {
  old_par <- par(mfrow = c(1, 2), mar = c(4, 4, 3, 1))
  on.exit(par(old_par))

  # --- Left: spatial scatter ---
  plot(
    x$data$x, x$data$y,
    col  = adjustcolor(col, alpha.f = 0.5),
    pch  = pch,
    cex  = cex,
    xlab = "x",
    ylab = "y",
    main = paste0("Spatial pattern  (n = ", nrow(x$data), ")"),
    asp  = 1,
    ...
  )

  # --- Right: temporal histogram ---
  # Convert POSIXct to numeric (seconds) before hist() to avoid integer
  # overflow in breaks arithmetic, then re-label the axis with dates.
  t_num  <- as.numeric(x$data$time)
  t_rng  <- range(t_num)
  breaks <- seq(t_rng[1], t_rng[2], length.out = bins + 1)

  hist(
    t_num,
    breaks = breaks,
    col    = adjustcolor(col, alpha.f = 0.4),
    border = adjustcolor(col, alpha.f = 0.8),
    xlab   = "Time",
    ylab   = "Count",
    main   = "Temporal intensity",
    freq   = TRUE,
    xaxt   = "n"          # suppress default numeric axis
  )

  # Draw a date axis: pick 5 evenly-spaced tick positions.
  tick_at     <- pretty(x$data$time, n = 5)
  tick_labels <- format(tick_at, "%Y-%m-%d")
  axis(1, at = as.numeric(tick_at), labels = tick_labels, cex.axis = 0.75, las = 2)

  invisible(x)
}

#' Plot a space-time tessellation
#'
#' Draws the spatial grid cells. If `count_events()` has been called and
#' `grid$counts` exists, cells are shaded by total event count (summed
#' across all time bins). Otherwise all cells are drawn with equal fill.
#'
#' @importFrom grDevices colorRampPalette
#' @importFrom graphics legend
#'
#' @param x An `stgrid` object.
#' @param t_bin Integer: if supplied, shade only the counts for this
#'   specific temporal bin. Default `NULL` (sum over all bins).
#' @param pal A vector of colours used as a palette for the count ramp.
#'   Default is a white-to-dark-orange ramp.
#' @param border Colour for cell borders. Default `"grey70"`.
#' @param ... Further arguments passed to [graphics::plot()].
#'
#' @return Invisibly returns `x`.
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
#' g <- count_events(ev, g)
#' plot(g)
#' plot(g, t_bin = 3)
plot.stgrid <- function(x, t_bin = NULL, pal = NULL, border = "grey70", ...) {
  # --- Default palette if none supplied ---
  if (is.null(pal)) {
    pal <- grDevices::colorRampPalette(c("#FFF5F0", "#FD8D3C", "#8B2500"))(50)
  }

  if (!is.null(x$counts) && nrow(x$counts) > 0) {
    # Filter to requested bin or aggregate over all bins.
    if (!is.null(t_bin)) {
      sub <- x$counts[x$counts$t_bin == t_bin, ]
      title_suffix <- paste0("  (bin ", t_bin, ": ",
                             format(sub$t_start[1], "%Y-%m-%d"), ")")
    } else {
      sub <- x$counts
      title_suffix <- "  (all bins)"
    }

    # Aggregate counts per cell and place into a length(cells) vector.
    cell_counts <- tapply(sub$n_events, sub$cell_id, sum)
    counts_vec  <- rep(0L, nrow(x$cells))
    matched_ids <- as.integer(names(cell_counts))
    counts_vec[matched_ids] <- as.integer(cell_counts)

    # Empty-bin safety: avoid division by zero in the colour index.
    max_count <- max(counts_vec)
    if (max_count == 0) {
      fill_cols <- rep(pal[1], nrow(x$cells))
    } else {
      colour_idx <- ceiling(counts_vec / max_count * (length(pal) - 1)) + 1
      fill_cols  <- pal[colour_idx]
    }
  } else {
    fill_cols    <- "white"
    title_suffix <- ""
    max_count    <- 0
  }

  # --- Draw cells ---
  plot(
    sf::st_geometry(x$cells),
    col    = fill_cols,
    border = border,
    main   = paste0("stgrid cells", title_suffix),
    ...
  )

  # --- Legend if counts are available ---
  if (!is.null(x$counts) && nrow(x$counts) > 0 && max_count > 0) {
    graphics::legend(
      "bottomright",
      legend = c(0, round(max_count / 2), max_count),
      fill   = pal[c(1, round(length(pal) / 2), length(pal))],
      title  = "Events",
      bty    = "n",
      cex    = 0.75
    )
  }

  invisible(x)
}

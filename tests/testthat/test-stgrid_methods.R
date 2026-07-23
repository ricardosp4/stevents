test_that("dim.stgrid returns n_cells and n_bins", {
  g <- stgrid(
    bbox      = c(0, 0, 100, 100),
    cell_size = 20,
    t_window  = as.POSIXct(c("2023-01-01", "2023-12-31")),
    t_step    = "1 month"
  )
  d <- dim(g)

  expect_equal(unname(d[1]), nrow(g$cells))
  expect_equal(unname(d[2]), length(g$t_breaks) - 1L)
})

test_that("as_sf.stgrid returns an sf object with one row per cell", {
  g <- stgrid(
    bbox      = c(0, 0, 100, 100),
    cell_size = 20,
    t_window  = as.POSIXct(c("2023-01-01", "2023-12-31")),
    t_step    = "1 month"
  )
  sf_g <- as_sf(g)

  expect_s3_class(sf_g, "sf")
  expect_equal(nrow(sf_g), nrow(g$cells))
  expect_true("cell_id" %in% names(sf_g))
})

test_that("as_sf.stgrid attaches n_events when counts are available", {
  set.seed(1)
  ev <- stevents(
    x    = runif(50, 0, 100),
    y    = runif(50, 0, 100),
    time = as.POSIXct("2023-01-01") + runif(50, 0, 365 * 86400)
  )
  g <- stgrid(
    bbox      = c(0, 0, 100, 100),
    cell_size = 20,
    t_window  = as.POSIXct(c("2023-01-01", "2023-12-31")),
    t_step    = "1 month"
  )
  g2 <- count_events(ev, g)
  sf_g2 <- as_sf(g2)

  expect_true("n_events" %in% names(sf_g2))
  expect_equal(sum(sf_g2$n_events), sum(g2$counts$n_events))
})

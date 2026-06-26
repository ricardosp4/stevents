test_that("count_events returns an stgrid with counts", {
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
  result <- count_events(ev, g)

  expect_s3_class(result, "stgrid")
  expect_true(!is.null(result$counts))
  expect_true(all(c("cell_id", "t_bin", "n_events") %in% names(result$counts)))
  expect_true(sum(result$counts$n_events) <= 50)
})

test_that("count_events rejects wrong input types", {
  expect_error(count_events(list(), list()), "`events` must be an `stevents`")
})

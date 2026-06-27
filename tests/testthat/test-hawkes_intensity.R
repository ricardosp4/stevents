test_that("hawkes_intensity returns stevents with new column", {
  set.seed(1)
  ev <- stevents(
    x    = runif(20, 0, 100),
    y    = runif(20, 0, 100),
    time = as.POSIXct("2023-01-01") + sort(runif(20, 0, 30 * 86400))
  )
  result <- hawkes_intensity(ev, alpha = 0.5, beta = 1 / (7 * 86400), gamma = 1 / 30)

  expect_s3_class(result, "stevents")
  expect_true("hawkes_intensity" %in% names(result$data))
  expect_equal(nrow(result$data), 20)
})

test_that("first event always has zero intensity", {
  set.seed(1)
  ev <- stevents(
    x    = runif(10, 0, 100),
    y    = runif(10, 0, 100),
    time = as.POSIXct("2023-01-01") + sort(runif(10, 0, 30 * 86400))
  )
  result <- hawkes_intensity(ev, alpha = 0.5, beta = 1 / (7 * 86400), gamma = 1 / 30)
  expect_equal(result$data$hawkes_intensity[1], 0)
})

test_that("intensity is non-negative for all events", {
  set.seed(1)
  ev <- stevents(
    x    = runif(30, 0, 100),
    y    = runif(30, 0, 100),
    time = as.POSIXct("2023-01-01") + sort(runif(30, 0, 30 * 86400))
  )
  result <- hawkes_intensity(ev, alpha = 0.5, beta = 1 / (7 * 86400), gamma = 1 / 30)
  expect_true(all(result$data$hawkes_intensity >= 0))
})

test_that("higher alpha produces higher intensity values", {
  set.seed(1)
  ev <- stevents(
    x    = runif(30, 0, 100),
    y    = runif(30, 0, 100),
    time = as.POSIXct("2023-01-01") + sort(runif(30, 0, 30 * 86400))
  )
  low  <- hawkes_intensity(ev, alpha = 0.1, beta = 1 / (7 * 86400), gamma = 1 / 30)
  high <- hawkes_intensity(ev, alpha = 2.0, beta = 1 / (7 * 86400), gamma = 1 / 30)
  expect_true(mean(high$data$hawkes_intensity) > mean(low$data$hawkes_intensity))
})

test_that("hawkes_intensity rejects invalid inputs", {
  set.seed(1)
  ev <- stevents(
    x    = runif(10, 0, 100),
    y    = runif(10, 0, 100),
    time = as.POSIXct("2023-01-01") + sort(runif(10, 0, 30 * 86400))
  )
  expect_error(hawkes_intensity(list(), 0.5, 0.1, 0.1), "`events` must be")
  expect_error(hawkes_intensity(ev, -1,   0.1, 0.1),    "`alpha` must be")
  expect_error(hawkes_intensity(ev,  0.5, 0,   0.1),    "`beta` must be")
  expect_error(hawkes_intensity(ev,  0.5, 0.1, -2),     "`gamma` must be")
})

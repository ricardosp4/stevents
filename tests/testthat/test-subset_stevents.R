test_that("subset by time window returns correct events", {
  set.seed(1)
  ev <- stevents(
    x    = runif(100, 0, 100),
    y    = runif(100, 0, 100),
    time = as.POSIXct("2023-01-01") + runif(100, 0, 365 * 86400)
  )
  t_from <- as.POSIXct("2023-06-01")
  t_to   <- as.POSIXct("2023-08-31")
  sub    <- subset(ev, t_from = t_from, t_to = t_to)

  expect_true(all(sub$data$time >= t_from))
  expect_true(all(sub$data$time <= t_to))
  expect_s3_class(sub, "stevents")
})

test_that("subset by bbox returns events within bounds", {
  ev  <- stevents(1:10, 1:10,
                  as.POSIXct("2023-01-01") + seq(0, 9) * 86400)
  sub <- subset(ev, bbox = c(3, 3, 7, 7))

  expect_true(all(sub$data$x >= 3 & sub$data$x <= 7))
  expect_true(all(sub$data$y >= 3 & sub$data$y <= 7))
})

test_that("subset with no matching events stops", {
  ev <- stevents(1:5, 1:5,
                 as.POSIXct("2023-01-01") + seq(0, 4) * 86400)
  expect_error(subset(ev, bbox = c(50, 50, 100, 100)), "No events remain")
})

test_that("subset rejects invalid t_from/t_to", {
  ev <- stevents(1:5, 1:5,
                 as.POSIXct("2023-01-01") + seq(0, 4) * 86400)
  expect_error(subset(ev, t_from = "2023-01-01"), "`t_from` must be a POSIXct")
  expect_error(
    subset(ev,
           t_from = as.POSIXct("2023-06-01"),
           t_to   = as.POSIXct("2023-01-01")),
    "`t_to` must be later"
  )
})

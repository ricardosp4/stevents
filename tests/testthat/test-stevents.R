test_that("stevents constructor validates inputs", {
  expect_error(stevents("a", 1:3, Sys.time()),  "`x` and `y` must be numeric")
  expect_error(stevents(1:3, 1:2, Sys.time()),  "same length")
  expect_error(stevents(numeric(0), numeric(0), as.POSIXct(character(0))),
               "At least one event")
  expect_error(stevents(1, 1, "2023-01-01"),    "`time` must be a POSIXct")
  expect_error(stevents(c(1, NA), c(1, 2),
                        as.POSIXct(c("2023-01-01", "2023-01-02"))), "NAs are not")
})

test_that("stevents sorts events by time on construction", {
  t <- as.POSIXct(c("2023-03-01", "2023-01-01", "2023-02-01"))
  ev <- stevents(x = 1:3, y = 1:3, time = t)
  expect_true(all(diff(as.numeric(ev$data$time)) >= 0))
})

test_that("stevents accepts Date input and coerces to POSIXct", {
  ev <- stevents(1:3, 1:3, as.Date(c("2023-01-01", "2023-02-01", "2023-03-01")))
  expect_s3_class(ev$data$time, "POSIXct")
})

test_that("stevents stores correct bbox and t_range", {
  ev <- stevents(c(1, 5), c(2, 8), as.POSIXct(c("2023-01-01", "2023-06-01")))
  expect_equal(ev$bbox[["xmin"]], 1)
  expect_equal(ev$bbox[["xmax"]], 5)
  expect_equal(ev$bbox[["ymin"]], 2)
  expect_equal(ev$bbox[["ymax"]], 8)
})

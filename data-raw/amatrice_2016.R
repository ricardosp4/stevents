url <- paste0(
  "https://earthquake.usgs.gov/fdsnws/event/1/query?format=csv",
  "&starttime=2016-08-24",
  "&endtime=2016-11-24",
  "&minmagnitude=2.5",
  "&latitude=42.698",
  "&longitude=13.234",
  "&maxradiuskm=100",
  "&orderby=time"
)

raw <- read.csv(url(url), stringsAsFactors = FALSE)

amatrice_2016 <- data.frame(
  lon       = raw$longitude,
  lat       = raw$latitude,
  depth_km  = raw$depth,
  magnitude = raw$mag,
  time      = as.POSIXct(raw$time,
                         format = "%Y-%m-%dT%H:%M:%OS",
                         tz     = "UTC")
)

usethis::use_data(amatrice_2016, overwrite = TRUE)

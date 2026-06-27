url <- paste0(
  "https://earthquake.usgs.gov/fdsnws/event/1/query?format=csv",
  "&starttime=2026-06-20",
  "&endtime=2026-07-30",
  "&minmagnitude=2.5",
  "&latitude=10.435",
  "&longitude=-68.472",
  "&maxradiuskm=200",
  "&orderby=time"
)

raw <- read.csv(url(url), stringsAsFactors = FALSE)

venezuela_2026 <- data.frame(
  lon       = raw$longitude,
  lat       = raw$latitude,
  depth_km  = raw$depth,
  magnitude = raw$mag,
  time      = as.POSIXct(raw$time,
                         format = "%Y-%m-%dT%H:%M:%OS",
                         tz     = "UTC")
)

usethis::use_data(venezuela_2026, overwrite = TRUE)

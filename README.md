# stevents 

> Lightweight S3 classes for spatio-temporal event pattern analysis in R

<!-- badges: start -->
[![R CMD check](https://github.com/ricardosp4/stevents/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/ricardosp4/stevents/actions)
<!-- badges: end -->

`stevents` provides tools for representing, manipulating, and analysing
spatio-temporal point patterns. It was designed with wildfire ignition
modelling in mind, but applies to any domain where events have both a
location and a timestamp — seismology, epidemiology, criminology.

---

## Installation

```r
# Install from GitHub
devtools::install_github("ricardosp4/stevents")
```

---

## Core classes

| Class | Description |
|---|---|
| `stevents` | A set of events with coordinates and timestamps |
| `stgrid` | A regular space-time tessellation for aggregating events |

Each class has `print()`, `summary()`, and `plot()` methods.

---

## Functions

| Function | Description |
|---|---|
| `count_events()` | Count events per grid cell and time bin |
| `neighbor_history()` | Count recent nearby events for each event (discrete excitation) |
| `hawkes_intensity()` | Compute the Hawkes self-excitation kernel (continuous) |
| `as_sf()` | Convert `stevents` to an `sf` point layer |
| `subset()` | Filter events by time window and/or bounding box |

---

## Quick start

```r
library(stevents)

# Create an event pattern
ev <- stevents(
  x    = runif(200, 0, 100),
  y    = runif(200, 0, 100),
  time = as.POSIXct("2023-01-01") + sort(runif(200, 0, 365 * 86400))
)

print(ev)
#> <stevents> spatio-temporal event pattern
#>   Events    : 200
#>   Time range: 2023-01-01 -> 2023-12-31
#>   CRS       : NA

plot(ev)
```

```r
# Compute Hawkes conditional intensity
ev2 <- hawkes_intensity(ev,
  alpha = 0.8,
  beta  = 1 / (7 * 86400),   # temporal decay: ~1 week
  gamma = 1 / 30              # spatial decay: ~30 units
)

summary(ev2$data$hawkes_intensity)
```

---

## Included datasets

| Dataset | Description | Source |
|---|---|---|
| `venezuela_2026` | Seismic sequence following the Mw 7.5 earthquake of 24 June 2026 | USGS |
| `amatrice_2016` | Amatrice–Norcia aftershock sequence, August–November 2016 (74 events) | USGS |

```r
# Load and analyse a real seismic sequence
data(amatrice_2016)

events <- stevents(
  x    = amatrice_2016$lon,
  y    = amatrice_2016$lat,
  time = amatrice_2016$time
)

plot(events)
```

---

## The Hawkes kernel

`hawkes_intensity()` computes the self-excitation contribution of all
past events at each event location using a separable exponential kernel:

$$\Lambda_i = \sum_{j:\, t_j < t_i} \alpha \cdot e^{-\beta(t_i - t_j)} \cdot e^{-\gamma \, d_{ij}}$$

where $\alpha$ controls excitation magnitude, $\beta$ controls temporal
decay, and $\gamma$ controls spatial decay. This is the continuous
counterpart of `neighbor_history()`, which uses a fixed binary window.

---

## Vignettes

| Vignette | Description |
|---|---|
| [Introduction](https://github.com/ricardosp4/stevents) | Full workflow with simulated data |
| [Seismic sequences](https://github.com/ricardosp4/stevents) | Real data: Venezuela 2026 and Amatrice 2016 |

---

## Motivation

`stevents` was developed as part of a Master's thesis on
spatio-temporal Hawkes process modelling of wildfire ignition risk on
the Iberian Peninsula. The package provides the preprocessing layer
between raw event data and intensity model fitting via INLA.

---

## License

MIT © Ricardo

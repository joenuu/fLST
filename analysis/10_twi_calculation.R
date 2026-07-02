library(terra)
library(whitebox)
library(here)
library(readr)

whitebox::install_whitebox()
whitebox::wbt_init()


#fill sinks (required before flow accumulation)
wbt_fill_depressions(
  dem    = here::here("data", "dem_30m.tif"),
  output = here::here("data", "dem_filled.tif")
)

#calculate slope
wbt_slope(
  dem    = here::here("data", "dem_filled.tif"),
  output = here::here("data", "slope.tif"),
  units  = "radians"
)

#calculate flow accumulation
wbt_d8_flow_accumulation(
  input  = here::here("data", "dem_filled.tif"),
  output = here::here("data", "flow_acc.tif")
)

#calculate TWI
wbt_wetness_index(
  sca    = here::here("data", "flow_acc.tif"),
  slope  = here::here("data", "slope.tif"),
  output = here::here("data", "twi_30m.tif")
)

#load and aggregate to 1km
twi_30m <- rast(here::here("data", "twi_30m.tif"))
twi_1km <- aggregate(twi_30m, fact = round(1000/30), fun = "mean")

#resample to LST grid
lst_ref <- readRDS(here::here("data", "lst_ref.rds"))
twi_1km_resampled <- resample(twi_1km, lst_ref, method = "bilinear")

#convert to dataframe for joining
twi_ch <- as.data.frame(twi_1km_resampled, xy = TRUE) |>
  tibble::as_tibble() |>
  dplyr::rename(lon = x, lat = y, twi = 3)

saveRDS(twi_ch, here::here("data", "twi_ch.rds"))
write_csv(twi_ch, here::here("data", "twi_ch.csv"))

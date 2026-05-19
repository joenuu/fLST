library(metR)
library(tidyverse)
library(lubridate)
library(raster)
library(ggplot2)
library(ncdf4)
library(here)
library(terra)
source(here::here("R", "get_resampled_grid.R"))

#---extract lst data---

lst_dir <- here::here("data-raw/lst")

lst_files <- list.files(lst_dir, pattern = "MOD11A1.*\\.nc$", full.names = TRUE)

lst_all <- map(lst_files, \(f) {
  ReadNetCDF(f, vars = "LST_Day_1km") |>
    as_tibble()
}) |>
  list_rbind()

lst_jjas_181920_ch <- lst_all |>
  rename(lst_raw  = LST_Day_1km) |>
  mutate(
    date = as_date(time),
    lst_kelvin  = lst_raw,
    lst_celsius = lst_kelvin - 273.15,
    lst_raw = NULL           # drop raw scaled integer
  ) |>
  filter(
    lat >= 46.4, lat <= 47.1,
    month(date) %in% c(6, 7, 8, 9),
    year(date)  %in% c(2018, 2019, 2020)
  )

glimpse(lst_jjas_181920_ch) #to have an overview

lst_jjas_181920_ch |> summarise(across(everything(), ~mean(is.na(.)) * 100)) # to know how many NAs are there

#save as .rds and .csv
saveRDS(lst_jjas_181920_ch, here::here("data", "lst_jjas_181920_ch.rds"))
write_csv(lst_jjas_181920_ch, here::here("data", "lst_jjas_181920_ch.csv"))

# 2010 and 2015 for cross-validation of the model
lst_jjas_1015_ch <- lst_all |>
  rename(lst_raw  = LST_Day_1km) |>
  mutate(
    date = as_date(time),
    lst_kelvin  = lst_raw,
    lst_celsius = lst_kelvin - 273.15,
    lst_raw = NULL           # drop raw scaled integer
  ) |>
  filter(
    lat >= 46.4, lat <= 47.1,
    month(date) %in% c(6, 7, 8, 9),
    year(date)  %in% c(2010, 2015)
  )

glimpse(lst_jjas_1015_ch)
lst_jjas_1015_ch |> summarise(across(everything(), ~mean(is.na(.)) * 100))

#save as .rds and .csv
saveRDS(lst_jjas_1015_ch, here::here("data", "lst_jjas_1015_ch.rds"))
write_csv(lst_jjas_1015_ch, here::here("data", "lst_jjas_1015_ch.csv"))


#---extract lc data and disaggregate to 1km---

lc <- rast(here::here("data-raw/lc", "MCD12Q1.061_500m_aid0001.nc"))
sds(lst_jjas_181920_ch[1])

lst_ref <- rast(lst_files[1], subds = "LST_Day_1km")
saveRDS(lst_ref, here::here("data", "lst_ref.rds")) # save this for use in other scripts

# resample lc to lst grid
lc_1km <- resample(lc, lst_ref, method = "near")

#convert using exact cell coordinates from the LST reference grid
lc_ch <- as.data.frame(lc_1km, xy = TRUE) |>
  as_tibble() |>
  rename(lon = x, lat = y, land_cover_type = 3)

glimpse(lc_ch)

#save as .rds and .csv
saveRDS(lc_ch, here::here("data", "lc_ch.rds"))
write_csv(lc_ch, here::here("data", "lc_ch.csv"))


#---extract dem and aggregate to 1km resolution---

dem <- rast(here::here("data-raw/elev", "SRTMGL1_NC.003_30m_aid0001.nc"))

#resample dem to lst grid
dem_1km <- resample(dem, lst_ref, method = "bilinear")

#convert dem
dem_ch <- as.data.frame(dem_1km, xy = TRUE) |>
  as_tibble() |>
  rename(lon = x, lat = y, elevation = 3)

#save the original resolution as .tif
writeRaster(dem, here::here("data", "dem_30m.tif"), overwrite = TRUE)

#save as .rds and .csv
saveRDS(dem_ch, here::here("data", "dem_ch.rds"))
write_csv(dem_ch, here::here("data", "dem_ch.csv"))


#---extract d2m data and aggregate to 1km resolution---
d2m_dir <- here::here("data-raw/d2m")

d2m_files <- list.files(d2m_dir, full.names = TRUE)

times <- ReadNetCDF(d2m_files[1], out = "vars")

bbox <- ext(6.0, 7.5, 46.4, 47.1)

d2m_all <- map(d2m_files, \(f) {
  r <- rast(f, "mean_d2m")
  r_crop <- crop(r, bbox)

  # get dates from layer names or construct from file year
  year <- stringr::str_extract(f, "\\d{4}")
  n_layers <- nlyr(r_crop)
  dates <- as.Date(paste0(year, "-01-01")) + 0:(n_layers - 1)

  df <- as.data.frame(r_crop, xy = TRUE) |>
    tibble::as_tibble()

  # set column names to actual dates before pivoting
  names(df)[3:ncol(df)] <- as.character(dates)

  df |>
    tidyr::pivot_longer(
      cols      = -c(x, y),
      names_to  = "date",
      values_to = "mean_d2m"
    ) |>
    dplyr::mutate(date = as.Date(date)) |>
    dplyr::rename(lon = x, lat = y)
}) |>
  list_rbind() |>
  dplyr::filter(month(date) %in% c(6, 7, 8, 9))

glimpse(d2m_all)

# check whether all dates are in the data (should be 610)
n_distinct(d2m_all$date)

# resample d2m to lst grid
d2m_jjas_181920_ch <- d2m_all |>
  dplyr::filter(year(date) %in% c(2018, 2019, 2020))|>
  resample_to_lst_grid(mean_d2m, lst_ref)

glimpse(d2m_jjas_181920_ch)

# save as .rds and .csv
saveRDS(d2m_jjas_181920_ch, here::here("data", "d2m_jjas_181920_ch.rds"))
write_csv(d2m_jjas_181920_ch, here::here("data", "d2m_jjas_181920_ch.csv"))

# 2010 and 2015 for cross-validation of the model
d2m_jjas_1015_ch <- d2m_all |> dplyr::filter(year(date) %in% c(2010, 2015)) |>
resample_to_lst_grid(mean_d2m, lst_ref)

glimpse(d2m_jjas_1015_ch)

# save as .rds and .csv
saveRDS(d2m_jjas_1015_ch, here::here("data", "d2m_jjas_1015_ch.rds"))
write_csv(d2m_jjas_1015_ch, here::here("data", "d2m_jjas_1015_ch.csv"))




library(metR)
library(tidyverse)
library(lubridate)
library(raster)
library(ggplot2)
library(ncdf4)

#---extract lst data---

lst_dir <- "/data_2/scratch/jlanz/fLST/data-raw/lst"

lst_files <- list.files(lst_dir, pattern = "MOD11A1.*\\.nc$", full.names = TRUE)

lst_all <- map(lst_files, \(f) {
  ReadNetCDF(f, vars = "LST_Day_1km") |>
    as_tibble()
}) |>
  list_rbind()

# MOD11A1 LST is scaled: multiply by 0.02 to get Kelvin, then convert to Celsius
lst_jjas_181920_ch <- lst_all |>
  rename(datetime = time,
         lst_raw  = LST_Day_1km) |>
  mutate(
    datetime = as_datetime(datetime),
    lst_kelvin  = lst_raw * 0.02,
    lst_celsius = lst_kelvin - 273.15,
    lst_raw = NULL           # drop raw scaled integer
  ) |>
  mutate(lat = round(lat, 2),
         lon = round(lon, 2)) |>
  filter(
    lat >= 46.4, lat <= 47.2,
    month(datetime) %in% c(6, 7, 8, 9),
    year(datetime)  %in% c(2018, 2019, 2020)
  )

glimpse(lst_jjas_181920_ch) #to have an overview

lst_jjas_181920_ch |> summarise(across(everything(), ~mean(is.na(.)) * 100)) # to know how many NAs are there

#save as .rds and .csv
saveRDS(lst_jjas_181920_ch, "/data_2/scratch/jlanz/fLST/data/lst_jjas_181920_ch.rds")
write_csv(lst_jjas_181920_ch, "/data_2/scratch/jlanz/fLST/data/lst_jjas_181920_ch.csv")


#---extract lc data and disaggregate to 1km---

lc_rast <- rast("/data_2/scratch/jlanz/fLST/data-raw/lc/MCD12Q1.061_500m_aid0001.nc",
                subds = "LC_Type1")

lst_ref <- rast(lst_files[1], subds = "LST_Day_1km")

# Resample lc to match LST grid exactly
lc_1km <- resample(lc_rast, lst_ref, method = "near")  # nearest neighbour for categorical

lc_jjas_181920_ch <- as.data.frame(lc_1km, xy = TRUE) |>
  as_tibble() |>
  rename(lon = x, lat = y, land_cover = LC_Type1) |>
  mutate(lat = round(lat, 2),
         lon = round(lon, 2))

glimpse(lc_jjas_181920_ch)

#save as .rds and .csv
saveRDS(lc_jjas_181920_ch, "/data_2/scratch/jlanz/fLST/data/lc_jjas_181920_ch.rds")
write_csv(lc_jjas_181920_ch, "/data_2/scratch/jlanz/fLST/data/lc_jjas_181920_ch.csv")


#---extract dem and aggregate to 1km resolution---

dem <- rast("/data_2/scratch/jlanz/fLST/data-raw/elev/SRTMGL1_NC.003_30m_aid0001.nc")

# aggregate to 1km: 1000m / 30m ≈ 33.3, so fact=33
dem_1km <- aggregate(dem, fact = 33, fun = "mean")

lst_ref <- rast(lst_files[1], subds = "LST_Day_1km")

dem_resampled <- resample(dem_1km, lst_ref, method = "bilinear")

dem_ch <- as.data.frame(dem_1km, xy = TRUE) |>
  as_tibble() |>
  rename(lon = x, lat = y) |>
  mutate(lat = round(lat, 2),
         lon = round(lon, 2))

#save as .rds and .csv
saveRDS(dem_ch, "/data_2/scratch/jlanz/fLST/data/dem_ch.rds")
write_csv(dem_ch, "/data_2/scratch/jlanz/fLST/data/dem_ch.csv")

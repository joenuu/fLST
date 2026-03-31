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
  rename(lst_raw  = LST_Day_1km) |>
  mutate(
    date = as_date(time),
    lst_kelvin  = lst_raw * 0.02,
    lst_celsius = lst_kelvin - 273.15,
    lst_raw = NULL           # drop raw scaled integer
  )
  filter(
    lat >= 46.4, lat <= 47.1,
    month(date) %in% c(6, 7, 8, 9),
    year(date)  %in% c(2018, 2019, 2020)
  )

glimpse(lst_jjas_181920_ch) #to have an overview

lst_jjas_181920_ch |> summarise(across(everything(), ~mean(is.na(.)) * 100)) # to know how many NAs are there

#save as .rds and .csv
saveRDS(lst_jjas_181920_ch, "/data_2/scratch/jlanz/fLST/data/lst_jjas_181920_ch.rds")
write_csv(lst_jjas_181920_ch, "/data_2/scratch/jlanz/fLST/data/lst_jjas_181920_ch.csv")


#---extract lc data and disaggregate to 1km---

lc <- rast("/data_2/scratch/jlanz/fLST/data-raw/lc/MCD12Q1.061_500m_aid0001.nc")
sds(lst_jjas_181920_ch[1])

lst_ref <- rast(lst_files[1], subds = "LST_Day_1km")

# resample lc to lst grid
lc_1km <- resample(lc, lst_ref, method = "near")

# Convert using exact cell coordinates from the LST reference grid
lc_ch <- as.data.frame(lc_1km, xy = TRUE) |>
  as_tibble() |>
  rename(lon = x, lat = y, land_cover_type = 3)

glimpse(lc_ch)

#save as .rds and .csv
saveRDS(lc_ch, "/data_2/scratch/jlanz/fLST/data/lc_ch.rds")
write_csv(lc_ch, "/data_2/scratch/jlanz/fLST/data/lc_ch.csv")


#---extract dem and aggregate to 1km resolution---

dem <- rast("/data_2/scratch/jlanz/fLST/data-raw/elev/SRTMGL1_NC.003_30m_aid0001.nc")

lst_ref <- rast(lst_files[1], subds = "LST_Day_1km")

# resample dem to lst grid
dem_1km <- resample(dem, lst_ref, method = "bilinear")

# convert dem
dem_ch <- as.data.frame(dem_1km, xy = TRUE) |>
  as_tibble() |>
  rename(lon = x, lat = y, elevation = 3)

#save as .rds and .csv
saveRDS(dem_ch, "/data_2/scratch/jlanz/fLST/data/dem_ch.rds")
write_csv(dem_ch, "/data_2/scratch/jlanz/fLST/data/dem_ch.csv")

res(lst_ref)
res(dem_resampled)
res(lc_1km)
ext(lst_ref)
ext(dem_resampled)
ext(lc_1km)

origin(lst_ref)
origin(dem_resampled)
origin(lc_1km)

library(terra)
library(metR)
library(tidyverse)
library(lubridate)
library(raster)
library(ggplot2)
library(ncdf4)
library(here)
source("")


# load data
rin <- rast("/data_2/scratch/ting/veg_topo_data/data/global_sw_in_450m/topographic_radiation_index_450m.tif")

lst_ref <- readRDS(here::here("data", "lst_ref.rds"))

# define bounding box
bbox <- ext(6.0, 7.5, 46.4, 47.1)  # xmin, xmax, ymin, ymax

# crop to bounding box
rin_cropped <- crop(rin, bbox)

# aggregate to 1km resolution and rename lon, lat and rin
rin_ch <- rin_cropped |>
  resample(lst_ref, method = "bilinear") |>
  as.data.frame(xy = TRUE) |>
  tibble::as_tibble() |>
  dplyr::rename(lon = x, lat = y, rin = 3)

glimpse(rin_ch)

# save as .rds and .csv
saveRDS(rin_ch, here::here("data", "rin_ch.rds"))
write_csv(rin_ch, here::here("data", "rin_ch.csv"))





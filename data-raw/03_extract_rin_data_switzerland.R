library(terra)
library(metR)
library(tidyverse)
library(lubridate)
library(raster)
library(ggplot2)
library(ncdf4)


rin <- rast("/data_2/scratch/ting/veg_topo_data/data/global_sw_in_450m/topographic_radiation_index_450m.tif")

# define bounding box
bbox <- ext(6.0, 7.5, 46.4, 47.1)  # xmin, xmax, ymin, ymax

# crop to bounding box
rin_cropped <- crop(rin, bbox)

# convert to dataframe with coordinates
rin_values <- as.data.frame(rin_cropped, xy = TRUE) |>
  tibble::as_tibble() |>
  dplyr::rename(lon = x, lat = y, tri = 3)

glimpse(rin_values)

rin_ch <- rin_1km <- resample(rin, template, method = "near")






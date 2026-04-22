library(metR)
library(tidyverse)
library(lubridate)
library(raster)
library(ggplot2)
library(ncdf4)

#---extract ndvi data---

ndvi_dir <- "/data_2/scratch/jlanz/fLST/data-raw/ndvi"

ndvi_files <- list.files(ndvi_dir, pattern = "MOD13A2.*\\.nc$", full.names = TRUE)

ndvi_all <- map(ndvi_files, \(f) {
  ReadNetCDF(f, vars = "_1_km_16_days_NDVI") |>
    as_tibble()
}) |>
  list_rbind()

ndvi_jjas_181920_ch <- ndvi_all |>
  rename(ndvi  = `_1_km_16_days_NDVI`) |>
  mutate(date = as_date(time)) |>
  filter(
    lat >= 46.4, lat <= 47.1,
    month(date) %in% c(6, 7, 8, 9),
    year(date)  %in% c(2018, 2019, 2020)
  )

glimpse(ndvi_jjas_181920_ch) #to have an overview

ndvi_jjas_181920_ch |> summarise(across(everything(), ~mean(is.na(.)) * 100)) # to know how many NAs are there

#save as .rds and .csv
saveRDS(ndvi_jjas_181920_ch, "/data_2/scratch/jlanz/fLST/data/ndvi_jjas_181920_ch.rds")
write_csv(ndvi_jjas_181920_ch, "/data_2/scratch/jlanz/fLST/data/ndvi_jjas_181920_ch.csv")



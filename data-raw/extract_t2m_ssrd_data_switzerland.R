#extract ssrd, t2m and pcwd data for western switzerland
#for june, july, august and september of 2018, 2019 and 2020

#load packages
library(terra)
library(dplyr)
library(patchwork)
library(scico)
library(raster)
library(tidymodels)
library(rnaturalearth)
library(rnaturalearthdata)
library(sf)
library(purrr)
library(lubridate)
library(tidyterra)
library(ggplot2)
library(ncdf4)
library(metR)
library(tidyverse)
library(lubridate)

#---extract the ssrd for switzerland---

ssrd_dir <- "/data_2/scratch/jlanz/fLST/data-raw/ssrd"

ssrd_files <- list.files(ssrd_dir, pattern = "ERA5Land_UTCDaily_tot_ssrd.*\\.rds$",
                         full.names = TRUE)

ssrd_all <- map(ssrd_files, \(f) {
  readRDS(f) |> as_tibble()
}) |>
  list_rbind()

ssrd_ch <- ssrd_all |>
  filter(lat >= 46.4, lat <= 47.1) |>
  unnest(data)

glimpse(ssrd_ch)

ssrd_jjas_181920_ch <- ssrd_ch |>
  mutate(date = as_date(datetime)) |>
  filter(
    month(datetime) %in% c(6, 7, 8, 9),
    year(datetime)  %in% c(2018, 2019, 2020)
  ) |>
  select(-datetime)

glimpse(ssrd_jjas_181920_ch)

#save as .rds and as .csv
saveRDS(ssrd_jjas_181920_ch, "/data_2/scratch/jlanz/fLST/data/ssrd_jjas_181920_ch.rds")
write_csv(ssrd_jjas_181920_ch, "/data_2/scratch/jlanz/fLST/data/ssrd_jjas_181920_ch.csv")

#---do the same now for t2m---
t2m_dir <- "/data_2/scratch/jlanz/fLST/data-raw/t2m"

t2m_files <- list.files(t2m_dir, pattern = "ERA5Land_UTCDaily_mean_t2m.*\\.rds$",
                         full.names = TRUE)

t2m_all <- map(t2m_files, \(f) {
  readRDS(f) |> as_tibble()
}) |>
  list_rbind()

glimpse(t2m_all)

t2m_ch <- t2m_all |>
  filter(lat >= 46.4, lat <= 47.1) |>
  unnest(data)

glimpse(t2m_ch)

t2m_jjas_181920_ch <- t2m_ch |>
  mutate(date = as_date(datetime)) |>
  filter(
    month(datetime) %in% c(6, 7, 8, 9),
    year(datetime)  %in% c(2018, 2019, 2020)
  ) |>
  select(-datetime)

glimpse(t2m_jjas_181920_ch)

#save as .rds and .csv
saveRDS(t2m_jjas_181920_ch, "/data_2/scratch/jlanz/fLST/data/t2m_jjas_181920_ch.rds")
write_csv(t2m_jjas_181920_ch, "/data_2/scratch/jlanz/fLST/data/t2m_jjas_181920_ch.csv")

#---do the same now with pcwd---

pcwd_dir <- "/data_2/scratch/jlanz/fLST/data-raw/pcwd"

pcwd_files <- list.files(pcwd_dir, pattern = "ERA5Land_pcwd.*\\.rds$",
                         full.names = TRUE)

pcwd_all <- map(pcwd_files, \(f) {
  readRDS(f) |> as_tibble()
}) |>
  list_rbind()

pcwd_ch <- pcwd_all |>
  filter(lat >= 46.4, lat <= 47.1)


glimpse(pcwd_ch)

pcwd_jjas_181920_ch <- pcwd_ch |>
  select(-year) |>
  filter(
    month(date) %in% c(6, 7, 8, 9),
    year(date)  %in% c(2018, 2019, 2020)
  )


glimpse(pcwd_jjas_181920_ch)

#save as .rds and as .csv
saveRDS(pcwd_jjas_181920_ch, "/data_2/scratch/jlanz/fLST/data/pcwd_jjas_181920_ch.rds")
write_csv(pcwd_jjas_181920_ch, "/data_2/scratch/jlanz/fLST/data/pcwd_jjas_181920_ch.csv")

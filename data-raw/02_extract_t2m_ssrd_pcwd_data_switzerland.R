library(terra)
library(dplyr)
library(patchwork)
library(scico)
library(tidymodels)
library(rnaturalearth)
library(rnaturalearthdata)
library(sf)
library(purrr)
library(lubridate)
library(tidyterra)
library(ggplot2)
library(ncdf4)
library(tidyverse)
library(here)
source(here::here("R", "get_resampled_grid.R"))

#---extract ssrd data---

ssrd_files <- list.files(
  "/data_2/scratch/jlanz/fLST/data-raw/ssrd",
  pattern = "ERA5Land_UTCDaily_tot_ssrd.*\\.rds$",
  full.names = TRUE
)

ssrd_jjas_181920_ch <- map(ssrd_files, \(f) readRDS(f) |> as_tibble()) |>
  list_rbind() |>
  filter(lat >= 46.4, lat <= 47.1) |>
  unnest(data) |>
  mutate(date = as_date(datetime)) |>
  filter(month(date) %in% c(6, 7, 8, 9),
         year(date)  %in% c(2018, 2019, 2020)) |>
  select(-datetime) |>
  resample_to_lst_grid(tot_ssrd, lst_ref)

glimpse(ssrd_jjas_181920_ch)

saveRDS(ssrd_jjas_181920_ch, here::here("data", "ssrd_jjas_181920_ch.rds"))
write_csv(ssrd_jjas_181920_ch, here::here("data", "ssrd_jjas_181920_ch.csv"))


#---extract t2m data---

t2m_files <- list.files(
  "/data_2/scratch/jlanz/fLST/data-raw/t2m",
  pattern = "ERA5Land_UTCDaily_mean_t2m.*\\.rds$",
  full.names = TRUE
)

t2m_jjas_181920_ch <- map(t2m_files, \(f) readRDS(f) |> as_tibble()) |>
  list_rbind() |>
  filter(lat >= 46.4, lat <= 47.1) |>
  unnest(data) |>
  mutate(date = as_date(datetime)) |>
  filter(month(date) %in% c(6, 7, 8, 9),
         year(date)  %in% c(2018, 2019, 2020)) |>
  select(-datetime) |>
  resample_to_lst_grid(mean_t2m, lst_ref)

glimpse(t2m_jjas_181920_ch)

saveRDS(t2m_jjas_181920_ch, here::here("data", "t2m_jjas_181920_ch.rds"))
write_csv(t2m_jjas_181920_ch, here::here("data", "t2m_jjas_181920_ch.csv"))


#---extract pcwd data---

pcwd_files <- list.files(
  "/data_2/scratch/jlanz/fLST/data-raw/pcwd",
  pattern = "ERA5Land_pcwd.*\\.rds$",
  full.names = TRUE
)

pcwd_jjas_181920_ch <- map(pcwd_files, \(f) readRDS(f) |> as_tibble()) |>
  list_rbind() |>
  filter(lat >= 46.4, lat <= 47.1) |>
  select(-any_of("year")) |>
  filter(month(date) %in% c(6, 7, 8, 9),
         year(date)  %in% c(2018, 2019, 2020)) |>
  resample_to_lst_grid(pcwd_mm, lst_ref)

glimpse(pcwd_jjas_181920_ch)

saveRDS(pcwd_jjas_181920_ch, here::here("data", "pcwd_jjas_181920_ch.rds"))
write_csv(pcwd_jjas_181920_ch, here::here("data", "pcwd_jjas_181920_ch.csv"))

library(tidyverse)
library(lubridate)
library(here)
library(readr)
library(dplyr)

# ---prepare the data such that it can be processed in the model---

# load data
lst_data       <- readRDS(here::here("data", "lst_jjas_181920_ch.rds"))
elevation_data <- readRDS(here::here("data", "dem_ch.rds"))
landcover_data <- readRDS(here::here("data", "lc_ch.rds"))
rin_data       <- readRDS(here::here("data", "rin_ch.rds"))
ssrd_data      <- readRDS(here::here("data", "ssrd_jjas_181920_ch.rds"))
t2m_data       <- readRDS(here::here("data", "t2m_jjas_181920_ch.rds"))
pcwd_data      <- readRDS(here::here("data", "pcwd_jjas_181920_ch.rds"))
d2m_data       <- readRDS(here::here("data", "d2m_jjas_181920_ch.rds"))

glimpse(d2m_data)

elevation_data |> count(lat, lon) |> filter(n > 1) # to check if data is ok
landcover_data |> count(lat, lon) |> filter(n > 1)

# a function to round coordinates to avoid NAs because of different decimal places
round_coords <- function(df, digits = 4) {
  df |> mutate(lat = round(lat, digits),
               lon = round(lon, digits))
}

# join all data into one tibble
model_data <- lst_data |>
  round_coords() |>
  left_join(elevation_data |> round_coords(),  by = c("lat", "lon"),
            relationship = "many-to-one") |>
  left_join(landcover_data |> round_coords(),  by = c("lat", "lon"),
            relationship = "many-to-one") |>
  left_join(rin_data |> round_coords(),        by = c("lat", "lon"),
            relationship = "many-to-one")  |>
  left_join(ssrd_data |> round_coords(),       by = c("lat", "lon", "date")) |>
  left_join(t2m_data |> round_coords(),        by = c("lat", "lon", "date")) |>
  left_join(pcwd_data |> round_coords(),       by = c("lat", "lon", "date")) |>
  left_join(d2m_data |> round_coords(),        by = c("lat", "lon", "date")) |>
  mutate(
    doy  = yday(date),
    year = factor(year(date))
  )

glimpse(model_data)

model_data_clean <- model_data |> # not sure if this step is still necessary
  filter(!is.na(elevation),
         !is.na(tot_ssrd))

glimpse(model_data_clean)


saveRDS(model_data_clean, here::here("data", "model_data_clean.rds"))
write_csv(model_data_clean, here::here("data", "model_data_clean.csv"))

# ---prepare the data for model cross-validation---

# load data
lst_val_data <- readRDS(here::here("data", "lst_jjas_1015_ch.rds"))
ssrd_val_data <- readRDS(here::here("data", "ssrd_jjas_1015_ch.rds"))
t2m_val_data <- readRDS(here::here("data", "t2m_jjas_1015_ch.rds"))
d2m_val_data <- readRDS(here::here("data", "d2m_jjas_1015_ch.rds"))
pcwd_val_data <- readRDS(here::here("data", "pcwd_jjas_1015_ch.rds"))

# join all data into one tibble
validation_data <- lst_val_data |>
  round_coords() |>
  left_join(elevation_data |> round_coords(),  by = c("lat", "lon"),
            relationship = "many-to-one") |>
  left_join(landcover_data |> round_coords(),  by = c("lat", "lon"),
            relationship = "many-to-one") |>
  left_join(rin_data |> round_coords(),        by = c("lat", "lon"),
            relationship = "many-to-one")  |>
  left_join(ssrd_val_data |> round_coords(),       by = c("lat", "lon", "date")) |>
  left_join(t2m_val_data |> round_coords(),        by = c("lat", "lon", "date")) |>
  left_join(pcwd_val_data |> round_coords(),       by = c("lat", "lon", "date")) |>
  left_join(d2m_val_data |> round_coords(),        by = c("lat", "lon", "date")) |>
  mutate(
    doy  = yday(date),
    year = factor(year(date))
  )

validation_data_clean <- validation_data |>
  filter(!is.na(elevation),
         !is.na(tot_ssrd))

glimpse(validation_data_clean)

saveRDS(validation_data_clean, here::here("data", "validation_data_clean.rds"))
write_csv(validation_data_clean, here::here("data", "validation_data_clean.csv"))

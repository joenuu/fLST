
library(ggplot2)
library(here)
library(scico)
library(lubridate)
source(here::here("R", "get_lst_plot.R"))
source(here::here("R", "get_stats_label.R")) # is executed inside get_lst_plot

# load data
model_data_clean <- readRDS(here::here("data", "model_data_clean.rds")) |>
  filter(!land_cover_type %in% c(11,17))
spatial_predictions_lst <- readRDS(here::here("data", "spatial_predictions_lst.rds"))

# get dry days
all_predictions_lst <- model_data_clean |>
  filter(!is.na(lst_kelvin)) |>
  dplyr::select(lat, lon, date, pcwd_mm) |>
  right_join(spatial_predictions_lst, by = c("lat", "lon", "date"))

dry_days <- all_predictions_lst |>
  group_by(date) |>
  summarise(mean_pcwd = mean(pcwd_mm, na.rm = TRUE)) |>
  filter(mean_pcwd > pcwd_threshold) |>
  pull(date)

dry_predictions_lst <- all_predictions_lst |>
  filter(date %in% dry_days)

moist_predictions_lst <- all_predictions_lst |>
  filter(!date %in% dry_days)

saveRDS(dry_predictions_lst, here::here("data", "dry_predictions_lst.rds"))
saveRDS(moist_predictions_lst, here::here("data", "moist_predictions_lst.rds"))









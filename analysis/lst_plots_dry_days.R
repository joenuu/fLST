library(ggplot2)
library(here)
library(scico)
source(here::here("R", "get_lst_plot.R"))
source(here::here("R", "get_stats_label.R")) # is executed inside get_lst_plot

# load data
model_data_clean <- readRDS(here::here("data", "model_data_clean.rds"))
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

dry_predictions_lst |>
  filter(land_cover_type != 17) |>
  group_by(lat, lon) |>
  summarise(mean_delta = mean(lst_delta_smooth, na.rm = TRUE)) |>
  ggplot(aes(x = lon, y = lat, fill = mean_delta)) +
  geom_raster() +
  scale_fill_scico(palette = "vik", midpoint = 0, na.value = "grey90") +
  coord_equal() +
  labs(title = "Mean ΔLST on dry days (LSTact − LSTpot)",
       fill = "ΔT") +
  theme_minimal()

all_predictions_lst |>
  filter(date == "2018-09-20") |>
  ggplot(aes(x = lon, y = lat, fill = lst_delta)) +
  geom_raster() +
  scale_fill_scico(palette = "vik", midpoint = 0, na.value = "grey90") +
  coord_equal() +
  facet_wrap(~date, ncol = 4) +
  labs(title = "ΔLST (LSTact − LSTpot)",
       fill = "ΔT") +
  theme_minimal()

unique(dry_predictions_lst$date) |> sort()

dry_predictions_lst |>
 mutate(sign = ifelse(lst_delta_smooth < 0, "negative", "positive")) |>
 ggplot(aes(x = elevation, y = lst_delta, colour = sign)) +
 geom_point(alpha = 0.1, size = 0.3) +
 geom_hline(yintercept = 0, linetype = "dashed") +
 facet_wrap(~land_cover_type) +
  theme_minimal()

saveRDS(dry_predictions_lst, here::here("data", "dry_predictions_lst.rds"))

#---plotting LSTobs vs LSTpot---
all_plot_obs <- make_lst_plot(all_predictions_lst,
                          obs_col  = "lst_kelvin",
                          pred_col = "lst_predicted",
                          title_label = "All days",
                          obs_label = "Observed LST [K]",
                          pred_label = "Potential LST [K]")

moist_plot_obs <- make_lst_plot(all_predictions_lst |> filter(date %in% wet_days),
                            obs_col  = "lst_kelvin",
                            pred_col = "lst_predicted",
                            title_label = "\"Moist\" days",
                            obs_label = "Observed LST [K]",
                            pred_label = "Potential LST [K]")

dry_plot_obs <- make_lst_plot(dry_predictions_lst,
                          obs_col = "lst_kelvin",
                          pred_col = "lst_predicted",
                          title_label = "\"Dry\" days",
                          obs_label = "Observed LST [K]",
                          pred_label = "Potential LST [K]")


# --- combine ---
combined_lst_comparison_obs <- plot_grid(
  all_plot_obs, moist_plot_obs, dry_plot_obs,
  ncol = 2,
  labels = c("(a)", "(b)", "(c)"),
  label_size = 11,
  label_fontface = "plain",
  rel_widths = c(1, 1, 1))

combined_lst_comparison_obs


#---plotting LSTact vs LSTpot---
all_plot_act <- make_lst_plot(all_predictions_lst,
                              obs_col  = "lst_act",
                              pred_col = "lst_predicted",
                              title_label = "All days",
                              obs_label = "Actual LST [K]",
                              pred_label = "Potential LST [K]")

moist_plot_act <- make_lst_plot(all_predictions_lst |> filter(date %in% wet_days),
                                obs_col  = "lst_act",
                                pred_col = "lst_predicted",
                                title_label = "\"Moist\" days",
                                obs_label = "Actual LST [K]",
                                pred_label = "Potential LST [K]")

dry_plot_act <- make_lst_plot(dry_predictions_lst,
                              obs_col = "lst_act",
                              pred_col = "lst_predicted",
                              title_label = "\"Dry\" days",
                              obs_label = "Actual LST [K]",
                              pred_label = "Potential LST [K]")


# combine
combined_lst_comparison_act <- plot_grid(
  all_plot_act, moist_plot_act, dry_plot_act,
  ncol = 2,
  labels = c("(a)", "(b)", "(c)"),
  label_size = 11,
  label_fontface = "plain",
  rel_widths = c(1, 1, 1))

combined_lst_comparison_act


# --- time series of DeltaLST on the dryest pixel ---
spatial_predictions |>
  dplyr::filter(year(date) == 2018) |>
  dplyr::summarise(
    lat_match = any(round(lat, 1) == 46.9),
    lon_match = any(round(lon, 2) == 6.35)
  )

spatial_predictions |>
  dplyr::filter(round(lat, 1) == 46.9, round(lon, 2) == 6.35, year(date) == 2018) |>
  nrow()  # check how many rows match


# get dryest pxel
dry_predictions |>
  group_by(lat, lon) |>
  summarise(mean_delta = mean(lst_delta_smooth, na.rm = TRUE)) |>
  ungroup() |>
  slice_max(mean_delta, n = 1)

# plot
spatial_predictions |>
  dplyr::filter(lat == 46.9, lon == 6.35, year(date) == 2018) |>
  left_join(model_data_clean |> dplyr::select(lat, lon, date, pcwd_mm),
            by = c("lat", "lon", "date")) |>
  ggplot(aes(x = date)) +
  geom_line(aes(y = lst_delta_smooth), colour = "firebrick") +
  geom_line(aes(y = pcwd_mm / 20), colour = "steelblue", linetype = "dashed") +  # scaled for dual axis
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey50") +
  scale_y_continuous(
    name = "ΔLST [K]",
    sec.axis = sec_axis(~ . * 20, name = "PCWD [mm]")
  ) +
  labs(title = "ΔLST and PCWD at highest stress pixel (2018)",
       x = "Date") +
  theme_minimal()





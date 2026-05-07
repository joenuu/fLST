# --- some plots to get an overview of the results ---
library(ggplot2)
library(here)
library(scico)
library(dplyr)
library(cowplot)

# load data
model_data_clean <- readRDS(here::here("data", "model_data_clean.rds"))
spatial_predictions_lst <- readRDS(
  here::here("data", "spatial_predictions_lst.rds"))

nrow(spatial_predictions_lst)
names(spatial_predictions_lst)

ggplot(data.frame(x = 1:10, y = 1:10), aes(x, y)) + geom_point()

# plot predicted LST vs observed LS
spatial_predictions_lst |>
  slice_sample(n = 50000) |>  # sample for speed
  ggplot(aes(x = lst_predicted, y = lst_kelvin)) +
  geom_point(alpha = 0.1, size = 0.5, colour = "grey40") +
  geom_abline(slope = 1, intercept = 0, colour = "firebrick", linewidth = 1) +
  labs(title = "Predicted vs Observed LST",
       x = "Predicted LST (K)", y = "Observed LST (K)") +
  theme_minimal()

# plot map with predicted LST for any given day
plot_1 <- spatial_predictions_lst |>
  filter(date == "2018-07-01") |>
  ggplot(aes(x = lon, y = lat, fill = lst_predicted)) +
  geom_raster() +
  scale_fill_scico(palette = "lajolla", direction = -1) +
  coord_equal() +
  labs(title = "predicted LST", fill = "LST [K]") +
  theme_minimal()

plot_1

# plot map with measured LST for any given day
plot_2 <- model_data_clean |>
  filter(date == "2018-07-01") |>
  ggplot(aes(x = lon, y = lat, fill = lst_kelvin)) +
  geom_raster() +
  scale_fill_scico(palette = "lajolla", direction = -1) +
  coord_equal() +
  labs(title = "measured LST", fill = "LST [K]") +
  theme_minimal()

plot_2

combined_plot <- plot_grid(plot_1, plot_2, ncol = 2)

combined_plot

ggdraw() +
  draw_label("Predicted vs. Measured LST – 2020-08-10",
             fontface = "bold", x = 0.5, y = 0.97, size = 14) +
  draw_plot(combined_plot, y = -0.02)

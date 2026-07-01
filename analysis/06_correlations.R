library(ggplot2)
library(here)
library(dplyr)

# This is a small script to plot the correlations of the different predictors and LST
# It serves as a test if the data is ready for processing.

# load data
model_data_clean <- readRDS(here::here("data", "model_data_clean.rds"))

plot_data <- model_data_clean |>
  select(lst_kelvin, elevation, land_cover_type, tot_ssrd, mean_t2m, doy, rin, mean_d2m) |>
  drop_na() |>
  slice_sample(n = 100000) |>
  pivot_longer(
    cols      = c(elevation, land_cover_type, tot_ssrd, mean_t2m, doy, rin, mean_d2m),
    names_to  = "predictor",
    values_to = "value"
  ) |>
  mutate(
    predictor = factor(predictor,
                       levels = c("mean_t2m", "tot_ssrd", "doy",
                                  "elevation", "land_cover_type", "rin",
                                  "mean_d2m"),
                       labels = c("Air Temperature", "Solar Radiation",
                                  "Day of Year", "Elevation", "Land Cover",
                                  "Radiation Index", "Dew Point Temperature"))
  )

# let's get a nice plot
ggplot(plot_data, aes(x = value, y = lst_kelvin)) +
  geom_point(alpha = 0.1, size = 0.5, colour = "grey40") +
  geom_smooth(method = "lm", colour = "firebrick", linewidth = 1) +
  facet_wrap(~ predictor, scales = "free_x", ncol = 2) +
  labs(title = "LST vs each predictor", x = NULL, y = "LST") +
  theme_minimal(base_size = 13) +
  theme(
    strip.text = element_text(face = "bold"),
    panel.grid = element_blank(),
    axis.line  = element_line(colour = "grey80")
  )


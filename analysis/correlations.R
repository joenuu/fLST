library(tidyverse)
library(lubridate)
library(ggplot2)




glimpse(lst_data)

setwd("/data_2/scratch/jlanz/fLST/data/")

lst_data       <- readRDS("lst_jjas_181920_ch.rds")
elevation_data <- readRDS("dem_ch.rds")
landcover_data <- readRDS("lc_ch.rds")
ssrd_data      <- readRDS("ssrd_jjas_181920_ch.rds")
t2m_data       <- readRDS("t2m_jjas_181920_ch.rds")

elevation_data |> count(lat, lon) |> filter(n > 1)
landcover_data |> count(lat, lon) |> filter(n > 1)

model_data <- lst_data |>
  left_join(elevation_data,  by = c("lat", "lon"),
            relationship = "many-to-one") |>
  left_join(landcover_data,  by = c("lat", "lon"),
            relationship = "many-to-one") |>
  left_join(ssrd_data,       by = c("lat", "lon", "date")) |>
  left_join(t2m_data,        by = c("lat", "lon", "date")) |>
  mutate(
    doy  = yday(date),
    year = factor(year(date))
  )

glimpse(model_data)

plot_data <- model_data |>
  select(lst_kelvin, elevation, land_cover_type, tot_ssrd, mean_t2m, doy) |>
  drop_na() |>
  slice_sample(n = 100000) |>
  pivot_longer(
    cols      = c(elevation, land_cover_type, tot_ssrd, mean_t2m, doy),
    names_to  = "predictor",
    values_to = "value"
  ) |>
  mutate(
    predictor = factor(predictor,
                       levels = c("mean_t2m", "tot_ssrd", "doy",
                                  "elevation", "land_cover_type"),
                       labels = c("Air Temperature", "Solar Radiation",
                                  "Day of Year", "Elevation", "Land Cover"))
  )

ggplot(plot_data, aes(x = value, y = lst_kelvin)) +
  geom_point(alpha = 0.1, size = 0.5, colour = "grey40") +
  geom_smooth(method = "lm", colour = "firebrick", linewidth = 1) +
  facet_wrap(~ predictor, scales = "free_x", ncol = 2) +
  labs(title = "LST vs each predictor", x = NULL, y = "LST (K)") +
  theme_minimal(base_size = 13) +
  theme(
    strip.text = element_text(face = "bold"),
    panel.grid = element_blank(),
    axis.line  = element_line(colour = "grey80")
  )


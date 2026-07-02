# ---physical validation: check correlation with ndvi---

library(ggplot2)
library(here)
library(scico)

# load data
ndvi_jjas_181920_ch <- readRDS(here::here("data", "ndvi_jjas_181920_ch.rds"))
dry_predictions_lst <- readRDS(here::here("data", "dry_predictions_lst.rds"))

dry_predictions_lst_ndvi <- dry_predictions_lst |>
  left_join(
    ndvi_jjas_181920_ch |> mutate(lat = round(lat, 4), lon = round(lon, 4)),
    by = c("lat", "lon", "date")
  )

lc_names <- c(
  "1"  = "Coniferous Forest",
  "4"  = "Deciduous Forest",
  "5"  = "Mixed Forest",
  "8"  = "Woody Savanna",
  "9"  = "Savanna",
  "10" = "Grassland",
  "11" = "Permanent Wetland", # this should maybe be masked
  "12" = "Cropland",
  "13" = "Urban and Built-up Land",
  "14" = "Cropland & Natural Vegetation",
  "16" = "Sand, Rock, Soil",
  "17" = "Water Bodies" # this should maybe be masked
)

dry_predictions_lst_ndvi |>
  mutate(land_cover_name = lc_names[as.character(land_cover_type)]) |>
  ggplot(aes(x = ndvi, y = lst_delta_smooth)) +
  geom_point(alpha = 0.1, size = 0.3, colour = "grey40") +
  geom_smooth(method = "lm", colour = "firebrick") +
  geom_hline(yintercept = 0, linetype = "dashed") +
  facet_wrap(~land_cover_name) +
  labs(title = "NDVI vs ΔLST by land cover type",
       x = "NDVI", y = "ΔLST [K]") +
  theme_minimal()

dry_predictions_lst_ndvi |>
  ggplot(aes(x = ndvi, y = lst_delta_smooth)) +
  geom_point(alpha = 0.1, size = 0.3, colour = "grey40") +
  geom_smooth(method = "lm", colour = "firebrick") +
  geom_hline(yintercept = 0, linetype = "dashed") +
  coord_cartesian(ylim = c(-10, 10)) +
  labs(title = "NDVI vs ΔLST",
       x = "NDVI", y = "ΔLST [K]") +
  theme_minimal()

# => results are physically consistent with an independent vegetation stress indicator




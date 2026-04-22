library(tidymodels)
library(ranger)
library(ggplot2)
library(cowplot)
library(scico)
library(MASS)
source(here::here("R", "get_pcwd_plot.R"))
source(here::here("R", "get_lst_plot"))
source(here::here("R", "get_stats_label.R")) # is executed inside get_lst_plot


# read data
model_data_clean <- readRDS(here::here("data", "model_data_clean.rds"))

glimpse(model_data_clean)

#---first: get rid of "dry" days, i.e. days above a certain threshold---

# plot pcwd data for visualization (also later in Rmd file)
pcwd_plot <- get_pcwd_plot(here::here("data", "pcwd_jjas_181920_ch.rds"))
pcwd_plot

# define threshold at the local minimum
pcwd_threshold <- 55 # keep in mind that this threshold might eventually change

pcwd_plot +
  geom_vline(xintercept = pcwd_threshold, colour = "firebrick",
             linetype = "dashed", linewidth = 0.8) +
  annotate("text", x = pcwd_threshold - 5, y = Inf,
           label = "\"wet\" days", colour = "firebrick",
           hjust = 1, vjust = 1.5) +
  annotate("text", x = pcwd_threshold + 120, y = Inf,
           label = "\"dry\" days", colour = "firebrick",
           hjust = 0, vjust = 1.5)

wet_data <- model_data_clean |>
  filter(pcwd_mm <= pcwd_threshold) |>
  select(lst_kelvin, elevation, land_cover_type, tot_ssrd, mean_t2m) |>
  mutate(land_cover_type = factor(land_cover_type)) |>
  drop_na()

glimpse(wet_data)

# range(model_data_ready$pcwd_mm) # just to check

#---random forest model training (this was done by AI)---

# 1. Train/Test split
set.seed(42)
split      <- initial_split(wet_data, prop = 0.8)
train_data <- training(split)
train_sample <- train_data |> slice_sample(n = 500000)
test_data  <- testing(split)

# 3. Recipe
rec <- recipe(lst_kelvin ~ ., data = train_sample)

# 4. Random forest model definition
rf_model <- rand_forest(
  trees = 100,       # number of trees
  mtry  = 3,         # predictors sampled per split (tune this)
  min_n = 10         # minimum node size (tune this)
) |>
  set_engine("ranger", importance = "impurity") |>  # enables variable importance
  set_mode("regression")

# 5. Workflow
rf_workflow <- workflow() |>
  add_recipe(rec) |>
  add_model(rf_model)

# 6. Train
rf_fit <- rf_workflow |> fit(data = train_sample)

# 7. Evaluate
predictions <- rf_fit |>
  predict(test_data) |>
  bind_cols(test_data)

metrics(predictions, truth = lst_kelvin, estimate = .pred)

# rebuild wet_data with spatial info for mapping
all_data_pred <- model_data_clean |>
  select(lat, lon, date, lst_kelvin, elevation, land_cover_type, tot_ssrd, mean_t2m) |>
  mutate(land_cover_type = factor(land_cover_type)) |>
  drop_na(elevation, land_cover_type, tot_ssrd, mean_t2m)

# apply trained model to spatial data
spatial_predictions <- rf_fit |>
  predict(all_data_pred) |>
  bind_cols(all_data_pred) |>
  rename(lst_predicted = .pred) |>
  mutate(lst_delta = lst_kelvin - lst_predicted)

# plot predicted LST vs observed LST
spatial_predictions |>
  slice_sample(n = 50000) |>  # sample for speed
  ggplot(aes(x = lst_predicted, y = lst_kelvin)) +
  geom_point(alpha = 0.1, size = 0.5, colour = "grey40") +
  geom_abline(slope = 1, intercept = 0, colour = "firebrick", linewidth = 1) +
  labs(title = "Predicted vs Observed LST",
       x = "Predicted LST (K)", y = "Observed LST (K)") +
  theme_minimal()

# plot map with predicted LST for any given day
plot_1 <- spatial_predictions |>
  filter(date == "2018-07-01") |>
  ggplot(aes(x = lon, y = lat, fill = lst_predicted)) +
  geom_raster() +
  scale_fill_scico(palette = "lajolla", direction = -1) +
  coord_equal() +
  labs(title = "predicted LST", fill = "LST [K]") +
  theme_minimal()

plot_1

# plot map with measured LST for any given (clear) day
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

ggdraw() +
  draw_label("Predicted vs. Measured LST – 2020-08-10",
             fontface = "bold", x = 0.5, y = 0.97, size = 14) +
  draw_plot(combined_plot, y = -0.02)


# get dry days
all_predictions <- model_data_clean |>
  filter(!is.na(lst_kelvin)) |>
  dplyr::select(lat, lon, date, pcwd_mm) |>
  right_join(spatial_predictions, by = c("lat", "lon", "date"))

dry_predictions <- all_predictions |>
  filter(pcwd_mm > pcwd_threshold)

dry_predictions |>
  group_by(lat, lon) |>
  summarise(mean_delta = mean(lst_delta, na.rm = TRUE)) |>
  ggplot(aes(x = lon, y = lat, fill = mean_delta)) +
  geom_raster() +
  scale_fill_scico(palette = "vik", midpoint = 0, na.value = "grey90") +
  coord_equal() +
  labs(title = "Mean ΔLST on dry days (LSTact − LSTpot)",
       fill = "ΔT") +
  theme_minimal()

all_predictions |>
  filter(date == "2020-09-04") |>
  ggplot(aes(x = lon, y = lat, fill = lst_delta)) +
  geom_raster() +
  scale_fill_scico(palette = "vik", midpoint = 0, na.value = "grey90") +
  coord_equal() +
  facet_wrap(~date, ncol = 4) +
  labs(title = "ΔLST (LSTact − LSTpot)",
       fill = "ΔT") +
  theme_minimal()

unique(dry_predictions$date) |> sort()

# dry_predictions |>
 # mutate(sign = ifelse(lst_delta < 0, "negative", "positive")) |>
 # ggplot(aes(x = elevation, y = lst_delta, colour = sign)) +
 # geom_point(alpha = 0.1, size = 0.3) +
  #geom_hline(yintercept = 0, linetype = "dashed") +
  #facet_wrap(~land_cover_type) +
 # theme_minimal()

#---plotting---
all_plot <- make_lst_plot(all_predictions,
                    obs_col  = "lst_kelvin",
                    pred_col = "lst_predicted",
                    title_label = "All days")

moist_plot <- make_lst_plot(all_predictions |> filter(pcwd_mm < pcwd_threshold),
                    obs_col  = "lst_kelvin",
                    pred_col = "lst_predicted",
                    title_label = "\"Moist\" days")

dry_plot <- make_lst_plot(dry_predictions,
                          obs_col = "lst_kelvin",
                          pred_col = "lst_predicted",
                          title_label = "\"Dry\" days")


# --- combine ---
combined_lst_comparison <- plot_grid(
  all_plot, moist_plot, dry_plot,
  ncol = 2,
  labels = c("(a)", "(b)", "(c)"),
  label_size = 11,
  label_fontface = "plain",
  rel_widths = c(1, 1, 1))

combined_lst_comparison

ggsave("/data_2/scratch/jlanz/fLST/data/lst_plots.png", combined_lst_comparison, width = 18, height = 14, dpi = 300)

# ---physical validation: check whether the results are physically plausible---
spatial_predictions |>
  left_join(model_data_clean |> dplyr::select(lat, lon, date, pcwd_mm),
            by = c("lat", "lon", "date")) |>
  mutate(condition = ifelse(pcwd_mm <= pcwd_threshold, "wet", "dry")) |>
  group_by(condition) |>
  summarise(mean_delta = mean(lst_delta, na.rm = TRUE))

# ---another physical validation: check correlation with ndvi---
dry_predictions_ndvi <- dry_predictions |>
  left_join(
    ndvi_jjas_181920_ch |> mutate(lat = round(lat, 4), lon = round(lon, 4)),
    by = c("lat", "lon", "date")
  )

lc_names <- c(
  "1"  = "Evergreen Needleleaf Forest",
  "4"  = "Deciduous Broadleaf Forest",
  "5"  = "Mixed Forest",
  "8"  = "Woody Savanna",
  "9"  = "Savanna",
  "10" = "Grassland",
  "11" = "Permanent Wetland",
  "12" = "Cropland",
  "13" = "Urban and Built-up Land",
  "14" = "Cropland & Natural Vegetation",
  "16" = "Sand, Rock, Soil",
  "17" = "Water Bodies"
)

dry_predictions_ndvi |>
  mutate(land_cover_name = lc_names[as.character(land_cover_type)]) |>
  slice_sample(n = 50000) |>
  ggplot(aes(x = ndvi, y = lst_delta)) +
  geom_point(alpha = 0.1, size = 0.3, colour = "grey40") +
  geom_smooth(method = "lm", colour = "firebrick") +
  geom_hline(yintercept = 0, linetype = "dashed") +
  facet_wrap(~land_cover_name) +
  labs(title = "NDVI vs ΔLST by land cover type",
       x = "NDVI", y = "ΔLST (K)") +
  theme_minimal()

# => results are physically consistent with an independent vegetation stress indicator


# ---plot deltaLST for every pcwd threshold between 0 and 300---
thresholds <- seq(0, 300, by = 5)

threshold_results <- map_dfr(thresholds, function(thresh) {
  spatial_predictions |>
    left_join(model_data_clean |> dplyr::select(lat, lon, date, pcwd_mm),
              by = c("lat", "lon", "date")) |>
    mutate(condition = ifelse(pcwd_mm <= thresh, "wet", "dry")) |>
    group_by(condition) |>
    summarise(mean_delta = mean(lst_delta, na.rm = TRUE), .groups = "drop") |>
    mutate(threshold = thresh)
})

threshold_results |>
  ggplot(aes(x = threshold, y = mean_delta, colour = condition)) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = pcwd_threshold, linetype = "dashed", colour = "grey40") +
  annotate("text", x = pcwd_threshold + 5, y = Inf,
           label = "study threshold", vjust = 1.5, hjust = 0, colour = "grey40") +
  labs(title = "Mean ΔLST by PCWD threshold",
       x = "PCWD threshold (mm)", y = "Mean ΔLST (K)",
       colour = "Condition") +
  theme_minimal()




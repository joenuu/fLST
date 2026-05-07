library(tidymodels)
library(ranger)
library(ggplot2)
library(cowplot)
library(scico)
library(MASS)
library(dplyr)
library(here)
source(here::here("R", "get_pcwd_plot.R"))

# load data
model_data_clean <- readRDS(here::here("data", "model_data_clean.rds")) |>
  filter(!land_cover_type %in% c(11,17))

validation_data_clean <- readRDS(here::here("data", "validation_data_clean.rds"))

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

# get the wet data
wet_days <- model_data_clean |>
  group_by(date) |>
  summarise(mean_pcwd = mean(pcwd_mm, na.rm = TRUE)) |>
  filter(mean_pcwd <= pcwd_threshold) |>
  pull(date)

saveRDS(wet_days, here::here("data", "wet_days.rds"))

wet_data <- model_data_clean |>
  filter(date %in% wet_days) |>
  dplyr::select(lst_kelvin, elevation, land_cover_type, tot_ssrd, mean_t2m, rin, mean_d2m) |>
  mutate(land_cover_type = factor(land_cover_type)) |>
  drop_na() |>
  filter(!land_cover_type %in% c(11,17))

glimpse(wet_data)

# for validation data
val_wet_days <- validation_data_clean |>
  group_by(date) |>
  summarise(mean_pcwd = mean(pcwd_mm, na.rm = TRUE)) |>
  filter(mean_pcwd <= pcwd_threshold) |>
  pull(date)

val_data <- validation_data_clean |>
  filter(date %in% val_wet_days) |>
  dplyr::select(lst_kelvin, elevation, land_cover_type, tot_ssrd, mean_t2m, rin, mean_d2m) |>
  mutate(land_cover_type = factor(land_cover_type)) |>
  drop_na() |>
  filter(!land_cover_type %in% c(11,17))

#---random forest model training (this was done mostly by AI)---

# split
set.seed(42) # for reproducibility
split      <- initial_split(wet_data, prop = 0.8)
train_data <- wet_data
test_data  <- testing(split)

# recipe
rec <- recipe(lst_kelvin ~ ., data = train_data)

# random forest model definition
rf_model <- rand_forest(
  trees = 100,       # number of trees
  mtry  = 3,         # predictors sampled per split (tune this)
  min_n = 10         # minimum node size (tune this)
) |>
  set_engine("ranger", importance = "impurity") |>  # enables variable importance
  set_mode("regression")

# workflow
rf_workflow <- workflow() |>
  add_recipe(rec) |>
  add_model(rf_model)

# train
rf_fit <- rf_workflow |> fit(data = train_data)

# evaluate
predictions1 <- rf_fit |>
  predict(test_data) |>
  bind_cols(test_data)

predictions2 <- rf_fit |>
  predict(val_data) |>
  bind_cols(val_data)

val_data_no_urban <- val_data |>
  filter(land_cover_type != 13)

predictions3 <- rf_fit |>
  predict(val_data_no_urban) |>
  bind_cols(val_data_no_urban)


# save model such that it can be used again without having to run it
saveRDS(rf_fit, here::here("data", "rf_fit.rds"))

# check model goodness
metrics(predictions1, truth = lst_kelvin, estimate = .pred)
metrics(predictions2, truth = lst_kelvin, estimate = .pred)
metrics(predictions3, truth = lst_kelvin, estimate = .pred)

# ---rebuild data with spatial info for mapping---
all_data_pred <- model_data_clean |>
  dplyr::select(lat, lon, date, lst_kelvin, elevation, land_cover_type, tot_ssrd,
                mean_t2m, rin, mean_d2m) |>
  mutate(land_cover_type = factor(land_cover_type)) |>
  drop_na(elevation, land_cover_type, tot_ssrd, mean_t2m, rin, mean_d2m)

# --- train a model for LSTact---
# train LSTact model on all days, with pcwd as additional predictor
all_data <- model_data_clean |>
  dplyr::select(lst_kelvin, elevation, land_cover_type, tot_ssrd,
                mean_t2m, rin, mean_d2m, pcwd_mm) |>
  mutate(land_cover_type = factor(land_cover_type)) |>
  drop_na() |>
  filter(!land_cover_type %in% c(11,17))

rec_act <- recipe(lst_kelvin ~ ., data = all_data)

set.seed(42) # for reproducibility
rf_fit_act <- workflow() |>
  add_recipe(rec_act) |>
  add_model(rf_model) |>  # reuse same rf_model definition
  fit(data = all_data)

# predict LSTact for all pixels
spatial_predictions_lst_act <- rf_fit_act |>
  predict(all_data_pred |>
            left_join(model_data_clean |>
                        dplyr::select(lat, lon, date, pcwd_mm),
                      by = c("lat", "lon", "date"))) |>
  bind_cols(all_data_pred) |>
  rename(lst_act = .pred)


# apply trained model to spatial data
spatial_predictions_lst <- rf_fit |>
  predict(all_data_pred) |>
  bind_cols(all_data_pred) |>
  rename(lst_predicted = .pred) |>
  mutate(lst_delta = lst_kelvin - lst_predicted)

# compute delta as LSTact - LSTpot
spatial_predictions_lst <- spatial_predictions_lst |>
  left_join(spatial_predictions_lst_act |>
              dplyr::select(lat, lon, date, lst_act),
            by = c("lat", "lon", "date")) |>
  mutate(lst_delta_smooth = lst_act - lst_predicted)


glimpse(spatial_predictions_lst)

# check whether lst_delta and lst_kelvin have the same NAs
mean(is.na(spatial_predictions_lst$lst_delta)) * 100
mean(is.na(spatial_predictions_lst$lst_kelvin)) * 100

saveRDS(spatial_predictions_lst, here::here("data", "spatial_predictions_lst.rds"))
write_csv(spatial_predictions_lst, here::here("data", "spatial_predictions_lst.csv"))


# ---physical validation: check whether the results are physically plausible---
day_conditions <- model_data_clean |>
  group_by(date) |>
  summarise(mean_pcwd = mean(pcwd_mm, na.rm = TRUE)) |>
  mutate(condition = ifelse(mean_pcwd <= pcwd_threshold, "wet", "dry"))

spatial_predictions_lst |>
  left_join(day_conditions, by = "date") |>
  group_by(condition) |>
  summarise(mean_delta = mean(lst_delta, na.rm = TRUE))

# --- confirm that pcwd_threshold = 55 was a good choice ---
# plot deltaLST for every pcwd threshold between 0 and 300
thresholds <- seq(0, 300, by = 5)

threshold_results <- map_dfr(thresholds, function(thresh) {
  spatial_predictions_lst |>
    left_join(model_data_clean |> dplyr::select(lat, lon, date, pcwd_mm),
              by = c("lat", "lon", "date")) |>
    mutate(condition = ifelse(pcwd_mm <= thresh, "wet", "dry")) |>
    group_by(condition) |>
    summarise(mean_delta = mean(lst_delta_smooth, na.rm = TRUE), .groups = "drop") |>
    mutate(threshold = thresh)
})

threshold_results |>
  ggplot(aes(x = threshold, y = mean_delta, colour = condition)) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = pcwd_threshold, linetype = "dashed", colour = "grey40") +
  annotate("text", x = pcwd_threshold + 5, y = Inf,
           label = "study threshold", vjust = 1.5, hjust = 0, colour = "grey40") +
  labs(title = "Mean ΔLST by PCWD threshold",
       x = "PCWD threshold [mm]", y = "Mean ΔLST [K]",
       colour = "Condition") +
  theme_minimal()







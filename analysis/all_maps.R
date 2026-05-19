library(here)
library(ggplot2)
library(scico)
library(cowplot)
library(purrr)
library(dplyr)

model_data_clean <- readRDS(here::here("data", "model_data_clean.rds"))  |>
  filter(!land_cover_type %in% c(11,17))
spatial_predictions_lst <- readRDS(here::here("data", "spatial_predictions_lst.rds"))

all_predictions_lst <- model_data_clean |>
  filter(!is.na(lst_kelvin)) |>
  dplyr::select(lat, lon, date, pcwd_mm) |>
  right_join(spatial_predictions_lst, by = c("lat", "lon", "date"))

all_predictions_lst <- all_predictions_lst |>
  left_join(model_data_clean |>
              dplyr::select(lat, lon, date, pcwd_mm) |>
              group_by(date) |>
              summarise(mean_pcwd = mean(pcwd_mm, na.rm = TRUE)),
            by = "date") |>
  mutate(condition = ifelse(mean_pcwd > pcwd_threshold, "dry", "moist"))


all_dates <- sort(unique(all_predictions_lst$date))
date_chunks <- split(all_dates, ceiling(seq_along(all_dates) / 18))

for (i in seq_along(date_chunks)) {

  plots <- map(date_chunks[[i]], \(d) {
    condition_label <- all_predictions_lst |>
      dplyr::filter(date == d) |>
      dplyr::pull(condition) |>
      unique()

    all_predictions_lst |>
      dplyr::filter(date == d) |>
      ggplot(aes(x = lon, y = lat, fill = lst_delta_smooth)) +
      geom_raster() +
      scale_fill_scico(palette = "vik", midpoint = 0, na.value = "grey90") +
      coord_equal() +
      labs(title = paste0(d, " (", condition_label, ")"), fill = "ΔT") +
      theme_minimal() +
      theme(axis.title = element_blank())
  })

  combined <- plot_grid(plotlist = plots, ncol = 3)

  ggsave(
    here::here("fig", paste0("dlst_map_", i, ".png")),
    combined,
    width = 18, height = 30, dpi = 150
  )

  message("Saved plot ", i, " of ", length(date_chunks))
}

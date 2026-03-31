# a function for resampling the lst grid
resample_to_lst_grid <- function(df, value_col, lst_ref) {
  value_col <- rlang::ensym(value_col)

  # pivot wide: one column per date
  df_wide <- df |>
    pivot_wider(names_from = date, values_from = !!value_col)

  # convert to SpatRaster (xyz format: lon, lat, values...)
  r <- rast(df_wide, type = "xyz", crs = "EPSG:4326")

  # resample to LST grid
  r_1km <- resample(r, lst_ref, method = "bilinear")

  # back to long tibble
  as.data.frame(r_1km, xy = TRUE) |>
    as_tibble() |>
    rename(lon = x, lat = y) |>
    pivot_longer(-c(lon, lat), names_to = "date", values_to = as.character(value_col)) |>
    mutate(date = as_date(date))
}

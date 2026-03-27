library(maptiles)
library(terra)
library(tidyterra)
library(ggplot2)
library(cowplot)
library(sf)

bbox <- c(xmin = 6.0, ymin = 46.4, xmax = 7.5, ymax = 47.1)
ext  <- terra::ext(bbox)

tiles <- get_tiles(
  x        = ext,
  provider = "Esri.WorldImagery",
  zoom     = 9, #to do it fast. for final version, make higher resolution, e.g. 10
  crop     = TRUE,
  project  = FALSE
)

main_map <- ggplot() +
  geom_spatraster_rgb(data = tiles) +
  coord_sf(
    xlim   = c(6.0, 7.5),
    ylim   = c(46.4, 47.1),
    expand = FALSE,
    crs = 4326
  ) +
  labs(title = "Study area: Western Switzerland") +
  theme_minimal(base_size = 13) +
  theme(panel.grid = element_line(colour = "white", linewidth = 0.3))


world <- sf::st_as_sf(maps::map("world", plot = FALSE, fill = TRUE))

study_box <- sf::st_as_sfc(
  sf::st_bbox(c(xmin = 6.0, ymin = 46.4, xmax = 7.5, ymax = 47.1),
              crs = 4326)
)

inset_map <- ggplot() +
  geom_sf(data  = world,
          fill  = "grey30",
          colour = "grey50",
          linewidth = 0.1) +
  geom_sf(data  = study_box,
          fill  = "red",
          colour = "red",
          alpha = 0.6) +
  coord_sf(
    xlim   = c(-10, 30),   #focus on Europe
    ylim   = c(35, 60),
    expand = FALSE
  ) +
  theme_void(base_size = 7) +
  theme(
    panel.background = element_rect(fill  = "lightblue", colour = NA),
    panel.border     = element_rect(fill  = NA,          colour = "black", linewidth = 0.8)
  )

final_map <- ggdraw(main_map) +
  draw_plot(
    inset_map,
    x      = 0.73,   # distance from left edge (0–1)
    y      = 0.63,   # distance from bottom edge (0–1)
    width  = 0.20,   # fraction of total plot width
    height = 0.20    # fraction of total plot height
  )

final_map

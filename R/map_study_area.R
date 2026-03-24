map_study_area <- function(name, input_geojson) {

  library(sf)
  library(tidyverse)
  library(basemaps)
  library(cowplot)

  # read geojson file
  geo_data <- st_read(input_geojson)

  # define background map
  set_defaults(map_service = "esri", map_type = "world_imagery")

  plot1 <- basemap_ggplot(geo_data) +
    geom_sf(data = geo_data,
            fill = "royalblue",
            alpha = 0.4,
            color = "white",
            linewidth = 0.8) +
    theme_minimal() +
    labs(title = name,
         subtitle = "Esri World Imagery",
         x = "Longitude",
         y = "Latitude")

  return(plot1)
}

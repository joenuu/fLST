get_pcwd_plot <- function(pcwd_rds_filepath){

  pcwd <- readRDS(pcwd_rds_filepath)

  pcwd_pl <- pcwd |>
    ggplot(aes(x = pcwd_mm)) +
    geom_density(colour = "steelblue", linewidth = 0.8) +
    labs(title = "Distribution of PCWD over Switzerland",
         x = "PCWD (mm)", y = "Density") +
    theme_minimal()

  return(pcwd_pl)
}


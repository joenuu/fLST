# a function to plot predicted values vs observed values, similar to Stocker et al. (2018)

make_lst_plot <- function(df, obs_col, pred_col, title_label, obs_label, pred_label) {

  source(here::here("R", "get_stats_label.R"))

  df <- df |>
    dplyr::select(obs = all_of(obs_col), pred = all_of(pred_col)) |>
    tidyr::drop_na()

  add_density <- function(df, x_var, y_var) {
    dens <- MASS::kde2d(df[[x_var]], df[[y_var]], n = 200)
    ix <- findInterval(df[[x_var]], dens$x)
    iy <- findInterval(df[[y_var]], dens$y)
    df$density <- dens$z[cbind(ix, iy)]
    df
  }

  df <- add_density(df, "obs", "pred")

  stats_label <- get_stats_label(df$obs, df$pred)

  axis_lim <- range(c(df$obs, df$pred), na.rm = TRUE)

  ggplot2::ggplot(df, ggplot2::aes(x = obs, y = pred)) +
    ggplot2::geom_point(ggplot2::aes(colour = density), size = 0.4, alpha = 0.6) +
    ggplot2::scale_colour_gradientn(
      colours = c("grey70", "navy", "blue", "cyan", "yellow", "red", "darkred"),
      guide = "none"
    ) +
    ggplot2::geom_abline(slope = 1, intercept = 0,          # 1:1 line
                colour = "red", linewidth = 0.8) +
    ggplot2::geom_smooth(method = "lm", se = FALSE,          # regression line
                colour = "red", linetype = "dashed", linewidth = 0.8) +
    ggplot2::annotate("text",
                      x = axis_lim[2], y = axis_lim[1],
                      label = stats_label,
                      hjust = 1, vjust = 0, size = 3) +
    ggplot2::coord_equal(xlim = axis_lim, ylim = axis_lim) +
    ggplot2::labs(title = title_label,
         x = obs_label,
         y = pred_label) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5))
}

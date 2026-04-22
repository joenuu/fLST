# a function to get the statistics of my model

get_stats_label <- function(obs, pred) {
  n     <- length(obs)
  nse   <- 1 - sum((obs - pred)^2) / sum((obs - mean(obs))^2)
  r2    <- cor(obs, pred)^2
  rmse  <- sqrt(mean((obs - pred)^2))
  rmse_pct <- rmse / mean(obs) * 100
  bias  <- mean((pred - obs) / obs) * 100

  paste0(
    "N = ", scales::comma(n), "\n",
    "NSE = ", round(nse, 2), "\n",
    "R² = ", round(r2, 2), "\n",
    "RMSE = ", round(rmse, 1), " (", round(rmse_pct), "%)\n",
    "bias = ", round(bias, 3), " %"
  )
}

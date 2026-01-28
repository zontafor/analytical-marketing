# 05_extras_validation.R
# Optional "extra portions": model fit / prediction diagnostic (if available in xlsx).
# Uses sheet `topics_prediction.txt` when present.

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(ggplot2)
})

source("R/00_config.R")
source("R/lib/utils.R")

sheets <- excel_sheets(cfg$topics_xlsx)
if (!("topics_prediction.txt" %in% sheets)) {
  message("No topics_prediction.txt sheet found; skipping.")
} else {
  pred <- read_excel(cfg$topics_xlsx, sheet = "topics_prediction.txt")
  # Expect columns like: term, actual, predicted (varies by instructor file)
  # Make this robust by selecting numeric columns.
  num_cols <- names(pred)[sapply(pred, is.numeric)]
  if (length(num_cols) < 2) {
    message("topics_prediction.txt does not have >=2 numeric columns; skipping plot.")
  } else {
    a <- num_cols[1]
    b <- num_cols[2]
    df <- pred %>% transmute(actual = as.numeric(.data[[a]]), predicted = as.numeric(.data[[b]])) %>% tidyr::drop_na()
    cor_val <- cor(df$actual, df$predicted)
    p <- ggplot(df, aes(x = actual, y = predicted)) +
      geom_point(alpha = 0.5) +
      geom_smooth(method = "lm", se = FALSE) +
      labs(
        title = "Topic Model Predictive Check (from topics_prediction.txt)",
        subtitle = paste0("Correlation(actual, predicted) = ", round(cor_val, 3)),
        x = "Actual",
        y = "Predicted"
      ) +
      theme_minimal()

    ggsave(file.path(cfg$out_dir, "topics_prediction_actual_vs_predicted.png"), p, width = 6, height = 4)
    write.csv(data.frame(correlation = cor_val), file.path(cfg$out_dir, "topics_prediction_correlation.csv"), row.names = FALSE)
    message("Wrote topics prediction plot + correlation.")
  }
}

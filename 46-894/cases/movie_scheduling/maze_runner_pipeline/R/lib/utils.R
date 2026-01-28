# R/lib/utils.R

stop_if_missing <- function(obj, name) {
  if (missing(obj) || is.null(obj)) stop(paste0("Missing object: ", name))
}

norm_title <- function(x) {
  x <- tolower(as.character(x))
  x <- gsub("&", " and ", x)
  x <- gsub("[^a-z0-9]+", " ", x)
  x <- gsub("\\s+", " ", x)
  trimws(x)
}

read_opus_movies <- function(path) {
  # opus_movies.txt is tab-delimited; readr is robust to encodings
  suppressPackageStartupMessages(library(readr))
  suppressPackageStartupMessages(library(dplyr))

  df <- readr::read_tsv(path, show_col_types = FALSE, progress = FALSE, locale = readr::locale(encoding = "latin1"))

  # best-effort typing
  if ("release_date" %in% names(df)) df$release_date <- as.Date(df$release_date)
  if ("production_budget" %in% names(df)) df$production_budget <- suppressWarnings(as.numeric(df$production_budget))
  if ("sequel" %in% names(df)) df$sequel <- suppressWarnings(as.numeric(df$sequel))

  df <- df %>%
    mutate(
      display_name = as.character(display_name),
      norm_name = norm_title(display_name)
    )

  df
}

euclid_to <- function(M, x) {
  # M: matrix, x: numeric vector
  sqrt(rowSums((M - matrix(x, nrow = nrow(M), ncol = length(x), byrow = TRUE))^2))
}

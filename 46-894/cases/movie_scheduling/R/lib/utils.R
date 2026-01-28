# lib/utils.R
# Small helpers (dev-style: short, single-purpose, defensive)

suppressPackageStartupMessages({
  library(stringr)
  library(dplyr)
  library(readr)
})

stop_if_missing <- function(path) {
  if (!file.exists(path)) stop(paste0("Missing file: ", path))
}

# Normalize titles for robust joining when a stable ID isn't available in both sources.
# - lowercase
# - remove punctuation
# - collapse whitespace
# - strip trailing years like "(2006)" or "(2010)"
norm_title <- function(x) {
  x %>%
    str_to_lower() %>%
    str_replace_all("\\(\\d{4}\\)", " ") %>%
    str_replace_all("[^a-z0-9]+", " ") %>%
    str_squish()
}

# Safe read for opus_movies (latin-1 is common for this dataset)
read_opus_movies <- function(path) {
  stop_if_missing(path)
  read_tsv(path, locale = locale(encoding = "latin1"), show_col_types = FALSE)
}

# Euclidean distance between one vector and many rows of a matrix (fast enough for this scale)
euclid_to <- function(x, M) {
  # x: numeric vector length K
  # M: numeric matrix n x K
  sqrt(rowSums((t(t(M) - x))^2))
}

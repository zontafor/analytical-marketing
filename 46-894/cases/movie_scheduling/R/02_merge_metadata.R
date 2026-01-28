# 02_merge_metadata.R
# Merge topic vectors to opus metadata. Produces diagnostics to catch join failures.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(lubridate)
})

source("R/00_config.R")
source("R/lib/utils.R")

movie_topic <- read_csv(file.path(cfg$out_dir, "movie_topic_clean.csv"), show_col_types = FALSE)
opus <- read_opus_movies(cfg$opus_movies) %>%
  mutate(
    display_name = as.character(display_name),
    norm_name = norm_title(display_name),
    release_date = as.Date(release_date)
  )

# Prefer exact normalized title match.
merged <- movie_topic %>%
  left_join(
    opus %>% select(odid, display_name, norm_name, release_date, genre, rating, production_budget, sequel),
    by = c("norm_name"),
    suffix = c("_topic", "_opus")
  )

# Diagnostics
diag <- merged %>%
  summarise(
    n_topics = n(),
    n_matched = sum(!is.na(odid)),
    match_rate = n_matched / n_topics,
    n_missing = sum(is.na(odid))
  )

# List the most common missing titles
missing_titles <- merged %>%
  filter(is.na(odid)) %>%
  count(display_name, sort = TRUE) %>%
  head(50)

# Collision check: multiple opus titles mapping to same norm_name
collisions <- opus %>%
  count(norm_name, sort = TRUE) %>%
  filter(n > 1) %>%
  head(50)

write_csv(merged, file.path(cfg$out_dir, "movie_topic_with_metadata.csv"))
write_csv(diag, file.path(cfg$out_dir, "merge_diagnostics_summary.csv"))
write_csv(missing_titles, file.path(cfg$out_dir, "merge_missing_titles_top50.csv"))
write_csv(collisions, file.path(cfg$out_dir, "opus_title_collisions_top50.csv"))

message("Merge diagnostics written to outputs/.")
message(sprintf("Match rate: %.1f%% (%d/%d)", 100*diag$match_rate, diag$n_matched, diag$n_topics))

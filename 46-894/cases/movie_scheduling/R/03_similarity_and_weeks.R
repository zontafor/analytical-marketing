# 03_similarity_and_weeks.R
# Compute: (1) nearest neighbors to Maze Runner, (2) 2014 weekly competitive pressure,
# and (3) top candidate weeks with coverage flags.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(lubridate)
  library(ggplot2)
})

source("R/00_config.R")
source("R/lib/utils.R")

df <- read_csv(file.path(cfg$out_dir, "movie_topic_with_metadata.csv"), show_col_types = FALSE)

# Identify topic columns
topic_cols <- paste0("Topic", 1:cfg$K)

# Target vector (use topic sheet title match; metadata match not required)
target <- df %>% filter(tolower(display_name) == tolower(cfg$target_title))
if (nrow(target) != 1) stop("Target title match failed or ambiguous in movie_topic_clean.csv")

x <- as.numeric(target[1, topic_cols])

# Nearest neighbors (exclude self)
M <- as.matrix(df[, topic_cols])
d_all <- euclid_to(x, M)

neighbors <- df %>%
  mutate(dist_to_target = d_all) %>%
  filter(tolower(display_name) != tolower(cfg$target_title)) %>%
  arrange(dist_to_target) %>%
  select(display_name, dist_to_target, release_date, genre, rating) %>%
  head(25)

write_csv(neighbors, file.path(cfg$out_dir, "maze_runner_nearest_neighbors.csv"))

# Weekly competition (2014)
df_2014 <- df %>%
  filter(!is.na(release_date)) %>%
  filter(year(release_date) == 2014)

# Anchor week by Friday
week_friday <- function(d) {
  d - days((wday(d, week_start = 1) + 1) %% 7) + days(4)  # ensures Friday anchor
}

df_2014 <- df_2014 %>%
  mutate(week = week_friday(release_date))

# competitor set: same week (+ prior week)
comp <- df_2014 %>%
  mutate(week_prior = week - weeks(1))

weeks <- sort(unique(df_2014$week))

score_week <- function(w) {
  if (cfg$include_prior_week) {
    idx <- which(comp$week == w | comp$week == (w - weeks(1)))
  } else {
    idx <- which(comp$week == w)
  }
  if (length(idx) == 0) return(NULL)

  M_w <- as.matrix(comp[idx, topic_cols])
  d_w <- euclid_to(x, M_w)

  j <- which.min(d_w)
  tibble(
    week_friday = w,
    n_competitors_considered = length(d_w),
    min_dist = d_w[j],
    avg_dist = mean(d_w),
    closest_competitor = comp[idx, ]$display_name[j]
  )
}

weekly <- bind_rows(lapply(weeks, score_week)) %>%
  arrange(week_friday) %>%
  mutate(
    coverage_flag = ifelse(n_competitors_considered < cfg$min_competitors_flag, "LOW_COVERAGE", "OK")
  )

write_csv(weekly, file.path(cfg$out_dir, "weekly_competition_2014_lda_with_coverage.csv"))

# Plot
p <- ggplot(weekly, aes(x = week_friday, y = min_dist)) +
  geom_line() + geom_point(aes(shape = coverage_flag)) +
  labs(
    title = "2014 Weekly Competitive Pressure vs The Maze Runner (LDA topics)",
    subtitle = "min distance to closest competitor (same week + prior week); LOW_COVERAGE flagged",
    x = "Week (Friday anchor)",
    y = "Min topic distance (higher = less competition)"
  ) +
  theme_minimal()

ggsave(file.path(cfg$out_dir, "weekly_min_distance_lda_with_coverage.png"), p, width = 10, height = 4)

# Top candidate weeks (filtering out low coverage by default)
top_weeks <- weekly %>%
  filter(coverage_flag == "OK") %>%
  arrange(desc(min_dist), desc(avg_dist)) %>%
  head(8)

write_csv(top_weeks, file.path(cfg$out_dir, "top_candidate_weeks_lda_filtered.csv"))

message("Wrote nearest neighbors, weekly scores w/ coverage, plot, and top weeks.")

# 04_kmeans_robustness.R
# Team E: k-means clustering / distance in characteristics space as a robustness check.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(lubridate)
  library(ggplot2)
})

source("R/00_config.R")
source("R/lib/utils.R")

df <- read_csv(file.path(cfg$out_dir, "movie_topic_with_metadata.csv"), show_col_types = FALSE)

# Features: genre + rating (one-hot) + budget + sequel
# Keep only rows with metadata present.
d <- df %>%
  filter(!is.na(release_date)) %>%
  filter(!is.na(genre), !is.na(rating), !is.na(production_budget), !is.na(sequel)) %>%
  mutate(
    genre = as.factor(genre),
    rating = as.factor(rating)
  )

# Model matrix
X <- model.matrix(~ genre + rating + scale(production_budget) + sequel, data = d)

set.seed(42)
k <- 10
km <- kmeans(X, centers = k, nstart = 50)

d$cluster <- km$cluster

# Target row
target <- d %>% filter(tolower(display_name) == tolower(cfg$target_title))
if (nrow(target) != 1) stop("Target not found uniquely after metadata filtering.")

x <- X[which(tolower(d$display_name) == tolower(cfg$target_title))[1], , drop=FALSE]

# Distances to target in standardized feature space
dist_char <- sqrt(rowSums((X - matrix(rep(x, nrow(X)), nrow = nrow(X), byrow = TRUE))^2))
d$dist_char_to_target <- dist_char

# Weekly 2014 scoring
d_2014 <- d %>% filter(year(release_date) == 2014)

week_friday <- function(dte) {
  dte - days((wday(dte, week_start = 1) + 1) %% 7) + days(4)
}
d_2014 <- d_2014 %>% mutate(week = week_friday(as.Date(release_date)))

score_week <- function(w) {
  idx <- which(d_2014$week == w | d_2014$week == (w - weeks(1)))
  if (length(idx) == 0) return(NULL)
  d_w <- d_2014$dist_char_to_target[idx]
  j <- which.min(d_w)
  tibble(
    week_friday = w,
    n_competitors_considered = length(d_w),
    min_dist_char = d_w[j],
    avg_dist_char = mean(d_w),
    closest_competitor = d_2014$display_name[idx][j]
  )
}

weeks <- sort(unique(d_2014$week))
weekly <- bind_rows(lapply(weeks, score_week)) %>%
  arrange(week_friday) %>%
  mutate(
    coverage_flag = ifelse(n_competitors_considered < cfg$min_competitors_flag, "LOW_COVERAGE", "OK")
  )

write_csv(weekly, file.path(cfg$out_dir, "weekly_competition_2014_kmeans_with_coverage.csv"))

p <- ggplot(weekly, aes(x = week_friday, y = min_dist_char)) +
  geom_line() + geom_point(aes(shape = coverage_flag)) +
  labs(
    title = "2014 Weekly Competitive Pressure vs The Maze Runner (k-means characteristics)",
    subtitle = "min distance in characteristics space (same week + prior week); LOW_COVERAGE flagged",
    x = "Week (Friday anchor)",
    y = "Min distance (higher = less competition)"
  ) +
  theme_minimal()

ggsave(file.path(cfg$out_dir, "weekly_min_distance_kmeans_with_coverage.png"), p, width = 10, height = 4)

top_weeks <- weekly %>%
  filter(coverage_flag == "OK") %>%
  arrange(desc(min_dist_char), desc(avg_dist_char)) %>%
  head(8)

write_csv(top_weeks, file.path(cfg$out_dir, "top_candidate_weeks_kmeans_filtered.csv"))

message("Wrote k-means weekly scores + plot + top weeks.")

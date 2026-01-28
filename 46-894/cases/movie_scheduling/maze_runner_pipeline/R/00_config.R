# 00_config.R
# Centralized configuration for paths and constants.

cfg <- list(
  # Input files
  topics_xlsx = "/mnt/data/topics_analysis_10.xlsx",
  opus_movies = "/mnt/data/opus_movies.txt",
  opus_tags   = "/mnt/data/opus_movielens_tags.txt",
  opus_kw     = "/mnt/data/opus_keywords.txt",

  # Output directory
  out_dir = "/mnt/data/maze_runner_pipeline/outputs",

  # Model constants
  K = 10L,
  target_title = "The Maze Runner",

  # Week scoring
  week_anchor = "Friday",
  include_prior_week = TRUE,

  # Coverage guardrail: flag (and optionally filter) weeks with few competitors
  min_competitors_flag = 3L
)

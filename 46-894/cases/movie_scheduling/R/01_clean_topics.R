# 01_clean_topics.R
# Read `topics_analysis_10.xlsx` and produce clean:
# - movie_topic: movie_title + Topic1..TopicK
# - term_topic: topic + term + p_term_given_topic

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(stringr)
})

source("R/00_config.R")
source("R/lib/utils.R")

stop_if_missing(cfg$topics_xlsx)

# Movies: the spreadsheet has duplicated topic columns; keep the first K only.
raw_movies <- read_excel(cfg$topics_xlsx, sheet = "topics_allmovies.txt")

movie_title_col <- names(raw_movies)[1]
topic_cols <- names(raw_movies)[str_detect(names(raw_movies), "^Topic\\d+$")][1:cfg$K]

movie_topic <- raw_movies %>%
  transmute(
    display_name = as.character(.data[[movie_title_col]]),
    norm_name = norm_title(as.character(.data[[movie_title_col]])),
    across(all_of(topic_cols), as.numeric)
  )

# Terms
raw_terms <- read_excel(cfg$topics_xlsx, sheet = "topics_allterms.txt")
term_col <- names(raw_terms)[1]
term_topic_cols <- names(raw_terms)[str_detect(names(raw_terms), "^Topic\\d+$")][1:cfg$K]

term_topic <- raw_terms %>%
  transmute(
    term = as.character(.data[[term_col]]),
    across(all_of(term_topic_cols), as.numeric)
  ) %>%
  tidyr::pivot_longer(cols = starts_with("Topic"), names_to = "topic", values_to = "p_term_given_topic") %>%
  mutate(topic = as.integer(str_replace(topic, "Topic", ""))) %>%
  arrange(topic, desc(p_term_given_topic))

dir.create(cfg$out_dir, showWarnings = FALSE, recursive = TRUE)
write_csv(movie_topic, file.path(cfg$out_dir, "movie_topic_clean.csv"))
write_csv(term_topic,  file.path(cfg$out_dir, "term_topic_long.csv"))

message("Wrote: movie_topic_clean.csv, term_topic_long.csv")

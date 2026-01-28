# run_all.R
# One-command entrypoint. Produces all outputs + bundle zip.

source("R/00_config.R")

# Ensure working directory is project root
# (If you run this from elsewhere, setwd() accordingly.)
scripts <- c(
  "R/01_clean_topics.R",
  "R/02_merge_metadata.R",
  "R/03_similarity_and_weeks.R",
  "R/04_kmeans_robustness.R",
  "R/05_extras_validation.R"
)

for (s in scripts) {
  message("\n=== Running: ", s, " ===")
  source(s)
}

# Bundle outputs
zip_path <- file.path(dirname(cfg$out_dir), "maze_runner_pipeline_outputs.zip")
if (file.exists(zip_path)) file.remove(zip_path)

files <- list.files(cfg$out_dir, full.names = TRUE)
zip(zipfile = zip_path, files = files, flags = "-j")

message("\nCreated bundle: ", zip_path)

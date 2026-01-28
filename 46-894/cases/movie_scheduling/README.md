# Maze Runner Release Timing – Reproducible Pipeline (R)

## What this does
End-to-end, reproducible generation of the analysis outputs used in the slide deck:
- Clean 10-topic LDA tables from `topics_analysis_10.xlsx`
- Merge topic vectors to movie metadata from `opus_movies.txt` with robust title normalization
- Compute similarity (Euclidean distance in topic space)
- Score 2014 release weeks by competitive pressure (closest substitute), including *coverage diagnostics*
- Run Team E robustness (k-means on characteristics)
- Produce CSVs + PNG charts + diagnostics, then bundle everything into a zip

## Inputs (place in project root or edit `R/00_config.R`)
- topics_analysis_10.xlsx
- opus_movies.txt
- opus_movielens_tags.txt (optional)
- opus_keywords.txt (optional)
- Movie_Analysis.R / Movie_Analysis_Extra.R (optional reference scripts)
- Movie_Data.RData, Movie_Data_LDA10.RData (optional)

## Quick start (R)
```r
source("R/run_all.R")
```

Outputs go to `outputs/` and a bundle zip is created in the project root.

## Notes on robustness
This pipeline **reports and guards against**:
- mismatched merges (title collisions)
- sparse-week bias (weeks with too few competitors considered)
- missing-topic coverage (movies present in `opus_movies.txt` but not in LDA outputs)
# The Maze Runner (2014) Release Timing Analysis  
**LDA Topic Modeling | k-Means Robustness**

---

This project supports **Gotham Group studio executives (circa 2013)** in deciding **when to release *The Maze Runner* in 2014**. The core objective is to maximize market share while minimizing competitive cannibalization by avoiding release weeks where competing films are *too similar*.

We use data mining and machine learning to:
- Quantify similarity between films using LDA topic models
- Translate similarity into weekly competitive pressure
- Identify 3 to 4 optimal release windows
- Validate robustness using k-means clustering on observable movie characteristics

This analysis complements (not replaces) industry heuristics around seasonality, awards cycles, and blockbuster congestion.

---

## Data Sources

### Primary Inputs
- `opus_movies.txt` – movie metadata (title, release date, genre, rating, budget, sequel)
- `opus_movielens_tags.txt` – tag × movie associations
- `opus_keywords.txt` – keyword frequencies
- `topics_analysis_10.xlsx` – pre-trained LDA output (10 topics)  
  - `topics_allmovies.txt`: Pr(topic | movie)
  - `topics_allterms.txt`: Pr(term | topic)
  - `topics_prediction.txt` (optional): predictive sanity check

### Why LDA?
LDA allows each movie to load on *multiple themes* (e.g., action, dystopian, YA, sci‑fi), which better reflects substitution risk than single-genre labels.

---

## Pipeline Overview (What Each Script Does)

Run the full pipeline with:

```r
source("R/run_all.R")
```

### Script Map
1. **`00_config.R`**  
   Central configuration (paths, flags, thresholds).  
   Key parameters:
   - `include_prior_week = TRUE` (ongoing competition)
   - `min_competitors_flag = 3` (coverage guardrail)

2. **`01_clean_topics.R`**  
   - Cleans LDA topic matrices  
   - Extracts top terms per topic for interpretation and labeling

3. **`02_merge_metadata.R`**  
   - Normalizes titles  
   - Merges LDA outputs with `opus_movies.txt`  
   - Produces merge diagnostics (match rate, collisions)

4. **`03_similarity_and_weeks.R`**  
   - Computes Euclidean distance between *The Maze Runner* and all films in 10‑D topic space  
   - Identifies top-10 most similar movies (sanity check)  
   - Scores each 2014 release week using:
     - `min_dist` (closest substitute → primary metric)
     - `avg_dist` (overall congestion → secondary metric)
   - Includes prior week releases to reflect box office carryover

5. **`04_kmeans_robustness.R`** *(Team E requirement)*  
   - Runs k-means clustering using observable characteristics:
     - One-hot encoded **Genre**
     - One-hot encoded **MPAA Rating**
     - Scaled **Production Budget**
     - **Sequel indicator**
   - Repeats weekly competition analysis in characteristic space
   - Used to validate that LDA-based recommendations are not artifacts

6. **`05_extras_validation.R`** *(optional)*  
   - Predictive checks using `topics_prediction.txt` (actual vs predicted word counts)

---

## Topic Interpretation

For each of the 10 LDA topics, we output the highest-probability terms:

**Output:**  
- `term_topic_long.csv`

These term lists allow analysts to label topics (e.g., *YA dystopian*, *action-adventure*, *romance*, *family animation*).  
These labels are used only for interpretation in the slide deck, not in the similarity math itself.

---

## Movie Similarity & Validation

### Similarity Metric
- Each movie is represented as a *n*‑dimensional topic probability vector
- Distance metric: Euclidean distance
- Interpretation:
  - Smaller distance → more similar → higher cannibalization risk

### Key Validation Outputs
- `maze_runner_nearest_neighbors.csv`  
  → Top 10 to 25 most similar films to *The Maze Runner*

**Sanity checks performed:**
- Nearest neighbors share plausible themes (YA, sci‑fi, action)
- Distances are not degenerate (no uniform topic vectors)
- Confirms model face validity before scheduling decisions

---

## Weekly Competition Scoring

### Weekly Definition
- Movies grouped by **Friday-anchored release week**
- Competitors include:
  - Films released the same week
  - Films released the prior week (carryover effects)

### Metrics Computed
- `min_dist`: closest competing movie (primary decision metric)
- `avg_dist`: average similarity within the week
- `coverage_flag`: marks weeks with sparse data

**Outputs:**
- `weekly_competition_2014_lda_with_coverage.csv`
- `weekly_competition_2014_kmeans_with_coverage.csv`

---

## Candidate Release Windows

From the weekly tables, we filter to:
- Adequate coverage weeks
- High `min_dist` and `avg_dist` (low competition)

**Outputs:**
- `top_candidate_weeks_lda_filtered.csv`
- `top_candidate_weeks_kmeans_filtered.csv`

From these tables, the slide deck selects 3 to 4 final recommended weeks, balancing:
- Quantitative competition metrics
- Industry seasonality heuristics

---

## Robustness Check: k-Means vs LDA

To assess robustness, we repeat the analysis using k-means clustering on observable movie characteristics.

### Why This Matters
If both:
- Topic-based similarity, and
- Genre/budget-based similarity

identify similar low-competition weeks, confidence in the recommendation increases.

**Key Finding:**  
LDA and k-means broadly agree on low-congestion windows, supporting the robustness of the strategy.

---

## Outputs & Visualization

All results are written to:

```
/maze_runner_pipeline/outputs/
```

Includes:
- Cleaned topic tables
- Merge diagnostics
- Nearest neighbors
- Weekly competition tables
- **Colorblind Friendly Plots**:
  - `maze_runner_topic_bar.png`
  - `weekly_min_distance_lda_with_coverage.png`
  - `weekly_min_distance_kmeans_with_coverage.png`

---

## Reproducibility & Dependencies

### R Packages Used
- `dplyr`, `tidyr`, `readr`
- `ggplot2`
- `lubridate`
- `readxl`

### Configuration
All tunable parameters (paths, thresholds) are centralized in `00_config.R`.

---



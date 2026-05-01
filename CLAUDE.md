# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

MIS 720 (Spring 2026) Team B2 group project: predicting Spotify track popularity from audio features. Source data is the [Kaggle Spotify Music Dataset](https://www.kaggle.com/datasets/solomonameh/spotify-music-dataset), pre-split into [data/high_popularity_spotify_data.csv](data/high_popularity_spotify_data.csv) and [data/low_popularity_spotify_data.csv](data/low_popularity_spotify_data.csv).

R / RStudio project. Indentation is 2 spaces (set in [MIS720_Group_Project.Rproj](MIS720_Group_Project.Rproj)).

## Pipeline

Two scripts run in strict order; the second consumes an artifact produced by the first.

1. **[01_eda.R](01_eda.R)** — loads both CSVs, reconciles to common columns, dedupes by `track_id` (keeping the row with max `track_popularity`), builds the binary response `high_popularity` from `track_popularity > 68`, recodes `key`/`mode` to readable labels, runs univariate and bivariate EDA, writes figures to `figures/` and the cleaned dataset to `output/spotify_clean.rds` (and `.csv`).
2. **[02_modeling.R](02_modeling.R)** — reads `output/spotify_clean.rds`, stratified 80/20 split, 5-fold CV on the train set, trains 3 models × 2 feature sets = 6 `tidymodels` workflows, tunes hyperparameters on `roc_auc`, evaluates on the held-out test set, sweeps the decision threshold for F1 on out-of-fold CV predictions, generates per-model and cross-model plots into `figures/models/`, and writes RDS artifacts (fitted workflows, predictions, metrics, importances, thresholds) to `output/`.

Re-running `02_modeling.R` requires `output/spotify_clean.rds` to exist — run `01_eda.R` first if it is missing or stale.

### Models and feature sets

- Models: logistic regression (`glm`), random forest (`ranger`, permutation importance), SVM RBF (`kernlab`).
- Feature sets: `audio` (continuous audio features + `key` + `mode` + `time_signature`) and `audio+genre` (audio + `playlist_genre`). The point of the second set is to test whether audio features add information beyond genre.
- LR/SVM share a recipe (median/mode impute → lump rare genres at 1% → dummy → drop ZV → z-standardize). RF uses a recipe without dummies or scaling (ranger handles factors, trees are scale-invariant).
- Tuning grid for SVM is range-constrained explicitly (`cost` 2^-2 to 2^8, `rbf_sigma` 1e-4 to 1e-1) because dials' defaults include degenerate regions; RF passes an integer grid size.

### Runtime

`02_modeling.R` takes ~5–25 min depending on cores. SVM RBF tuning is the bottleneck; lower `svm_grid_size` (defined near the top of the script) to speed up. Parallelism is on by default via `doParallel`; set `use_parallel <- FALSE` to disable.

## Running

From R / RStudio at the repo root:

```r
source("01_eda.R")       # produces output/spotify_clean.rds, figures/*.png
source("02_modeling.R")  # produces output/*.rds, figures/models/*.png
```

From a shell:

```sh
Rscript 01_eda.R
Rscript 02_modeling.R
```

### Required packages

EDA: `tidyverse`, `scales`, `ggcorrplot`. Modeling: `tidymodels`, `ranger`, `kernlab`, `vip`, `doParallel`, `broom`, `patchwork`. Both scripts list the install command in their setup blocks.

## Conventions to preserve when editing

- **`set.seed(42)`** at the top of both scripts. Per-feature permutation importance also seeds explicitly (`1000 + i`) so importance numbers are reproducible across runs.
- **Color palette is defined as base tokens, then semantic assignments**, in both scripts. The block comment `# ---- 1b. Color scheme configuration` calls this out — edit the tokens (`spotify_green`, `contrast_accent`, etc.) and the change propagates to every plot. Don't hard-code hex values inline. Keep the palette in sync between [01_eda.R](01_eda.R) and [02_modeling.R](02_modeling.R) when changing tokens.
- **`high_popularity` factor level order matters.** EDA writes `levels = c("Low", "High")`; modeling re-levels to `c("High", "Low")` so `yardstick`'s default `event_level = "first"` reports sensitivity/precision/recall for the "High" class. If you change this, audit the metric calls.
- **`popularity_threshold <- 68`** is the proposal-defined cutoff used to construct the response. Don't change it casually.
- **Tuning uses threshold-independent metrics only** (`roc_auc`, `accuracy`, `brier_class`). Threshold-dependent metrics are computed in `last_fit()` for the chosen model, and via the explicit CV threshold sweep in section 11b. The SVM grid hits all-Low predictions for some cells, which would make precision/F1 NaN and emit noise — keep that separation.
- **kernlab SMO convergence warnings are deliberately muffled** during tuning via `quiet_kernlab()`. Only `"maximum number of iterations reached"` and `"line search fails"` are suppressed; everything else passes through. Don't broaden the filter.
- **LR coefficient plot filters out quasi-separated terms** (`std.error > 5`) and lists them in the console. The threshold and the auto-zoom logic are intentional; keep both if you regenerate the plot.

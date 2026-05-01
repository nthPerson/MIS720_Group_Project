# Figure Inventory

Use this file as a lookup: when you know what idea you want to communicate, find the figure file here. Every figure listed below already exists in the repo — re-running the pipeline regenerates them in place.

## Quick reference — by use case

| If the slide/section needs to show… | Use this figure |
|---|---|
| The response distribution and the threshold-68 cut | [figures/01b_histogram_track_popularity.png](../../figures/01b_histogram_track_popularity.png) |
| Continuous-predictor distributions | [figures/01_histograms_continuous.png](../../figures/01_histograms_continuous.png) |
| Continuous predictors split by High vs Low class | [figures/03_box_continuous_by_response.png](../../figures/03_box_continuous_by_response.png) |
| That `playlist_genre` is the strongest single predictor | [figures/04_cat_vs_response_playlist_genre_full.png](../../figures/04_cat_vs_response_playlist_genre_full.png) (full) or [figures/04_cat_vs_response_playlist_genre_top10.png](../../figures/04_cat_vs_response_playlist_genre_top10.png) (cleaner for slides) |
| Multicollinearity among continuous predictors | [figures/05_correlation_heatmap.png](../../figures/05_correlation_heatmap.png) |
| Which audio predictors lean toward "hit" | [figures/06_point_biserial_with_response.png](../../figures/06_point_biserial_with_response.png) |
| Test-set metric comparison at **default threshold 0.5** | [figures/models/all_metric_comparison.png](../../figures/models/all_metric_comparison.png) |
| Test-set metric comparison at **CV-tuned thresholds** | [figures/models/all_metric_comparison_tuned.png](../../figures/models/all_metric_comparison_tuned.png) |
| **Both threshold schemes side by side, one chart** | [figures/models/all_metric_comparison_combined.png](../../figures/models/all_metric_comparison_combined.png) |
| ROC curves for all six workflows (with CV-tuned operating points marked) | [figures/models/all_roc_overlay.png](../../figures/models/all_roc_overlay.png) |
| Precision-recall curves for all six workflows | [figures/models/all_pr_overlay.png](../../figures/models/all_pr_overlay.png) |
| Calibration plots for all six workflows | [figures/models/all_calibration_overlay.png](../../figures/models/all_calibration_overlay.png) |
| F1 vs threshold (with tuned thresholds marked) | [figures/models/threshold_sweep_f1.png](../../figures/models/threshold_sweep_f1.png) |
| Logistic-regression coefficients (signed effects) | [figures/models/interp_lr_coefficients.png](../../figures/models/interp_lr_coefficients.png) |
| Random forest variable importance (engine-native) | [figures/models/interp_rf_importance.png](../../figures/models/interp_rf_importance.png) |
| **Cross-model feature attribution (the comparable one)** | [figures/models/interp_permutation_importance_all.png](../../figures/models/interp_permutation_importance_all.png) |
| **Partial dependence for top audio features** (best workflow) | [figures/models/pdp_rf_genre_top4.png](../../figures/models/pdp_rf_genre_top4.png) |
| Per-model deep-dive (single workflow) | `figures/models/perm_<wf_id>_{confmat,confmat_tuned,roc,pr,calibration,proba}.png` |

`<wf_id>` is one of `lr_audio`, `lr_genre`, `rf_audio`, `rf_genre`, `svm_audio`, `svm_genre`.

## EDA figures

These come from [01_eda.R](../../01_eda.R) and are numbered by section.

### 01 — Continuous distributions
- **[figures/01_histograms_continuous.png](../../figures/01_histograms_continuous.png)** — 10-panel grid of audio-feature histograms. Use to show acousticness/instrumentalness skew and overall data shape.
- **[figures/01b_histogram_track_popularity.png](../../figures/01b_histogram_track_popularity.png)** — distribution of `track_popularity` (0–100) with the threshold-68 line. **This is the slide for "what is the response, and where is the cutoff."**

### 02 — Categorical bar charts
- **[figures/02_bar_key_full.png](../../figures/02_bar_key_full.png)** — distribution of musical key (12 levels).
- **[figures/02_bar_mode_full.png](../../figures/02_bar_mode_full.png)** — distribution of mode (major vs minor).
- **[figures/02_bar_time_signature_full.png](../../figures/02_bar_time_signature_full.png)** — distribution of time signature.
- **[figures/02_bar_playlist_genre_full.png](../../figures/02_bar_playlist_genre_full.png)** — full distribution of `playlist_genre` (35 levels). Useful for an appendix or the methodology section to show why `step_other` is needed.
- **[figures/02_bar_playlist_genre_top10.png](../../figures/02_bar_playlist_genre_top10.png)** — top-10 genres + "Other". Cleaner version for slides.
- **[figures/02_bar_playlist_subgenre_full.png](../../figures/02_bar_playlist_subgenre_full.png)** and **[figures/02_bar_playlist_subgenre_top15.png](../../figures/02_bar_playlist_subgenre_top15.png)** — distribution of `playlist_subgenre`. Used only as appendix material to justify excluding subgenre from modeling.

### 03 — Continuous predictors by response class
- **[figures/03_box_continuous_by_response.png](../../figures/03_box_continuous_by_response.png)** — boxplots of every continuous predictor split by `high_popularity`. **Use this slide to show the loudness/instrumentalness/acousticness/energy class differences directly.**

### 04 — Categorical predictors vs response
- **[figures/04_cat_vs_response_key_full.png](../../figures/04_cat_vs_response_key_full.png)** — class composition by key.
- **[figures/04_cat_vs_response_mode_full.png](../../figures/04_cat_vs_response_mode_full.png)** — class composition by mode.
- **[figures/04_cat_vs_response_time_signature_full.png](../../figures/04_cat_vs_response_time_signature_full.png)** — class composition by time signature.
- **[figures/04_cat_vs_response_playlist_genre_full.png](../../figures/04_cat_vs_response_playlist_genre_full.png)** — class composition by playlist_genre, all 35 levels. **The single most informative EDA slide — shows the genre-level high-share spans 0% to 96%.**
- **[figures/04_cat_vs_response_playlist_genre_top10.png](../../figures/04_cat_vs_response_playlist_genre_top10.png)** — same idea, cleaner top-10 version. Better for the 12-minute deck.
- **[figures/04_cat_vs_response_playlist_subgenre_full.png](../../figures/04_cat_vs_response_playlist_subgenre_full.png)** and **[figures/04_cat_vs_response_playlist_subgenre_top15.png](../../figures/04_cat_vs_response_playlist_subgenre_top15.png)** — appendix-only.

### 05 — Multicollinearity
- **[figures/05_correlation_heatmap.png](../../figures/05_correlation_heatmap.png)** — Pearson correlation among continuous predictors. Use this to flag energy ↔ loudness = 0.80 and energy ↔ acousticness = −0.76 in methods (caveats LR coefficient interpretation).

### 06 — Predictor signal toward the response
- **[figures/06_point_biserial_with_response.png](../../figures/06_point_biserial_with_response.png)** — bar chart of point-biserial correlations of each continuous predictor with `high_popularity`. Use this to motivate which audio features will be informative before introducing the models.

## Modeling figures

These come from [02_modeling.R](../../02_modeling.R) and live under `figures/models/`.

### Cross-model overlays — these are the headline figures

- **[figures/models/all_roc_overlay.png](../../figures/models/all_roc_overlay.png)** — all six ROC curves on one panel, with each workflow's CV-tuned operating point marked as a hollow point on its curve. **THE headline figure for the Results section.** Threshold-independent; matches the instructor's "ROC curve to identify best threshold" guidance directly. The operating-point markers also let the reader see where the chosen threshold lands on each curve's sensitivity/specificity tradeoff.
- **[figures/models/all_metric_comparison.png](../../figures/models/all_metric_comparison.png)** — six bars per metric (Accuracy, F1, Precision, ROC AUC, Sensitivity, Specificity), grouped by model and feature set, at **default threshold 0.5**.
- **[figures/models/all_metric_comparison_tuned.png](../../figures/models/all_metric_comparison_tuned.png)** — same chart at **CV-tuned F1-optimal thresholds** per workflow. ROC AUC is repeated from the default-0.5 chart since it is threshold-independent.
- **[figures/models/all_metric_comparison_combined.png](../../figures/models/all_metric_comparison_combined.png)** — **single chart showing both schemes side by side.** Lighter bars = default 0.5; solid bars = CV-tuned. Most efficient slide if you only have room for one metric chart in the deck or report.
- **[figures/models/all_pr_overlay.png](../../figures/models/all_pr_overlay.png)** — all six precision-recall curves. Better than ROC for showing the imbalance problem honestly.
- **[figures/models/all_calibration_overlay.png](../../figures/models/all_calibration_overlay.png)** — calibration plots. Useful for showing that LR/RF probabilities are roughly well-calibrated and that SVM probabilities deviate from the diagonal more (consistent with `kernlab`'s known calibration behavior — see [03_methodology.md](03_methodology.md) §6).

### Threshold tuning
- **[figures/models/threshold_sweep_f1.png](../../figures/models/threshold_sweep_f1.png)** — F1 vs threshold sweep (per workflow), with the F1-optimal CV-tuned threshold marked as a dashed vertical line. **The right slide if the team wants to show that threshold tuning was principled, not cosmetic.**

### Feature attribution
- **[figures/models/interp_lr_coefficients.png](../../figures/models/interp_lr_coefficients.png)** — LR coefficients (audio+genre), filtered to terms with `std.error < 5`. Use for the music-maker recommendation slide.
- **[figures/models/interp_rf_importance.png](../../figures/models/interp_rf_importance.png)** — RF engine-native permutation importance (audio+genre).
- **[figures/models/interp_permutation_importance_all.png](../../figures/models/interp_permutation_importance_all.png)** — **the comparable cross-model importance** (drop in test AUC after permuting each feature, with ±SD error bars). Three model panels stacked. **This is the right figure for "playlist_genre is far and away the strongest predictor" because the three model families are on the same scale.**
- **[figures/models/pdp_rf_genre_top4.png](../../figures/models/pdp_rf_genre_top4.png)** — **partial-dependence plots for the top 4 audio features** (loudness, instrumentalness, acousticness, energy) in the best workflow (`rf_genre`). Each panel shows mean predicted P(High) on the test set as the focal feature is swept across a 30-point quantile-spaced grid, holding the empirical distribution of all other features fixed. Dashed line = marginal P(High). **Use this directly to support the music-maker recommendations** — it answers "what does the model say about loudness/instrumentalness/etc." in a quantitative way that the LR coefficient plot cannot.

### Per-workflow deep-dives

For each of the six workflows there are six plots. Use them in an appendix or for Q&A backup, particularly for the headline `rf_genre` workflow:

- **[figures/models/perm_rf_genre_confmat.png](../../figures/models/perm_rf_genre_confmat.png)** — confusion matrix at **default threshold 0.5**.
- **[figures/models/perm_rf_genre_confmat_tuned.png](../../figures/models/perm_rf_genre_confmat_tuned.png)** — confusion matrix at the **CV-tuned threshold** (0.33 for `rf_genre`). Use this version when the surrounding text references tuned thresholds.
- **[figures/models/perm_rf_genre_roc.png](../../figures/models/perm_rf_genre_roc.png)** — ROC curve with the CV-tuned operating point marked.
- **[figures/models/perm_rf_genre_pr.png](../../figures/models/perm_rf_genre_pr.png)** — precision-recall.
- **[figures/models/perm_rf_genre_calibration.png](../../figures/models/perm_rf_genre_calibration.png)** — calibration plot.
- **[figures/models/perm_rf_genre_proba.png](../../figures/models/perm_rf_genre_proba.png)** — predicted-probability density by class.

Substitute the workflow ID for the others (`lr_audio`, `lr_genre`, `rf_audio`, `svm_audio`, `svm_genre`). All have the same six plots.

## Style notes

- **Colors:** the palette is defined as base tokens in both R scripts; both use a Spotify-coded scheme (Spotify green + coral contrast accent). Don't hand-edit hex values in figures — change the tokens at the top of the scripts and re-run.
- **Class color order:** Low is the "first" class in the EDA factor and High is "first" in the modeling factor. The plots are consistent within their domain, but if you screenshot one EDA plot and one modeling plot together, double-check the legend.
- **Slide-size suitability:** the `_top10` / `_top15` versions of the genre/subgenre plots are visually cleaner for slides; the `_full` versions belong in an appendix or the report.
- **Figures the instructor specifically asked for:** feature importance visualizations are already generated (see [07_instructor_feedback.md](07_instructor_feedback.md), Action Item 4) — `interp_permutation_importance_all.png`, `interp_lr_coefficients.png`, and `interp_rf_importance.png`. All three should appear in both deliverables.

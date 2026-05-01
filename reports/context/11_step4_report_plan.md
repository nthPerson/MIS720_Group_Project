# Step 4 — Final Report Plan (10–15 page Word document)

This file is the section-by-section blueprint for the Step 4 report. Use it as the table of contents while drafting; each section points at the supporting context file and the figures/numbers to use.

## Constraints

- **Word document** (`.docx`), not PDF.
- **10–15 pages** total, including figures and tables.
- Must include the **data and the R code** so the analysis is reproducible.
- Must "show all your work, what models you have considered, and the model-building process" (course guidelines).
- Must include **AI disclosure** ([09_writing_style_and_ai_disclosure.md](09_writing_style_and_ai_disclosure.md)).
- Audio-vs-audio+genre comparison should be **visible throughout**, not just in the results table.

## Page budget

| Section | Target pp | Hard cap | What goes here |
|---|---:|---:|---|
| §1 Introduction | 1.5 | 2 | Industry framing, research question, sub-question |
| §2 Data and EDA | 2 | 2.5 | Source, cleaning, response, predictors, EDA highlights |
| §3 Methods | 2 | 2.5 | Pipeline, models, recipes, tuning, threshold tuning |
| §4 Results | 4 | 5 | Test/CV metrics, threshold comparison, feature attribution |
| §5 Discussion + Limitations | 3 | 3.5 | Interpretation, recommendations, limitations, future work |
| §6 Conclusion | 0.5 | 1 | Bottom-line summary |
| AI disclosure | 0.25 | 0.5 | Required disclosure language |
| **Total** | **~13 pp** | **15 pp** | |

## Section-by-section content

### §1 Introduction (~1.5 pp)

- **Opening hook:** the "why we care" framing the instructor asked for. Streaming as the dominant mode of music consumption; Spotify's scale; popularity as a listener-validated proxy for commercial success.
  - Verify current MAU and revenue numbers from a 2025/2026 source before quoting.
- **Research question:** "Can Spotify audio features help predict whether a track is high popularity?"
- **Sub-question:** "How much of the predictive signal comes from intrinsic audio features versus the playlist-assigned genre?"
- **The threshold-68 origin** — explain that the dataset author pre-split the data; we inherited the cutoff (Action Item 2).
- **Roadmap of the rest of the paper.**

**Supporting files:** [01_project_synopsis.md](01_project_synopsis.md), [07_instructor_feedback.md](07_instructor_feedback.md) Action Items 2 and 3.

**No figures needed** unless space allows for [figures/01b_histogram_track_popularity.png](../../figures/01b_histogram_track_popularity.png).

### §2 Data and EDA (~2 pp)

#### §2.1 Source and cleaning (~0.5 pp)

- Kaggle Spotify Music Dataset, sourced from Spotify Web API.
- Two pre-split CSVs joined to 4,831 raw rows.
- Deduplication by `track_id` keeping highest `track_popularity` per track → 4,495 EDA rows; one additional NA row dropped at modeling stage → **4,494 modeling rows**.
- **29.5% High / 70.5% Low** class split.

#### §2.2 Variables (~0.75 pp, table-driven)

- Reproduce the variable table from [02_data.md](02_data.md) §3 (continuous + categorical predictors).
- Note `playlist_subgenre` excluded (84 levels, overlap with `playlist_genre`).
- Note response `high_popularity` factor coding for `yardstick`.

#### §2.3 Univariate EDA (~0.25 pp)

- Continuous distributions reasonable; acousticness and instrumentalness right-skewed.
- 35-level `playlist_genre`; rare levels lumped to "other" (<1%) for modeling.
- Figure: [figures/01_histograms_continuous.png](../../figures/01_histograms_continuous.png).

#### §2.4 Bivariate EDA (~0.5 pp)

- Continuous vs class: loudness, instrumentalness, acousticness, energy show the largest separation. Mean differences and point-biserial correlations from [02_data.md](02_data.md) §4.3 / §4.5.
- Genre vs class: high-share spans 0% to 96% (high-share genres = pop, hip-hop, r&b, rock; low-share = ambient, lofi, jazz, world).
- Multicollinearity callout: energy ↔ loudness r = 0.80.
- Figures: [figures/03_box_continuous_by_response.png](../../figures/03_box_continuous_by_response.png), [figures/04_cat_vs_response_playlist_genre_top10.png](../../figures/04_cat_vs_response_playlist_genre_top10.png), [figures/05_correlation_heatmap.png](../../figures/05_correlation_heatmap.png), [figures/06_point_biserial_with_response.png](../../figures/06_point_biserial_with_response.png).

**Supporting files:** [02_data.md](02_data.md) §1–§4.

### §3 Methods (~2 pp)

#### §3.1 Train/test split and CV (~0.25 pp)

- 80/20 stratified split, seed 42; train n = 3,595, test n = 899.
- 5-fold stratified CV on the training set only.

#### §3.2 Models and feature sets (~0.5 pp)

- Three classifiers (LR, RF, SVM (RBF)) × two feature sets (audio, audio+genre) = six workflows.
- Engines: `glm` (LR), `ranger` 500-tree (RF), `kernlab` (SVM).
- Restate sub-question as the motivation for the parallel feature-set design.

#### §3.3 Recipes (~0.25 pp, table-driven)

- LR/SVM: median/mode impute → rare-level lump (1%) → one-hot encode → drop ZV → z-standardize.
- RF: median/mode impute → rare-level lump → no encoding, no scaling.

#### §3.4 Hyperparameter tuning (~0.5 pp)

- Tuning objective: `roc_auc` (threshold-independent, robust to imbalance).
- LR: no tuning. RF: `mtry`, `min_n` via 20-point space-filling grid. SVM: `cost ∈ [2^-2, 2^8]`, `rbf_sigma ∈ [1e-4, 1e-1]` via 20-point grid.
- Mention the explicit grid range constraints for SVM and *why* they exist (degenerate-corner avoidance from earlier debugging) — this is where the team shows methodological care.
- Selected hyperparameters table from [03_methodology.md](03_methodology.md) §6.

#### §3.5 Threshold tuning (~0.5 pp)

- F1-optimal threshold selected on CV out-of-fold predictions, applied once to the test set.
- Selected thresholds 0.19–0.33 (all below 0.5, consistent with 30/70 prior).
- We report **both** the default 0.5 numbers and the CV-tuned numbers for transparency.
- Frame this in line with the instructor's recommendation: ROC AUC is the threshold-independent headline; threshold tuning is shown as methodological completeness.

**Supporting files:** [03_methodology.md](03_methodology.md) §1–§7, [06_decisions_and_caveats.md](06_decisions_and_caveats.md) §3 (SVM grid history).

**No figures required.** The threshold-tuning explanation can be illustrated with [figures/models/threshold_sweep_f1.png](../../figures/models/threshold_sweep_f1.png) if space allows.

### §4 Results (~4 pp)

#### §4.1 ROC AUC: the threshold-independent headline (~0.75 pp)

- **This is the section the rest of the results section is anchored to.** Lead with the ROC overlay across all six workflows: [figures/models/all_roc_overlay.png](../../figures/models/all_roc_overlay.png).
- Three observations:
  1. Audio-only models reach AUC 0.67–0.76; audio+genre models reach AUC ≥ 0.84.
  2. Genre lift across all three model families: +0.07 to +0.17 in test ROC AUC. Consistent and large.
  3. The RF audio+genre curve dominates the others on audio+genre across most operating points; LR and SVM are nearly indistinguishable on the same feature set.
- Brier score (also threshold-independent) reinforces the ranking: RF audio+genre 0.132 < LR audio+genre 0.142 < SVM audio+genre 0.162.

#### §4.2 Test-set metrics — default 0.5 (~0.5 pp)

- Reproduce the default-0.5 metric table from [04_results.md](04_results.md) §2.
- Walk the reader through three observations:
  1. RF audio+genre is the best workflow on every metric (Accuracy 0.803, F1 0.613, ROC AUC 0.872).
  2. SVM (RBF) trails on every metric, by a small margin on audio+genre and a larger one on audio-only — acknowledged honestly per the user's direction. Possible interpretations are discussed in §5.3 (Limitations).
  3. Audio-only sensitivity at 0.5 is misleadingly low (0.09–0.20); this is a property of the 30/70 prior interacting with a fixed cutoff, not of the models — and motivates §4.3.

#### §4.3 Test-set metrics — CV-tuned thresholds (~0.75 pp)

- Reproduce the CV-tuned metric table from [04_results.md](04_results.md) §3.
- Show the sensitivity-gain table from §4 of `04_results.md`.
- Reference the F1-vs-threshold sweep figure ([figures/models/threshold_sweep_f1.png](../../figures/models/threshold_sweep_f1.png)) and note the broad F1 plateau on LR/RF audio+genre vs the sharper SVM audio+genre peak (consistent with `kernlab` calibration).
- Note: the rankings change slightly under tuned thresholds — RF audio+genre remains best (F1 0.690), but LR audio+genre is now competitive (F1 0.675), and the audio-only models cluster within a 0.058-F1 band.

#### §4.4 Cross-validation stability (~0.25 pp)

- Brief paragraph noting that test ROC AUC is within ~1 SE of CV ROC AUC for every workflow → no overfitting; the held-out test performance matches what the CV resamples predicted.
- Reproduce the CV metrics table from [04_results.md](04_results.md) §5 if space allows; otherwise summarize in prose.

#### §4.5 Feature attribution (~1.25 pp)

- Cross-model permutation importance — drop in test ROC AUC after shuffling each feature.
- Figure: [figures/models/interp_permutation_importance_all.png](../../figures/models/interp_permutation_importance_all.png).
- Three observations:
  1. `playlist_genre` dominates when available.
  2. Among audio features, instrumentalness and loudness consistently lead.
  3. Adding genre largely *replaces* the role of acousticness/energy/duration but not the role of instrumentalness/loudness — those remain informative even after controlling for genre.
- LR coefficients (Figure: [figures/models/interp_lr_coefficients.png](../../figures/models/interp_lr_coefficients.png)) interpreted carefully — note z-standardization, note the energy ↔ loudness multicollinearity.
- RF native importance (Figure: [figures/models/interp_rf_importance.png](../../figures/models/interp_rf_importance.png)) as a confirmation.

#### §4.6 Best-workflow deep-dive (~0.5 pp)

- For RF on audio+genre: confusion matrix at the **CV-tuned threshold** (since the surrounding text references tuned thresholds), ROC curve with operating-point marker, calibration plot.
- Figures: [figures/models/perm_rf_genre_confmat_tuned.png](../../figures/models/perm_rf_genre_confmat_tuned.png), [figures/models/perm_rf_genre_roc.png](../../figures/models/perm_rf_genre_roc.png), [figures/models/perm_rf_genre_calibration.png](../../figures/models/perm_rf_genre_calibration.png).

**Supporting files:** [04_results.md](04_results.md), [05_figures.md](05_figures.md).

### §5 Discussion + Limitations (~3 pp)

#### §5.1 Interpretation: what the results tell us about hits (~1 pp)

- Re-state the headline numbers in plain language.
- Address the sub-question: how much signal comes from audio vs from genre?
- Use the LR coefficient signs and the cross-model permutation importance to characterize the audio properties that distinguish hits from non-hits.

#### §5.2 Recommendations for music makers (~1 pp)

- The five recommendations from [04_results.md](04_results.md) §7. **This is where the instructor's "actionable insights" expectation gets answered.**
- **Anchor each quantitative recommendation in the partial-dependence plots** ([figures/models/pdp_rf_genre_top4.png](../../figures/models/pdp_rf_genre_top4.png)). For example: "the model's predicted P(High) rises from roughly 0.15 at −20 dB loudness to roughly 0.45 at 0 dB loudness, holding all other features at their empirical distribution." Reading numbers directly off the PDP curves is much more concrete than reading them off LR coefficients (which are partial-effect-conditional and on a z-scaled axis).
- Phrase recommendations conditionally and honestly — no causal claims.

#### §5.3 Limitations (~0.75 pp)

- The `playlist_genre` curatorial-signal caveat (most important).
- Popularity threshold inherited.
- SVM underperformance, even after grid-range fixes.
- Static popularity snapshot, no temporal validation.
- Multicollinearity caveat for LR coefficient interpretation.
- See [08_limitations_future_work.md](08_limitations_future_work.md).

#### §5.4 Future work (~0.25 pp)

- Sensitivity at alternative popularity thresholds.
- Continuous regression on `track_popularity`.
- Intrinsic genre derived from audio (removes curatorial leakage).
- Linear-kernel SVM as a comparison.
- Optional: a small neural network as the optional fourth model the instructor mentioned.

**Supporting files:** [04_results.md](04_results.md) §7, [08_limitations_future_work.md](08_limitations_future_work.md).

### §6 Conclusion (~0.5 pp)

- One paragraph restating: audio features predict popularity meaningfully (AUC ≈ 0.73–0.76); adding playlist genre boosts predictions substantially (AUC ≈ 0.84–0.87); loudness, instrumentalness, and genre are the three most informative levers; the audio+genre lift partly reflects curatorial signal, which is itself a useful but caveated predictor.
- One closing sentence on what this means for an artist or label deciding what to do next.

### AI disclosure (~0.25 pp)

Verbatim from [09_writing_style_and_ai_disclosure.md](09_writing_style_and_ai_disclosure.md), edited as needed to be accurate.

## Tables to include in the report

These are explicit tables (not just figures) the report should have:

1. **Variable table** in §2.2 (continuous + categorical predictors with type, range, description).
2. **Test-set metrics, default 0.5** in §4.2.
3. **Test-set metrics, CV-tuned thresholds vs default 0.5 side-by-side** in §4.3 — this is the table that operationalizes the "show both threshold schemes" decision.
4. **CV metrics** at selected hyperparameters in §4.4 (or summary in prose).
5. **Selected hyperparameters** in §3.4.
6. **Permutation importance** for the audio+genre feature set in §4.5 (top 5–8 features).

All tables should be Word native tables (not screenshots), with caption and source references.

## Figures to include in the report

Recommended set, approximately in this order:

1. [figures/01b_histogram_track_popularity.png](../../figures/01b_histogram_track_popularity.png) (§2.1) — response distribution + threshold line.
2. [figures/03_box_continuous_by_response.png](../../figures/03_box_continuous_by_response.png) (§2.4) — continuous predictors by class.
3. [figures/04_cat_vs_response_playlist_genre_full.png](../../figures/04_cat_vs_response_playlist_genre_full.png) or top-10 (§2.4) — genre signal.
4. [figures/05_correlation_heatmap.png](../../figures/05_correlation_heatmap.png) (§2.4) — multicollinearity.
5. [figures/06_point_biserial_with_response.png](../../figures/06_point_biserial_with_response.png) (§2.4) — predictor signal direction.
6. **[figures/models/all_roc_overlay.png](../../figures/models/all_roc_overlay.png) (§4.1) — ROC overlay with CV-tuned operating-point markers. THE headline figure.**
7. [figures/models/all_metric_comparison_combined.png](../../figures/models/all_metric_comparison_combined.png) (§4.2 / §4.3) — single chart showing default 0.5 and CV-tuned bars side by side. Use *this* chart instead of separate default and tuned versions when space is tight.
8. [figures/models/threshold_sweep_f1.png](../../figures/models/threshold_sweep_f1.png) (§4.3) — F1 vs threshold, with CV-tuned thresholds marked.
9. [figures/models/interp_permutation_importance_all.png](../../figures/models/interp_permutation_importance_all.png) (§4.5) — cross-model importance with ±SD error bars.
10. **[figures/models/pdp_rf_genre_top4.png](../../figures/models/pdp_rf_genre_top4.png) (§5.1 / §5.2)** — partial-dependence plots for loudness, instrumentalness, acousticness, energy. Anchors the music-maker recommendations.
11. [figures/models/perm_rf_genre_confmat_tuned.png](../../figures/models/perm_rf_genre_confmat_tuned.png) (§4.6) — best-workflow confusion matrix at the CV-tuned threshold.

Optional appendix figure (if space allows):
- [figures/models/interp_lr_coefficients.png](../../figures/models/interp_lr_coefficients.png) — LR coefficients, useful for discussion of multicollinearity-aware coefficient interpretation.

That's 11 figures over ~13 pp. Cap at 12 to leave room for prose.

## Submission packaging

- Report: `MIS720_Step4_FinalReport_TeamB2.docx`
- Data files: `data/high_popularity_spotify_data.csv`, `data/low_popularity_spotify_data.csv` (and ideally `output/spotify_clean.csv` for traceability).
- R code: `01_eda.R`, `02_modeling.R`, plus `MIS720_Group_Project.Rproj` for one-click open.
- Coordinator emails on May 7 with subject `MIS720 project report + B2`, CC'ing all team members.

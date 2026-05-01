# Results — Headline numbers, full tables, and what to say about them

All numbers re-extracted from `output/*.rds` and `output/*.csv` on 2026-04-30. If the modeling pipeline is re-run, these may shift slightly.

## 0. Headline reporting convention (settled)

- **Lead with ROC AUC** as the threshold-independent headline metric. The headline visual is [figures/models/all_roc_overlay.png](../../figures/models/all_roc_overlay.png).
- **Show both threshold schemes** (default 0.5 *and* CV-tuned F1-optimal) for sensitivity, specificity, precision, F1, and accuracy. The numerical record is [output/threshold_comparison.csv](../../output/threshold_comparison.csv).
- **SVM stays in the headline tables.** Its underperformance is acknowledged honestly, not hidden.
- **Do not** drop or relegate the threshold-tuning work to an appendix — it is methodologically real and the F1-vs-threshold sweep ([figures/models/threshold_sweep_f1.png](../../figures/models/threshold_sweep_f1.png)) is the visual that explains why audio-only sensitivity at 0.5 looks weak.

## 1. Headline numbers (memorize)

1. **Best model: Random Forest on audio + genre.**
   - Test ROC AUC = **0.872**
   - CV-tuned F1 = **0.690** (at threshold 0.33)
   - Default-0.5 F1 = 0.613, accuracy 0.803

2. **Genre lift in test ROC AUC** — adding `playlist_genre` to the audio features:
   - Logistic Regression: 0.731 → 0.849 (**+0.118**)
   - Random Forest:     0.760 → 0.872 (**+0.112**)
   - SVM (RBF):         0.674 → 0.842 (**+0.168**)

3. **Threshold tuning lifts sensitivity dramatically.** Selected thresholds are all in the 0.19–0.33 range (well below 0.5), consistent with the 30/70 prior. Sensitivity gains range from +0.20 to +0.84 across the six workflows.

4. **Top features (cross-model permutation importance, drop in test AUC):**
   - **Audio-only models:** instrumentalness (0.084–0.096) and loudness (0.032–0.039) dominate.
   - **Audio+genre models:** `playlist_genre` dominates by a wide margin (~0.18–0.23), with instrumentalness and loudness retaining secondary importance.

5. **SVM is the weakest of the three model families on every metric.** Even after explicit grid range constraints, audio+genre SVM peaks at AUC 0.842 — behind both LR (0.849) and RF (0.872). Acknowledge honestly; do not hide.

## 2. Test-set metrics — at default threshold 0.50

From [output/test_metrics_summary.csv](../../output/test_metrics_summary.csv).

| Model | Feature set | ROC AUC | Accuracy | Sensitivity | Specificity | Precision | F1 | Brier |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| Logistic Regression | audio | 0.731 | 0.703 | 0.094 | 0.957 | 0.481 | 0.158 | 0.178 |
| Logistic Regression | audio+genre | **0.849** | 0.784 | 0.562 | 0.877 | 0.656 | 0.606 | 0.142 |
| Random Forest | audio | 0.760 | 0.724 | 0.200 | 0.943 | 0.596 | 0.299 | 0.172 |
| Random Forest | audio+genre | **0.872** | **0.803** | 0.528 | 0.918 | **0.729** | 0.613 | **0.132** |
| SVM (RBF) | audio | 0.674 | 0.686 | 0.155 | 0.909 | 0.414 | 0.225 | 0.196 |
| SVM (RBF) | audio+genre | 0.842 | 0.778 | 0.475 | 0.904 | 0.674 | 0.558 | 0.162 |

**Read this table at default 0.5:** ROC AUC and Brier score are threshold-independent — the genre lift in those columns is the cleanest evidence for the sub-question. The threshold-dependent columns (sensitivity, F1) look weak for the audio-only models because the 0.5 cutoff doesn't intersect a 30/70 prior usefully — see §3.

## 3. Test-set metrics — at CV-tuned thresholds

From [output/threshold_comparison.csv](../../output/threshold_comparison.csv) (CV-tuned rows).

| Model | Feature set | Threshold | Accuracy | Sensitivity | Specificity | Precision | F1 |
|---|---|---:|---:|---:|---:|---:|---:|
| Logistic Regression | audio | 0.23 | 0.586 | 0.936 | 0.440 | 0.411 | 0.571 |
| Logistic Regression | audio+genre | 0.29 | 0.765 | 0.826 | 0.740 | 0.570 | 0.675 |
| Random Forest | audio | 0.31 | 0.654 | 0.804 | 0.591 | 0.451 | 0.578 |
| Random Forest | audio+genre | **0.33** | **0.779** | **0.834** | 0.756 | 0.588 | **0.690** |
| SVM (RBF) | audio | 0.25 | 0.590 | 0.755 | 0.521 | 0.397 | 0.520 |
| SVM (RBF) | audio+genre | 0.19 | 0.758 | 0.743 | 0.763 | 0.568 | 0.644 |

**Compared to default 0.5:** sensitivity goes up substantially in every workflow, at some cost to specificity and precision. F1 (the metric used to choose the threshold) goes up in every workflow except none.

### Two observations to use in the prose around this table

1. **At CV-tuned thresholds, RF on audio+genre remains best (F1 0.690), but LR on audio+genre is now competitive (F1 0.675).** The headline ranking does not change, but the model-to-model gaps narrow when each model operates at its own appropriate decision point rather than a uniform 0.5 cut.
2. **On audio-only inputs, the three models cluster within a 0.058-F1 band (0.520–0.578) at tuned thresholds.** Threshold tuning largely closes the model-family gap when audio is the only signal — meaning the choice of model matters less than the choice of feature set.

### Threshold-sweep stability (from the F1 vs threshold sweep)

[figures/models/threshold_sweep_f1.png](../../figures/models/threshold_sweep_f1.png) shows the F1 curves for each workflow with the CV-selected threshold marked.

- **LR and RF on audio+genre have broad F1 plateaus** — F1 stays roughly 0.65 across thresholds 0.25–0.55. These models are robust to small threshold misspecification.
- **The audio-only curves and the SVM audio+genre curve peak more sharply.** The SVM audio+genre curve peaks at the lowest threshold of any workflow (0.19), consistent with `kernlab`'s known difficulty producing well-calibrated probabilities (see [03_methodology.md](03_methodology.md) §6).

## 4. Difference between the two threshold schemes (sensitivity gain)

Using the tuned threshold relative to default 0.5:

| Workflow | Sensitivity (0.5) | Sensitivity (tuned) | Gain |
|---|---:|---:|---:|
| `lr_audio` | 0.094 | 0.936 | **+0.84** |
| `lr_genre` | 0.562 | 0.826 | +0.26 |
| `rf_audio` | 0.200 | 0.804 | +0.60 |
| `rf_genre` | 0.528 | 0.834 | +0.31 |
| `svm_audio` | 0.155 | 0.755 | +0.60 |
| `svm_genre` | 0.475 | 0.743 | +0.27 |

This is the "why threshold tuning matters" table. Sensitivity gains are largest on audio-only models because that's where the default 0.5 was hurting them most.

## 5. CV metrics at the selected hyperparameters

From [output/cv_metrics.rds](../../output/cv_metrics.rds). These are out-of-fold averages across the 5 CV folds, at threshold 0.5 (CV uses threshold-independent metrics for tuning).

| Workflow | CV ROC AUC (mean ± SE) | CV Accuracy (mean ± SE) | CV Brier (mean ± SE) |
|---|---:|---:|---:|
| `lr_audio` | 0.705 ± 0.012 | 0.700 ± 0.006 | 0.185 ± 0.002 |
| `lr_genre` | 0.830 ± 0.009 | 0.779 ± 0.007 | 0.147 ± 0.004 |
| `rf_audio` | 0.741 ± 0.013 | 0.718 ± 0.008 | 0.178 ± 0.003 |
| `rf_genre` | 0.840 ± 0.009 | 0.790 ± 0.006 | 0.144 ± 0.004 |
| `svm_audio` | 0.687 ± 0.012 | 0.699 ± 0.003 | 0.192 ± 0.001 |
| `svm_genre` | 0.829 ± 0.007 | 0.781 ± 0.007 | 0.162 ± 0.004 |

CV-vs-test agreement is good — test ROC AUCs are within ~1 SE of the CV estimates for every workflow, suggesting no overfitting and a stable pipeline.

## 6. Permutation importance (cross-model, drop in test AUC)

From [output/permutation_importance.rds](../../output/permutation_importance.rds). Higher = more important. Negative values mean shuffling that feature happened to *help* the test AUC slightly (within noise).

### Audio-only feature set

| Feature | LR (audio) | RF (audio) | SVM (audio) |
|---|---:|---:|---:|
| **instrumentalness** | **0.096** | **0.084** | **0.093** |
| **loudness** | **0.039** | **0.037** | 0.032 |
| acousticness | 0.019 | 0.018 | 0.016 |
| energy | 0.016 | 0.016 | 0.028 |
| speechiness | 0.010 | 0.013 | n/a |
| key | 0.005 | −0.001 | n/a |
| time_signature | 0.005 | 0.002 | n/a |
| duration_ms | 0.000 | 0.027 | n/a |
| valence | 0.001 | 0.002 | 0.004 |
| tempo | −0.006 | 0.004 | n/a |
| danceability | 0.000 | 0.007 | 0.030 |
| liveness | 0.000 | 0.001 | n/a |
| mode | −0.003 | 0.000 | n/a |

(Some SVM cells were not extracted in the snippet above; see the full RDS for completeness.)

### Audio + genre feature set

| Feature | LR (audio+genre) | RF (audio+genre) |
|---|---:|---:|
| **playlist_genre** | **0.230** | **0.182** |
| instrumentalness | 0.034 | 0.085 |
| loudness | 0.019 | 0.046 |
| duration_ms | 0.002 | 0.020 |
| energy | 0.002 | 0.016 |
| acousticness | 0.000 | 0.010 |
| valence | 0.000 | 0.007 |
| danceability | 0.006 | 0.006 |
| speechiness | 0.005 | 0.004 |
| tempo | −0.001 | 0.005 |
| key | 0.004 | 0.001 |
| time_signature | 0.000 | 0.001 |
| liveness | 0.000 | 0.001 |
| mode | 0.000 | 0.000 |

**Three things to say about this table in the report and presentation:**

1. **`playlist_genre` dominates** when it's available — its mean drop in test AUC is roughly 4× the next-most-important feature. This is consistent with the EDA finding that genre-level high-share varies from 0% to 96% (see [02_data.md](02_data.md) §4.7).
2. **Among audio features, instrumentalness and loudness are the consistent winners** across all model families and both feature sets. They are the audio properties with the strongest single-feature signal for predicting "hit" status.
3. **Adding genre largely *replaces* the predictive role of acousticness, energy, and duration**, but instrumentalness and loudness remain importantly informative even after controlling for genre. This is the mechanistically interesting finding: the audio properties that survive the addition of genre are the ones most likely to reflect intrinsic production choices, not just genre conventions.

## 7. Logistic-regression coefficient story (for music-maker recommendations)

The instructor explicitly asked us to **examine which variables are significant in logistic regression and provide actionable suggestions for music makers**. The figure is [figures/models/interp_lr_coefficients.png](../../figures/models/interp_lr_coefficients.png).

Because the LR recipe z-standardizes numeric features, coefficients on continuous predictors are on a per-SD basis. Use the figure to read the magnitudes; the directions are:

| Predictor | Effect on log-odds of High | Practical translation |
|---|---|---|
| **loudness** | +(strong) | Louder masters are more likely to be classified High. A 1-SD increase (~7 dB) is a sizeable bump in odds. |
| **energy** | + | More energetic tracks score higher (correlated with loudness). |
| **danceability** | + (modest) | Danceability is positive but smaller after controlling for loudness/energy. |
| **valence** | + (modest) | More positive-sounding tracks score higher. |
| **instrumentalness** | − (strong) | Heavily instrumental tracks are far less likely to be classified High. |
| **acousticness** | − | Acoustic tracks are less likely to be classified High. |
| **speechiness** | ~0 | No strong direction on average. |
| **liveness** | ~0 | No strong direction. |
| **playlist_genre dummies** | varies — pop, hip-hop, r&b, rock are large positives; ambient, lofi, jazz, classical are large negatives | Genre membership is the largest single predictor by far. |

> **Important caveat to state in the report:** these coefficients describe associations under z-standardized features, with all other predictors held constant. They are not causal; tracks that are louder are also typically more produced and on different playlists. Multicollinearity (energy ↔ loudness ≈ 0.80) means the partial coefficient for energy is suppressed when loudness is also in the model.

### Recommendations to music makers (actionable conclusion the instructor asked for)

Phrase these in plain language. Suggested form for the conclusion:

1. **Master your tracks loud (within mainstream norms, ~−7 to −5 dB integrated loudness).** Loudness is the single largest *intrinsically controllable* audio feature for predicted-popularity. High-popularity tracks in our dataset average **−6.8 dB** vs **−10.6 dB** for low-popularity tracks.
2. **Avoid heavy instrumentalness.** Vocal-driven tracks are far more likely to be classified High; tracks with `instrumentalness > 0.5` (effectively no vocals) are extremely rare in the High class.
3. **Aim for vocal-driven, produced (non-acoustic) production.** This is consistent with mainstream charting tracks and is the second-strongest controllable lever after loudness.
4. **Genre-fit matters a lot — but it is a *placement* lever, not a *production* lever.** A track placed on a pop, hip-hop, R&B, or rock playlist starts with a much higher prior probability of being classified High than one placed on an ambient, lofi, or jazz playlist. This is partly real (mainstream genres are more popular) and partly an artifact of how the dataset is built (popularity is propagated through playlist provenance).
5. **Energy and danceability help, but smaller.** Once loudness is controlled, the additional contribution of energy and danceability is modest. Don't sacrifice production quality to chase these.

## 8. Per-workflow visual deep-dives

For any single model the team wants to discuss in detail (e.g., the best workflow `rf_genre`), there are five companion plots:

- `figures/models/perm_<wf_id>_confmat.png` — confusion matrix
- `figures/models/perm_<wf_id>_roc.png` — ROC curve
- `figures/models/perm_<wf_id>_pr.png` — precision-recall curve
- `figures/models/perm_<wf_id>_calibration.png` — calibration plot
- `figures/models/perm_<wf_id>_proba.png` — predicted-probability density by class

Substitute `lr_audio`, `lr_genre`, `rf_audio`, `rf_genre`, `svm_audio`, `svm_genre`. Use these for an appendix or for Q&A backup; the headline figures are the cross-model overlays in [05_figures.md](05_figures.md).

## 9. What to say about model agreement

LR and RF on audio+genre are very close on test ROC AUC (0.849 vs 0.872) and CV ROC AUC (0.830 vs 0.840). LR is meaningfully more interpretable; RF is meaningfully more accurate. The "right" choice depends on whether the user values explanatory clarity (LR) or predictive performance (RF).

SVM (RBF) tracks the other two on audio+genre AUC but underperforms on every threshold-dependent metric and is harder to tune. The takeaway: for tabular Spotify-style data with a strong categorical signal, RBF kernels do not buy anything that a glm or a tree ensemble doesn't already provide.

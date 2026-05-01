# Methodology — Pipeline, Models, Tuning, Threshold Selection

Authoritative source for any methodology detail. If a number or step here disagrees with the slides or the proposal, this file is correct (it was reverified against [02_modeling.R](../../02_modeling.R) on 2026-04-30).

## 1. Pipeline overview

Two scripts run in strict order; the second consumes an artifact from the first.

1. **[01_eda.R](../../01_eda.R)** — load, reconcile, deduplicate, build the response, run univariate and bivariate EDA, write `output/spotify_clean.{rds,csv}` and figures under `figures/`.
2. **[02_modeling.R](../../02_modeling.R)** — read `output/spotify_clean.rds`, drop one NA-heavy row, stratified 80/20 split, 5-fold stratified CV on the training set, fit and tune 6 workflows, evaluate on the held-out test set, sweep the decision threshold for F1, generate per-model and cross-model figures, and write modeling artifacts to `output/`.

Re-running the modeling script requires the EDA output to exist; if it is missing, run `01_eda.R` first. From a shell:

```sh
Rscript 01_eda.R
Rscript 02_modeling.R
```

## 2. Train/test split

- **80/20 stratified by `high_popularity`**, seed 42.
- **Train n = 3,595**, **Test n = 899**.
- Test set is held out for one-shot evaluation per workflow.

## 3. Cross-validation

- **5-fold stratified by class**, on the **training set only**.
- CV is the basis for hyperparameter selection and for the threshold sweep (see §6 below).

## 4. Models and feature sets

Three models × two feature sets = **six workflows**.

| Workflow ID | Model | Engine | Feature set |
|---|---|---|---|
| `lr_audio` | Logistic Regression | `glm` | audio only |
| `lr_genre` | Logistic Regression | `glm` | audio + playlist_genre |
| `rf_audio` | Random Forest | `ranger` (500 trees) | audio only |
| `rf_genre` | Random Forest | `ranger` (500 trees) | audio + playlist_genre |
| `svm_audio` | SVM (RBF) | `kernlab` | audio only |
| `svm_genre` | SVM (RBF) | `kernlab` | audio + playlist_genre |

**Feature sets:**
- *audio* = the 10 continuous audio features + `key` + `mode` + `time_signature`.
- *audio + genre* = the audio set plus `playlist_genre`.

The point of this parallel structure is to isolate how much signal `playlist_genre` adds beyond the intrinsic audio features (research sub-question — see [01_project_synopsis.md](01_project_synopsis.md)).

## 5. Recipes (preprocessing)

### LR and SVM recipe (shared)

1. Median-impute numeric predictors.
2. Mode-impute nominal predictors.
3. `step_other(threshold = 0.01)` on `playlist_genre` — lump rare levels (<1%) into "other" (audio+genre only).
4. One-hot encode all factors.
5. Drop zero-variance columns.
6. Z-standardize all numeric columns (mean 0, SD 1).

### RF recipe

1. Median-impute numerics.
2. Mode-impute nominals.
3. `step_other(threshold = 0.01)` on `playlist_genre` (audio+genre only).
4. **No** dummy encoding (ranger handles factor levels natively).
5. **No** scaling (trees are scale-invariant).

This split exists because LR and SVM benefit substantially from standardized inputs and need numeric encoding; RF does not, and forcing dummy encoding on RF is known to hurt high-cardinality categorical handling.

## 6. Hyperparameter tuning

- **Tuning objective:** `roc_auc` (threshold-independent and not biased by class imbalance).
- **Tuning metric set:** `{roc_auc, accuracy, brier_class}` — only threshold-independent metrics. Threshold-dependent metrics like F1/precision are NaN for hyperparameter combinations that predict no positives, which created warning noise during SVM tuning. Threshold-dependent metrics are computed only at final test-set evaluation and during the threshold sweep.
- **Random Forest:** `mtry` and `min_n` tuned via 20-point space-filling grid; default `dials` ranges. **500 trees**. Permutation importance enabled on the engine.
- **SVM (RBF):** `cost` and `rbf_sigma` tuned via 20-point space-filling grid over **explicit ranges**:
  - `cost ∈ [2^−2, 2^8]` (i.e., 0.25 to 256)
  - `rbf_sigma ∈ [1e-4, 1e-1]`
  - These ranges replace the `dials` defaults, which include degenerate corners that caused SVMs to land on a constant kernel and predict majority class. See [06_decisions_and_caveats.md](06_decisions_and_caveats.md) §3 for the history.
- **Logistic Regression:** no tuning (single fit per workflow).

### Selected hyperparameters (re-extracted from `output/best_hyperparameters.rds`)

| Workflow | Hyperparameter | Value |
|---|---|---|
| `lr_audio` | none | — |
| `lr_genre` | none | — |
| `rf_audio` | `mtry`, `min_n` | 3, 18 |
| `rf_genre` | `mtry`, `min_n` | 8, 16 |
| `svm_audio` | `cost`, `rbf_sigma` | 9.6008, 0.02336 |
| `svm_genre` | `cost`, `rbf_sigma` | 177.7473, 0.000428 |

Note that the genre SVM `cost` value (177.7) is well below the upper grid bound (256), confirming the search was not truncated this time.

### `kernlab` warning suppression

During SVM tuning, `kernlab` emits "maximum number of iterations reached" and "line search fails" warnings on degenerate cells. These are suppressed via a narrow `quiet_kernlab()` filter that only catches those two strings; everything else passes through. Final fits are sound and converge on the selected hyperparameters.

### Note on `kernlab` probability calibration

`kernlab` is known to produce **less-well-calibrated probabilities** than `glm` or `ranger`. This shows up in two places:
1. The audio+genre SVM's F1-optimal threshold lands at **0.19** — the lowest of the six workflows — because the SVM's probability outputs sit lower than the other models' for the same level of evidence.
2. The SVM rows of [figures/models/all_calibration_overlay.png](../../figures/models/all_calibration_overlay.png) deviate from the diagonal more than LR or RF.
This is a property of `kernlab`, not of the data; the team is aware of it and does not attempt to recalibrate.

## 7. Threshold tuning (F1-optimal, on CV out-of-fold predictions)

This step matters and the team should be ready to defend it cleanly in Q&A.

- **Why it exists:** at the conventional 0.5 cutoff, audio-only models had sensitivity 0.09–0.20 for the High class. The models were not broken; the 0.5 cutoff just doesn't intersect a 30/70 prior in a useful place.
- **How it's done:**
  1. For each tuned workflow, get the CV out-of-fold predicted probabilities (held-out-fold predictions across the 5 CV folds).
  2. Sweep candidate thresholds from 0.05 to 0.95 in 0.01 steps.
  3. Select the threshold that maximizes F1 (High class).
  4. Apply that single threshold once to the held-out test set.
- **Selected thresholds** (from `output/best_thresholds.rds`):

| Workflow | F1-optimal threshold | CV F1 at that threshold |
|---|---:|---:|
| `lr_audio` | **0.23** | 0.541 |
| `lr_genre` | **0.29** | 0.649 |
| `rf_audio` | **0.31** | 0.562 |
| `rf_genre` | **0.33** | 0.656 |
| `svm_audio` | **0.25** | 0.518 |
| `svm_genre` | **0.19** | 0.632 |

All selected thresholds are below 0.5, consistent with the 30/70 prior (positive class is the minority).

The F1-vs-threshold curves with these tuned thresholds marked are in [figures/models/threshold_sweep_f1.png](../../figures/models/threshold_sweep_f1.png).

### Reporting threshold convention

**Per the instructor's Step-2 feedback** ([07_instructor_feedback.md](07_instructor_feedback.md)), the headline visual should be the **ROC AUC comparison** (threshold-independent), and the report should present **both threshold schemes side-by-side** so the reader can see the impact of threshold choice:

- ROC AUC and Brier score: report once (threshold-independent).
- Accuracy, sensitivity, specificity, precision, F1: report at default 0.5 *and* CV-tuned thresholds. The narrative explanation should make the threshold-tuning rationale explicit.

## 8. Class imbalance — handled by thresholds, not resampling

- The proposal explicitly avoided SMOTE/up-sampling.
- Class imbalance shows up only in the threshold tuning above.
- **Do not** add resampling discussion to the report unless the team decides to add it later. The instructor said the imbalance is mild ("data isn't very imbalanced") and resampling is unnecessary.

## 9. Final-evaluation metric set

On the test set, per workflow, at both threshold schemes:
`{roc_auc, accuracy, sensitivity, specificity, precision, f_meas, brier_class}`

The High class is the positive class everywhere because the response was releveled to `c("High", "Low")` so `yardstick`'s default `event_level = "first"` reports sensitivity/precision/recall for High.

## 10. Permutation importance (cross-model feature attribution)

- **Computed manually** on the held-out test set (not via any model's engine-native importance).
- **For each feature:** shuffle that feature's values, score the perturbed test set, record the drop in test ROC AUC. Repeat **5 times per feature** (each shuffle uses a deterministic seed `1000 + i`), report the mean drop.
- All three model families (LR, RF, SVM) are scored on the **same scale** — drop in test AUC — so they are directly comparable.
- The result table is in `output/permutation_importance.rds`. Cross-model figure: [figures/models/interp_permutation_importance_all.png](../../figures/models/interp_permutation_importance_all.png).
- **Random forest also has its own engine-native permutation importance** (from `ranger`), used in [figures/models/interp_rf_importance.png](../../figures/models/interp_rf_importance.png). Either is fine; the cross-model version is the comparable one.

## 11. Logistic-regression coefficient interpretability

- All numeric features are z-standardized in the LR recipe, so coefficients on continuous predictors are on a per-SD basis.
- The coefficient plot ([figures/models/interp_lr_coefficients.png](../../figures/models/interp_lr_coefficients.png)) **filters out quasi-separated terms** with `std.error > 5`. The filtered terms are listed in the script's console output (typically narrow genre dummies with very few examples). Keep this filter — quasi-separated coefficients have non-meaningful magnitudes and would dominate the plot otherwise.

## 12. Reproducibility

- `set.seed(42)` at the top of both scripts.
- Per-feature permutation importance seeds with `1000 + i` so importance numbers are stable across runs.
- Output artifacts in `output/` are fully reproducible from the two scripts and the source CSVs in `data/`.
- Both `RDS` and `CSV` versions exist for the cleaned dataset and the metric tables, so the instructor can inspect them in any tool.

## 13. Runtime

- `01_eda.R`: ~30 seconds on a modern laptop.
- `02_modeling.R`: ~5–25 minutes depending on cores. SVM RBF tuning is the bottleneck. `svm_grid_size` near the top of the script can be lowered to speed it up. Parallelism is on by default via `doParallel`; set `use_parallel <- FALSE` to disable.

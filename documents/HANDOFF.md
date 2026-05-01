# MIS 720 Team B2 — Project Handoff for Claude Code

**Project:** From Beats to Hits — Predicting Spotify Song Popularity
**Course:** MIS 720 (AI and Big Data), Spring 2026
**Team:** B2
**Current milestone:** Step 2 (Preliminary Analysis) — completed
**Next milestones:** Step 3 (12-min presentation, due May 4) and Step 4 (10–15 page report, due May 7)

---

## 1. Purpose of this document

You (Claude Code) are picking up an active project and will help the user assemble two deliverables:

1. **Step 3** — a 12-minute presentation (PowerPoint) with 3 minutes of Q&A
2. **Step 4** — a 10–15 page Word document final report, accompanied by the data and reproducible R code

The complete EDA and modeling work is already done. The R scripts run end-to-end and produce all of the figures and metrics the deliverables will reference. There is no remaining methodological work for the deliverables themselves — your job is aggregation, structuring, and writing, not analysis.

This document gives you the project background, scope, decisions, results, and gotchas. **Read sections 2–6 in order**; sections 7–9 are reference material to consult as needed.

The three PDFs in `documents/` are authoritative for content. This handoff complements them by surfacing context that isn't in any single document — decisions made, dead ends hit, and the "why" behind choices.

---

## 2. Repository orientation

Note that I do not know the exact repository layout the user has settled on, so the paths below reflect what the R scripts produce. If anything is missing, run `01_eda.R` then `02_modeling.R` to regenerate.

```
documents/
├── MIS720_Project_Proposal_Team_B2.pdf          # Step 1 deliverable; defines scope and methods
├── MIS720_Step2_PreliminaryAnalysis_Team_B2.pdf # Step 2 deliverable; closest analog to the final report
└── MIS720_Step2_TeamB2_Discussion_Slides.pdf    # Step 2 meeting deck (image-based PDF; reference for slide style)

01_eda.R                                          # EDA pipeline; produces output/spotify_clean.{rds,csv} and figures/*.png
02_modeling.R                                     # Modeling pipeline; produces output/*.rds and figures/models/*.png

data/
├── high_popularity_spotify_data.csv              # Source CSV (Kaggle), High class
└── low_popularity_spotify_data.csv               # Source CSV (Kaggle), Low class

output/
├── spotify_clean.rds                             # Cleaned/deduped dataset, factors set, response built
├── spotify_clean.csv                             # Same as above, CSV form
├── final_workflows.rds                           # 6 fitted tidymodels workflows
├── test_predictions.rds                          # Per-workflow test-set predictions
├── test_metrics.rds                              # Test metrics at threshold = 0.5
├── test_metrics_summary.csv                      # Same as above, CSV
├── test_metrics_tuned.rds                        # Test metrics at CV-tuned thresholds
├── threshold_comparison.rds                      # Long-format default-vs-tuned table
├── threshold_comparison.csv                      # Same as above, CSV
├── best_thresholds.rds                           # CV-selected F1-optimal threshold per workflow
├── best_hyperparameters.rds                      # Tuned hyperparameter values
├── cv_metrics.rds                                # CV metrics at the selected hyperparameters
└── permutation_importance.rds                    # Cross-model permutation importance (drop in test AUC)

figures/                                          # EDA plots (numbered by section in 01_eda.R)
├── 01_histograms_continuous.png
├── 01b_histogram_track_popularity.png
├── 02_bar_<varname>_full.png                     # one per categorical: key, mode, time_signature, playlist_genre, playlist_subgenre
├── 02_bar_playlist_genre_top10.png
├── 02_bar_playlist_subgenre_top15.png
├── 03_box_continuous_by_response.png
├── 04_cat_vs_response_<varname>_full.png         # one per categorical
├── 04_cat_vs_response_playlist_genre_top10.png
├── 04_cat_vs_response_playlist_subgenre_top15.png
├── 05_correlation_heatmap.png
└── 06_point_biserial_with_response.png

figures/models/
├── perm_<wf_id>_{confmat,roc,pr,calibration,proba}.png  # 5 plots × 6 workflows
├── all_roc_overlay.png
├── all_pr_overlay.png
├── all_calibration_overlay.png
├── all_metric_comparison.png
├── threshold_sweep_f1.png                        # F1 vs threshold; one panel per feature set
├── interp_lr_coefficients.png
├── interp_rf_importance.png
└── interp_permutation_importance_all.png         # Cross-model perm importance, three model panels stacked
```

Workflow IDs: `lr_audio`, `lr_genre`, `rf_audio`, `rf_genre`, `svm_audio`, `svm_genre`. `*_genre` is the audio+genre feature set.

---

## 3. The project in one paragraph

Two pre-split CSV files from a Kaggle Spotify dataset (one "high popularity," one "low") are joined into a 4,494-row track-level dataset after deduplication. The response is a binary indicator `high_popularity = (track_popularity > 68)`, yielding a 29.5% / 70.5% (High / Low) class split. Predictors are 10 continuous audio features plus 4 categoricals (key, mode, time_signature, playlist_genre); `playlist_subgenre` is excluded from modeling due to its 84-level cardinality and overlap with playlist_genre. Three classifiers (logistic regression, random forest with 500 trees, SVM with RBF kernel) are each trained on two parallel feature sets — *audio only* and *audio + playlist_genre* — for six workflows total. Each is tuned by 5-fold stratified CV on an 80/20 stratified train/test split, with ROC AUC as the tuning objective and decision thresholds tuned per-workflow on CV out-of-fold predictions to maximize F1. The headline finding is that adding `playlist_genre` to the audio features lifts test ROC AUC by 0.07–0.17 across all three model families; random forest on audio+genre is the best workflow (test AUC 0.872, CV-tuned F1 0.690).

---

## 4. Decisions and dead ends — read this before writing anything

These are the things that shaped the project but aren't obvious from reading the documents alone. They explain *why* the analysis is what it is.

### 4.1 The audio-vs-audio+genre framing is the spine

The proposal posed the research question *"Can Spotify audio features help predict whether a track is high popularity?"* The follow-up sub-question *"how much of the predictive signal comes from intrinsic audio features versus the playlist-assigned genre?"* is what actually drives the modeling architecture. Every result is paired across two feature sets so this comparison can be made directly. Both deliverables should keep this comparison at the center of the results discussion.

### 4.2 Threshold tuning is methodologically real, not cosmetic

Initial test-set metrics at the conventional 0.5 threshold made the audio-only models look broken (sensitivity 0.09–0.20 for the High class). They aren't broken; the 0.5 cutoff just doesn't intersect a 30/70 prior in a useful place. The pipeline now tunes each workflow's threshold on CV out-of-fold predictions to maximize F1, then applies that single threshold once to the held-out test set. Selected thresholds range from 0.19 to 0.33. **The final report should headline the CV-tuned numbers** (the team's stated preference, pending instructor confirmation in the Step 2 meeting). The 0.5 numbers are retained for transparency.

### 4.3 SVM (RBF) underperforms across the board

SVM is the weakest of the three models on every metric. Two earlier rounds of SVM debugging are reflected in the current code:

- The original `rbf_sigma` search range (`dials` default 1e-10 to 1) included a degenerate corner where the kernel matrix is essentially constant; the audio SVM landed there and predicted majority class. The grid is now constrained to `[1e-4, 1e-1]`.
- The original `cost` ceiling of 2^5 = 32 was being hit exactly by the genre SVM, indicating the search was truncating. It's now `[2^-2, 2^8]`.

Even after those fixes, SVM is best AUC 0.842 (audio+genre) — reasonable, but behind RF and LR. `kernlab` also produces "max iterations reached" warnings during tuning that we did not silence; they are harmless and the final fits are sound. The Step 2 meeting included a discussion question about whether to keep SVM or replace it; assume it stays unless the user says otherwise.

### 4.4 Class imbalance: handled via thresholds, not via resampling

The proposal explicitly avoided SMOTE-style resampling. Class imbalance shows up only in the threshold tuning. Do not add resampling discussion to the final report unless the user requests it.

### 4.5 Deduplication and the "one row" gotcha

Joining the two CSVs produces 4,831 rows; 295 of those are duplicates by `track_id`, of which 43 appear in both classes. The pipeline deduplicates by keeping the highest-popularity row per `track_id`, leaving 4,495 rows. One additional row has NA across most audio features and is dropped at the start of `02_modeling.R`. Final modeling dataset: **4,494 rows**.

### 4.6 `playlist_genre` as predictor — open methodological question

`playlist_genre` is derived from the *playlist* a track was sourced from, not from the track itself. Tracks on multiple playlists were deduplicated to keep the highest-popularity row, which means each track ends up tagged with the genre of its most-popular containing playlist. The Step 2 document raises this as a possible source of curatorial-signal leakage rather than pure track-level prediction. The team's plan is to report both feature sets and discuss the framing question explicitly in the final report's limitations section. Do not soften this; it is a real and substantive caveat.

### 4.7 What's *not* in scope

- **Decision trees and neural networks** are listed in the proposal as additional candidate methods. We did not implement them. The Step 2 discussion deck asks the instructor whether to add a fourth model. Until the user says otherwise, **assume three models, not four**.
- **No feature engineering** beyond standardization and rare-level lumping (`step_other(threshold = 0.01)` on `playlist_genre`).
- **`playlist_subgenre` is not modeled.** It is shown only in the appendix-style EDA figures (`figures/02_bar_playlist_subgenre_*` and `figures/04_cat_vs_response_playlist_subgenre_*`).

### 4.8 Reporting threshold convention to follow

All model metrics in the final report should follow the convention established in the Step 2 document:

- ROC AUC and Brier score are threshold-independent; report once.
- Sensitivity, specificity, precision, F1, accuracy: report at the CV-tuned threshold by default. The default-0.5 numbers can be retained in a comparison table for transparency, but the headline narrative should use the tuned thresholds. **The High class is the positive class everywhere** (the response factor was releveled to `c("High", "Low")` so yardstick metrics treat High as positive by default).

---

## 5. Headline numbers (memorize these)

These are the five things to know cold before writing about results.

1. **Working dataset:** 4,494 unique tracks; 29.5% High / 70.5% Low.
2. **Best model:** Random Forest on audio+genre. Test ROC AUC = **0.872**, CV-tuned F1 = **0.690** at threshold 0.33.
3. **Genre lift:** Adding `playlist_genre` lifts test ROC AUC by **0.07–0.17** across all three model families. The lift is consistent and large.
4. **Top audio features:** instrumentalness and loudness dominate when genre is excluded. When genre is included, `playlist_genre` dominates by a wide margin (~0.18–0.24 drop in test AUC under permutation), with instrumentalness and loudness retaining secondary importance.
5. **Threshold tuning:** CV-selected thresholds range 0.19–0.33 (all below 0.5, consistent with the 30/70 prior). The tuned thresholds raise sensitivity by 0.20–0.84 absolute across workflows.

Full test-set metrics table is in `output/test_metrics_summary.csv` (default 0.5) and `output/threshold_comparison.csv` (both schemes side-by-side). The Step 2 PDF (Tables 2 and 3) renders these for human reading.

---

## 6. Building Steps 3 and 4

### 6.1 Source-of-truth priority

When something needs to go into the final report or the presentation, the priority order for content is:

1. **`MIS720_Step2_PreliminaryAnalysis_Team_B2.pdf`** — closest in structure to what the final report should be. Sections 1–4 are essentially ready to be expanded; section 5 (Concerns and Questions) is where revision happens, since by Step 4 those questions will have been answered or absorbed.
2. **`MIS720_Project_Proposal_Team_B2.pdf`** — primary source for the introduction and motivation framing. The "why we care" framing, the dataset link, and the original variable hypotheses live here.
3. **`MIS720_Step2_TeamB2_Discussion_Slides.pdf`** — visual-style reference for the Step 3 deck. It establishes the team's slide aesthetic (teal-and-navy palette, white callout cards, "WHAT WE ANALYZED" / "REQUIREMENT: …" tag headers). The Step 3 deck should follow this style for consistency, though the content itself will change since Step 3 is the full presentation, not a check-in.
4. **R scripts (`01_eda.R`, `02_modeling.R`)** — authoritative for any methodological detail (preprocessing, hyperparameter ranges, exact metric definitions). Do not paraphrase methodology from memory; check the scripts.

### 6.2 Step 3 — Presentation (May 4, 12 min + 3 min Q&A)

Course requirements (from the project guidelines):
- Each team member must present.
- Do **not** include any R code.
- Summarize results in figures and tables, not prose.
- Audience is mixed-background; assume not everyone knows ML.

Suggested structure (~12 slides for a 12-minute talk):
1. Title
2. Motivation and research question (with sub-question on audio vs genre)
3. Data and response definition
4. EDA: continuous distributions
5. EDA: categorical predictors and the genre signal
6. EDA: response–predictor relationships (box plots / class composition)
7. Methods overview (the three classifiers, the two feature sets, the pipeline)
8. Hyperparameter tuning and threshold tuning
9. Results: test-set metrics comparison (the bar chart)
10. Results: ROC overlay and feature attribution (permutation importance)
11. Interpretation: which features matter, audio vs genre conclusion
12. Limitations and conclusion

Reference figures from the lists in section 7 below. The headline visualization for the talk is `figures/models/all_metric_comparison.png` — six bars per metric, organized by model and feature set, makes the audio-vs-genre lift immediately readable.

### 6.3 Step 4 — Final report (May 7, 10–15 pages, Word document)

Course requirements:
- Word document, not PDF.
- 10–15 pages.
- Must include the data and R code so the analysis is reproducible.
- Show all work — what models were considered and the model-building process.

Suggested page allocation (this matches the team's proposal in §5.5 of the Step 2 PDF):
- ~2 pp data and EDA
- ~2 pp methods
- ~4 pp results (including model comparison and feature attribution)
- ~3 pp interpretation, limitations, and the audio-vs-genre framing discussion

The Step 2 document is structurally the closest analog. Specifically:
- §1 (Project Recap) → expand into a full Introduction
- §2 (Data and EDA) → expand to ~2 pp with a couple of additional figures
- §3 (Methods) → expand with hyperparameter details and the threshold tuning subsection
- §4 (Preliminary Results) → this *is* the results section; add the per-model figures (ROC, calibration, etc.) for the best workflow
- §5 (Concerns and Questions) → reframe as Limitations and Future Work; the questions will have been answered by the meeting

**Required AI disclosure:** Anything written with AI assistance must be disclosed per the project guidelines. The Step 2 document's §6 has the disclosure language we used; carry that pattern forward.

---

## 7. Figure inventory by use case

This is a quick lookup table mapping "what do you want to show?" to "which figure file?".

| If you want to show… | Use this file |
|---|---|
| The response distribution and the threshold | `figures/01b_histogram_track_popularity.png` |
| Continuous predictor distributions | `figures/01_histograms_continuous.png` |
| Continuous predictors split by class | `figures/03_box_continuous_by_response.png` |
| Genre is the strongest single predictor | `figures/04_cat_vs_response_playlist_genre_full.png` |
| Multicollinearity among continuous predictors | `figures/05_correlation_heatmap.png` |
| Which predictors lean toward "hit" | `figures/06_point_biserial_with_response.png` |
| Headline test-set metric comparison (six bars per metric) | `figures/models/all_metric_comparison.png` |
| ROC curves, all six models | `figures/models/all_roc_overlay.png` |
| Precision-recall curves | `figures/models/all_pr_overlay.png` |
| Calibration overlay | `figures/models/all_calibration_overlay.png` |
| F1 vs threshold (with tuned thresholds marked) | `figures/models/threshold_sweep_f1.png` |
| Logistic regression coefficients | `figures/models/interp_lr_coefficients.png` |
| Random forest variable importance | `figures/models/interp_rf_importance.png` |
| Cross-model feature attribution (the comparable one) | `figures/models/interp_permutation_importance_all.png` |
| Per-model deep-dive (ROC, calibration, confusion, etc.) | `figures/models/perm_<wf_id>_{confmat,roc,pr,calibration,proba}.png` |

`<wf_id>` is one of `lr_audio`, `lr_genre`, `rf_audio`, `rf_genre`, `svm_audio`, `svm_genre`.

---

## 8. Methodology cheat sheet

Quick reference for any methodological detail you need to write up:

- **Train/test split:** 80/20, stratified by `high_popularity`, seed 42. Train n = 3,595, test n = 899.
- **CV scheme:** 5-fold stratified by class, on the training set only.
- **Tuning objective:** ROC AUC. Threshold-independent and not biased by class imbalance.
- **Tuning metric set:** `{roc_auc, accuracy, brier_class}` only — threshold-independent metrics. (Threshold-dependent metrics like F1/precision are NaN for hyperparameter combinations that predict no positives, which created warnings during SVM tuning. The full metric set is computed only at final test-set evaluation.)
- **Final-evaluation metric set:** `{roc_auc, accuracy, sensitivity, specificity, precision, f_meas, brier_class}` plus threshold-comparison metrics.
- **Random forest:** `ranger`, 500 trees; `mtry` and `min_n` tuned via 20-point space-filling grid; permutation importance enabled on the engine.
- **SVM:** `kernlab`, RBF kernel; `cost` and `rbf_sigma` tuned via 20-point space-filling grid over `cost ∈ [2^-2, 2^8]`, `rbf_sigma ∈ [1e-4, 1e-1]`.
- **Logistic regression:** `glm`, no tuning.
- **Recipes (LR and SVM):** median-impute numerics, mode-impute nominals, `step_other(threshold = 0.01)` on `playlist_genre` (audio+genre only), one-hot encode, drop zero-variance columns, z-standardize all numerics.
- **Recipes (RF):** same imputation and rare-level lumping; no encoding, no scaling.
- **Threshold tuning:** F1-optimal threshold selected on CV out-of-fold predictions, applied once to the held-out test set. Sweep 0.05–0.95 in 0.01 steps.
- **Permutation importance:** computed manually on the test set as the mean drop in ROC AUC over 5 shuffles per feature, so all three model families are on a comparable scale. (Random forest also has its own engine-native permutation importance, used in `figures/models/interp_rf_importance.png`.)

---

## 9. Final-report checklist

Things that are easy to forget. Cross-check before submitting Step 4:

- [ ] Word document (`.docx`), not PDF
- [ ] 10–15 pages
- [ ] Data files included (or accessible link)
- [ ] R code included and runnable end-to-end
- [ ] AI disclosure statement included
- [ ] Subject of email to instructor uses pattern: `MIS720 project report + team number`
- [ ] Coordinator emails report; CC all team members
- [ ] All model-building work shown (not just the final picks)
- [ ] Audio-vs-audio+genre comparison visible throughout the results section
- [ ] CV-tuned thresholds used for headline metrics; default-0.5 retained for transparency
- [ ] `playlist_genre` leakage caveat addressed in limitations
- [ ] SVM underperformance acknowledged honestly rather than hidden

For Step 3 (presentation):
- [ ] No R code in slides
- [ ] Each team member presents at least one section
- [ ] Slides emailed to instructor before class with subject `MIS 720 project presentation + team number`
- [ ] Coordinator sends, CCs all team members

---

## 10. Where to start

To get familiar with the project, start by:
1. Reading `documents/MIS720_Step2_PreliminaryAnalysis_Team_B2.pdf` cover to cover. This is the closest existing analog to the deliverable.
2. Reading `documents/MIS720_Project_Proposal_Team_B2.pdf` to get the introduction/motivation framing.
3. Reading `documents/MIS720_Step2_TeamB2_Discussion_Slides.pdf`. This was a progress update presentation the user created during Step 2.
4. Spot-checking `02_modeling.R` for any methodology detail before writing about it.
5. Asking the user clarifying questions about: (a) instructor feedback from the Step 2 meeting, since that meeting will have answered or reframed several of the open questions, and (b) team-level decisions about whether SVM stays, whether a fourth model gets added, and which threshold scheme is the headline.

Do not produce either deliverable without first confirming with the user what feedback came out of the Step 2 instructor meeting.

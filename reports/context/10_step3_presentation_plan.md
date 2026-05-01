# Step 3 — Presentation Plan (12 minutes + 3 minutes Q&A)

This file is the slide-by-slide blueprint for the Step 3 deck. It is a starting structure, not a deck to copy verbatim — confirm the assignments and sub-bullets with the team before building.

## Constraints

- **12 minutes** for the talk, **3 minutes** for Q&A.
- **No R code** on slides. Summarize in figures and tables.
- **Each member presents at least one section** (Step 3 requirement).
- **Mixed audience.** Define jargon the first time it appears.
- Visual style: match the Step 2 discussion deck (teal/coral palette, small-caps section tags, big-number callouts, white callout cards). See [09_writing_style_and_ai_disclosure.md](09_writing_style_and_ai_disclosure.md).

## Slide budget

12 minutes ≈ **12 content slides + 1 title slide + 1 closing slide** (so ~14 max). Don't pack more — the audience will be lost. Aim for 50–70 seconds per content slide.

## Proposed slide structure

The structure below maps each slide to (a) the content file in this directory that supports it, (b) the figure(s) to use, and (c) which team member is the natural presenter. Adjust the presenter assignments after team discussion.

### Slide 1 — Title

- **Title:** *From Beats to Hits — Predicting Spotify Song Popularity*
- **Subtitle:** *Team B2 | MIS 720 | Spring 2026*
- **Members:** Senjuti Sarkar, Robert Ashe, Sonika Srinivas
- **Visual style:** mirror the Step 2 discussion deck's title slide.
- **Time:** 15 seconds.

### Slide 2 — Motivation ("Why we care") — Member A

- **Goal:** answer the instructor's Action Item 3 (industry framing).
- **Bullets:**
  - Streaming is now the dominant mode of recorded-music consumption.
  - Spotify is the largest streaming platform globally (cite current MAU and revenue from a 2025/2026 source — verify before quoting).
  - A reliable model of *what makes a track hit-like* is useful to artists, labels, and playlist editors.
- **One-sentence research question on the slide:** *"Can Spotify audio features help predict whether a track is high popularity — and how much of that signal comes from intrinsic audio features versus the playlist a track is sourced from?"*
- **Source:** [01_project_synopsis.md](01_project_synopsis.md), [07_instructor_feedback.md](07_instructor_feedback.md) Action Item 3.
- **Time:** 60–90 seconds.

### Slide 3 — Data and Response — Member A

- **Goal:** introduce the dataset, the threshold of 68, and the class split.
- **Bullets / big-number callouts:**
  - Source: Kaggle Spotify Music Dataset (audio features from Spotify Web API).
  - Pre-split into two CSVs at `track_popularity > 68` — *we inherited this threshold; the original dataset author chose it.* (Action Item 2.)
  - **4,494 unique tracks** after dedup (4,495 EDA / 4,494 modeling).
  - **29.5% High / 70.5% Low** — mildly imbalanced.
- **Figure:** [figures/01b_histogram_track_popularity.png](../../figures/01b_histogram_track_popularity.png) (popularity histogram with threshold line).
- **Source:** [02_data.md](02_data.md) §1–§3, [07_instructor_feedback.md](07_instructor_feedback.md) Action Item 2.
- **Time:** 60 seconds.

### Slide 4 — EDA: continuous predictors — Member A or B

- **Goal:** what audio features look like and what separates High from Low at the predictor level.
- **Layout:** boxplots-by-class on the left, three-bullet callout card on the right.
- **Bullets (callout):**
  - High-popularity tracks are **louder** (−6.8 dB vs −10.6 dB).
  - High-popularity tracks have **less instrumentalness** (0.04 vs 0.28).
  - **Acousticness** and **energy** also clearly differ; speechiness/liveness do not.
- **Figure:** [figures/03_box_continuous_by_response.png](../../figures/03_box_continuous_by_response.png).
- **Source:** [02_data.md](02_data.md) §4.3.
- **Time:** 60–75 seconds.

### Slide 5 — EDA: categorical predictors and the genre signal — Member B

- **Goal:** show that `playlist_genre` is the most informative single predictor and motivate the audio-vs-genre comparison.
- **Bullets:**
  - 35 genre levels in the working dataset; rare levels lumped to "other" (<1%) for modeling.
  - High-popularity share by genre spans 0% (cantopop, funk, gospel, wellness) to 96% (r&b).
  - Pop, hip-hop, R&B, rock have higher High-class shares; ambient/lofi/jazz/world/classical are mostly Low.
  - **This is the motivation for the audio-only vs audio+genre comparison.**
- **Figure:** [figures/04_cat_vs_response_playlist_genre_top10.png](../../figures/04_cat_vs_response_playlist_genre_top10.png) (cleaner top-10 version) or the full one if the team prefers density.
- **Source:** [02_data.md](02_data.md) §4.6–§4.7.
- **Time:** 75 seconds.

### Slide 6 — Multicollinearity quick check — Member B

- **Goal:** flag the energy-loudness collinearity so the audience can interpret LR coefficients later.
- **Bullets:**
  - Energy ↔ loudness Pearson r = **0.80** (highest pair).
  - Energy ↔ acousticness r = **−0.76**.
  - Implication: LR coefficients on energy and loudness should be read jointly, not independently. Random forest is unaffected.
- **Figure:** [figures/05_correlation_heatmap.png](../../figures/05_correlation_heatmap.png).
- **Source:** [02_data.md](02_data.md) §4.4.
- **Time:** 45 seconds.

### Slide 7 — Methods overview — Member B or C

- **Goal:** introduce the modeling architecture.
- **Bullets:**
  - **Three classifiers**: logistic regression (LR), random forest (RF, 500 trees), SVM with RBF kernel.
  - **Two feature sets**: audio-only and audio + playlist_genre.
  - **Six workflows total.**
  - **80/20 stratified split** (seed 42), **5-fold stratified CV** for hyperparameter tuning, evaluation on held-out test (n = 899).
  - Recipes: median/mode imputation, rare-level lumping, z-standardization for LR/SVM; raw factors for RF.
- **Visual:** a small table or flow diagram with the six workflows. No code.
- **Source:** [03_methodology.md](03_methodology.md) §1–§5.
- **Time:** 60 seconds.

### Slide 8 — Hyperparameter and threshold tuning — Member C

- **Goal:** explain *why* threshold tuning exists; address Action Item 1 directly.
- **Bullets:**
  - Tuning objective: ROC AUC (threshold-independent, robust to class imbalance).
  - Tuned: RF (`mtry`, `min_n`), SVM (`cost`, `rbf_sigma`); LR has no hyperparameters.
  - **Decision threshold tuned per workflow** on CV out-of-fold predictions to maximize F1.
  - Selected thresholds: **0.19–0.33** (all below 0.5, consistent with the 30/70 prior).
  - **LR and RF on audio+genre have broad F1 plateaus** (F1 ≈ 0.65 across thresholds 0.25–0.55) — robust to small threshold misspecification. SVM audio+genre peaks more sharply at 0.19, consistent with `kernlab`'s known weaker probability calibration.
  - We report **both default 0.5 and CV-tuned** metrics in the results table for transparency.
- **Figure:** [figures/models/threshold_sweep_f1.png](../../figures/models/threshold_sweep_f1.png).
- **Source:** [03_methodology.md](03_methodology.md) §6–§7, [07_instructor_feedback.md](07_instructor_feedback.md) Action Item 1, [04_results.md](04_results.md) §3 (threshold-sweep stability subsection).
- **Time:** 60–75 seconds.

### Slide 9 — Results: test-set comparison — Member C

- **Goal:** the headline result. Show all six workflows on one slide.
- **Headline framing (settled):** lead with **ROC AUC** (threshold-independent) so the genre lift is the cleanest story, then point at the metric-comparison bar chart for the rest.
- **Bullets:**
  - **Best workflow: Random Forest on audio + genre.** Test ROC AUC **0.872**, CV-tuned F1 **0.690**.
  - **Genre lift:** adding `playlist_genre` raises test ROC AUC by **+0.07–0.17** across all three model families. *Consistent and large.*
  - LR on audio+genre is close (0.849 AUC); SVM trails (0.842 AUC).
  - Audio-only models all sit around AUC 0.67–0.76 — useful, but well below audio+genre.
- **Recommended visual:** **[figures/models/all_roc_overlay.png](../../figures/models/all_roc_overlay.png)** (six ROC curves with CV-tuned operating points marked) is the headline figure — it directly answers the instructor's "use 0.5 or create a ROC curve" guidance and shows where the chosen threshold sits on each curve. Pair with [figures/models/all_metric_comparison_combined.png](../../figures/models/all_metric_comparison_combined.png) on the same slide if there's room — that chart shows default-0.5 and CV-tuned bars side-by-side, telling the threshold-tuning story in one figure.
- **Source:** [04_results.md](04_results.md) §0–§3.
- **Time:** 90 seconds.

### Slide 10 — Feature attribution (cross-model) — Member C

- **Goal:** answer the "which features matter?" question across all three models on a comparable scale.
- **Bullets:**
  - Permutation importance: drop in test ROC AUC after shuffling each feature (5 shuffles per feature).
  - **`playlist_genre` dominates** when it is available (~0.18–0.23 drop), ~4× the next-most-important feature.
  - **Among audio features:** instrumentalness and loudness consistently lead in every model. Acousticness, energy, and duration matter without genre but largely drop out once genre is in the model.
- **Figure:** [figures/models/interp_permutation_importance_all.png](../../figures/models/interp_permutation_importance_all.png).
- **Source:** [04_results.md](04_results.md) §6.
- **Time:** 75 seconds.

### Slide 11 — Interpretation: recommendations for music makers — Member A or all

- **Goal:** the actionable conclusion the instructor asked for (Action Items 4 + 5).
- **Five bullets (memorize these — they answer "what do you tell an artist?"):**
  1. **Master loud** (~−7 to −5 dB integrated). High-popularity tracks average −6.8 dB; Low-popularity average −10.6 dB.
  2. **Avoid heavy instrumentalness.** Vocal-driven tracks dominate the High class.
  3. **Aim for produced (non-acoustic) production.** Acoustic tracks correlate strongly with Low class.
  4. **Genre fit is a placement lever, not a production lever.** Pop/hip-hop/R&B/rock playlists confer a higher prior probability — but this partly reflects how the dataset was built (curatorial signal), not just intrinsic style.
  5. **Energy and danceability help, but smaller.** Once loudness is in, additional energy buys little.
- **Recommended figure:** **[figures/models/pdp_rf_genre_top4.png](../../figures/models/pdp_rf_genre_top4.png)** — partial-dependence plots for loudness, instrumentalness, acousticness, and energy. These show the model's mean predicted P(High) as each feature varies, directly translating "the model says louder is better" into a curve the audience can read. Optional companion: [figures/models/interp_lr_coefficients.png](../../figures/models/interp_lr_coefficients.png).
- **Source:** [04_results.md](04_results.md) §7, [07_instructor_feedback.md](07_instructor_feedback.md) Action Item 5.
- **Time:** 90 seconds.

### Slide 12 — Limitations and conclusion — Member A or shared

- **Goal:** honest caveats + the bottom-line statement.
- **Two-column layout: limitations on the left, conclusion on the right.**
- **Limitations bullets:**
  - `playlist_genre` is a curatorial signal, not a pure intrinsic-track signal. Some of the genre lift is dataset construction.
  - Popularity threshold is inherited from the dataset author; we did not test alternatives.
  - SVM (RBF) underperformed even after grid-range fixes.
  - Static popularity snapshot — no temporal validation.
- **Conclusion:**
  - Audio features alone can predict "high popularity" with **AUC ≈ 0.73–0.76** — useful but limited.
  - Adding playlist genre lifts AUC to **0.84–0.87** — large and consistent.
  - **Loudness, instrumentalness, and (when available) genre** are the three most informative levers.
- **Source:** [08_limitations_future_work.md](08_limitations_future_work.md), [04_results.md](04_results.md) §1.
- **Time:** 60–75 seconds.

### Slide 13 (optional) — Q&A holding slide / AI disclosure

- "Questions?" + the AI disclosure footer (per the proposal's pattern).
- See [09_writing_style_and_ai_disclosure.md](09_writing_style_and_ai_disclosure.md) for disclosure language.

## Speaker section assignment

**To be determined once the deck is built.** The team will finalize who presents which section after the slides are drafted; the requirement is that each of the three team members presents at least one section.

A reasonable starting split (use only as a placeholder while building):

| Slides | Theme | Approx. minutes |
|---|---|---|
| 1 | Title / hand-off | 0:15 |
| 2–4 | Motivation, data, continuous EDA | ~3:00 |
| 5–7 | Categorical EDA, multicollinearity, methods | ~3:00 |
| 8–10 | Tuning, results, feature attribution | ~3:30 |
| 11–12 | Recommendations and conclusion | ~2:30 |

Total: ~12 minutes. All members can field Q&A regardless of section assignment ("any member should be able to answer all the questions" — Step 3 requirement).

## Q&A preparation

The 3 minutes of Q&A is its own 10% of the grade. The team should pre-rehearse the answers in [06_decisions_and_caveats.md](06_decisions_and_caveats.md) §11 — particularly:
- Why threshold 68? *(inherited from dataset author)*
- Is the genre lift real? *(real but partly curatorial; we discuss in limitations)*
- Why not SMOTE? *(mild imbalance; threshold tuning is sufficient)*
- Why is SVM weak? *(tabular categorical signal; RBF kernels don't help here; instructor said this is normal)*
- Why threshold tuning if you're reporting AUC? *(AUC is the headline; threshold tuning makes the threshold-dependent metrics interpretable)*

## Pre-flight checklist

- [ ] No R code is visible on any slide.
- [ ] AI disclosure is on the closing slide or speaker notes.
- [ ] Every section has a presenter assigned.
- [ ] Each presenter has rehearsed their portion at least twice.
- [ ] All numbers on slides match those in [04_results.md](04_results.md). Re-check if any artifact was regenerated.
- [ ] Slide footer shows "MIS 720 Step 3 Presentation | Team B2".
- [ ] Subject line: `MIS 720 project presentation + B2`. Coordinator emails before class on May 4; CCs all team members.

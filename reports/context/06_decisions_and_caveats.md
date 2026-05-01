# Project Decisions and Caveats

These are the things that shape the analysis but are not obvious from reading any single document — the *whys*. Each is also a likely Q&A topic in Step 3, so prepare to discuss them. Material is drawn from [documents/HANDOFF.md](../../documents/HANDOFF.md) §4 and verified against the R scripts and Notion meeting notes.

## 1. The audio-vs-audio+genre framing is the spine

- **Decision:** every model is trained twice — once on audio features only, once on audio + `playlist_genre`. The full set is six workflows, not three.
- **Why:** the proposal posed the research question "Can Spotify audio features help predict whether a track is high popularity?" The follow-up sub-question "how much of the predictive signal comes from intrinsic audio features versus the playlist-assigned genre?" is what actually drives the modeling architecture.
- **How to apply:** when writing or presenting results, never report a single model in isolation; always compare the audio and audio+genre versions of the same model so the reader can see the genre lift directly. The genre lift in test ROC AUC (0.07–0.17 across all three model families) is the headline finding.

## 2. Threshold tuning is methodologically real, not cosmetic

- **Decision (settled):** decision thresholds are tuned per workflow on CV out-of-fold predictions to maximize F1, and the tuned threshold is applied once to the test set. The final report **leads with the threshold-independent ROC AUC comparison** as the headline visual, and **shows both default 0.5 and CV-tuned metrics side-by-side** in the metric tables. ROC AUC and Brier score are reported once.
- **Why this convention:** the instructor's Step-2 advice was "use 0.5 since the data isn't very imbalanced, *or* create a ROC curve to identify the best threshold." Leading with ROC AUC matches the "ROC curve" half of that guidance directly; preserving the tuned-threshold table preserves the team's methodological work as transparent reporting.
- **Why threshold tuning exists at all:** at the conventional 0.5 threshold, audio-only models had sensitivity 0.09–0.20 for the High class. The 0.5 cutoff doesn't intersect a 30/70 prior usefully; the models are not broken.
- **How to speak to it (Q&A line):** "We tuned thresholds on cross-validation out-of-fold predictions to maximize F1, then applied the chosen threshold once to the test set. We report both schemes side by side; ROC AUC is threshold-independent and is our primary headline."

## 3. SVM (RBF) underperforms — and it took two passes to be sure

- **Observed:** SVM is the weakest of the three model families on every metric. Best SVM AUC = 0.842 (audio+genre); both LR and RF beat it.
- **Earlier debugging the team did:**
  - **`rbf_sigma` original `dials` default range was 1e-10 to 1**, which includes a degenerate corner where the kernel matrix is essentially constant. The audio SVM landed there and predicted majority class. The grid is now constrained to `[1e-4, 1e-1]`.
  - **`cost` original ceiling of 2^5 = 32** was being hit exactly by the genre SVM, indicating the search was truncating. The grid is now `[2^-2, 2^8]`. The genre SVM now selects `cost = 177.7`, well below the new upper bound — so the search is no longer truncated.
- **Remaining warnings** during tuning ("maximum number of iterations reached") are harmless and the final fits converge. The narrow `quiet_kernlab()` filter suppresses just those two strings; everything else passes through.
- **The Step 2 discussion deck asked the instructor whether to drop SVM or replace it with a neural network.** The instructor's answer (Notion meeting): *"It's normal for some models to perform better than others; current model set is sufficient, though neural network is optional."*
- **The team's decision (settled):** **Keep SVM in the headline tables, do not add a neural network.** The Step 4 report acknowledges SVM's underperformance honestly (does not hide it), explains that the underperformance persisted after grid-range fixes, and treats SVM as a comparative reference rather than a recommended model. Two interpretations to mention in the report (per Step 2 §5.3): (i) the data's decision boundary may be well-approximated by linear and tree-ensemble models, leaving the kernel SVM little to add; (ii) further tuning (e.g., wider grids, Bayesian optimization) might close the gap. We do not pursue (ii); we report (i) as the working interpretation.

## 4. Class imbalance handled via thresholds, not resampling

- **Decision:** no SMOTE, no up-sampling, no class weights.
- **Why:** the proposal explicitly avoided resampling, and the instructor confirmed in the meeting that the imbalance is mild ("data isn't very imbalanced") and resampling is unnecessary.
- **How to apply:** do not add resampling discussion to the report. If anyone asks in Q&A why the team didn't use SMOTE, the answer is: the imbalance is mild (1:2.4), threshold tuning addresses the practical issue (low sensitivity at 0.5), and resampling adds methodological complexity without a clear benefit at this imbalance level.

## 5. Deduplication and the "one row" gotcha

- Joining the two CSVs gives **4,831 rows**.
- **295 are duplicates by `track_id`**, of which 43 appear in both classes (high and low CSVs).
- The pipeline keeps the highest-popularity row per `track_id` → **4,495 rows** in the EDA dataset.
- **One additional row** is NA across most audio features and is dropped at the start of `02_modeling.R` → **4,494 rows** for modeling.
- **How to apply:** when the report says "4,494 rows," add a footnote that the EDA stage operated on 4,495 rows (the one-row drop happens at the modeling stage). The discussion slides used 4,494 throughout. Be consistent.

## 6. `playlist_genre` as a predictor — open methodological question

- **The caveat:** `playlist_genre` is derived from the *playlist a track was sourced from*, not from the track itself. Tracks on multiple playlists were deduplicated to keep the highest-popularity row, which means each track ends up tagged with the genre of its most-popular containing playlist.
- **Why this is the most important caveat in the project:** the audio+genre model is partly using a *curatorial* signal (which playlist editors thought this song fit) rather than a pure track-level signal. Adding `playlist_genre` lifts test AUC by 0.07–0.17 — which is large — but some of that lift is leakage from the dedup rule that biases each track's genre tag toward popular playlists.
- **The team's plan:** report both feature sets and discuss this framing question explicitly in the limitations section. **Do not soften this.** It is the most important real and substantive caveat in the work.
- **For Q&A:** if the instructor or a peer asks "is the genre lift real?" the answer is: it is real *as a predictor that is available at score time given the dataset's construction*, but it is not a clean test of whether a track's *intrinsic genre* is predictive — playlist tagging conflates intrinsic style with curatorial choice. This is why we keep the audio-only model in the comparison.

## 7. What is *not* in scope (and why)

- **Decision trees** are listed in the proposal as a candidate. The team did not implement a single-tree model; the random forest was treated as the tree-based representative. Decision trees would add interpretability over RF but lower performance.
- **Neural networks** are listed in the proposal as a candidate and the discussion deck asked whether to add one. Per user direction and instructor feedback, we are not adding one.
- **No feature engineering** beyond standardization (numerics) and rare-level lumping on `playlist_genre`.
- **`playlist_subgenre` is not modeled.** It has 84 levels and overlaps with `playlist_genre`. Shown only in EDA appendix figures.

## 8. The `popularity_threshold = 68` is inherited, not chosen

- The dataset's original Kaggle author split the data at `track_popularity > 68` into the two CSV files.
- **The team did not choose 68.** The instructor explicitly asked us to explain this in the presentation (see [07_instructor_feedback.md](07_instructor_feedback.md), Action Item 2) — exactly because it is a design choice that looks arbitrary unless its origin is explained.
- **How to apply:** when introducing the response in the deck or the report, say something like: "The dataset is distributed as two CSV files that the original author pre-split at a popularity score of 68. We inherited that threshold and used it to construct the binary response, which preserves the dataset's intended high/low partition and gives a roughly 30/70 class split."

## 9. Color palette and reproducibility hygiene

- Color tokens are defined as named variables (`spotify_green`, `contrast_accent`, etc.) at the top of both scripts. Don't hard-code hex values inline.
- Both scripts set `set.seed(42)`. Per-feature permutation importance also seeds explicitly with `1000 + i`.
- The `high_popularity` factor level order **differs** between EDA (`c("Low", "High")`) and modeling (`c("High", "Low")`). The modeling order is required so `yardstick`'s default `event_level = "first"` reports sensitivity/precision/recall for the High class. **Do not change either order without auditing the metric calls.**

## 10. Data quality items to surface explicitly

The Data-Quality rubric category is 10% of the grade. Make these explicit in the report's data section so they get credit:

- **Provenance:** machine-generated audio features from Spotify Web API; metadata is editorially curated. The dataset is publicly available on Kaggle.
- **Completeness:** essentially zero missingness in audio features after the one NA-heavy row is dropped.
- **Consistency:** the dedup rule is documented and applied uniformly.
- **Bias surfaces (audio-only):** none beyond the 30/70 prior — no track is excluded for sociocultural reasons, only for missing data.
- **Bias surfaces (audio+genre):** the curatorial-signal leakage discussed above. Surface this honestly.

## 11. Anticipated Q&A questions and crisp answers

| Likely question | Crisp answer |
|---|---|
| "Why threshold 68?" | Inherited from the dataset author. We didn't pick it. Preserves their high/low partition; gives a 30/70 class split. |
| "Is the genre lift real?" | It's real as a *predictor* given the dataset's construction. But playlist_genre conflates intrinsic style with curatorial choice — that's a real caveat we discuss in limitations. |
| "Why not SMOTE?" | Imbalance is mild (1:2.4). Threshold tuning addresses the symptom (low sensitivity at 0.5). Resampling adds complexity without clear benefit here. |
| "Why is SVM so weak?" | Tabular features with strong categorical signal don't favor RBF kernels. We constrained the grid carefully (after one earlier round of debugging) and the issue persisted. The instructor told us this is normal across model families. |
| "What does instrumentalness even mean?" | Spotify's heuristic for whether a track has vocals. Values >0.5 are likely instrumental. Heavy-instrumental tracks are far less likely to be classified High in our data. |
| "Why threshold tuning at all if you're reporting ROC AUC anyway?" | ROC AUC is the headline because it's threshold-independent. But sensitivity at 0.5 is misleadingly low for the audio-only models (the cutoff doesn't intersect a 30/70 prior usefully), so we tune the threshold to make the threshold-dependent metrics interpretable. |
| "Did you cross-validate the threshold?" | Yes — the threshold is selected on CV out-of-fold predictions and applied once to the held-out test set. |
| "Is RF or LR the right model to deploy?" | LR is more interpretable, RF is slightly more accurate (~+0.02 AUC). The "right" answer depends on whether the consumer values explanation or accuracy. |

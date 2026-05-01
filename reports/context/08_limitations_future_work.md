# Limitations and Future Work

The Step 4 report's limitations section is reframed from §5 of the Step 2 Preliminary Analysis ("Concerns and Questions"). Many of the open questions there are now answered (the instructor weighed in; the team made decisions); what's left is the honest list of caveats. This file is the source for that section.

## Limitations to surface in Step 4 (~1 pp of the report)

These are listed roughly in order of importance. The first one is the most important to be honest about.

### 1. `playlist_genre` is a curatorial signal, not a pure intrinsic-track signal

- `playlist_genre` is the genre of the **playlist a track was sourced from**, not a property of the track. Tracks that appeared on multiple playlists were deduplicated to keep the row with the highest `track_popularity`, which biases each track's genre tag toward its **most popular containing playlist**.
- **Implication:** the audio+genre model is partly using a signal about *how playlist editors categorized this song*, not just about the song itself. A genuinely intrinsic-genre signal (derived from the audio waveform alone) would not have this leakage but would also be weaker.
- **What we report anyway:** the audio-only models give a clean answer to the original research question ("can audio features predict popularity?"). The audio+genre models give a useful upper bound on what is achievable when the curatorial signal is also available. Reporting both lets the reader see the contribution of each.
- **Phrasing for the report:** "Because `playlist_genre` reflects how a track was *placed* on Spotify rather than its intrinsic acoustic identity, the audio+genre lift partially conflates production properties with curatorial decisions. We report both feature sets so the reader can disentangle them."

### 2. Popularity threshold is inherited, not justified independently

- The dataset is pre-split at `track_popularity > 68`; we adopted that cutoff. We did not test sensitivity to alternative thresholds (e.g., 50, 60, 75).
- **Implication:** the conclusions are conditional on this specific cutoff. A different threshold could shift class shares and feature signals. Loudness, for instance, may matter more for distinguishing a 70-popularity track from a 30-popularity track than for distinguishing a 50 from a 30.
- **Future work:** rerun the analysis at threshold 60 and 75 to test stability of the genre lift and the headline features.

### 3. SVM (RBF) underperformed, even after grid-range fixes

- After explicit constraints on `cost ∈ [2^-2, 2^8]` and `rbf_sigma ∈ [1e-4, 1e-1]`, SVM still trails LR and RF on every metric.
- **Implication:** for tabular data of this size with strong categorical signal, RBF kernels do not help. We retain SVM as a comparative reference, not as a recommended model.
- **Future work:** try a linear-kernel SVM as a third comparison; in our setting it would likely match LR closely and would be cheaper.

### 4. Audio features are aggregate summaries, not waveforms

- Spotify's audio features (energy, loudness, etc.) are scalar summaries of full tracks. They do not capture sequential structure (verse/chorus dynamics, intro length, drop placement) that real producers care about.
- **Implication:** the model's "actionable" recommendations are necessarily coarse — "make it louder," "less instrumental." A model that consumed the audio waveform directly could give richer feedback, but it would also be less interpretable.

### 5. Static popularity snapshot

- `track_popularity` is a single scalar from the time the dataset was scraped. It does not distinguish:
  - Tracks that were viral and have decayed.
  - Tracks that are slowly accumulating popularity.
  - Tracks that are popular only in specific markets.
- **Implication:** the binary High/Low label is a noisy proxy. A track scored 67 (Low) and a track scored 69 (High) are nearly indistinguishable.
- **Future work:** model `track_popularity` as a continuous response (linear regression) and compare. The proposal mentioned this alternative framing; we chose binary classification to align with the dataset's pre-partition.

### 6. No temporal validation

- The train/test split is random within the dataset, not temporal. We don't know whether the model would generalize to tracks released *after* the dataset's snapshot.
- **Implication:** popularity drivers shift over time (chart trends, listener tastes, platform algorithm changes). A 2026 model trained on a 2024–2025 snapshot may decay.
- **Future work:** if the dataset includes release dates, refit with a temporal split.

### 7. Interpretability is local to the standardization

- LR coefficients are on z-standardized features, so a "1-SD increase in loudness" in the report = ~7.3 dB. When translating to recommendations for music makers, the units must be reattached carefully. Don't write "a 1-unit increase in loudness" without specifying that 1 unit is 1 SD ≈ 7.3 dB.

### 8. Multicollinearity caveats LR coefficient interpretation

- energy ↔ loudness Pearson r = 0.80; energy ↔ acousticness r = −0.76. LR coefficients on these features are partial-effect estimates conditional on the other being in the model.
- **Implication:** "loudness has a strong positive effect on log-odds of High" is correct. "Energy doesn't matter (small partial coefficient)" would be wrong — energy looks small partly because loudness is also in the model and absorbs much of the same variance.
- **Phrasing:** "Loudness and energy are highly correlated (r = 0.80); their partial coefficients should be read jointly, not independently."

### 9. Spotify's audio-feature definitions are proprietary

- We treat `energy`, `valence`, etc. as black-box scalars produced by Spotify's pipeline. We don't know exactly how they're computed, and Spotify could change the definitions over time.
- **Implication:** these are convenient, reproducible features for *this* dataset, but they are not first-principles audio descriptors.

### 10. Class imbalance handled, not eliminated

- 30/70 imbalance is mild but real. Threshold tuning addresses the practical effect on sensitivity but does not change the fact that at the conventional 0.5 cutoff, audio-only models look weak. A stricter resampling treatment (SMOTE, class weights) might help slightly, but per the proposal and the instructor's feedback, it was deliberately avoided.

## Future work suggestions (~0.5 pp)

A short paragraph at the end of the limitations section. Suggested items:

1. **Rerun at alternative popularity thresholds** (60, 75) to test sensitivity of the genre lift.
2. **Fit a continuous regression on `track_popularity`** alongside the classifier to capture popularity-as-degree, not just popularity-as-class.
3. **Replace the curatorial `playlist_genre` with an intrinsic genre classifier** trained on audio features alone, and use *that* as the genre signal — this removes the curatorial leakage cleanly.
4. **Try a linear-kernel SVM** to compare against LR.
5. **Add a temporal split** if release-date information is added to the dataset.
6. **Compute Shapley values** for the best workflow to give per-track explanations alongside the global feature importances we already report.
7. **Compare against a small neural network** as an extension if the team revisits this work — explicitly noted as optional by the instructor.

## What is *not* a real limitation (don't list these)

- Class imbalance — already handled at the threshold level. Listing it again as a "limitation" would invite unnecessary criticism.
- 12 keys × 2 modes × 5 time signatures — these are already included as categorical predictors.
- "Could have used more data." The dataset is sufficient (4,494 rows is comfortable for the methods used). If pressed in Q&A, just say "yes, more data is always better, but the methods used are stable at this sample size as evidenced by the small CV standard errors."

# Project Synopsis & Research Question

## Title

**From Beats to Hits: Predicting Spotify Song Popularity**

Working subtitle (from the proposal): *A classification study of audio features as predictors of whether a track reaches a high-popularity threshold on Spotify.*

## One-paragraph summary

Two pre-split CSV files from a Kaggle Spotify dataset (one "high-popularity," one "low") are joined into a 4,494-row track-level dataset after deduplication. The response is a binary indicator `high_popularity = (track_popularity > 68)`, yielding a 29.5% / 70.5% (High / Low) class split. Predictors are 10 continuous Spotify audio features (danceability, energy, loudness, valence, acousticness, instrumentalness, speechiness, liveness, tempo, duration_ms) plus 4 categoricals (key, mode, time_signature, playlist_genre). Three classifiers (logistic regression, random forest, SVM with RBF kernel) are trained on two parallel feature sets — *audio only* and *audio + playlist_genre* — for six workflows total. The headline finding is that adding `playlist_genre` lifts test ROC AUC by 0.07–0.17 across all three model families, with random forest on audio+genre as the best workflow (test AUC = 0.872, CV-tuned F1 = 0.690 at threshold 0.33).

## Research question

> **Can Spotify audio features help predict whether a track is "high popularity"?**

## Sub-question (the spine of the analysis)

> **How much of the predictive signal comes from intrinsic audio features versus the playlist-assigned genre?**

This sub-question is what motivates the parallel *audio-only vs audio + genre* feature-set comparison. Every reported result is paired across both feature sets so the comparison is direct. The presentation and the report should keep this comparison at the center of the results discussion.

## Why we care — the "why" the instructor asked us to lead with

The instructor's explicit Step-2 feedback (Notion meeting notes, 2026-04-27) was: **add a strong introduction explaining why this analysis matters — include industry size, Spotify's popularity, and company revenue.** Use the framing below in the Step 3 opener and the Step 4 introduction.

### Audience-first framing (use this language directly in the deck)

- **Music streaming is the dominant mode of music consumption.** Streaming accounts for the majority of recorded-music revenue worldwide; Spotify alone has hundreds of millions of monthly active users and is the single largest streaming platform.
- **Popularity on Spotify is a reasonable proxy for commercial success.** When millions of listeners "vote with their plays," the resulting popularity score is a useful, if noisy, surrogate for the commercial outcomes that artists and labels actually care about.
- **A reliable, interpretable model of what makes a track "hit-like" is useful at multiple points in the music-business pipeline:**
  - **Artists and producers** — guidance on production choices (loudness, energy, instrumentalness) before a track is released.
  - **Record labels and A&R teams** — triage of large release catalogs to identify promising tracks earlier in their lifecycle.
  - **Playlist editors and music marketers** — a signal that complements editorial taste and listener behavior.
- **The dataset is publicly available and machine-generated**, which means the predictors are reproducible and the conclusions can be checked or extended by anyone.

> **Verify the specific industry-scale numbers** (revenue, MAU, market share) from a current source before quoting them on the slide. Spotify, IFPI, and RIAA publish these annually. Do not rely on numbers in this file or in HANDOFF.md without re-checking — these decay quickly.

### The "why we care" sentence to memorize

> *Music popularity has enormous commercial and cultural consequences, and Spotify's catalog gives us a public-facing, machine-generated, listener-validated signal that lets us ask which audio characteristics actually distinguish hits from non-hits — a question that matters to artists, labels, and listeners in roughly that order.*

## Hypothesized relationships (from the proposal — useful in the introduction)

These hypotheses came from the Step 1 proposal and shape the narrative the analysis confirms or contradicts. Compare them against the actual point-biserial correlations in [02_data.md](02_data.md) §4 to write a tight "what we expected vs what we found" paragraph in the introduction or results.

| Predictor | Proposed direction | Actual point-biserial correlation with `high_popularity` |
|---|---|---|
| Energy | Positive | **+0.218** ✓ |
| Loudness | Positive | **+0.241** ✓ |
| Danceability | Positive | +0.106 ✓ (smaller than expected) |
| Acousticness | Negative | **−0.244** ✓ |
| Instrumentalness | Negative | **−0.305** ✓ (largest single audio effect) |
| Valence | Small positive (possibly nonlinear) | +0.121 ✓ |
| Tempo | Small positive (possibly nonlinear) | +0.070 ≈ |
| Speechiness | Weakly negative | −0.023 (essentially null) |
| Liveness | Weakly negative | +0.027 (essentially null, sign flipped) |
| Genre | Substantial signal on its own | **Largest predictor in models** ✓ |

The "substantial genre signal" hypothesis turned out to be the dominant finding — see [04_results.md](04_results.md).

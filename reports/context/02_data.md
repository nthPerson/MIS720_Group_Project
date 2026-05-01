# Data — Source, Cleaning, Predictors, EDA Findings

This file holds the grounded, cite-ready facts about the data. Numbers were re-extracted from `output/spotify_clean.rds` on 2026-04-30; if the EDA pipeline is re-run they may shift slightly.

## 1. Source

- **Platform:** Kaggle.
- **Dataset:** [Spotify Music Dataset](https://www.kaggle.com/datasets/solomonameh/spotify-music-dataset) (uploaded by user *solomonameh*).
- **Underlying source:** Spotify Web API (the audio features are produced by Spotify's audio-analysis pipeline).
- **Pre-split structure:** the dataset comes as **two CSV files** that the original author split at `track_popularity > 68`:
  - [data/high_popularity_spotify_data.csv](../../data/high_popularity_spotify_data.csv) — 1,686 tracks
  - [data/low_popularity_spotify_data.csv](../../data/low_popularity_spotify_data.csv) — 3,145 tracks
  - **Combined raw:** ~4,831 rows.

This pre-split structure is **why the popularity threshold is 68** — it is the cutoff the dataset's original author chose. The team did not pick 68; it inherited it. The instructor explicitly asked us to explain this in the presentation (see [07_instructor_feedback.md](07_instructor_feedback.md), Action Item 2).

## 2. Cleaning pipeline (in [01_eda.R](../../01_eda.R))

1. Load both CSVs, reconcile to common columns.
2. Combine: 4,831 rows.
3. **Deduplicate by `track_id`**, keeping the row with maximum `track_popularity` per track. 295 duplicate `track_id`s removed (43 of which appeared in both classes), leaving 4,495 rows.
4. Recode `key` (0–11 → C, C♯/D♭, …) and `mode` (0/1 → minor/major) into readable labels.
5. Build the binary response `high_popularity = (track_popularity > 68)` as a factor; EDA uses level order `c("Low", "High")`, modeling re-levels to `c("High", "Low")` so `yardstick` treats High as positive.
6. **Modeling stage** ([02_modeling.R](../../02_modeling.R)) drops one row that is NA across most audio features → **final modeling dataset = 4,494 rows**.

> **Numbers to memorize:** 4,495 EDA rows, 4,494 modeling rows, 1,325 High vs 3,170 Low, 29.5% / 70.5% class split.

## 3. Final variable set

### Response

| Variable | Definition |
|---|---|
| `high_popularity` | 1 if `track_popularity > 68`, else 0. Coded as factor with levels `c("High", "Low")` for modeling. |

### Continuous predictors (10)

All bounded-numeric audio features from the Spotify Web API. Descriptions are condensed from the proposal's variable table.

| Variable | Range | Description | Mean | Median | SD | Mean (High) | Mean (Low) |
|---|---|---|---:|---:|---:|---:|---:|
| `danceability` | 0.0–1.0 | Suitability for dancing (tempo, rhythm stability) | 0.620 | 0.653 | 0.190 | 0.652 | 0.607 |
| `energy` | 0.0–1.0 | Perceptual intensity/activity | 0.580 | 0.627 | 0.250 | 0.664 | 0.544 |
| `loudness` | ~−60 to 0 dB | Overall track loudness | −9.49 | −7.30 | 7.29 | −6.77 | −10.62 |
| `valence` | 0.0–1.0 | Musical positiveness | 0.479 | 0.480 | 0.260 | 0.527 | 0.459 |
| `acousticness` | 0.0–1.0 | Confidence track is acoustic | 0.351 | 0.238 | 0.329 | 0.227 | 0.403 |
| `instrumentalness` | 0.0–1.0 | Predicts no vocals (>0.5 likely instrumental) | 0.212 | 0.000 | 0.359 | 0.043 | 0.283 |
| `speechiness` | 0.0–1.0 | Spoken-word content | 0.100 | 0.055 | 0.101 | 0.097 | 0.102 |
| `liveness` | 0.0–1.0 | Probability of audience presence | 0.168 | 0.117 | 0.125 | 0.173 | 0.166 |
| `tempo` | BPM | Estimated tempo | 118.3 | 118.1 | 28.7 | 121.4 | 117.0 |
| `duration_ms` | milliseconds | Track length | 205,576 | 194,041 | 82,768 | 214,345 | 201,910 |

The clearest class separations (largest absolute mean differences and point-biserial correlations) are for **loudness, energy, instrumentalness, and acousticness**.

### Categorical predictors (4 used in modeling)

| Variable | Levels | Notes |
|---|---|---|
| `key` | 12 (C, C♯/D♭, …, B) + occasional NA | Roughly evenly distributed; included in models |
| `mode` | 2 (major / minor) | Included in models |
| `time_signature` | 5 (3, 4, 5, …) | Included in models |
| `playlist_genre` | **35 levels** | Used as the discriminating "genre" predictor. `step_other(threshold = 0.01)` lumps rare levels as "other" before modeling |

### Excluded from modeling

- `playlist_subgenre` — **84 levels**, overlaps with `playlist_genre`. Shown in EDA appendix figures only; not used as a predictor.
- `track_id`, `track_name`, `track_artist`, `track_album_name` — identifier/metadata columns retained for traceability only.

## 4. EDA findings (cite these in the presentation and report)

Numbers below were recomputed on 2026-04-30 from `output/spotify_clean.rds`.

### 4.1 Response distribution

- `track_popularity` ranges from **11 to 100**, with mean **54.8** and median **56**. Applying the threshold of 68 yields:
- 1,325 High (29.5%), 3,170 Low (70.5%) — note: this is on the EDA-stage dataset (4,495 rows) before the one-row NA drop in modeling. The Step 2 PDF reports 3,169 Low / 1,325 High = 4,494 modeling rows; the one-row difference is the NA-row drop.
- Histogram with the threshold-68 line: [figures/01b_histogram_track_popularity.png](../../figures/01b_histogram_track_popularity.png).

### 4.2 Continuous distributions

- Most predictors are reasonably distributed for modeling.
- **Right-skewed:** acousticness, instrumentalness — both have a large mass at zero. The vast majority of tracks are not acoustic and not instrumental.
- **Long left tail:** loudness clusters near 0 dB with a long left tail down to ~−48 dB.
- All continuous predictors are z-standardized for the LR and SVM recipes; RF uses raw values (trees are scale-invariant).
- Figure: [figures/01_histograms_continuous.png](../../figures/01_histograms_continuous.png).

### 4.3 Continuous predictors by class (High vs Low)

Strongest class differences:
- **Loudness:** High tracks are about **3.85 dB louder** on average (−6.77 vs −10.62 dB).
- **Instrumentalness:** High tracks are far less instrumental (0.043 vs 0.283).
- **Energy:** High tracks are more energetic (0.664 vs 0.544).
- **Acousticness:** High tracks are less acoustic (0.227 vs 0.403).
- **Danceability** and **valence** show smaller positive shifts; **speechiness** and **liveness** show essentially no separation.

Figure: [figures/03_box_continuous_by_response.png](../../figures/03_box_continuous_by_response.png).

### 4.4 Multicollinearity (continuous-only Pearson correlation)

|   | dance | energy | loud | valence | acoust | instrum | speech | live | tempo | dur |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| danceability | 1.00 | 0.41 | 0.57 | 0.53 | −0.40 | −0.36 | 0.26 | 0.00 | 0.03 | −0.13 |
| energy | | 1.00 | **0.80** | 0.50 | **−0.76** | −0.57 | 0.14 | 0.20 | 0.20 | 0.12 |
| loudness | | | 1.00 | 0.48 | −0.65 | −0.64 | 0.18 | 0.16 | 0.17 | 0.07 |
| valence | | | | 1.00 | −0.37 | −0.43 | 0.17 | 0.07 | 0.09 | −0.03 |
| acousticness | | | | | 1.00 | 0.51 | −0.12 | −0.14 | −0.17 | −0.12 |
| instrumentalness | | | | | | 1.00 | −0.21 | −0.13 | −0.13 | −0.14 |
| speechiness | | | | | | | 1.00 | 0.10 | 0.07 | −0.09 |
| liveness | | | | | | | | 1.00 | 0.05 | 0.00 |
| tempo | | | | | | | | | 1.00 | 0.03 |
| duration_ms | | | | | | | | | | 1.00 |

Notable correlations to flag in the report:
- **energy ↔ loudness = 0.80** (strong positive — these two carry overlapping signal).
- **energy ↔ acousticness = −0.76** (strong negative).
- **loudness ↔ acousticness = −0.65** and **loudness ↔ instrumentalness = −0.64**.
- danceability ↔ loudness = 0.57, danceability ↔ valence = 0.53.

This multicollinearity matters mainly for interpreting LR coefficients — energy and loudness are partially redundant predictors. RF and SVM are not impaired by this.

Figure: [figures/05_correlation_heatmap.png](../../figures/05_correlation_heatmap.png).

### 4.5 Point-biserial correlations with the response

| Predictor | r with `high_popularity` |
|---|---:|
| **instrumentalness** | **−0.305** |
| **acousticness** | −0.244 |
| **loudness** | +0.241 |
| **energy** | +0.218 |
| **valence** | +0.121 |
| **danceability** | +0.106 |
| tempo | +0.070 |
| duration_ms | +0.069 |
| liveness | +0.027 |
| speechiness | −0.023 |

The four dominant audio-only predictors of "hit" status are **instrumentalness, acousticness, loudness, and energy** — and these match the directions hypothesized in the proposal. Figure: [figures/06_point_biserial_with_response.png](../../figures/06_point_biserial_with_response.png).

### 4.6 Categorical predictors

#### Distribution summaries (from Step 2 preliminary analysis)

- **`key`** — 12 fairly even levels. Maximum level share **12.2%**, minimum **3.4%**.
- **`mode`** — **56% Major / 44% Minor**.
- **`time_signature`** — dominated by 4/4 (**88.9%**); 4 effective levels in the working dataset.
- **`playlist_genre`** — 35 distinct levels; top genres are electronic, pop, latin, hip-hop. Rare levels (<1%) are lumped into "other" via `step_other(threshold = 0.01)` in the LR/SVM and RF audio+genre recipes.
- **`playlist_subgenre`** — 84 levels; **no single level exceeds 15%**. Excluded from modeling because of cardinality and overlap with `playlist_genre`.

#### `playlist_genre` — top-15 by count

| Genre | n |
|---|---:|
| electronic | 561 |
| pop | 456 |
| latin | 400 |
| hip-hop | 355 |
| ambient | 321 |
| rock | 312 |
| lofi | 299 |
| world | 228 |
| arabic | 184 |
| brazilian | 147 |
| jazz | 145 |
| classical | 116 |
| gaming | 107 |
| wellness | 80 |
| blues | 79 |

Figures: [figures/02_bar_playlist_genre_full.png](../../figures/02_bar_playlist_genre_full.png), [figures/02_bar_playlist_genre_top10.png](../../figures/02_bar_playlist_genre_top10.png).

### 4.7 Genre vs response — the strongest single predictor signal

High-popularity share by genre (n ≥ 20 to keep sample sizes meaningful):

| Genre | n | High share |
|---|---:|---:|
| **r&b** | 50 | **96.0%** |
| **gaming** | 107 | **69.2%** |
| **pop** | 456 | **65.6%** |
| rock | 312 | 61.2% |
| punk | 70 | 60.0% |
| metal | 30 | 50.0% |
| hip-hop | 355 | 49.3% |
| folk | 64 | 43.8% |
| blues | 79 | 41.8% |
| latin | 400 | 38.0% |
| j-pop | 23 | 34.8% |
| electronic | 561 | 21.0% |
| korean | 32 | 18.8% |
| ambient | 321 | 14.0% |
| arabic | 184 | 12.5% |
| ... | ... | ... |
| world | 228 | 1.8% |
| jazz | 145 | 0.7% |
| lofi | 299 | 0.7% |
| wellness | 80 | 0.0% |
| gospel | 34 | 0.0% |
| funk | 28 | 0.0% |
| cantopop | 27 | 0.0% |

This range — from r&b at 96% high-share down to multiple genres at 0% — is the visually clearest single fact in the EDA. It is **the reason the audio-vs-audio+genre framing is the spine of the analysis**: any model that gets to use `playlist_genre` is starting from a much stronger prior than one that only sees audio features.

Figure: [figures/04_cat_vs_response_playlist_genre_full.png](../../figures/04_cat_vs_response_playlist_genre_full.png) (full distribution), [figures/04_cat_vs_response_playlist_genre_top10.png](../../figures/04_cat_vs_response_playlist_genre_top10.png) (cleaner version for slides).

## 5. Data quality note (for the rubric's 10% Data-Quality category)

Make this paragraph explicit somewhere in the report, since data quality is its own grading category:

- **Source provenance:** machine-generated audio features from Spotify's API; metadata is editorially curated.
- **Missingness:** essentially zero in the audio features (one row dropped from modeling); no imputation was needed beyond defensive median/mode steps in the recipe.
- **Duplicates:** 295 `track_id` duplicates (~6%) removed; the dedup rule (keep max-popularity row) is documented and consistent.
- **Class imbalance:** mild (1:2.4). Not severe enough to motivate SMOTE/upsampling; instead handled at the decision-threshold level (see [03_methodology.md](03_methodology.md) §6).
- **Train/test discipline:** 80/20 stratified split, 5-fold stratified CV on the train set only. Test set is touched once per workflow at evaluation time.

# Instructor Feedback — Step 2 Meeting (2026-04-27)

Source: Notion page **"15-Minute Meeting with Instructor (Step 2)"** under *MIS 720 Team Project* / *Academic Dashboard*.

This is the canonical record of what the instructor asked for during the Step 2 Zoom meeting. Every action item below should be visibly addressed somewhere in the Step 3 deck or the Step 4 report (or both).

## Meeting context

- **Date:** 2026-04-27.
- **Format:** 15-minute Zoom check-in, per Step 2 of the project guidelines.
- **Materials brought to the meeting:** the discussion deck ([documents/MIS720_Step2_TeamB2_Discussion_Slides.pdf](../../documents/MIS720_Step2_TeamB2_Discussion_Slides.pdf)) and the preliminary analysis document ([documents/MIS720_Step2_PreliminaryAnalysis_Team_B2.pdf](../../documents/MIS720_Step2_PreliminaryAnalysis_Team_B2.pdf)).
- **Project name on Notion:** *Spotify Track Popularity Prediction Project Check-in*.

## Action items the instructor explicitly assigned

These are the items from Notion's "Action Items" block. **Each one should be ticked off in the deliverables.**

### Action Item 1 — Threshold strategy

> Use 0.5 as threshold value or create ROC curve to identify best threshold.

- **What this means:** the instructor was reacting to the team's question about whether to spend slide-time on threshold tuning. The instructor recommended either staying at 0.5 (since the data is only mildly imbalanced) or showing a ROC curve so the audience can see how a threshold choice would shift performance.
- **How we address it (settled):** the headline visual in the Results section is the **all-six-ROC overlay** ([figures/models/all_roc_overlay.png](../../figures/models/all_roc_overlay.png)) — threshold-independent. The metric tables retain **both the default 0.5 numbers and the CV-tuned numbers**, drawn from [output/threshold_comparison.csv](../../output/threshold_comparison.csv), so the threshold-tuning work is preserved as transparent methodology rather than the headline.
- **Where it lands:**
  - Step 3: Results slide leads with the ROC overlay + the metric-comparison bar chart. Threshold-tuning gets its own slide ([10_step3_presentation_plan.md](10_step3_presentation_plan.md), Slide 8).
  - Step 4: §3 Methods (a "threshold tuning" subsection with light treatment) and §4 Results (both schemes side-by-side, with the threshold-sweep figure).
- **Asset gap to be aware of:** the existing [figures/models/all_metric_comparison.png](../../figures/models/all_metric_comparison.png) bar chart is at default 0.5 only. Both threshold schemes are still preserved by the ROC overlay (threshold-independent) and the threshold-comparison table; if a tuned-threshold bar chart is needed for a slide, [02_modeling.R](../../02_modeling.R) needs a small addition to emit one.

### Action Item 2 — Explain why 68 was chosen as the popularity threshold

> Explain why 68 was chosen as the popularity threshold in the presentation.

- **What this means:** when the instructor saw the response defined as `track_popularity > 68`, it looked like an arbitrary choice. We needed to make clear it was inherited from the dataset author.
- **The actual answer:** the Kaggle dataset is distributed as **two CSV files that the original author pre-split at `track_popularity > 68`**: one "high-popularity" file and one "low-popularity" file. We did not choose 68; we adopted the partition the data publisher chose, which gave a coherent binary class structure to begin with.
- **Where it lands:**
  - Step 3: Slide 3 (Data and response) explicitly says "the dataset is distributed pre-split at popularity 68" before showing the threshold line.
  - Step 4: §2 (Data) opens with this explanation.

### Action Item 3 — "Why we care" introduction with industry context

> Add introduction explaining why this analysis matters - include industry size, Spotify's popularity, and company revenue.

- **What this means:** the instructor wants the deliverables to motivate the analysis with concrete industry framing for a mixed-background audience, not just a research-question framing.
- **Talking points to verify and use** (re-check current numbers from a recent IFPI / Spotify investor / RIAA source before quoting on a slide):
  - Recorded music industry global revenue (annual, growing).
  - Streaming as the dominant share of recorded-music revenue.
  - Spotify's MAU and paid-subscriber count.
  - Spotify's annual revenue.
  - Why the popularity score is a useful proxy: listener-driven, machine-aggregated, public.
- **Where it lands:**
  - Step 3: Slide 2 ("Motivation").
  - Step 4: §1 Introduction (~1.5 pp).

### Action Item 4 — Feature importance in the conclusion

> Add feature importance analysis to conclusion section.

- **What this means:** the instructor wants the conclusion to do more than restate model accuracy. It should communicate which features matter and what the model is "saying."
- **Materials we already have:**
  - [figures/models/interp_permutation_importance_all.png](../../figures/models/interp_permutation_importance_all.png) — the comparable cross-model attribution.
  - [figures/models/interp_lr_coefficients.png](../../figures/models/interp_lr_coefficients.png) — signed effects from LR.
  - [figures/models/interp_rf_importance.png](../../figures/models/interp_rf_importance.png) — RF engine-native importance.
- **Where it lands:**
  - Step 3: Slide 10 (Feature attribution) and Slide 11 (Interpretation/Recommendations).
  - Step 4: §5 (Discussion / Interpretation), with the recommendations bullets.

### Action Item 5 — Actionable suggestions for music makers

> Provide actionable suggestions for music makers based on significant variables (e.g., loudness, duration).

- **What this means:** the instructor specifically called out *loudness* and *duration* as examples; the broader ask is to translate the model into prescriptive language. The conclusion should answer "what do you tell an artist or producer?", not just "what does the model do?".
- **The five recommendations the team should land on** (drawn from [04_results.md](04_results.md) §7):
  1. Master tracks toward mainstream loudness (~−7 to −5 dB integrated). High-popularity tracks average **−6.8 dB** vs −10.6 dB for low-popularity tracks. Loudness is the single largest *intrinsically controllable* audio lever.
  2. Avoid heavy instrumentalness; vocal-driven tracks are far more likely to land High.
  3. Aim for a vocal-driven, produced (non-acoustic) production aesthetic — consistent with mainstream charting.
  4. Genre-fit matters, but it is a *placement* lever (which playlist a track is on), not a *production* lever. Place into pop, hip-hop, R&B, or rock playlists for higher prior probability.
  5. Energy and danceability help, but their effects shrink once loudness is controlled. Don't sacrifice production quality for these.
- **Where it lands:**
  - Step 3: Slide 11 (Recommendations).
  - Step 4: §5 Discussion (~1 pp on recommendations) and §6 Conclusion.

## Other instructor feedback (from the meeting summary)

These are not "action items" but they are direct comments from the instructor that the team should incorporate.

- **"Overall performance is satisfactory — 100% accuracy is not expected."** Don't apologize in the report for AUC ≈ 0.87. State the result directly.
- **"Conclusion should focus on actionable insights from significant variables."** Reinforces Action Item 5; the conclusion's center of gravity should be the recommendations, not the model leaderboard.
- **"Examine which variables are significant in logistic regression and provide suggestions for music makers."** Use [figures/models/interp_lr_coefficients.png](../../figures/models/interp_lr_coefficients.png).
- **"Review feature importance from random forest to identify which variables are used most in trees."** Already generated — see [figures/models/interp_rf_importance.png](../../figures/models/interp_rf_importance.png).
- **"Feature importance visualizations already generated — include these in final presentation."** Confirms the figures are ready.
- **"Focus on insights from the model, not just the modeling process."** Watch the proportion of methods text vs interpretation text in Step 4. Methods should be ~2 pp; interpretation/discussion/limitations should be ~3+ pp.

## Questions the team raised, and the instructor's answers

### Question 1: How much should threshold tuning be foregrounded?

- **Instructor's answer:** "Use 0.5 since the data isn't very imbalanced, or create a ROC curve to compare different thresholds."
- **Team's take:** present the ROC curves as the primary visual; show both threshold schemes in the metric tables. See [03_methodology.md](03_methodology.md) §7 for the protocol.

### Question 2: Should SVM be replaced (e.g., with a neural network) given underperformance?

- **Instructor's answer:** "It's normal for some models to perform better than others; current model set is sufficient, though neural network is optional."
- **Team's decision (per user direction):** Keep SVM, do not add a neural network. The Step 4 report should acknowledge SVM underperformance honestly.

### Question 3: Add a fourth model (neural network) at all?

- **Instructor's answer:** Not necessary; three is sufficient.
- **Team's decision:** Stay at three models.

## What the instructor liked

(Not listed explicitly in the action-items block but visible in the meeting summary as "satisfactory" or as direct positive comments.)

- The class-balance + threshold framing.
- The audio-vs-audio+genre comparison structure.
- The threshold-tuning rationale (even though their guidance was to de-emphasize it visually).
- The breadth of EDA and the cross-model permutation importance analysis.
- The fact that feature-importance visualizations were already done — they explicitly noted these should appear in the final presentation.

## Cross-reference table — every action item maps to a deliverable section

| Action item | Step 3 slide | Step 4 section |
|---|---|---|
| 1 — Threshold via ROC | Slide 9 (Results: ROC + metrics) and Slide 8 (Threshold tuning) | §3 Methods, §4 Results |
| 2 — Explain threshold-68 origin | Slide 3 (Data) | §2 Data |
| 3 — "Why we care" introduction with industry framing | Slide 2 (Motivation) | §1 Introduction |
| 4 — Feature importance in conclusion | Slide 10 (Attribution) and Slide 11 (Interpretation) | §4 Results (importance subsection) and §5 Discussion |
| 5 — Actionable suggestions for music makers | Slide 11 (Recommendations) and Slide 12 (Conclusion) | §5 Discussion (recommendations) and §6 Conclusion |

If a deliverable is missing one of these mappings, treat it as a defect.

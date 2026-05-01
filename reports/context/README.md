# Reports Context — Master Index

This directory aggregates everything needed to write the Step 3 presentation (May 4) and the Step 4 final report (May 7) for MIS 720 Team B2's project, *From Beats to Hits: Predicting Spotify Song Popularity*.

These files are reference material, not deliverables. Each one is a single-purpose distillation of the source documents, R artifacts, instructor meeting notes, and team decisions. When writing a slide or a paragraph, open the relevant file here rather than re-deriving from sources.

## Source priority (when files disagree)

1. **R scripts and `output/` artifacts** — authoritative for any number, metric, or methodology detail. Re-extracted into the files below as of 2026-04-30; refresh by re-running [01_eda.R](../../01_eda.R) and [02_modeling.R](../../02_modeling.R).
2. **Notion: 15-Minute Meeting with Instructor (Step 2)** — authoritative for instructor expectations on Step 3/4. See [07_instructor_feedback.md](07_instructor_feedback.md).
3. **[documents/MIS720_Step2_PreliminaryAnalysis_Team_B2.pdf](../../documents/MIS720_Step2_PreliminaryAnalysis_Team_B2.pdf)** — closest structural analog to the final report. Sections 1–4 are essentially ready to expand; section 5 is reframed as Limitations.
4. **[documents/MIS720_Project_Proposal_Team_B2.pdf](../../documents/MIS720_Project_Proposal_Team_B2.pdf)** — primary source for introduction/motivation framing and the original variable hypotheses.
5. **[documents/MIS720_Step2_TeamB2_Discussion_Slides.pdf](../../documents/MIS720_Step2_TeamB2_Discussion_Slides.pdf)** — visual-style reference for the Step 3 deck (teal/coral/navy palette, "WHAT WE ANALYZED" / "REQUIREMENT: ..." tag headers, white callout cards).
6. **[documents/HANDOFF.md](../../documents/HANDOFF.md)** — written by the previous Claude session; covers project decisions and dead ends. Useful background but superseded by the files here for any specific number.

## File map

| File | Purpose | Open when… |
|---|---|---|
| [00_deliverable_requirements.md](00_deliverable_requirements.md) | Step 3 + Step 4 official requirements, deadlines, submission protocol, grading rubric | Confirming what must be submitted, by whom, in what format |
| [01_project_synopsis.md](01_project_synopsis.md) | Elevator pitch, research question, sub-question, business motivation | Drafting introduction, motivation, or one-paragraph summary |
| [02_data.md](02_data.md) | Source dataset, cleaning, response definition, predictor list, EDA findings with exact numbers | Writing the data section; building EDA slides |
| [03_methodology.md](03_methodology.md) | Pipeline, models, recipes, hyperparameter ranges, threshold tuning, permutation importance | Writing the methods section; explaining decisions in Q&A |
| [04_results.md](04_results.md) | Headline numbers, full metric tables (default 0.5 vs CV-tuned), CV metrics, hyperparameters, permutation importance | Writing the results section; building results slides |
| [05_figures.md](05_figures.md) | All 38+ figures indexed by use case, with captions and "use this when…" guidance | Picking a figure for any slide or report section |
| [06_decisions_and_caveats.md](06_decisions_and_caveats.md) | Why we made the choices we made (audio-vs-genre framing, threshold tuning, SVM range fixes, dedup, scope) | Writing methods or limitations; preparing for Q&A |
| [07_instructor_feedback.md](07_instructor_feedback.md) | Step 2 meeting notes with explicit action items, instructor feedback, and how each is addressed | Writing introduction, conclusion; addressing instructor asks throughout |
| [08_limitations_future_work.md](08_limitations_future_work.md) | Honest limitations, especially the playlist_genre leakage caveat and SVM underperformance | Writing the limitations section |
| [09_writing_style_and_ai_disclosure.md](09_writing_style_and_ai_disclosure.md) | Audience, voice, tone, AI disclosure language carried forward from Step 2 | Drafting any prose; ensuring disclosure is included |
| [10_step3_presentation_plan.md](10_step3_presentation_plan.md) | Slide-by-slide outline for the 12-minute deck, with figure assignments and team-section split markers | Building the deck |
| [11_step4_report_plan.md](11_step4_report_plan.md) | Section-by-section outline for the 10–15 page Word report, with target page counts and source pointers | Drafting the report |

## Headline numbers (memorize these five)

1. **Working dataset:** 4,494 unique tracks; 29.5% High / 70.5% Low (popularity threshold = 68).
2. **Best model:** Random Forest on audio+genre. Test ROC AUC = **0.872**, CV-tuned F1 = **0.690** at threshold 0.33.
3. **Genre lift:** Adding `playlist_genre` lifts test ROC AUC by **0.07–0.17** across all three model families. Lift is consistent and large.
4. **Top features:** instrumentalness and loudness dominate when genre is excluded. With genre included, `playlist_genre` dominates (~0.18–0.23 drop in test AUC under permutation), with instrumentalness and loudness retaining secondary importance.
5. **Threshold tuning:** CV-selected F1-optimal thresholds range 0.19–0.33 (all below 0.5, consistent with the 30/70 prior). Tuning lifts sensitivity by 0.20–0.84 absolute across the six workflows.

Full grounded numbers are in [04_results.md](04_results.md).

## Two pieces of guidance the instructor gave that change the deliverables

These came out of the Step 2 meeting on 2026-04-27 and are easy to overlook:

- **Add a strong "why we care" introduction.** The instructor specifically asked for industry size, Spotify's scale, and revenue context. This frames the work for non-technical audience members. See [01_project_synopsis.md](01_project_synopsis.md) for materials.
- **Make the conclusion actionable.** Translate the model-derived feature importances into concrete recommendations for music makers (e.g., "tracks above −7 dB loudness are roughly 2× more likely to be classified High than tracks below −10 dB"). The conclusion should not just describe model performance. See [04_results.md](04_results.md) §5 and [11_step4_report_plan.md](11_step4_report_plan.md) for the recommended framing.

## Team and submission logistics

- **Team B2 members:** Senjuti Sarkar (ssarkar3184@sdsu.edu), Robert Ashe (rashe7414@sdsu.edu), Sonika Srinivas (ssrinivas9210@sdsu.edu).
- **Coordinator role:** the coordinator emails the instructor and CCs all team members on every contact (see [00_deliverable_requirements.md](00_deliverable_requirements.md)).
- **Robert is presumed coordinator** based on the proposal email thread and is listed as such in Notion. Confirm with the team before sending Step 3/4 deliverables.

## Settled decisions (carry these into the deliverables)

1. **Headline threshold strategy: lead with ROC AUC; present both threshold schemes side-by-side.** ROC AUC and Brier are reported once. Threshold-dependent metrics (sensitivity, specificity, precision, F1, accuracy) are shown for **both default 0.5 and CV-tuned** thresholds. This satisfies the instructor's "use 0.5 or create a ROC curve to identify best threshold" guidance while preserving the team's tuned-threshold methodology as transparent reporting. Headline visual is the ROC overlay ([figures/models/all_roc_overlay.png](../../figures/models/all_roc_overlay.png)). See [03_methodology.md](03_methodology.md) §7 and [07_instructor_feedback.md](07_instructor_feedback.md) Action Item 1.
2. **SVM stays in the headline tables.** The Step 4 report acknowledges SVM (RBF) underperformance honestly rather than hiding it. The instructor's meeting feedback explicitly endorsed keeping the existing model set ("It's normal for some models to perform better than others; current model set is sufficient"). See [06_decisions_and_caveats.md](06_decisions_and_caveats.md) §3 and [08_limitations_future_work.md](08_limitations_future_work.md) §3.
3. **No neural network is added.** The team stays at three classifiers × two feature sets = six workflows.

## Open items the team still needs to settle

1. **Per-team-member section/slide assignments for Step 3.** [10_step3_presentation_plan.md](10_step3_presentation_plan.md) contains a proposed split (Member A: Slides 2–4; Member B: 5–7; Member C: 8–10; shared: 11–12); the team will finalize once the deck is drafted.

## Visualization assets — additions in the latest run of the modeling script

The previous gap (no tuned-threshold metric chart) has been closed. The current [02_modeling.R](../../02_modeling.R) emits, in addition to all earlier figures:

- **[figures/models/all_metric_comparison_tuned.png](../../figures/models/all_metric_comparison_tuned.png)** — metric-comparison bar chart at CV-tuned thresholds.
- **[figures/models/all_metric_comparison_combined.png](../../figures/models/all_metric_comparison_combined.png)** — single chart showing default 0.5 and CV-tuned bars side by side. Most efficient figure if you only have room for one metric chart in the deck or report.
- **[figures/models/all_roc_overlay.png](../../figures/models/all_roc_overlay.png)** — ROC overlay now also marks each workflow's CV-tuned operating point.
- **`figures/models/perm_<wf>_confmat_tuned.png`** — confusion matrices at each workflow's CV-tuned threshold (the existing `perm_<wf>_confmat.png` files remain at default 0.5).
- **[figures/models/pdp_rf_genre_top4.png](../../figures/models/pdp_rf_genre_top4.png)** — partial-dependence plots for loudness, instrumentalness, acousticness, and energy in the best workflow (`rf_genre`). Directly supports the music-maker recommendation slide.

These were added to satisfy the "lead with ROC AUC, preserve tuned-threshold work" reporting convention and the instructor's request for actionable, feature-importance-grounded insights for music makers.

# Deliverable Requirements — Step 3 (Presentation) and Step 4 (Final Report)

Source: [documents/official_project_requirements.pdf](../../documents/official_project_requirements.pdf) (MIS 720 Spring 2026 Project Guidelines).

## Step 3 — Presentation (Deadline: May 4)

- **Format:** PowerPoint slides emailed before class.
- **Length:** 12 minutes for the talk + 3 minutes Q&A.
- **Subject line:** `MIS 720 project presentation + team number` (i.e., `MIS 720 project presentation + B2`).
- **Sender:** Coordinator emails the instructor; **CC all team members**.
- **Each team member must present.** "Any member in your team is supposed to be able to answer all the questions" — every member needs to know every detail, since Q&A questions can be directed to anyone.
- **No R code on slides.** Summarize results in figures and tables.
- **Audience:** mixed-background. "Try your best to let everyone understand or learn something from your presentation." Assume some attendees are not data scientists.
- **Required content** (from the guidelines, beyond Steps 0–2 material):
  - Interpretation of the data — background, summary statistics (mean, median, variance, SD).
  - Why is it important to analyze the data? Why do we care?
  - Results.

## Step 4 — Final Report (Deadline: May 7)

- **Format:** **Word document (`.docx`), not a PDF**. Length **10–15 pages**.
- **Must also submit:** the data files and the R code, so that the analysis is reproducible by re-running the R code with the data.
- **Subject line:** `MIS720 project report + team number` (i.e., `MIS720 project report + B2`).
- **Sender:** Coordinator emails the instructor; **CC all team members**.
- **Required content:**
  - "Show all your work, what models you have considered, and model building process."
  - Reproducibility — the data and code must let the instructor replicate the analysis.

## Grading rubric (from the guidelines)

| Category | Weight |
|---|---|
| Data quality | 10% |
| Data analysis | 30% |
| Speaking and presentation | 20% |
| Q&A | 10% |
| Final report | 30% |
| **Total** | **100%** |

Implications:
- 60% of the grade depends on Step 3 + Step 4 (and 30% on the final report alone).
- Q&A is its own 10% category — preparation for likely instructor questions matters as much as the talk itself. See [06_decisions_and_caveats.md](06_decisions_and_caveats.md) for the Q&A-anticipated items.
- Data quality (10%) is largely already achieved (deduplication, NA handling, response definition); document it explicitly so it is graded.
- Each member's substantive contribution is required; trivial contribution leads to point deductions per the rubric.

## AI disclosure (mandatory)

> "If you use generative AI (e.g. ChatGPT) to do any part of the project (including but not limited to writing the proposal, preparing the ppt, conducting data analysis, drafting the report, and polishing the report), please disclose in the proposal/ppt/report."

The proposal already contains AI-disclosure language (see [09_writing_style_and_ai_disclosure.md](09_writing_style_and_ai_disclosure.md)). The same pattern is carried forward into Step 3 and Step 4.

## What's already done

- Step 0 (team formation): Done. Team B2: Senjuti Sarkar, Robert Ashe, Sonika Srinivas.
- Step 1 (proposal): Submitted 2026-04-19. See [documents/MIS720_Project_Proposal_Team_B2.pdf](../../documents/MIS720_Project_Proposal_Team_B2.pdf).
- Step 2 (preliminary analysis + 15-minute meeting): Meeting held 2026-04-27. See [documents/MIS720_Step2_PreliminaryAnalysis_Team_B2.pdf](../../documents/MIS720_Step2_PreliminaryAnalysis_Team_B2.pdf), [documents/MIS720_Step2_TeamB2_Discussion_Slides.pdf](../../documents/MIS720_Step2_TeamB2_Discussion_Slides.pdf), and [07_instructor_feedback.md](07_instructor_feedback.md).

## Pre-submission checklist (Step 3)

- [ ] Slides have no R code visible.
- [ ] Each member's presenting section is identified on the slide footer or speaker notes.
- [ ] AI disclosure appears on a final-slide or notes slide.
- [ ] Coordinator confirms the team intends to keep SVM and not add a neural network (per user guidance, both decisions are settled).
- [ ] Coordinator emails slides before class on May 4 with subject `MIS 720 project presentation + B2`, CC'ing all team members.
- [ ] Every member has rehearsed their section and the cross-talk transitions.

## Pre-submission checklist (Step 4)

- [ ] File is `.docx`, not `.pdf`.
- [ ] Page count is between 10 and 15.
- [ ] Data files (`data/high_popularity_spotify_data.csv`, `data/low_popularity_spotify_data.csv`, and ideally `output/spotify_clean.csv` for traceability) are attached or linked.
- [ ] R code (`01_eda.R`, `02_modeling.R`, plus the `MIS720_Group_Project.Rproj` for one-click open) is attached.
- [ ] Coordinator runs both R scripts on a fresh clone before submission to confirm reproducibility end-to-end.
- [ ] AI disclosure section is present.
- [ ] Audio-vs-audio+genre comparison appears throughout the results discussion (not just once).
- [ ] Default-0.5 *and* CV-tuned threshold metrics are both shown; headline narrative uses the ROC-AUC comparison plus whichever threshold scheme the team finalizes.
- [ ] `playlist_genre` leakage caveat is addressed in the limitations section.
- [ ] SVM underperformance is acknowledged honestly.
- [ ] Coordinator emails the report on May 7 with subject `MIS720 project report + B2`, CC'ing all team members.

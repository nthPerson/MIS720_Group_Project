# ============================================================================
# MIS 720 — Spring 2026 — Team B2
# Project: From Beats to Hits: Predicting Spotify Song Popularity
# Step 2/3: Model training, evaluation, and interpretation
#
# Companion to 01_eda.R. This script:
#   1. Loads the cleaned dataset from output/spotify_clean.rds
#   2. Builds two feature sets:
#        - audio:        intrinsic audio features only
#                        (continuous + key + mode + time_signature)
#        - audio+genre:  audio features plus playlist_genre
#                        (tests "do audio features add information beyond genre?")
#   3. Trains 3 models x 2 feature sets = 6 workflows
#        - Logistic regression (glm)
#        - Random forest       (ranger, with permutation importance)
#        - SVM, RBF kernel     (kernlab)
#   4. Tunes hyperparameters via 5-fold CV on the training set
#   5. Evaluates final fits on the held-out test set
#   6. Generates per-model, cross-model, and interpretation plots
#   7. Saves fitted workflows and a tidy results table for downstream use
#
# Runtime: ~5-25 min depending on parallel processing. SVM RBF tuning is
# the bottleneck; reduce `svm_grid_size` if you need it faster.
# ============================================================================


# ---- 0. Setup ---------------------------------------------------------------
# If any of these are missing:
#   install.packages(c("tidymodels", "ranger", "kernlab", "vip",
#                      "doParallel", "broom", "patchwork"))
suppressPackageStartupMessages({
  library(tidymodels)   # parsnip, recipes, workflows, rsample, yardstick, tune
  library(tidyverse)    # dplyr, tidyr, ggplot2, etc.
  library(ranger)       # random forest engine
  library(kernlab)      # SVM engine
  library(vip)          # extracting variable importance from fitted models
  library(scales)
  library(broom)        # tidy() for logistic regression coefficients
  library(patchwork)    # composing multi-panel plots
})

tidymodels_prefer(quiet = TRUE)
set.seed(42)


# ---- 1. Configuration -------------------------------------------------------
input_file <- "output/spotify_clean.rds"

fig_dir <- "figures/models"
out_dir <- "output"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# Train/test
test_prop <- 0.2

# Cross-validation
cv_folds <- 5

# Hyperparameter grid sizes (reduce to speed up; SVM is the bottleneck)
rf_grid_size  <- 20
svm_grid_size <- 20

# Permutation importance: number of shuffles per feature
perm_n_sims <- 5

# Decision threshold for confusion matrices and threshold-dependent metrics
default_threshold <- 0.5

# Parallel
use_parallel <- TRUE
n_cores      <- max(1, parallel::detectCores() - 1)

# Theme + colors (kept consistent with 01_eda.R)
theme_set(theme_minimal(base_size = 11) +
            theme(plot.title       = element_text(face = "bold"),
                  plot.subtitle    = element_text(color = "grey30"),
                  strip.text       = element_text(face = "bold"),
                  legend.position  = "bottom"))

# Color palettes
model_colors <- c(`Logistic Regression` = "#3F8FAB",
                  `Random Forest`       = "#7BAB3F",
                  `SVM (RBF)`           = "#AB3F8F")
fset_palette <- c(audio = "#E07B5C", `audio+genre` = "#3F8FAB")
class_colors <- c(Low = "#E07B5C", High = "#3F8FAB")

# Set up parallel backend
if (use_parallel && requireNamespace("doParallel", quietly = TRUE)) {
  doParallel::registerDoParallel(cores = n_cores)
  message(sprintf("Parallel processing enabled with %d cores.", n_cores))
} else if (use_parallel) {
  message("doParallel not installed; running sequentially.")
  use_parallel <- FALSE
}


# ---- 2. Load data -----------------------------------------------------------
spotify <- readRDS(input_file) %>%
  # Relevel so High is the FIRST level. yardstick's default event_level is
  # "first", so this makes sensitivity/precision/recall report metrics for
  # the "High popularity" class — which is what we actually care about.
  mutate(high_popularity = factor(high_popularity, levels = c("High", "Low")))

# Defensive: drop the one row with NA across audio features (caught in EDA)
spotify <- spotify %>%
  drop_na(high_popularity,
          danceability, energy, loudness, valence,
          acousticness, instrumentalness, speechiness, liveness,
          tempo, duration_ms, key, mode, time_signature)

cat(sprintf("Loaded %d rows from %s\n", nrow(spotify), input_file))
cat("Response distribution:\n")
print(spotify %>% count(high_popularity) %>%
        mutate(pct = percent(n / sum(n), accuracy = 0.1)))


# ---- 3. Train/test split (stratified) --------------------------------------
data_split <- initial_split(spotify, prop = 1 - test_prop,
                            strata = high_popularity)
train_data <- training(data_split)
test_data  <- testing(data_split)

cat(sprintf("\nTrain: %d rows | Test: %d rows\n",
            nrow(train_data), nrow(test_data)))


# ---- 4. CV resamples on the training set -----------------------------------
cv_resamples <- vfold_cv(train_data, v = cv_folds, strata = high_popularity)


# ---- 5. Feature sets and recipes -------------------------------------------
# Predictor groups
audio_continuous <- c("danceability", "energy", "loudness", "valence",
                      "acousticness", "instrumentalness", "speechiness",
                      "liveness", "tempo", "duration_ms")
audio_categorical <- c("key", "mode", "time_signature")
genre_var         <- "playlist_genre"

audio_predictors <- c(audio_continuous, audio_categorical)
ag_predictors    <- c(audio_predictors, genre_var)

# 5a. Recipe builder for logistic regression and SVM
#     - impute NAs (defensive; drop_na above should have handled them)
#     - lump rare playlist_genre levels (<1%) into "Other" (audio+genre only)
#     - dummy-encode categoricals
#     - drop zero-variance columns introduced by dummies
#     - z-standardize all numeric predictors (essential for kernel SVM,
#       and lets logistic coefficients be interpreted on a common scale)
make_recipe_lr_svm <- function(predictors, train_data) {
  rhs <- paste(predictors, collapse = " + ")
  rec <- recipe(as.formula(paste("high_popularity ~", rhs)),
                data = train_data) %>%
    step_impute_median(all_numeric_predictors()) %>%
    step_impute_mode(all_nominal_predictors())
  
  if (genre_var %in% predictors) {
    rec <- rec %>% step_other(all_of(genre_var), threshold = 0.01,
                              other = "other_genre")
  }
  
  rec %>%
    step_dummy(all_nominal_predictors()) %>%
    step_zv(all_predictors()) %>%
    step_normalize(all_numeric_predictors())
}

# 5b. Recipe builder for random forest
#     - impute NAs (defensive)
#     - lump rare playlist_genre levels for tree-split stability
#     - no dummy-encoding (ranger handles factors natively)
#     - no scaling (trees are scale-invariant)
make_recipe_rf <- function(predictors, train_data) {
  rhs <- paste(predictors, collapse = " + ")
  rec <- recipe(as.formula(paste("high_popularity ~", rhs)),
                data = train_data) %>%
    step_impute_median(all_numeric_predictors()) %>%
    step_impute_mode(all_nominal_predictors())
  
  if (genre_var %in% predictors) {
    rec <- rec %>% step_other(all_of(genre_var), threshold = 0.01,
                              other = "other_genre")
  }
  
  rec
}

rec_lr_audio  <- make_recipe_lr_svm(audio_predictors, train_data)
rec_lr_genre  <- make_recipe_lr_svm(ag_predictors,    train_data)
rec_svm_audio <- rec_lr_audio   # same preprocessing
rec_svm_genre <- rec_lr_genre
rec_rf_audio  <- make_recipe_rf(audio_predictors, train_data)
rec_rf_genre  <- make_recipe_rf(ag_predictors,    train_data)


# ---- 6. Model specifications ------------------------------------------------
spec_lr <- logistic_reg() %>%
  set_engine("glm") %>%
  set_mode("classification")

spec_rf <- rand_forest(
  mtry  = tune(),
  min_n = tune(),
  trees = 500
) %>%
  set_engine("ranger", importance = "permutation",
             num.threads = if (use_parallel) 1 else n_cores) %>%
  set_mode("classification")

# `kernlab` does not always learn well-calibrated probabilities; we use AUC
# (threshold-independent) for tuning to side-step that.
spec_svm <- svm_rbf(
  cost      = tune(),
  rbf_sigma = tune()
) %>%
  set_engine("kernlab") %>%
  set_mode("classification")

# Constrained SVM grid.
# - rbf_sigma: dials default is 1e-10 to 1 (way too wide; the lower end leads
#   to a near-constant kernel and a degenerate "predict majority" model).
#   For standardized predictors ~1e-4 to 1e-1 is the useful range.
# - cost: dials default tops out at 2^5 = 32. Previous run hit that ceiling
#   exactly on svm_genre, suggesting the true optimum is higher; extend to 2^8.
svm_grid <- grid_space_filling(
  cost(range      = c(-2, 8)),    # 2^-2 to 2^8  = 0.25 to 256
  rbf_sigma(range = c(-4, -1)),   # 1e-4 to 1e-1
  size = svm_grid_size
)


# ---- 7. Build the six workflows --------------------------------------------
all_workflows <- list(
  lr_audio  = workflow() %>% add_recipe(rec_lr_audio)  %>% add_model(spec_lr),
  lr_genre  = workflow() %>% add_recipe(rec_lr_genre)  %>% add_model(spec_lr),
  rf_audio  = workflow() %>% add_recipe(rec_rf_audio)  %>% add_model(spec_rf),
  rf_genre  = workflow() %>% add_recipe(rec_rf_genre)  %>% add_model(spec_rf),
  svm_audio = workflow() %>% add_recipe(rec_svm_audio) %>% add_model(spec_svm),
  svm_genre = workflow() %>% add_recipe(rec_svm_genre) %>% add_model(spec_svm)
)

wf_meta <- tibble(
  workflow_id = names(all_workflows),
  model       = c("lr",  "lr",  "rf",  "rf",  "svm", "svm"),
  feature_set = c("audio", "audio+genre",
                  "audio", "audio+genre",
                  "audio", "audio+genre"),
  model_label = c("Logistic Regression", "Logistic Regression",
                  "Random Forest",       "Random Forest",
                  "SVM (RBF)",           "SVM (RBF)")
)


# ---- 8. Tune / cross-validate ----------------------------------------------
# Tuning objective: roc_auc. It is threshold-independent and not biased by
# the moderate class imbalance, so it picks hyperparameters on actual ranking
# quality rather than threshold-specific accuracy.
#
# We split metrics into two sets:
# - tuning_metrics: threshold-INDEPENDENT only. Computed inside the CV loop.
#   Threshold-dependent metrics like precision/F1 are undefined (0/0 -> NaN)
#   when a hyperparameter combination yields a model that predicts all-Low,
#   which happens for non-trivial fractions of the SVM grid and produces
#   noisy warnings. AUC, accuracy, and Brier score are always defined.
# - my_metrics: full set, including threshold-dependent ones. Used for the
#   final test-set evaluation in last_fit() where the model is the chosen
#   one and the warnings would actually be meaningful if they occurred.
tuning_metrics <- metric_set(roc_auc, accuracy, brier_class)
my_metrics     <- metric_set(roc_auc, accuracy, sensitivity, specificity,
                             precision, f_meas, brier_class)

ctrl_grid <- control_grid(save_pred = TRUE, save_workflow = TRUE,
                          parallel_over = "everything")
ctrl_resamples <- control_resamples(save_pred = TRUE, save_workflow = TRUE,
                                    parallel_over = "everything")

# Picks tune_grid for tunable workflows, fit_resamples for plain logistic.
tune_or_resample <- function(wf, name) {
  has_tunables <- nrow(extract_parameter_set_dials(wf)) > 0
  cat(sprintf("[%s] %s...\n", name,
              ifelse(has_tunables, "tuning", "resampling")))
  if (!has_tunables) {
    return(fit_resamples(wf, resamples = cv_resamples,
                         metrics = tuning_metrics, control = ctrl_resamples))
  }
  # Pick the right grid for this model family. SVM uses an explicit, range-
  # constrained grid (see section 6); RF uses an integer to let dials build a
  # default space-filling design from its (sensible) default ranges.
  grid_arg <- if (grepl("^svm_", name)) svm_grid else rf_grid_size
  tune_grid(wf, resamples = cv_resamples, grid = grid_arg,
            metrics = tuning_metrics, control = ctrl_grid)
}

tic <- Sys.time()
tuning_results <- imap(all_workflows, ~ tune_or_resample(.x, .y))
toc <- Sys.time()
cat(sprintf("\nTuning complete. Elapsed: %s\n",
            format(round(difftime(toc, tic, units = "mins"), 2))))


# ---- 9. Best hyperparameters and CV summary --------------------------------
best_params_list <- map(tuning_results, ~ select_best(.x, metric = "roc_auc"))

cat("\n--- Best hyperparameters (selected on CV roc_auc) ---\n")
walk2(names(best_params_list), best_params_list, function(nm, bp) {
  cat(sprintf("\n[%s]\n", nm))
  print(bp %>% select(-.config))
})

# CV-mean metrics for the best hyperparameter combo of each workflow
cv_metrics <- imap_dfr(tuning_results, function(tr, nm) {
  bp <- best_params_list[[nm]]
  collect_metrics(tr) %>%
    semi_join(bp, by = intersect(names(bp), names(.))) %>%
    mutate(workflow_id = nm)
}) %>%
  left_join(wf_meta, by = "workflow_id")

cat("\n--- CV-mean metrics at the selected hyperparameters ---\n")
print(cv_metrics %>%
        select(model_label, feature_set, .metric, mean, std_err) %>%
        arrange(.metric, model_label, feature_set))


# ---- 10. Finalize and fit on the full train set, evaluate on test ----------
final_workflows <- map2(all_workflows, best_params_list, function(wf, bp) {
  if (nrow(extract_parameter_set_dials(wf)) > 0) {
    finalize_workflow(wf, bp)
  } else {
    wf
  }
})

last_fits <- map(final_workflows,
                 ~ last_fit(.x, split = data_split, metrics = my_metrics))

# Test predictions and metrics
test_predictions <- map(last_fits, ~ collect_predictions(.x) %>% as_tibble())
test_metrics_long <- imap_dfr(last_fits, function(lf, nm) {
  collect_metrics(lf) %>% mutate(workflow_id = nm)
})


# ---- 11. Tidy results table ------------------------------------------------
test_metrics <- test_metrics_long %>%
  select(workflow_id, .metric, .estimate) %>%
  pivot_wider(names_from = .metric, values_from = .estimate) %>%
  left_join(wf_meta, by = "workflow_id") %>%
  arrange(model, feature_set) %>%
  select(model_label, feature_set, accuracy, roc_auc, sensitivity,
         specificity, precision, f_meas, brier_class, everything())

cat("\n--- Test-set metrics (default threshold = 0.5) ---\n")
print(test_metrics %>%
        select(model_label, feature_set, accuracy, roc_auc, sensitivity,
               specificity, precision, f_meas, brier_class) %>%
        mutate(across(where(is.numeric), ~ round(.x, 3))))


# ---- 12. Per-model plots ---------------------------------------------------
# For each of the six workflows we save: confusion matrix, ROC curve,
# precision-recall curve, calibration plot, and a predicted-probability
# density panel. Files: figures/models/perm_<wf_id>_<plot>.png.

# 12a. Confusion matrix at default threshold
plot_confusion <- function(preds, title) {
  cm <- preds %>%
    conf_mat(truth = high_popularity, estimate = .pred_class)
  autoplot(cm, type = "heatmap") +
    scale_fill_gradient(low = "white", high = "#3F8FAB") +
    labs(title    = title,
         subtitle = sprintf("Confusion matrix at threshold = %.2f",
                            default_threshold))
}

# 12b. ROC curve with AUC annotated
plot_roc_one <- function(preds, title) {
  auc_val <- preds %>%
    roc_auc(truth = high_popularity, .pred_High) %>%
    pull(.estimate)
  
  preds %>%
    roc_curve(truth = high_popularity, .pred_High) %>%
    ggplot(aes(x = 1 - specificity, y = sensitivity)) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed",
                color = "grey60") +
    geom_path(linewidth = 0.9, color = "#3F8FAB") +
    coord_equal() +
    annotate("label", x = 0.65, y = 0.1, hjust = 0,
             label = sprintf("AUC = %.3f", auc_val)) +
    labs(title    = title, subtitle = "ROC curve, test set",
         x = "False positive rate", y = "True positive rate")
}

# 12c. Precision-recall curve with average precision annotated
plot_pr_one <- function(preds, title) {
  ap_val <- preds %>%
    pr_auc(truth = high_popularity, .pred_High) %>%
    pull(.estimate)
  
  preds %>%
    pr_curve(truth = high_popularity, .pred_High) %>%
    ggplot(aes(x = recall, y = precision)) +
    geom_path(linewidth = 0.9, color = "#3F8FAB") +
    coord_equal() +
    annotate("label", x = 0.05, y = 0.1, hjust = 0,
             label = sprintf("AP = %.3f", ap_val)) +
    labs(title    = title, subtitle = "Precision-Recall, test set",
         x = "Recall", y = "Precision")
}

# 12d. Calibration plot (10-bin reliability diagram)
plot_calibration <- function(preds, title) {
  preds %>%
    mutate(bin = cut(.pred_High, breaks = seq(0, 1, by = 0.1),
                     include.lowest = TRUE)) %>%
    group_by(bin) %>%
    summarise(mean_pred = mean(.pred_High),
              actual    = mean(high_popularity == "High"),
              n         = n(), .groups = "drop") %>%
    ggplot(aes(x = mean_pred, y = actual)) +
    geom_abline(slope = 1, intercept = 0,
                linetype = "dashed", color = "grey50") +
    geom_line(color = "#3F8FAB") +
    geom_point(aes(size = n), color = "#3F8FAB") +
    scale_x_continuous(limits = c(0, 1)) +
    scale_y_continuous(limits = c(0, 1)) +
    coord_equal() +
    labs(title    = title,
         subtitle = "Reliability diagram (test set, 10 bins)",
         x = "Mean predicted P(High)",
         y = "Observed proportion High",
         size = "Bin n")
}

# 12e. Predicted-probability density by true class
plot_proba_density <- function(preds, title) {
  ggplot(preds, aes(x = .pred_High, fill = high_popularity)) +
    geom_density(alpha = 0.55) +
    geom_vline(xintercept = default_threshold,
               linetype = "dashed", color = "grey40") +
    scale_fill_manual(values = class_colors) +
    labs(title    = title,
         subtitle = "Predicted P(High) by true class (test set)",
         x = "Predicted P(High)", y = "Density", fill = "True class")
}

# Build and save all per-model plots
cat("\n--- Saving per-model plots ---\n")
per_model_plot_fns <- list(
  confmat     = plot_confusion,
  roc         = plot_roc_one,
  pr          = plot_pr_one,
  calibration = plot_calibration,
  proba       = plot_proba_density
)

for (wf_id in names(all_workflows)) {
  meta  <- wf_meta %>% filter(workflow_id == wf_id)
  ttl   <- sprintf("%s — %s", meta$model_label, meta$feature_set)
  preds <- test_predictions[[wf_id]]
  for (pname in names(per_model_plot_fns)) {
    p <- per_model_plot_fns[[pname]](preds, ttl)
    ggsave(file.path(fig_dir, sprintf("perm_%s_%s.png", wf_id, pname)),
           p, width = 5.5, height = 5, dpi = 150)
  }
}


# ---- 13. Cross-model plots -------------------------------------------------

# 13a. ROC overlay (faceted by feature set, colored by model)
all_roc <- imap_dfr(test_predictions, function(preds, wf_id) {
  preds %>%
    roc_curve(truth = high_popularity, .pred_High) %>%
    mutate(workflow_id = wf_id)
}) %>%
  left_join(wf_meta, by = "workflow_id")

p_roc_all <- all_roc %>%
  ggplot(aes(x = 1 - specificity, y = sensitivity, color = model_label)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed",
              color = "grey60") +
  geom_path(linewidth = 0.9) +
  facet_wrap(~ feature_set) +
  scale_color_manual(values = model_colors) +
  coord_equal() +
  labs(title    = "ROC curves: all six models",
       subtitle = "Test set; faceted by feature set",
       x = "False positive rate", y = "True positive rate",
       color = NULL)
ggsave(file.path(fig_dir, "all_roc_overlay.png"),
       p_roc_all, width = 11, height = 5.5, dpi = 150)
print(p_roc_all)

# 13b. PR overlay
all_pr <- imap_dfr(test_predictions, function(preds, wf_id) {
  preds %>%
    pr_curve(truth = high_popularity, .pred_High) %>%
    mutate(workflow_id = wf_id)
}) %>%
  left_join(wf_meta, by = "workflow_id")

p_pr_all <- all_pr %>%
  ggplot(aes(x = recall, y = precision, color = model_label)) +
  geom_path(linewidth = 0.9) +
  facet_wrap(~ feature_set) +
  scale_color_manual(values = model_colors) +
  coord_equal() +
  labs(title    = "Precision-Recall curves: all six models",
       subtitle = "Test set; faceted by feature set",
       x = "Recall", y = "Precision", color = NULL)
ggsave(file.path(fig_dir, "all_pr_overlay.png"),
       p_pr_all, width = 11, height = 5.5, dpi = 150)
print(p_pr_all)

# 13c. Test-set metric comparison
metric_long <- test_metrics %>%
  select(model_label, feature_set,
         accuracy, roc_auc, sensitivity, specificity, precision, f_meas) %>%
  pivot_longer(c(accuracy, roc_auc, sensitivity, specificity,
                 precision, f_meas),
               names_to = "metric", values_to = "value") %>%
  mutate(metric = recode(metric,
                         accuracy    = "Accuracy",
                         roc_auc     = "ROC AUC",
                         sensitivity = "Sensitivity (Recall)",
                         specificity = "Specificity",
                         precision   = "Precision",
                         f_meas      = "F1"))

p_metrics <- metric_long %>%
  ggplot(aes(x = model_label, y = value, fill = feature_set)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  geom_text(aes(label = sprintf("%.3f", value)),
            position = position_dodge(width = 0.8),
            vjust = -0.3, size = 2.8) +
  facet_wrap(~ metric, scales = "free_y") +
  scale_fill_manual(values = fset_palette) +
  scale_y_continuous(limits = c(0, NA),
                     expand = expansion(mult = c(0, 0.18))) +
  labs(title    = "Test-set metrics by model and feature set",
       subtitle = sprintf("Default threshold = %.2f", default_threshold),
       x = NULL, y = NULL, fill = "Feature set") +
  theme(axis.text.x = element_text(angle = 20, hjust = 1))
ggsave(file.path(fig_dir, "all_metric_comparison.png"),
       p_metrics, width = 12, height = 7, dpi = 150)
print(p_metrics)

# 13d. Calibration overlay
all_calib <- imap_dfr(test_predictions, function(preds, wf_id) {
  preds %>%
    mutate(bin = cut(.pred_High, breaks = seq(0, 1, by = 0.1),
                     include.lowest = TRUE)) %>%
    group_by(bin) %>%
    summarise(mean_pred = mean(.pred_High),
              actual    = mean(high_popularity == "High"),
              n         = n(), .groups = "drop") %>%
    mutate(workflow_id = wf_id)
}) %>%
  left_join(wf_meta, by = "workflow_id")

p_calib_all <- all_calib %>%
  ggplot(aes(x = mean_pred, y = actual, color = model_label)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed",
              color = "grey50") +
  geom_line(linewidth = 0.7) +
  geom_point(aes(size = n)) +
  facet_wrap(~ feature_set) +
  scale_color_manual(values = model_colors) +
  scale_x_continuous(limits = c(0, 1)) +
  scale_y_continuous(limits = c(0, 1)) +
  coord_equal() +
  labs(title    = "Calibration curves: all six models",
       subtitle = "Reliability diagrams (test set, 10 bins)",
       x = "Mean predicted P(High)", y = "Observed proportion High",
       color = NULL, size = "Bin n")
ggsave(file.path(fig_dir, "all_calibration_overlay.png"),
       p_calib_all, width = 11, height = 6, dpi = 150)
print(p_calib_all)


# ---- 14. Interpretation plots ----------------------------------------------

# 14a. Logistic regression coefficients (forest plot, 95% CI)
# Inputs are standardized so coefficients are directly comparable.
#
# Coefficient plotting traps to handle:
# - Quasi-complete separation: rare predictors (e.g. small playlist_genre
#   levels with few or no Highs) produce a degenerate MLE with absurd
#   estimates and astronomical standard errors. These terms are not
#   meaningful as effect sizes and, more practically, they compress the
#   x-axis and crowd out everything else. We detect them by std.error and
#   exclude from the plot, listing them in a console table for awareness.
# - Long tails of legitimate but big effects: an x-axis zoom keeps the
#   plot readable for the bulk of coefficients.

extract_lr_coefs <- function(wf_id) {
  fit <- last_fits[[wf_id]] %>% extract_fit_parsnip()
  broom::tidy(fit, conf.int = TRUE) %>%
    filter(term != "(Intercept)") %>%
    mutate(workflow_id = wf_id)
}

lr_coefs <- bind_rows(extract_lr_coefs("lr_audio"),
                      extract_lr_coefs("lr_genre")) %>%
  left_join(wf_meta, by = "workflow_id") %>%
  mutate(sig = case_when(p.value < 0.001 ~ "p < 0.001",
                         p.value < 0.01  ~ "p < 0.01",
                         p.value < 0.05  ~ "p < 0.05",
                         TRUE            ~ "n.s."),
         sig = factor(sig, levels = c("p < 0.001", "p < 0.01",
                                      "p < 0.05", "n.s.")))

# Identify quasi-separation: enormous standard errors are the signature.
sep_threshold_se <- 5
separated <- lr_coefs %>% filter(std.error > sep_threshold_se)

if (nrow(separated) > 0) {
  cat("\n--- LR coefficients excluded from plot (quasi-complete separation) ---\n")
  cat(sprintf("Filter: std.error > %s\n", sep_threshold_se))
  print(separated %>%
          select(workflow_id, term, estimate, std.error, p.value) %>%
          mutate(across(where(is.numeric), ~ signif(.x, 3))))
}

lr_coefs_plot <- lr_coefs %>% filter(std.error <= sep_threshold_se)

coef_xlim <- c(-1.0, 1.0)
plot_subtitle <- if (nrow(separated) > 0) {
  sprintf("Standardized inputs; positive = predicts High popularity. %d term(s) excluded due to quasi-separation; see console.",
          nrow(separated))
} else {
  "Standardized inputs; positive = predicts High popularity"
}

p_lr_coef <- lr_coefs_plot %>%
  group_by(workflow_id) %>%
  mutate(term = fct_reorder(term, estimate)) %>%
  ungroup() %>%
  ggplot(aes(x = estimate, y = term)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_pointrange(aes(xmin = conf.low, xmax = conf.high, color = sig)) +
  facet_wrap(~ feature_set, scales = "free_y") +
  scale_color_manual(values = c("p < 0.001" = "#3F8FAB",
                                "p < 0.01"  = "#7BAB3F",
                                "p < 0.05"  = "#E0B85C",
                                "n.s."      = "grey60")) +
  coord_cartesian(xlim = coef_xlim) +
  labs(title    = "Logistic regression coefficients (95% CI)",
       subtitle = plot_subtitle,
       x = "Log-odds change per 1 SD (or vs. reference level)",
       y = NULL, color = "Significance")
ggsave(file.path(fig_dir, "interp_lr_coefficients.png"),
       p_lr_coef, width = 12, height = 8, dpi = 150)
print(p_lr_coef)

# 14b. Random forest variable importance (ranger's permutation importance)
extract_rf_importance <- function(wf_id) {
  fit <- last_fits[[wf_id]] %>% extract_fit_parsnip()
  vip::vi(fit) %>% mutate(workflow_id = wf_id)
}

rf_imp <- bind_rows(extract_rf_importance("rf_audio"),
                    extract_rf_importance("rf_genre")) %>%
  left_join(wf_meta, by = "workflow_id")

p_rf_imp <- rf_imp %>%
  group_by(workflow_id) %>%
  mutate(Variable = fct_reorder(Variable, Importance)) %>%
  ungroup() %>%
  ggplot(aes(x = Importance, y = Variable, fill = feature_set)) +
  geom_col() +
  facet_wrap(~ feature_set, scales = "free") +
  scale_fill_manual(values = fset_palette, guide = "none") +
  labs(title    = "Random forest permutation importance (built-in, ranger)",
       subtitle = "Higher = larger drop in performance when feature is permuted",
       x = "Importance", y = NULL)
ggsave(file.path(fig_dir, "interp_rf_importance.png"),
       p_rf_imp, width = 12, height = 7, dpi = 150)
print(p_rf_imp)

# 14c. Cross-model permutation importance on the test set
# Computed manually so importances are directly comparable across all three
# model types on a single scale (drop in test-set ROC AUC).
permutation_importance <- function(workflow_obj, predictors, test_data,
                                   n_perms = perm_n_sims) {
  baseline_pred <- predict(workflow_obj, test_data, type = "prob")$.pred_High
  baseline_auc  <- yardstick::roc_auc_vec(
    truth = test_data$high_popularity,
    estimate = baseline_pred
  )
  
  imap_dfr(set_names(predictors), function(feat, .) {
    drops <- map_dbl(seq_len(n_perms), function(i) {
      set.seed(1000 + i)  # reproducible per-feature shuffles
      data_perm <- test_data
      data_perm[[feat]] <- sample(data_perm[[feat]])
      pred_perm <- predict(workflow_obj, data_perm, type = "prob")$.pred_High
      auc_perm <- yardstick::roc_auc_vec(
        truth = test_data$high_popularity,
        estimate = pred_perm
      )
      baseline_auc - auc_perm
    })
    tibble(feature = feat,
           importance_mean = mean(drops),
           importance_sd   = sd(drops))
  })
}

cat("\n--- Computing test-set permutation importance for all 6 workflows ---\n")
cat("(this can take a couple of minutes; SVMs are the slow ones)\n")

tic <- Sys.time()
all_perm_imp <- imap_dfr(last_fits, function(lf, wf_id) {
  preds_set <- if (grepl("genre$", wf_id)) ag_predictors else audio_predictors
  wf_obj <- extract_workflow(lf)
  cat(sprintf("  [%s]\n", wf_id))
  permutation_importance(wf_obj, preds_set, test_data) %>%
    mutate(workflow_id = wf_id)
}) %>%
  left_join(wf_meta, by = "workflow_id")
toc <- Sys.time()
cat(sprintf("Elapsed: %s\n",
            format(round(difftime(toc, tic, units = "mins"), 2))))

# Build per-model panels with a y-axis ordering shared across feature sets.
# Each panel (one per model) has two facets, audio and audio+genre, that
# share the same feature ordering — sorted by audio+genre importance, with
# the most important features at the top. The audio facet shows empty rows
# for features it doesn't have (e.g. playlist_genre), keeping variables
# horizontally aligned across the two columns.
build_perm_imp_panel <- function(data, model_lbl) {
  d <- data %>% filter(model_label == model_lbl)
  
  feature_order <- d %>%
    filter(feature_set == "audio+genre") %>%
    arrange(importance_mean) %>%   # ascending -> top of y-axis = most important
    pull(feature)
  
  d <- d %>% mutate(feature = factor(feature, levels = feature_order))
  bar_color <- unname(model_colors[[model_lbl]])
  
  ggplot(d, aes(x = importance_mean, y = feature)) +
    geom_col(fill = bar_color) +
    geom_errorbar(aes(xmin = importance_mean - importance_sd,
                      xmax = importance_mean + importance_sd),
                  width = 0.2, color = "grey30") +
    geom_vline(xintercept = 0, color = "grey60", linewidth = 0.3) +
    facet_wrap(~ feature_set, nrow = 1) +
    labs(title = model_lbl, x = NULL, y = NULL) +
    theme(plot.title = element_text(face = "bold", size = 11))
}

panels <- map(c("Logistic Regression", "Random Forest", "SVM (RBF)"),
              ~ build_perm_imp_panel(all_perm_imp, .x))

p_perm_imp <- panels[[1]] / panels[[2]] / panels[[3]] +
  plot_annotation(
    title    = "Test-set permutation importance (drop in ROC AUC)",
    subtitle = sprintf("Mean ± SD across %d shuffles. Variables ordered by audio+genre importance within each model; audio panel does not include playlist_genre.",
                       perm_n_sims),
    caption  = "Larger bars = larger drop in test-set AUC when the feature is randomly shuffled (i.e. more important to the model)."
  ) &
  theme(plot.title.position = "plot")

ggsave(file.path(fig_dir, "interp_permutation_importance_all.png"),
       p_perm_imp, width = 11, height = 13, dpi = 150)
print(p_perm_imp)


# ---- 15. Save artifacts ----------------------------------------------------
# Final fitted workflows (re-fit on full train) — handy for any downstream
# script (e.g., the presentation deck builder) that wants to load and predict
# without retraining.
final_fitted <- map(last_fits, extract_workflow)

saveRDS(final_fitted,    file.path(out_dir, "final_workflows.rds"))
saveRDS(test_predictions, file.path(out_dir, "test_predictions.rds"))
saveRDS(test_metrics,     file.path(out_dir, "test_metrics.rds"))
saveRDS(cv_metrics,       file.path(out_dir, "cv_metrics.rds"))
saveRDS(all_perm_imp,     file.path(out_dir, "permutation_importance.rds"))
saveRDS(best_params_list, file.path(out_dir, "best_hyperparameters.rds"))

# Plain-text summary
write_csv(test_metrics,
          file.path(out_dir, "test_metrics_summary.csv"))

cat("\n",
    "============================================================\n",
    " Modeling complete.\n",
    " Figures saved to: ", normalizePath(fig_dir), "\n",
    " Artifacts in    : ", normalizePath(out_dir), "\n",
    "------------------------------------------------------------\n",
    " Saved RDS files:\n",
    "   final_workflows.rds       - 6 fitted workflows (train-fit)\n",
    "   test_predictions.rds      - test-set predictions per workflow\n",
    "   test_metrics.rds          - tidy test-set metrics table\n",
    "   cv_metrics.rds            - CV metrics at best hyperparameters\n",
    "   permutation_importance.rds- cross-model perm importance\n",
    "   best_hyperparameters.rds  - tuned hyperparameter values\n",
    "============================================================\n",
    sep = "")

# Clean up parallel backend if registered
if (use_parallel) {
  try(doParallel::stopImplicitCluster(), silent = TRUE)
}
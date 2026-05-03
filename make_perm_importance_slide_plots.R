# make_perm_importance_slide_plots.R
# Slide-friendly (16:9, horizontal) alternatives to
#   figures/models/interp_permutation_importance_all.png
# Reads the artifact already written by 02_modeling.R.
#
# Run:  Rscript make_perm_importance_slide_plots.R
# Produces:
#   figures/models/interp_permutation_importance_heatmap.png
#   figures/models/interp_permutation_importance_dotplot.png

set.seed(42)

suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
})

# ---- Palette (kept in sync with 01_eda.R / 02_modeling.R) -------------------
spotify_green       <- "#1db954"
spotify_dark        <- "#212121"
spotify_grey_dark   <- "#535353"
spotify_grey_light  <- "#b3b3b3"
contrast_accent     <- "#E07B5C"

model_colors <- c(`Logistic Regression` = spotify_grey_dark,
                  `Random Forest`       = spotify_green,
                  `SVM (RBF)`           = contrast_accent)

reference_line_color <- spotify_grey_light

theme_set(theme_minimal(base_size = 12) +
            theme(plot.title       = element_text(face = "bold"),
                  plot.subtitle    = element_text(color = "grey30"),
                  strip.text       = element_text(face = "bold"),
                  legend.position  = "bottom"))

fig_dir <- "figures/models"
if (!dir.exists(fig_dir)) dir.create(fig_dir, recursive = TRUE)

perm <- readRDS("output/permutation_importance.rds")

# Shared y-axis ordering across both plots: sort features by mean importance
# across all 6 model x feature_set cells (most important at the top).
feature_order <- perm %>%
  group_by(feature) %>%
  summarise(score = mean(importance_mean, na.rm = TRUE), .groups = "drop") %>%
  arrange(score) %>%
  pull(feature)

model_order <- c("Logistic Regression", "Random Forest", "SVM (RBF)")

perm <- perm %>%
  mutate(feature     = factor(feature, levels = feature_order),
         model_label = factor(model_label, levels = model_order),
         feature_set = factor(feature_set, levels = c("audio", "audio+genre")))


# ---- Viz #3: Heatmap --------------------------------------------------------
# Rows: features (sorted; most important at top).
# Cols: 3 models, faceted by feature_set (audio | audio+genre) -> 6 cells.
# Fill: importance_mean (diverging, since some cells are slightly negative).
# Cells where the feature is not in the model's input (e.g. playlist_genre
# under audio) are made explicit and rendered as greyed-out "—".

heatmap_full <- perm %>%
  complete(feature, model_label, feature_set,
           fill = list(importance_mean = NA_real_,
                       importance_sd   = NA_real_))

fill_limit <- max(abs(perm$importance_mean), na.rm = TRUE)

# Choose label color per cell: white on the most saturated tiles, dark
# otherwise. Mapped via scale_color_identity to avoid the vector-outside-aes
# pitfall.
heatmap_full <- heatmap_full %>%
  mutate(label_text  = ifelse(is.na(importance_mean), "—",
                              formatC(importance_mean, format = "f", digits = 3)),
         label_color = case_when(
           is.na(importance_mean)                       ~ spotify_grey_dark,
           abs(importance_mean) > fill_limit * 0.55     ~ "white",
           TRUE                                         ~ spotify_dark
         ))

p_heat <- ggplot(heatmap_full,
                 aes(x = model_label, y = feature, fill = importance_mean)) +
  geom_tile(color = "white", linewidth = 0.6) +
  geom_text(aes(label = label_text, color = label_color), size = 3.4) +
  facet_wrap(~ feature_set, nrow = 1) +
  scale_fill_gradient2(low      = contrast_accent,
                       mid      = "white",
                       high     = spotify_green,
                       midpoint = 0,
                       limits   = c(-fill_limit, fill_limit),
                       na.value = "grey92",
                       labels   = label_number(accuracy = 0.01),
                       name     = "Drop in test ROC AUC") +
  scale_color_identity() +
  scale_x_discrete(position = "top") +
  labs(
    title    = "Test-set permutation importance (drop in ROC AUC)",
    subtitle = "Greener = larger drop in test AUC when the feature is shuffled (more important to the model). Grey cells: feature not in that model's input.",
    x = NULL, y = NULL,
    caption  = "Mean across 5 shuffles. Features sorted by mean importance across all six cells."
  ) +
  theme(panel.grid       = element_blank(),
        axis.text.x.top  = element_text(face = "bold", size = 11),
        legend.position  = "bottom",
        legend.key.width = unit(2.6, "cm"),
        legend.key.height= unit(0.4, "cm"),
        strip.text       = element_text(face = "bold", size = 12),
        plot.title.position = "plot")

ggsave(file.path(fig_dir, "interp_permutation_importance_heatmap.png"),
       p_heat, width = 14, height = 7, dpi = 150)


# ---- Viz #4: Dot plot, audio | audio+genre side by side ---------------------
# Two facets, one per feature set. Each feature row carries 3 dots (one per
# model, color-coded). Horizontal whiskers = +/- 1 SD across shuffles.

dot_dodge <- position_dodge(width = 0.55)

p_dot <- ggplot(perm,
                aes(x = importance_mean, y = feature, color = model_label)) +
  geom_vline(xintercept = 0, color = reference_line_color,
             linewidth = 0.3, linetype = "dashed") +
  geom_errorbarh(aes(xmin = importance_mean - importance_sd,
                     xmax = importance_mean + importance_sd),
                 height = 0, linewidth = 0.55,
                 position = dot_dodge, alpha = 0.75) +
  geom_point(size = 2.8, position = dot_dodge) +
  facet_wrap(~ feature_set, nrow = 1, scales = "free_x") +
  scale_color_manual(values = model_colors, name = NULL) +
  scale_x_continuous(labels = label_number(accuracy = 0.01)) +
  labs(
    title    = "Test-set permutation importance (drop in ROC AUC)",
    subtitle = "One dot per model per feature; whiskers = +/- 1 SD across 5 shuffles. Larger x = more important to that model.",
    x        = "Drop in test-set ROC AUC when feature is shuffled",
    y        = NULL,
    caption  = "Features sorted by mean importance across all model x feature-set cells. Empty rows in the audio panel = feature not in that model's input."
  ) +
  theme(panel.grid.major.y = element_line(color = "grey92"),
        panel.grid.minor   = element_blank(),
        legend.position    = "bottom",
        strip.text         = element_text(face = "bold", size = 12),
        plot.title.position = "plot")

ggsave(file.path(fig_dir, "interp_permutation_importance_dotplot.png"),
       p_dot, width = 14, height = 7, dpi = 150)


cat("Wrote:\n",
    " ", file.path(fig_dir, "interp_permutation_importance_heatmap.png"), "\n",
    " ", file.path(fig_dir, "interp_permutation_importance_dotplot.png"), "\n",
    sep = "")

# ============================================================================
# MIS 720 — Spring 2026 — Team B2
# Project: From Beats to Hits: Predicting Spotify Song Popularity
# Step 2: Preliminary Exploratory Data Analysis
#
# This script:
#   1. Loads the two source CSVs (high- and low-popularity tracks)
#   2. Reconciles schemas and combines them into a single working dataset
#   3. Flags duplicates (informational; does not auto-remove)
#   4. Builds the binary response variable (high_popularity)
#   5. Performs univariate EDA (histograms, bar charts, frequency tables)
#   6. Performs bivariate EDA against the response (box plots, stacked bars)
#   7. Examines multicollinearity (correlation matrix, point-biserial)
#   8. Saves all figures to ./figures and a cleaned dataset to ./output
# ============================================================================


# ---- 0. Setup ---------------------------------------------------------------
# If any of these are missing:
#   install.packages(c("tidyverse", "scales", "ggcorrplot"))
suppressPackageStartupMessages({
  library(tidyverse)    # dplyr, tidyr, readr, ggplot2, forcats, etc.
  library(scales)       # percent(), comma()
  library(ggcorrplot)   # ggplot-based correlation heatmap
})

set.seed(42)


# ---- 1. Configuration -------------------------------------------------------
# Adjust `data_dir` to wherever the two CSVs live on your machine.
data_dir          <- "data"
high_pop_file     <- "high_popularity_spotify_data.csv"
low_pop_file      <- "low_popularity_spotify_data.csv"

# Per the dataset's pre-split (and our proposal):
popularity_threshold <- 68

# How many top levels to keep when plotting high-cardinality categoricals
top_n_genres      <- 10
top_n_subgenres   <- 15

# Above this many levels, switch bar plots to a horizontal layout for legibility
horizontal_threshold <- 20

# Output directories
fig_dir <- "figures"
out_dir <- "output"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# Plot theme + class colors used throughout
theme_set(theme_minimal(base_size = 11) +
            theme(plot.title    = element_text(face = "bold"),
                  plot.subtitle = element_text(color = "grey30"),
                  strip.text    = element_text(face = "bold")))

class_colors <- c("Low" = "#E07B5C", "High" = "#3F8FAB")


# ---- 2. Load raw files ------------------------------------------------------
high_raw <- read_csv(file.path(data_dir, high_pop_file), show_col_types = FALSE)
low_raw  <- read_csv(file.path(data_dir, low_pop_file),  show_col_types = FALSE)

cat("\n--- Raw file dimensions ---\n")
cat(sprintf("High-popularity file: %d rows x %d cols\n", nrow(high_raw), ncol(high_raw)))
cat(sprintf("Low-popularity  file: %d rows x %d cols\n", nrow(low_raw),  ncol(low_raw)))


# ---- 3. Schema reconciliation & combine -------------------------------------
hi_cols <- names(high_raw)
lo_cols <- names(low_raw)
common  <- intersect(hi_cols, lo_cols)
hi_only <- setdiff(hi_cols, lo_cols)
lo_only <- setdiff(lo_cols, hi_cols)

cat("\n--- Schema comparison ---\n")
cat(sprintf("Columns in both files: %d\n", length(common)))
if (length(hi_only) > 0) cat("Only in HIGH file: ", paste(hi_only, collapse = ", "), "\n")
if (length(lo_only) > 0) cat("Only in LOW  file: ", paste(lo_only, collapse = ", "), "\n")

# Use only the columns common to both files; tag origin for traceability.
spotify <- bind_rows(
  high_raw %>% select(all_of(common)) %>% mutate(.source_class = "High"),
  low_raw  %>% select(all_of(common)) %>% mutate(.source_class = "Low")
) %>%
  mutate(.source_class = factor(.source_class, levels = c("Low", "High")))

cat(sprintf("\nCombined dataset: %d rows x %d cols\n", nrow(spotify), ncol(spotify)))
cat("\n--- glimpse() ---\n")
glimpse(spotify)


# ---- 4. Duplicate detection (informational) --------------------------------
# Pick the best available row identifier
dup_key_expr <- if ("track_id" %in% names(spotify)) {
  rlang::expr(track_id)
} else if (all(c("track_name", "track_artist") %in% names(spotify))) {
  rlang::expr(paste(track_name, track_artist, sep = " || "))
} else {
  NULL
}

if (!is.null(dup_key_expr)) {
  spotify <- spotify %>% mutate(.dup_key = !!dup_key_expr)

  total_keys      <- length(unique(spotify$.dup_key))
  dup_counts      <- spotify %>% count(.dup_key) %>% filter(n > 1)
  cross_class_dup <- spotify %>%
    group_by(.dup_key) %>%
    summarise(classes = paste(sort(unique(.source_class)), collapse = ","),
              .groups = "drop") %>%
    filter(grepl(",", classes))

  cat("\n--- Duplicate detection ---\n")
  cat(sprintf("Unique row keys                 : %d\n", total_keys))
  cat(sprintf("Keys appearing more than once   : %d\n", nrow(dup_counts)))
  cat(sprintf("Keys appearing in BOTH classes  : %d\n", nrow(cross_class_dup)))
}


# ---- 4b. Deduplication ------------------------------------------------------
# Strategy: keep one row per track_id, choosing the row with the highest
# track_popularity. This:
#   - Resolves cross-class duplicates by keeping the High instance (its
#     popularity is by definition > the threshold, so it wins automatically).
#   - Resolves within-class duplicates (same track appearing on multiple
#     playlists) by keeping the row with the highest popularity score; ties
#     broken by row order. The audio features are track-level and identical
#     across rows, so the only thing lost is the alternative playlist
#     genre/subgenre tag for that track.
if ("track_id" %in% names(spotify) && "track_popularity" %in% names(spotify)) {
  n_before <- nrow(spotify)
  spotify <- spotify %>%
    arrange(desc(track_popularity)) %>%
    distinct(track_id, .keep_all = TRUE)
  cat("\n--- Deduplication (by track_id, max track_popularity wins) ---\n")
  cat(sprintf("Rows: %d -> %d (%d duplicates removed)\n",
              n_before, nrow(spotify), n_before - nrow(spotify)))
}


# ---- 5. Response variable & factor conversion ------------------------------
# Per the proposal: high_popularity = 1 if track_popularity > 68, else 0.
# If track_popularity isn't in the file, fall back to the file-of-origin label.
if ("track_popularity" %in% names(spotify)) {
  spotify <- spotify %>%
    mutate(high_popularity = factor(
      if_else(track_popularity > popularity_threshold, "High", "Low"),
      levels = c("Low", "High")
    ))
} else {
  spotify <- spotify %>% mutate(high_popularity = .source_class)
}

# Variables encoded as integers but conceptually categorical
known_categoricals <- c("key", "mode", "time_signature",
                        "playlist_genre", "playlist_subgenre")
categorical_vars   <- intersect(known_categoricals, names(spotify))
spotify <- spotify %>% mutate(across(all_of(categorical_vars), as.factor))

# Human-readable labels for `mode` and `key`
if ("mode" %in% categorical_vars) {
  levels(spotify$mode) <- recode(levels(spotify$mode), `0` = "Minor", `1` = "Major")
}
if ("key" %in% categorical_vars) {
  key_labels <- c("0" = "C", "1" = "C#/Db", "2" = "D", "3" = "D#/Eb",
                  "4" = "E", "5" = "F", "6" = "F#/Gb", "7" = "G",
                  "8" = "G#/Ab", "9" = "A", "10" = "A#/Bb", "11" = "B")
  levels(spotify$key) <- recode(levels(spotify$key), !!!key_labels)
}

cat("\n--- Response distribution ---\n")
print(spotify %>%
        count(high_popularity) %>%
        mutate(pct = percent(n / sum(n), accuracy = 0.1)))


# ---- 6. Variable typing -----------------------------------------------------
candidate_continuous <- c("danceability", "energy", "loudness", "valence",
                          "acousticness", "instrumentalness", "speechiness",
                          "liveness", "tempo", "duration_ms",
                          "track_popularity")

continuous_vars <- intersect(candidate_continuous, names(spotify))
id_text_vars    <- intersect(c("track_id", "track_name", "track_artist",
                               "track_album_id", "track_album_name",
                               "track_album_release_date",
                               "playlist_id", "playlist_name"),
                             names(spotify))

cat("\n--- Variable typing ---\n")
cat("Continuous     :", paste(continuous_vars,  collapse = ", "), "\n")
cat("Categorical    :", paste(categorical_vars, collapse = ", "), "\n")
cat("ID / text only :", paste(id_text_vars,     collapse = ", "), "\n")

# Sanity: any expected vars missing?
missing_expected <- setdiff(c(candidate_continuous, known_categoricals),
                            names(spotify))
if (length(missing_expected) > 0) {
  cat("NOTE — expected vars NOT found in data:",
      paste(missing_expected, collapse = ", "), "\n")
}


# ---- 7. Missing-value audit -------------------------------------------------
miss_summary <- spotify %>%
  summarise(across(everything(), ~sum(is.na(.x)))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "n_missing") %>%
  mutate(pct_missing = n_missing / nrow(spotify)) %>%
  arrange(desc(n_missing))

cat("\n--- Missing values (top 10) ---\n")
print(miss_summary %>% slice_head(n = 10) %>%
        mutate(pct_missing = percent(pct_missing, accuracy = 0.01)))


# ---- 8. Univariate EDA: continuous variables --------------------------------
# Summary statistics
cat("\n--- Continuous variable summaries ---\n")
print(spotify %>%
        select(all_of(continuous_vars)) %>%
        summary())

# Faceted histograms for predictor continuous variables
predictor_cont <- setdiff(continuous_vars, "track_popularity")

p_hist <- spotify %>%
  select(all_of(predictor_cont)) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "value") %>%
  ggplot(aes(x = value)) +
    geom_histogram(fill = "#3F8FAB", color = "white", bins = 40) +
    facet_wrap(~ variable, scales = "free", ncol = 3) +
    labs(title    = "Distributions of continuous audio features",
         subtitle = "Combined dataset (high + low popularity tracks)",
         x = NULL, y = "Count")

ggsave(file.path(fig_dir, "01_histograms_continuous.png"),
       p_hist, width = 11, height = 8, dpi = 150)
print(p_hist)

# Dedicated plot for track_popularity with threshold marked
if ("track_popularity" %in% continuous_vars) {
  p_pop <- ggplot(spotify, aes(x = track_popularity)) +
    geom_histogram(fill = "#3F8FAB", color = "white", bins = 50) +
    geom_vline(xintercept = popularity_threshold,
               color = "#E07B5C", linewidth = 0.9, linetype = "dashed") +
    annotate("text", x = popularity_threshold + 1, y = Inf, vjust = 2,
             hjust = 0, color = "#E07B5C",
             label = paste0("Threshold = ", popularity_threshold)) +
    labs(title    = "Distribution of track_popularity",
         subtitle = "Dashed line marks the high/low split used to build the response",
         x = "Spotify popularity score (0-100)", y = "Count")

  ggsave(file.path(fig_dir, "01b_histogram_track_popularity.png"),
         p_pop, width = 8, height = 4.5, dpi = 150)
  print(p_pop)
}


# ---- 9. Univariate EDA: categorical variables -------------------------------
cat("\n--- Categorical variable counts ---\n")
for (v in categorical_vars) {
  cat("\n>>> ", v, " (", nlevels(spotify[[v]]), " levels)\n", sep = "")
  print(spotify %>%
          count(.data[[v]], sort = TRUE) %>%
          mutate(pct = percent(n / sum(n), accuracy = 0.1)) %>%
          slice_head(n = 20))   # cap printout for very long tables
}

# --- bar-chart helpers ---
plot_full_bar <- function(varname, horizontal = NULL) {
  if (is.null(horizontal)) {
    horizontal <- nlevels(spotify[[varname]]) > horizontal_threshold
  }

  if (horizontal) {
    ggplot(spotify, aes(y = fct_rev(fct_infreq(.data[[varname]])))) +
      geom_bar(fill = "#3F8FAB") +
      labs(title = paste("Distribution of", varname),
           x = "Count", y = varname)
  } else {
    ggplot(spotify, aes(x = fct_infreq(.data[[varname]]))) +
      geom_bar(fill = "#3F8FAB") +
      labs(title = paste("Distribution of", varname),
           x = varname, y = "Count") +
      theme(axis.text.x = element_text(angle = 30, hjust = 1))
  }
}

plot_topn_bar <- function(varname, top_n) {
  top_levels <- spotify %>%
    count(.data[[varname]], sort = TRUE) %>%
    slice_head(n = top_n) %>%
    pull(1) %>%
    as.character()

  spotify %>%
    mutate(.lvl = fct_other(.data[[varname]],
                            keep = top_levels,
                            other_level = "Other")) %>%
    count(.lvl) %>%
    ggplot(aes(x = fct_reorder(.lvl, n, .desc = TRUE), y = n)) +
      geom_col(fill = "#3F8FAB") +
      labs(title = sprintf("Top %d %s (rest grouped as 'Other')", top_n, varname),
           x = varname, y = "Count") +
      theme(axis.text.x = element_text(angle = 30, hjust = 1))
}

for (v in categorical_vars) {
  n_lvl    <- nlevels(spotify[[v]])
  go_horiz <- n_lvl > horizontal_threshold

  p_full <- plot_full_bar(v)
  if (go_horiz) {
    fig_w <- 9
    fig_h <- min(max(6, n_lvl * 0.22), 22)
  } else {
    fig_w <- max(6, n_lvl * 0.4)
    fig_h <- 5
  }
  ggsave(file.path(fig_dir, sprintf("02_bar_%s_full.png", v)),
         p_full,
         width = fig_w, height = fig_h, dpi = 150)
  print(p_full)

  if (v == "playlist_genre" && n_lvl > top_n_genres) {
    p_top <- plot_topn_bar(v, top_n_genres)
    ggsave(file.path(fig_dir, sprintf("02_bar_%s_top%d.png", v, top_n_genres)),
           p_top, width = 9, height = 5, dpi = 150)
    print(p_top)
  } else if (v == "playlist_subgenre" && n_lvl > top_n_subgenres) {
    p_top <- plot_topn_bar(v, top_n_subgenres)
    ggsave(file.path(fig_dir, sprintf("02_bar_%s_top%d.png", v, top_n_subgenres)),
           p_top, width = 11, height = 5, dpi = 150)
    print(p_top)
  }
}


# ---- 10. Bivariate EDA: continuous predictors vs response -------------------
# Drop track_popularity here — it defines the response, so a box plot would
# trivially separate the classes and add no information.
p_box <- spotify %>%
  select(high_popularity, all_of(predictor_cont)) %>%
  pivot_longer(-high_popularity, names_to = "variable", values_to = "value") %>%
  ggplot(aes(x = high_popularity, y = value, fill = high_popularity)) +
    geom_boxplot(outlier.alpha = 0.2, outlier.size = 0.6) +
    facet_wrap(~ variable, scales = "free_y", ncol = 3) +
    scale_fill_manual(values = class_colors) +
    labs(title    = "Continuous audio features by popularity class",
         subtitle = sprintf("High = track_popularity > %d, Low = otherwise",
                            popularity_threshold),
         x = "Popularity class", y = NULL, fill = "Class")

ggsave(file.path(fig_dir, "03_box_continuous_by_response.png"),
       p_box, width = 11, height = 8, dpi = 150)
print(p_box)


# ---- 11. Bivariate EDA: categorical predictors vs response ------------------
# Stacked proportion bars: each bar sums to 100%, fill shows class composition.
# Useful with imbalanced classes because it normalizes for level frequency.
plot_cat_vs_response <- function(varname, top_n = NULL, horizontal = NULL) {
  d <- spotify %>% select(high_popularity, all_of(varname))

  if (!is.null(top_n)) {
    top_levels <- d %>%
      count(.data[[varname]], sort = TRUE) %>%
      slice_head(n = top_n) %>%
      pull(1) %>% as.character()
    d <- d %>% mutate(!!varname := fct_other(.data[[varname]],
                                              keep = top_levels,
                                              other_level = "Other"))
    title_suffix <- sprintf(" (top %d + Other)", top_n)
  } else {
    title_suffix <- ""
  }

  if (is.null(horizontal)) {
    horizontal <- length(unique(d[[varname]])) > horizontal_threshold
  }

  d_summary <- d %>%
    count(.data[[varname]], high_popularity) %>%
    group_by(.data[[varname]]) %>%
    mutate(prop        = n / sum(n),
           level_total = sum(n),
           prop_high   = sum(n[high_popularity == "High"]) / sum(n)) %>%
    ungroup()

  if (horizontal) {
    # Horizontal layout, sorted by share of High-popularity tracks.
    # Bonus interpretation: the most hit-prone levels rise to the top.
    d_summary %>%
      ggplot(aes(y    = fct_reorder(.data[[varname]], prop_high),
                 x    = prop,
                 fill = high_popularity)) +
        geom_col() +
        scale_x_continuous(labels = percent_format(accuracy = 1)) +
        scale_fill_manual(values = class_colors) +
        labs(title    = sprintf("Class composition by %s%s", varname, title_suffix),
             subtitle = "Each row = 100%; sorted by share of High-popularity tracks",
             x = "Proportion of tracks", y = varname, fill = "Class")
  } else {
    d_summary %>%
      ggplot(aes(x    = fct_reorder(.data[[varname]], level_total, .desc = TRUE),
                 y    = prop,
                 fill = high_popularity)) +
        geom_col() +
        scale_y_continuous(labels = percent_format(accuracy = 1)) +
        scale_fill_manual(values = class_colors) +
        labs(title    = sprintf("Class composition by %s%s", varname, title_suffix),
             subtitle = "Each bar = 100%; fill shows share of high- vs. low-popularity tracks",
             x = varname, y = "Proportion of tracks", fill = "Class") +
        theme(axis.text.x = element_text(angle = 30, hjust = 1))
  }
}

for (v in categorical_vars) {
  n_lvl    <- nlevels(spotify[[v]])
  go_horiz <- n_lvl > horizontal_threshold

  p_full <- plot_cat_vs_response(v)
  if (go_horiz) {
    fig_w <- 9
    fig_h <- min(max(6, n_lvl * 0.22), 22)
  } else {
    fig_w <- max(7, n_lvl * 0.5)
    fig_h <- 5
  }
  ggsave(file.path(fig_dir, sprintf("04_cat_vs_response_%s_full.png", v)),
         p_full,
         width = fig_w, height = fig_h, dpi = 150)
  print(p_full)

  if (v == "playlist_genre" && n_lvl > top_n_genres) {
    p_top <- plot_cat_vs_response(v, top_n_genres)
    ggsave(file.path(fig_dir, sprintf("04_cat_vs_response_%s_top%d.png", v, top_n_genres)),
           p_top, width = 9, height = 5, dpi = 150)
    print(p_top)
  } else if (v == "playlist_subgenre" && n_lvl > top_n_subgenres) {
    p_top <- plot_cat_vs_response(v, top_n_subgenres)
    ggsave(file.path(fig_dir, sprintf("04_cat_vs_response_%s_top%d.png", v, top_n_subgenres)),
           p_top, width = 11, height = 5, dpi = 150)
    print(p_top)
  }
}


# ---- 12. Multicollinearity & response association --------------------------
cor_mat <- spotify %>%
  select(all_of(predictor_cont)) %>%
  cor(use = "complete.obs")

cat("\n--- Correlation matrix among continuous predictors ---\n")
print(round(cor_mat, 2))

p_corr <- ggcorrplot(cor_mat,
                     hc.order = TRUE,
                     type     = "lower",
                     lab      = TRUE,
                     lab_size = 3,
                     colors   = c("#E07B5C", "white", "#3F8FAB"),
                     title    = "Pearson correlation among continuous audio features") +
  theme(plot.title = element_text(face = "bold"))

ggsave(file.path(fig_dir, "05_correlation_heatmap.png"),
       p_corr, width = 8, height = 7, dpi = 150)
print(p_corr)

# Point-biserial correlation between each continuous predictor and the response.
# Encoding: High = 1, Low = 0. This is just Pearson r with a binary 0/1 outcome.
resp_num <- as.integer(spotify$high_popularity == "High")
pb_cor <- sapply(spotify[predictor_cont], function(x) {
  cor(x, resp_num, use = "complete.obs")
})

pb_tbl <- tibble(variable = names(pb_cor), point_biserial = pb_cor) %>%
  arrange(desc(abs(point_biserial)))

cat("\n--- Point-biserial correlation with response (sorted by |r|) ---\n")
print(pb_tbl %>% mutate(point_biserial = round(point_biserial, 3)))

p_pb <- pb_tbl %>%
  ggplot(aes(x = fct_reorder(variable, point_biserial),
             y = point_biserial,
             fill = point_biserial > 0)) +
    geom_col() +
    coord_flip() +
    scale_fill_manual(values = c(`TRUE` = "#3F8FAB", `FALSE` = "#E07B5C"),
                      guide  = "none") +
    labs(title    = "Point-biserial correlation: each predictor vs. high_popularity",
         subtitle = "Positive = predictor higher among hits; negative = lower",
         x = NULL, y = "Correlation with high_popularity (1 = High, 0 = Low)")

ggsave(file.path(fig_dir, "06_point_biserial_with_response.png"),
       p_pb, width = 8, height = 5, dpi = 150)
print(p_pb)


# ---- 13. Save cleaned dataset for downstream modeling ----------------------
# Drop helper columns that aren't part of the model-ready dataset.
spotify_clean <- spotify %>% select(-any_of(c(".source_class", ".dup_key")))
saveRDS(spotify_clean, file.path(out_dir, "spotify_clean.rds"))
write_csv(spotify_clean, file.path(out_dir, "spotify_clean.csv"))

cat("\n",
    "============================================================\n",
    " EDA complete.\n",
    " Figures saved to: ", normalizePath(fig_dir),  "\n",
    " Cleaned data in : ", normalizePath(out_dir),  "\n",
    "============================================================\n",
    sep = "")
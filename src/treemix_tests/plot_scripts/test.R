#!/usr/bin/env Rscript --vanilla

# Simple baseline TreeMix plotting script

# Usage: Rscript plotting_baseline.R <treemix_dir> <plots_dir> <plotting_funcs_path>

# Load required libraries
suppressPackageStartupMessages({
  library(RColorBrewer)
})

# Command line arguments
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3) {
  stop("Usage: Rscript plotting_baseline.R <treemix_dir> <plots_dir> <plotting_funcs_path>")
}

TREEMIX_DIR <- args[1]
PLOTS_DIR <- args[2]
PLOTTING_FUNCS_PATH <- args[3]

if (!file.exists(PLOTTING_FUNCS_PATH)) {
  stop(sprintf("ERROR: plotting_funcs.R not found at: %s", PLOTTING_FUNCS_PATH))
}

if (!dir.exists(PLOTS_DIR)) {
  dir.create(PLOTS_DIR, recursive = TRUE)
}

source(PLOTTING_FUNCS_PATH)

# Plot settings
IMG_WIDTH <- 4000
IMG_HEIGHT <- 3500
IMG_RES <- 600
TEXT_SIZE <- 0.7
ARROW_SIZE <- 0.06
LINE_WIDTH <- 1.5

cat("\nBASELINE TREEMIX PLOTTING\n")
cat(sprintf("TreeMix results: %s\n", TREEMIX_DIR))
cat(sprintf("Plots output:    %s\n", PLOTS_DIR))
cat("\n")

# Find baseline TreeMix output
treeout_file <- file.path(TREEMIX_DIR, "baseline.treeout.gz")
if (!file.exists(treeout_file)) {
  stop(sprintf("ERROR: baseline.treeout.gz not found in: %s", TREEMIX_DIR))
}

output_file <- file.path(PLOTS_DIR, "baseline.png")

cat(sprintf("Plotting: %s\n", treeout_file))
cat(sprintf("Output:   %s\n", output_file))

png(filename = output_file,
    width = IMG_WIDTH,
    height = IMG_HEIGHT,
    res = IMG_RES,
    bg = "white",
    type = "cairo")

par(mar = c(5, 4, 4, 2) + 0.1)

tryCatch({
  plot_tree(
    file.path(TREEMIX_DIR, "baseline"),
    cex = TEXT_SIZE,
    arrow = ARROW_SIZE,
    disp = 0.004,
    plus = 0.01,
    ybar = 0.01,
    plotmig = TRUE,
    plotnames = TRUE,
    scale = FALSE,
    lwd = LINE_WIDTH,
    xmin = 0,
    font = 1
  )
  title(main = "Baseline", cex.main = 1.2, font.main = 2)
}, error = function(e) {
  cat(sprintf("❌ Error plotting baseline: %s\n", e$message))
}, finally = {
  dev.off()
})

cat("✅ Plotting complete!\n")
cat(sprintf("View your plot at: %s\n", output_file))
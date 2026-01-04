#!/usr/bin/env Rscript --vanilla

# Baseline treemix plotting script with colored labels
# Script to plot baseline TreeMix results with publication-quality output
 
# Usage: Rscript plotting_baseline.R <treemix_dir> <plots_dir> <plotting_funcs_path> [region_mapping_json]

# Load required libraries
suppressPackageStartupMessages({
  library(jsonlite)
  library(RColorBrewer)
})

# Command line arguments
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3) {
  stop("Usage: Rscript plotting_baseline.R <treemix_dir> <plots_dir> <plotting_funcs_path> [region_mapping_json]")
}

# Assign arguments
TREEMIX_DIR <- args[1]
PLOTS_DIR <- args[2]
PLOTTING_FUNCS_PATH <- args[3]
REGION_MAPPING_PATH <- if (length(args) >= 4) args[4] else NULL

# Validate paths
if (!file.exists(PLOTTING_FUNCS_PATH)) {
  stop(sprintf("ERROR: plotting_funcs.R not found at: %s", PLOTTING_FUNCS_PATH))
}

# Create output directory
if (!dir.exists(PLOTS_DIR)) {
  dir.create(PLOTS_DIR, recursive = TRUE)
}

# Source TreeMix plotting functions
source(PLOTTING_FUNCS_PATH)

# Function for loading the colours for region mapping from the json file
load_region_mapping <- function(region_path = NULL) {
  # Try to load region mapping JSON
  if (!is.null(region_path) && file.exists(region_path)) {
    cat(sprintf("Loading region mapping from: %s\n", region_path))
    return(fromJSON(region_path))
  }
  
  # Try default locations
  default_paths <- c(
    file.path(dirname(TREEMIX_DIR), "..", "..", "raw_data", "region_mapping.json"),
    file.path(dirname(dirname(dirname(TREEMIX_DIR))), "raw_data", "region_mapping.json"),
    "raw_data/region_mapping.json",
    "../raw_data/region_mapping.json",
    "../../raw_data/region_mapping.json"
  )
  
  for (path in default_paths) {
    if (file.exists(path)) {
      cat(sprintf("Found region mapping at: %s\n", path))
      return(fromJSON(path))
    }
  }
  
  cat("Warning: No region mapping found. Labels will be black.\n")
  return(NULL)
}

CONTINENT_MAP <- load_region_mapping(REGION_MAPPING_PATH)

# Fucction for getting colours for the regions
get_region_colors <- function() {
  # Define consistent color scheme for different regions
  colors <- c(
    "Subsaharan Africa" = "#E69F00",     # Orange
    "North Africa" = "#CC6600",          # Dark Orange
    "Europe" = "#0072B2",                # Blue
    "Asia" = "#009E73",                  # Green
    "East Asia" = "#009E73",             # Green (same as Asia)
    "South Asia" = "#117733",            # Dark Green
    "Central Asia" = "#44AA99",          # Teal
    "Oceania" = "#CC79A7",               # Pink
    "America" = "#D55E00",               # Vermillion
    "Middle East" = "#882255"            # Purple
  )
  
  return(colors)
}

REGION_COLORS <- get_region_colors()

# Plot Settings
# Image dimensions (optimized for publication)
IMG_WIDTH <- 4000      # Pixels (was 3500)
IMG_HEIGHT <- 3500     # Pixels (was 3000)
IMG_RES <- 600         # DPI (was 400) - higher for publication

# Text and visual elements
TEXT_SIZE <- 0.7       # Population label size (0.7 prevents overlap better than 1.0)
ARROW_SIZE <- 0.06     # Migration arrow size
SHOW_MIGRATION <- TRUE
SHOW_POP_NAMES <- TRUE
SHOW_SCALE <- FALSE    # Set to FALSE for cleaner look

# Line width for tree edges
LINE_WIDTH <- 1.5      # Thicker lines for clarity

# ==============================================================================
# ENHANCED PLOTTING FUNCTION WITH COLOR SUPPORT
# ==============================================================================

plot_treemix_with_colors <- function(stem, output_file, title = NULL, 
                                     poporder = NA) {
  cat(sprintf("\n📊 Plotting: %s\n", stem))
  cat(sprintf("   Output: %s\n", output_file))
  
  # Check if input files exist
  treeout_file <- paste0(stem, ".treeout.gz")
  if (!file.exists(treeout_file)) {
    warning(sprintf("⚠️  File not found: %s", treeout_file))
    return(FALSE)
  }
  
  # Prepare population color mapping
  pop_colors <- NULL
  if (!is.null(CONTINENT_MAP)) {
    # Create a data frame with population names and their colors
    pop_colors <- data.frame(
      population = names(CONTINENT_MAP),
      region = unlist(CONTINENT_MAP),
      stringsAsFactors = FALSE
    )
    
    # Map regions to colors
    pop_colors$color <- sapply(pop_colors$region, function(r) {
      if (r %in% names(REGION_COLORS)) {
        return(REGION_COLORS[[r]])
      } else {
        return("black")
      }
    })
    
    # Create poporder data frame for plot_tree
    poporder <- data.frame(
      V1 = pop_colors$population,
      V2 = pop_colors$color,
      stringsAsFactors = FALSE
    )
  }
  
  # Create plot with high quality settings
  png(filename = output_file,
      width = IMG_WIDTH,
      height = IMG_HEIGHT,
      res = IMG_RES,
      bg = "white",
      type = "cairo")  # Cairo for better anti-aliasing
  
  # Set margins for better spacing
  par(mar = c(5, 4, 4, 2) + 0.1)
  
  tryCatch({
    # Plot the tree
    plot_tree(
      stem,
      o = if (!is.null(pop_colors)) poporder else NA,
      cex = TEXT_SIZE,
      arrow = ARROW_SIZE,
      disp = 0.004,        # Label displacement (smaller = closer to tips)
      plus = 0.01,         # Extra space on right
      ybar = 0.01,         # Y-axis bar width
      plotmig = SHOW_MIGRATION,
      plotnames = SHOW_POP_NAMES,
      scale = SHOW_SCALE,
      lwd = LINE_WIDTH,
      xmin = 0,
      font = 1
    )
    
    # Add title if provided
    if (!is.null(title)) {
      title(main = title, cex.main = 1.2, font.main = 2)
    }
    
    # Add legend for regions (if we have color mapping)
    if (!is.null(CONTINENT_MAP)) {
      unique_regions <- unique(pop_colors$region)
      legend_colors <- sapply(unique_regions, function(r) {
        if (r %in% names(REGION_COLORS)) REGION_COLORS[[r]] else "black"
      })
      
      legend("topright",
             legend = unique_regions,
             col = legend_colors,
             pch = 15,
             cex = 0.6,
             bty = "n",
             title = "Regions")
    }
    
  }, error = function(e) {
    cat(sprintf("❌ Error plotting %s: %s\n", stem, e$message))
    return(FALSE)
  }, finally = {
    dev.off()
  })
  
  cat(sprintf("   ✅ Saved: %s\n", basename(output_file)))
  return(TRUE)
}

# Main script excecution
cat("  BASELINE TREEMIX PLOTTING\n")
cat(sprintf("TreeMix results: %s\n", TREEMIX_DIR))
cat(sprintf("Plots output:    %s\n", PLOTS_DIR))
cat(sprintf("Plotting funcs:  %s\n", PLOTTING_FUNCS_PATH))
cat(sprintf("\nPlot settings:\n"))
cat(sprintf("  - Size: %d x %d pixels @ %d DPI\n", IMG_WIDTH, IMG_HEIGHT, IMG_RES))
cat(sprintf("  - Text size: %.2f\n", TEXT_SIZE))
cat(sprintf("  - Arrow size: %.2f\n", ARROW_SIZE))
cat(sprintf("  - Line width: %.1f\n", LINE_WIDTH))
cat(sprintf("  - Colored labels: %s\n", ifelse(!is.null(CONTINENT_MAP), "YES", "NO")))
cat("\n")

# Find all TreeMix output files in the directory
treemix_files <- list.files(TREEMIX_DIR, pattern = "\\.treeout\\.gz$", full.names = FALSE)
base_names <- gsub("\\.treeout\\.gz$", "", treemix_files)

if (length(base_names) == 0) {
  cat("⚠️  No TreeMix output files found in:", TREEMIX_DIR, "\n")
  cat("   Looking for files matching pattern: *.treeout.gz\n")
  quit(status = 1)
}

cat(sprintf("Found %d TreeMix result(s) to plot:\n", length(base_names)))
for (name in base_names) {
  cat(sprintf("  • %s\n", name))
}
cat("\n")

# Plot each TreeMix result
success_count <- 0
for (base_name in base_names) {
  stem <- file.path(TREEMIX_DIR, base_name)
  output_file <- file.path(PLOTS_DIR, paste0(base_name, ".png"))
  
  # Extract migration edge count from filename for title
  title_text <- NULL
  if (grepl("_m0", base_name)) {
    title_text <- "Baseline - No Migration (m=0)"
  } else if (grepl("_m(\\d+)", base_name)) {
    m_val <- gsub(".*_m(\\d+).*", "\\1", base_name)
    title_text <- sprintf("Baseline - %s Migration Edges (m=%s)", m_val, m_val)
  } else if (grepl("baseline", base_name, ignore.case = TRUE)) {
    title_text <- "Baseline Analysis"
  }
  
  # Plot
  result <- plot_treemix_with_colors(stem, output_file, title = title_text)
  if (result) {
    success_count <- success_count + 1
  }
}

cat("\n")
cat("══════════════════════════════════════════════════════════════════\n")
cat(sprintf("  ✅ PLOTTING COMPLETE: %d/%d successful\n", success_count, length(base_names)))
cat("══════════════════════════════════════════════════════════════════\n")
cat(sprintf("\nView your plots in: %s\n\n", PLOTS_DIR))

# List created plots
created_plots <- list.files(PLOTS_DIR, pattern = "\\.png$", full.names = FALSE)
if (length(created_plots) > 0) {
  cat("Created plots:\n")
  for (plot in created_plots) {
    file_size <- file.info(file.path(PLOTS_DIR, plot))$size / 1024 / 1024
    cat(sprintf("  • %s (%.2f MB)\n", plot, file_size))
  }
}
cat("\n")



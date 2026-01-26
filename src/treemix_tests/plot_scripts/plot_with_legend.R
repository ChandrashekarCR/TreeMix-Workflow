#!/usr/bin/env Rscript
#
# TreeMix Plot with Legend
# Creates high-quality TreeMix plots with continental region color legend
#

library(jsonlite)
library(RColorBrewer)

# Source custom plotting functions
# Get script directory
get_script_dir <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    return(dirname(sub("^--file=", "", file_arg)))
  }
  return(getwd())
}

script_dir <- get_script_dir()
source(file.path(script_dir, "plotting_funcs.R"))
#source("/home/inf-21-2024/miniconda3/envs/treemix_env/bin/plotting_funcs.R")

#' Plot TreeMix tree with legend
#' @param stem Prefix of TreeMix output files (without extensions)
#' @param output_file Output filename (PDF or PNG)
#' @param use_colors Whether to color populations by region (default: TRUE)
#' @param add_legend Whether to add region legend (default: TRUE)
#' @param legend_pos Legend position: "topright", "topleft", "bottomright", "bottomleft" (default: "topright")
#' @param plot_migrations Whether to show migration edges (default: TRUE)
#' @param width Plot width in inches (default: 10)
#' @param height Plot height in inches (default: 8)
#' @param cex Text size multiplier (default: 0.8)
#' @param lwd Line width (default: 2)
#' @param displacement Text displacement from tips (default: 0.005)
#' @param font Font style: 1=normal, 2=bold, 3=italic, 4=bold italic (default: 2)
#' @return Invisible list with vertices and edges data
plot_treemix_with_legend <- function(stem, 
                                     output_file = NULL,
                                     use_colors = TRUE,
                                     add_legend = TRUE,
                                     legend_pos = "topright",
                                     plot_migrations = TRUE,
                                     width = 10,
                                     height = 8,
                                     cex = 0.6,
                                     lwd = 2,
                                     displacement = 0.005,
                                     font = 2) {
  
  # Validate inputs
  if (!file.exists(paste0(stem, ".vertices.gz"))) {
    stop(sprintf("TreeMix output files not found for stem: %s", stem))
  }
  
  # Determine output file if not provided
  if (is.null(output_file)) {
    output_file <- paste0(stem, "_plot.pdf")
  }
  
  # Determine file type from extension
  file_ext <- tolower(tools::file_ext(output_file))
  
  # Open graphics device
  if (file_ext == "pdf") {
    pdf(output_file, width = width, height = height)
  } else if (file_ext %in% c("png", "")) {
    if (file_ext == "") {
      output_file <- paste0(output_file, ".png")
    }
    png(output_file, width = width * 150, height = height * 150, res = 150)
  } else {
    stop("Unsupported file format. Use .pdf or .png")
  }
  
  # Plot the tree
  result <- plot_tree(
    stem = stem,
    cex = cex,
    disp = displacement,
    plus = 0.01,
    arrow = 0.05,
    scale = TRUE,
    #flip = c(76, 2372, 1504),
    ybar = 0.1,
    mbar = TRUE,
    plotmig = plot_migrations,
    plotnames = TRUE,
    changed_pops_path = '/home/inf-21-2024/projects/treemix_project/comparision_results/test_comparison_differences.txt',
    xmin = 0,
    lwd = lwd,
    font = font,
    use_region_colors = use_colors,
    add_legend = add_legend,
    legend_pos = legend_pos
  )
  
  dev.off()
  
  cat(sprintf("Plot saved to: %s\n", output_file))
  return(invisible(result))
}

# Command-line interface
if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  
  if (length(args) == 0) {
    cat("=== TreeMix Plot with Legend ===\n\n")
    cat("Usage:\n")
    cat("  Rscript plot_with_legend.R <stem> [output_file] [options]\n\n")
    cat("Arguments:\n")
    cat("  stem         Path to TreeMix output files (without extension)\n")
    cat("  output_file  Output filename (optional, default: <stem>_plot.pdf)\n\n")
    cat("Options:\n")
    cat("  --no-colors      Plot in black and white\n")
    cat("  --no-legend      Don't show legend\n")
    cat("  --no-mig         Don't show migration edges\n")
    cat("  --legend-pos <pos>  Legend position: topright, topleft, bottomright, bottomleft\n")
    cat("  --png            Save as PNG instead of PDF\n")
    cat("  --width <n>      Plot width in inches (default: 10)\n")
    cat("  --height <n>     Plot height in inches (default: 8)\n")
    cat("  --cex <n>        Text size multiplier (default: 0.8)\n\n")
    cat("Examples:\n")
    cat("  # Basic plot with legend\n")
    cat("  Rscript plot_with_legend.R baseline_m_2_output\n\n")
    cat("  # Custom output file and legend position\n")
    cat("  Rscript plot_with_legend.R baseline_m_2_output my_plot.pdf --legend-pos topleft\n\n")
    cat("  # Large PNG without legend\n")
    cat("  Rscript plot_with_legend.R baseline_m_2_output --png --no-legend --width 14 --height 10\n\n")
    quit(status = 0)
  }
  
  # Parse arguments
  stem <- args[1]
  output_file <- NULL
  use_colors <- TRUE
  add_legend <- TRUE
  legend_pos <- "topright"
  plot_migrations <- TRUE
  use_png <- FALSE
  width <- 10
  height <- 8
  cex <- 0.8
  
  i <- 2
  while (i <= length(args)) {
    arg <- args[i]
    
    if (arg == "--no-colors") {
      use_colors <- FALSE
    } else if (arg == "--no-legend") {
      add_legend <- FALSE
    } else if (arg == "--no-mig") {
      plot_migrations <- FALSE
    } else if (arg == "--legend-pos") {
      i <- i + 1
      legend_pos <- args[i]
    } else if (arg == "--png") {
      use_png <- TRUE
    } else if (arg == "--width") {
      i <- i + 1
      width <- as.numeric(args[i])
    } else if (arg == "--height") {
      i <- i + 1
      height <- as.numeric(args[i])
    } else if (arg == "--cex") {
      i <- i + 1
      cex <- as.numeric(args[i])
    } else if (!startsWith(arg, "--") && is.null(output_file)) {
      output_file <- arg
    }
    
    i <- i + 1
  }
  
  # Set default output file if not provided
  if (is.null(output_file)) {
    base_name <- basename(stem)
    output_file <- paste0(base_name, "_plot")
    if (use_png) {
      output_file <- paste0(output_file, ".png")
    } else {
      output_file <- paste0(output_file, ".pdf")
    }
  }
  
  # Create the plot
  cat(sprintf("Plotting TreeMix results from: %s\n", stem))
  cat(sprintf("Output file: %s\n", output_file))
  cat(sprintf("Settings: colors=%s, legend=%s, migrations=%s\n", 
              use_colors, add_legend, plot_migrations))
  
  plot_treemix_with_legend(
    stem = stem,
    output_file = output_file,
    use_colors = use_colors,
    add_legend = add_legend,
    legend_pos = legend_pos,
    plot_migrations = plot_migrations,
    width = width,
    height = height,
    cex = cex
  )
  
  cat("Done!\n")
}

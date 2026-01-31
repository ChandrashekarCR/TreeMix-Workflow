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
#' @param changed_pops_path Path to the file with changed populations (defaul is null)
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
#' @param create_both Whether to create both PDF and PNG versions (default: FALSE)
#' @param png_dpi DPI resolution for PNG files (default: 600)
#' @return Invisible list with vertices and edges data
plot_treemix_with_legend <- function(stem, 
                                     output_file = NULL,
                                     changed_pops_path = NULL,
                                     use_colors = TRUE,
                                     add_legend = TRUE,
                                     legend_pos = "topright",
                                     plot_migrations = TRUE,
                                     width = 10,
                                     height = 8,
                                     cex = 0.6,
                                     lwd = 2,
                                     displacement = 0.005,
                                     font = 2,
                                     create_both = FALSE,
                                     png_dpi = 600) {
  
  # Validate inputs
  if (!file.exists(paste0(stem, ".vertices.gz"))) {
    stop(sprintf("TreeMix output files not found for stem: %s", stem))
  }
  
  # Determine output file if not provided
  if (is.null(output_file)) {
    output_file <- paste0(stem, "_plot")
  }
  
  # Function to create a single plot
  create_plot <- function(file_path, file_type) {
    # Open graphics device
    if (file_type == "pdf") {
      pdf(file_path, width = width, height = height)
    } else if (file_type == "png") {
      # Fixed PNG creation with proper DPI scaling
      png(file_path, width = width, height = height, units = "in", res = png_dpi)
    }
    
    # Plot the tree
    result <- plot_tree(
      stem = stem,
      cex = cex,
      disp = displacement,
      plus = 0.01,
      arrow = 0.05,
      scale = TRUE,
      ybar = 0.1,
      mbar = TRUE,
      plotmig = plot_migrations,
      plotnames = TRUE,
      changed_pops_path = changed_pops_path,
      xmin = 0,
      lwd = lwd,
      font = font,
      use_region_colors = use_colors,
      add_legend = add_legend,
      legend_pos = legend_pos
    )
    
    dev.off()
    return(result)
  }
  
  # Create plots based on options
  if (create_both) {
    # Remove extension from output_file if present
    base_name <- tools::file_path_sans_ext(output_file)
    
    # Create both formats
    pdf_file <- paste0(base_name, ".pdf")
    png_file <- paste0(base_name, ".png")
    
    cat(sprintf("Creating PDF: %s\n", pdf_file))
    result <- create_plot(pdf_file, "pdf")
    
    cat(sprintf("Creating PNG: %s (%d DPI)\n", png_file, png_dpi))
    create_plot(png_file, "png")
    
    cat("Both plots saved successfully!\n")
    
  } else {
    # Single format (existing behavior)
    file_ext <- tolower(tools::file_ext(output_file))
    
    if (file_ext == "pdf") {
      result <- create_plot(output_file, "pdf")
    } else if (file_ext %in% c("png", "")) {
      if (file_ext == "") {
        output_file <- paste0(output_file, ".png")
      }
      result <- create_plot(output_file, "png")
    } else {
      stop("Unsupported file format. Use .pdf or .png")
    }
    
    cat(sprintf("Plot saved to: %s\n", output_file))
  }
  
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
    cat("  --both           Create both PDF and PNG versions\n")
    cat("  --dpi <n>        PNG resolution in DPI (default: 600)\n")
    cat("  --changed-pops <file>  Path to file with changed population names (one per line)\n")
    cat("  --output_dir <dir> Output directo for the plots (defail is the current directory)")
    cat("  --width <n>      Plot width in inches (default: 10)\n")
    cat("  --height <n>     Plot height in inches (default: 8)\n")
    cat("  --cex <n>        Text size multiplier (default: 0.8)\n\n")
    cat("Examples:\n")
    cat("Rscript plot_with_legend.R experiments/baseline/treemix_results/baseline_split \
          --output-dir plots/baseline/ \
          --both \
          --dpi 600 \
          --changed-pops comparison_results/differences.txt \
          --legend-pos topleft")
    quit(status = 0)
  }
  
  # Parse arguments
  stem <- args[1]
  output_file <- NULL
  changed_pops_path <- NULL 
  output_dir <- NULL
  use_colors <- TRUE
  add_legend <- TRUE
  legend_pos <- "topright"
  plot_migrations <- TRUE
  use_png <- FALSE
  create_both <- FALSE
  png_dpi <- 600
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
    } else if (arg == "--both") {
      create_both <- TRUE
    } else if (arg == "--dpi") {
      i <- i + 1
      png_dpi <- as.numeric(args[i])
    } else if (arg == "--changed-pops") {
      i <- i + 1
      changed_pops_path <- args[i]
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
    if (use_png && !create_both) {
      output_file <- paste0(output_file, ".png")
    } else if (!create_both) {
      output_file <- paste0(output_file, ".pdf")
    }
  }
  
  # Create the plot
  cat(sprintf("Plotting TreeMix results from: %s\n", stem))
  if (create_both) {
    cat("Creating both PDF and PNG versions\n")
  } else {
    cat(sprintf("Output file: %s\n", output_file))
  }
  cat(sprintf("Settings: colors=%s, legend=%s, migrations=%s\n", 
              use_colors, add_legend, plot_migrations))
  
  plot_treemix_with_legend(
    stem = stem,
    output_file = output_file,
    changed_pops_path = changed_pops_path,
    use_colors = use_colors,
    add_legend = add_legend,
    legend_pos = legend_pos,
    plot_migrations = plot_migrations,
    width = width,
    height = height,
    cex = cex,
    create_both = create_both,
    png_dpi = png_dpi
  )
  
  cat("Done!\n")
}

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
#source(file.path(script_dir, "plotting_funcs_marlene.R"))
source("/home/inf-21-2024/miniconda3/envs/treemix_env/bin/plotting_funcs.R")

#' Get continental region colors
#' @return Named list of colors for each region
get_region_colors <- function() {
  return(list(
    "Subsaharan Africa" = "#E41A1C",    # Red
    "North Africa" = "#FF7F00",         # Orange  
    "Europe" = "#4a62af",               # Green (not blue!)
    "Oceania" = "#984EA3",              # Purple
    "America" = "#F781BF",              # Pink
    "Asia" = "#377EB8",                 # Blue (not dark green!)
    "Middle East" = "#A65628"           # Brown (not purple!)
  ))
}

#' Load region mapping from JSON file
#' @param json_file Path to region_mapping.json
#' @return Data frame with population and region columns
load_region_mapping <- function(json_file = "/home/inf-21-2024/projects/Treemix/raw_data/region_mapping.json") {
  if (!file.exists(json_file)) {
    warning(sprintf("Region mapping file not found: %s", json_file))
    return(NULL)
  }
  
  region_data <- fromJSON(json_file)
  df <- data.frame(
    population = names(region_data),
    region = as.character(region_data),
    stringsAsFactors = FALSE
  )
  return(df)
}

#' Create population color mapping
#' @param region_mapping Data frame from load_region_mapping()
#' @return Data frame with population and color columns
create_population_colors <- function(region_mapping = NULL) {
  if (is.null(region_mapping)) {
    region_mapping <- load_region_mapping()
  }
  
  if (is.null(region_mapping)) {
    return(NULL)
  }
  
  region_colors <- get_region_colors()
  
  pop_colors <- data.frame(
    population = region_mapping$population,
    color = sapply(region_mapping$region, function(r) region_colors[[r]]),
    stringsAsFactors = FALSE
  )
  
  return(pop_colors)
}

#' Add region legend to plot
#' @param x X position ("topright", "topleft", "bottomright", "bottomleft", or numeric)
#' @param y Y position (numeric, or NULL if x is character)
#' @param cex Text size
#' @param title Legend title
add_region_legend <- function(x = "topright", y = NULL, cex = 0.7, title = "Continental regions") {
  region_colors <- get_region_colors()
  
  legend(
    x = x,
    y = y,
    legend = names(region_colors),
    col = unlist(region_colors),
    pch = 15,
    pt.cex = 1.5,
    cex = cex,
    title = title,
    bty = "n",
    bg = "white"
  )
}

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
  
  # Prepare color file - write to temp file for plot_tree function
  color_file <- NA
  if (use_colors) {
    color_data <- create_population_colors()
    if (!is.null(color_data)) {
      color_file <- tempfile(fileext = ".txt")
      write.table(color_data, color_file, quote = FALSE, row.names = FALSE, 
                  col.names = FALSE, sep = "\t")
    }
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
    o = color_file,
    cex = cex,
    disp = displacement,
    plus = 0.01,
    arrow = 0.05,
    scale = TRUE,
    flip = c(105, 92),
    ybar = 0.1,
    mbar = TRUE,
    plotmig = plot_migrations,
    plotnames = TRUE,
    xmin = 0,
    lwd = lwd,
    font = font
  )
  
  # Add legend if requested
  if (add_legend && use_colors) {
    add_region_legend(x = legend_pos, cex = 0.7)
  }
  
  dev.off()
  
  # Clean up temp file
  if (!is.na(color_file) && file.exists(color_file)) {
    unlink(color_file)
  }
  
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

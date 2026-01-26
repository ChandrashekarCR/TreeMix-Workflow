#!/usr/bin/env Rscript

# TreeMix Plotting Functions
# Custom implementation of TreeMix plotting functions without bugs
# Based on original plotting_funcs.R but with fixes and improvements


library(RColorBrewer)
library(jsonlite)

# ============================================================================
# Region Mapping and Legend Functions
# ============================================================================

#' Get continental region colors
#' @return Named list of colors for each region
get_region_colors <- function() {
  return(list(
    "Subsaharan Africa" = "#E41A1C",    # Red
    "North Africa" = "#FF7F00",         # Orange  
    "Europe" = "#4a62af",               # Blue
    "Oceania" = "#984EA3",              # Purple
    "America" = "#F781BF",              # Pink
    "Asia" = "#377EB8",                 # Light Blue
    "Middle East" = "#A65628"           # Brown
  ))
}

#' Load region mapping from JSON file
#' @param json_file Path to region_mapping.json
#' @return Data frame with population and region columns
load_region_mapping <- function(json_file = "/home/inf-21-2024/projects/treemix_project/raw_data/region_mapping.json") {
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

# ============================================================================
# Core Tree Coordinate Functions
# ============================================================================

# Set Y coordinates for tree vertices
# Dataframe of vertices
# Dataframe with y coordinates set
set_y_coords <- function(d) {
  i <- which(d[,3] == "ROOT")
  y <- d[i,8] / (d[i,8] + d[i,10])
  d[i,]$y <- 1 - y
  d[i,]$ymin <- 0
  d[i,]$ymax <- 1
  
  c1 <- d[i,7]
  c2 <- d[i,9]
  
  ni <- which(d[,1] == c1)
  ny <- d[ni,8] / (d[ni,8] + d[ni,10])
  d[ni,]$ymin <- 1 - y
  d[ni,]$ymax <- 1
  d[ni,]$y <- 1 - ny * y
  
  ni <- which(d[,1] == c2)
  ny <- d[ni,8] / (d[ni,8] + d[ni,10])
  d[ni,]$ymin <- 0
  d[ni,]$ymax <- 1 - y
  d[ni,]$y <- (1 - y) - ny * (1 - y)
  
  for (j in 1:nrow(d)) {
    d <- set_y_coord(d, j)
  }
  return(d)
}

# Set Y coordinate for a single vertex
# d Dataframe of vertices
# i Index of vertex to set
# Updated dataframe
set_y_coord <- function(d, i) {
  index <- d[i,1]
  parent <- d[i,6]
  
  if (!is.na(d[i,]$y)) {
    return(d)
  }
  
  tmp <- d[d[,1] == parent,]
  if (is.na(tmp[1,]$y)) {
    d <- set_y_coord(d, which(d[,1] == parent))
    tmp <- d[d[,1] == parent,]
  }
  
  py <- tmp[1,]$y
  pymin <- tmp[1,]$ymin
  pymax <- tmp[1,]$ymax
  f <- d[i,8] / (d[i,8] + d[i,10])
  
  if (tmp[1,7] == index) {
    d[i,]$ymin <- py
    d[i,]$ymax <- pymax
    d[i,]$y <- pymax - f * (pymax - py)
    if (d[i,5] == "TIP") {
      d[i,]$y <- (py + pymax) / 2
    }
  } else {
    d[i,]$ymin <- pymin
    d[i,]$ymax <- py
    d[i,]$y <- py - f * (py - pymin)
    if (d[i,5] == "TIP") {
      d[i,]$y <- (pymin + py) / 2
    }
  }
  return(d)
}

# Set X coordinates for tree vertices
# d Dataframe of vertices
# e Dataframe of edges
# Dataframe with x coordinates set
set_x_coords <- function(d, e) {
  i <- which(d[,3] == "ROOT")
  index <- d[i,1]
  d[i,]$x <- 0
  
  c1 <- d[i,7]
  c2 <- d[i,9]
  
  ni <- which(d[,1] == c1)
  tmpx <- e[e[,1] == index & e[,2] == c1, 3]
  if (length(tmpx) == 0) {
    tmp <- e[e[,1] == index,]
    tmpc1 <- tmp[1,2]
    if (d[d[,1] == tmpc1, 4] != "MIG") {
      tmpc1 <- tmp[2,2]
    }
    tmpx <- get_dist_to_nmig(d, e, index, tmpc1)
  }
  if (tmpx < 0) {
    tmpx <- 0
  }
  d[ni,]$x <- tmpx
  
  ni <- which(d[,1] == c2)
  tmpx <- e[e[,1] == index & e[,2] == c2, 3]
  if (length(tmpx) == 0) {
    tmp <- e[e[,1] == index,]
    tmpc2 <- tmp[2,2]
    if (d[d[,1] == tmpc2, 4] != "MIG") {
      tmpc2 <- tmp[1,2]
    }
    tmpx <- get_dist_to_nmig(d, e, index, tmpc2)
  }
  if (tmpx < 0) {
    tmpx <- 0
  }
  d[ni,]$x <- tmpx
  
  for (j in 1:nrow(d)) {
    d <- set_x_coord(d, e, j)
  }
  return(d)
}

# Set X coordinate for a single vertex
# d Dataframe of vertices
# e Dataframe of edges
# i Index of vertex to set
# Updated dataframe
set_x_coord <- function(d, e, i) {
  index <- d[i,1]
  parent <- d[i,6]
  
  if (!is.na(d[i,]$x)) {
    return(d)
  }
  
  tmp <- d[d[,1] == parent,]
  if (is.na(tmp[1,]$x)) {
    d <- set_x_coord(d, e, which(d[,1] == parent))
    tmp <- d[d[,1] == parent,]
  }
  
  tmpx <- e[e[,1] == parent & e[,2] == index, 3]
  if (length(tmpx) == 0) {
    tmp2 <- e[e[,1] == parent,]
    tmpc2 <- tmp2[2,2]
    if (d[d[,1] == tmpc2, 4] != "MIG") {
      tmpc2 <- tmp2[1,2]
    }
    tmpx <- get_dist_to_nmig(d, e, parent, tmpc2)
  }
  if (tmpx < 0) {
    tmpx <- 0
  }
  d[i,]$x <- tmp[1,]$x + tmpx
  return(d)
}

# Get distance to non-migration node
# d Dataframe of vertices
# e Dataframe of edges
# n1 Node 1
# n2 Node 2
# Distance
get_dist_to_nmig <- function(d, e, n1, n2) {
  toreturn <- e[e[,1] == n1 & e[,2] == n2, 3]
  while (d[d[,1] == n2, 4] == "MIG") {
    tmp <- e[e[,1] == n2 & e[,5] == "NOT_MIG",]
    toreturn <- toreturn + tmp[1,3]
    n2 <- tmp[1,2]
  }
  return(toreturn)
}

# Set migration coordinates
# d Dataframe of vertices
# e Dataframe of edges
# Updated dataframe
set_mig_coords <- function(d, e) {
  for (j in 1:nrow(d)) {
    if (d[j,4] == "MIG") {
      p <- d[d[,1] == d[j,6],]
      c <- d[d[,1] == d[j,7],]
      tmpe <- e[e[,1] == d[j,1],]
      y1 <- p[1,]$y
      y2 <- c[1,]$y
      x1 <- p[1,]$x
      x2 <- c[1,]$x
      
      mf <- tmpe[1,6]
      if (is.nan(mf)) {
        mf <- 0
      }
      d[j,]$y <- y1 + (y2 - y1) * mf
      d[j,]$x <- x1 + (x2 - x1) * mf
    }
  }
  return(d)
}

# Flip children of a node
# d Dataframe of vertices
# n Node to flip
# Updated dataframe
flip_node <- function(d, n) {
  i <- which(d[,1] == n)
  t1 <- d[i,7]
  t2 <- d[i,8]
  d[i,7] <- d[i,9]
  d[i,8] <- d[i,10]
  d[i,9] <- t1
  d[i,10] <- t2
  return(d)
}

#' Plot tree internal implementation (FIXED VERSION)
#' @param d Dataframe of vertices
#' @param e Dataframe of edges
#' @param o Color data (either NA or a dataframe with population names and colors)
#' @param cex Text size
#' @param disp Text displacement from point
#' @param plus Extra space on right
#' @param arrow Arrow length for migrations
#' @param ybar Y position for scale bar
#' @param scale Whether to show scale bar
#' @param mbar Whether to show migration color bar
#' @param mse Mean standard error
#' @param plotmig Whether to plot migration edges
#' @param plotnames Whether to plot population names
#' @param xmin Minimum x value
#' @param lwd Line width
#' @param font Font type (1=normal, 2=bold, 3=italic, 4=bold italic)
#' @param mark_changes Whether to highlight changed populations
#' @param changed_pops_path Path to file containing changed population names (one per line)
#' @param add_legend Whether to add continental region legend
#' @param legend_pos Legend position ("topright", "topleft", "bottomright", "bottomleft")
plot_tree_internal <- function(d, e, o = NA, cex = 1, disp = 0.005, plus = 0.005, 
                                arrow = 0.05, ybar = 0.01, scale = TRUE, mbar = TRUE, 
                                mse = 0.01, plotmig = TRUE, plotnames = TRUE, xmin = 0, 
                                lwd = 1, font = 1, mark_changes = FALSE, changed_pops_path = NULL,
                                add_legend = FALSE, legend_pos = "topright") {
  
  # Create base plot
  plot(d$x, d$y, axes = FALSE, ylab = "", xlab = "Drift parameter", 
       xlim = c(xmin, max(d$x) + plus), pch = "")
  axis(1)
  
  # Get max migration weight for color scaling
  mw <- max(e[e[,5] == "MIG", 4])
  mcols <- rev(heat.colors(150))
  
  # Plot edges
  for (i in 1:nrow(e)) {
    col <- "black"
    
    # Color migration edges
    if (e[i,5] == "MIG") {
      w <- floor(e[i,4] * 200) + 50
      if (mw > 0.5) {
        w <- floor(e[i,4] * 100) + 50
      }
      col <- mcols[w]
      if (is.na(col)) {
        col <- "blue"
      }
    }
    
    v1 <- d[d[,1] == e[i,1],]
    v2 <- d[d[,1] == e[i,2],]
    
    if (e[i,5] == "MIG") {
      if (plotmig) {
        arrows(v1[1,]$x, v1[1,]$y, v2[1,]$x, v2[1,]$y, col = col, length = arrow)
      }
    } else {
      lines(c(v1[1,]$x, v2[1,]$x), c(v1[1,]$y, v2[1,]$y), col = col, lwd = lwd)
    }
  }
  
  # Plot tip labels
  tmp <- d[d[,5] == "TIP",]
  
  # Read changed populations if mark_changes is enabled
  changed_pops <- c()
  if (mark_changes && !is.null(changed_pops_path)) {
    if (file.exists(changed_pops_path)) {
      changed_pops <- readLines(changed_pops_path)
    } else {
      warning(paste("Changed populations file not found:", changed_pops_path))
    }
  }
  
  # Fixed color handling - check if o is NA or a dataframe
  if (length(o) == 1 && is.na(o)) {
    # No colors provided
    if (plotnames) {
      for (i in 1:nrow(tmp)) {
        node_name <- tmp[i,2]
        font_weight <- ifelse(node_name %in% changed_pops, 4, font)
        
        # Draw highlighting rectangle if this population changed
        if (node_name %in% changed_pops) {
          label_width <- strwidth(node_name, cex = cex, font = font_weight)
          label_height <- strheight(node_name, cex = cex, font = font_weight)
          
          rect(
            xleft = (tmp[i,]$x + disp) * 0.995,
            ybottom = (tmp[i,]$y - label_height / 2) * 0.995,
            xright = (tmp[i,]$x + disp + label_width) * 1.005,
            ytop = (tmp[i,]$y + label_height / 2) * 1.005,
            border = adjustcolor("red", alpha.f = 0.6),
            col = rgb(1, 1, 1, alpha = 0)
          )
        }
        
        text(tmp[i,]$x + disp, tmp[i,]$y, labels = node_name, 
             adj = 0, cex = cex, font = font_weight)
      }
    }
  } else {
    # Colors provided as dataframe
    if (plotnames) {
      for (i in 1:nrow(tmp)) {
        node_name <- tmp[i,2]
        tcol <- o[o[,1] == node_name, 2]
        if (length(tcol) == 0) tcol <- "black"
        font_weight <- ifelse(node_name %in% changed_pops, 4, font)
        
        # Draw highlighting rectangle if this population changed
        if (node_name %in% changed_pops) {
          label_width <- strwidth(node_name, cex = cex, font = font_weight)
          label_height <- strheight(node_name, cex = cex, font = font_weight)
          
          rect(
            xleft = (tmp[i,]$x + disp) * 0.995,
            ybottom = (tmp[i,]$y - label_height / 2) * 0.995,
            xright = (tmp[i,]$x + disp + label_width) * 1.005,
            ytop = (tmp[i,]$y + label_height / 2) * 1.005,
            border = adjustcolor("red", alpha.f = 0.6),
            col = rgb(1, 1, 1, alpha = 0)
          )
        }
        
        text(tmp[i,]$x + disp, tmp[i,]$y, labels = node_name, 
             adj = 0, cex = cex, col = tcol, font = font_weight)
      }
    }
  }
  
  # Plot scale bar
  if (scale) {
    lines(c(0, mse * 10), c(ybar, ybar))
    text(0, ybar - 0.04, lab = "10 s.e.", adj = 0, cex = 0.8)
    lines(c(0, 0), c(ybar - 0.01, ybar + 0.01))
    lines(c(mse * 10, mse * 10), c(ybar - 0.01, ybar + 0.01))
  }
  
  # Plot migration weight color bar
  if (mbar) {
    mcols <- rev(heat.colors(150))
    mcols <- mcols[50:length(mcols)]
    ymi <- ybar + 0.15
    yma <- ybar + 0.35
    l <- 0.2
    w <- l / 100
    xma <- max(d$x / 20)
    rect(rep(0, 100), ymi + (0:99) * w, rep(xma, 100), ymi + (1:100) * w, 
         col = mcols, border = mcols)
    text(xma + disp, ymi, lab = "0", adj = 0, cex = 0.7)
    if (mw > 0.5) {
      text(xma + disp, yma, lab = "1", adj = 0, cex = 0.7)
    } else {
      text(xma + disp, yma, lab = "0.5", adj = 0, cex = 0.7)
    }
    text(0, yma + 0.06, lab = "Migration", adj = 0, cex = 0.6)
    text(0, yma + 0.03, lab = "weight", adj = 0, cex = 0.6)
  }
  
  # Add region legend if requested and colors are being used
  if (add_legend && !(length(o) == 1 && is.na(o))) {
    add_region_legend(x = legend_pos, cex = 0.7)
  }
}

#' Main function to plot a TreeMix tree
#' @param stem File stem (path without extension)
#' @param o Color file or NA. If NA and use_region_colors=TRUE, colors from region mapping will be used
#' @param cex Text size
#' @param disp Text displacement
#' @param plus Extra space on right
#' @param flip Vector of nodes to flip
#' @param arrow Arrow length for migrations
#' @param scale Whether to show scale bar
#' @param ybar Y position for scale bar
#' @param mbar Whether to show migration color bar
#' @param plotmig Whether to plot migrations
#' @param plotnames Whether to plot names
#' @param xmin Minimum x value
#' @param lwd Line width
#' @param font Font type
#' @param mark_changes Whether to highlight changed populations
#' @param changed_pops_path Path to file containing changed population names (one per line)
#' @param use_region_colors Whether to automatically color populations by continental region
#' @param add_legend Whether to add continental region legend (only if using region colors)
#' @param legend_pos Legend position ("topright", "topleft", "bottomright", "bottomleft")
#' @return List with vertices (d) and edges (e) dataframes
plot_tree <- function(stem, o = NA, cex = 1, disp = 0.003, plus = 0.01, flip = vector(), 
                      arrow = 0.05, scale = TRUE, ybar = 0.1, mbar = TRUE, plotmig = TRUE, 
                      plotnames = TRUE, xmin = 0, lwd = 1, font = 1, mark_changes = FALSE, 
                      changed_pops_path = NULL, use_region_colors = FALSE, add_legend = FALSE,
                      legend_pos = "topright") {
  
  # Read data files
  d <- paste(stem, ".vertices.gz", sep = "")
  e <- paste(stem, ".edges.gz", sep = "")
  se <- paste(stem, ".covse.gz", sep = "")
  
  d <- read.table(gzfile(d), as.is = TRUE, comment.char = "", quote = "")
  e <- read.table(gzfile(e), as.is = TRUE, comment.char = "", quote = "")
  
  # Handle color input
  if (use_region_colors && (length(o) == 1 && is.na(o))) {
    # Use continental region colors
    color_data <- create_population_colors()
    if (!is.null(color_data)) {
      o <- color_data
    } else {
      warning("Could not load region colors, plotting without colors")
    }
  } else if (!is.na(o) && is.character(o)) {
    # Read color file if path provided
    o <- read.table(o, as.is = TRUE, comment.char = "", quote = "")
  }
  
  # Scale edge weights
  e[,3] <- e[,3] * e[,4]
  
  # Calculate mean standard error
  se <- read.table(gzfile(se), as.is = TRUE, comment.char = "", quote = "")
  m1 <- apply(se, 1, mean)
  m <- mean(m1)
  
  # Flip nodes if requested
  for (i in 1:length(flip)) {
    d <- flip_node(d, flip[i])
  }
  
  # Initialize coordinate columns
  d$x <- NA
  d$y <- NA
  d$ymin <- NA
  d$ymax <- NA
  d$x <- as.numeric(d$x)
  d$y <- as.numeric(d$y)
  d$ymin <- as.numeric(d$ymin)
  d$ymax <- as.numeric(d$ymax)
  
  # Set coordinates
  d <- set_y_coords(d)
  d <- set_x_coords(d, e)
  d <- set_mig_coords(d, e)
  
  # Plot
  plot_tree_internal(d, e, o = o, cex = cex, xmin = xmin, disp = disp, plus = plus, 
                     arrow = arrow, ybar = ybar, mbar = mbar, mse = m, scale = scale, 
                     plotmig = plotmig, plotnames = plotnames, lwd = lwd, font = font,
                     mark_changes = mark_changes, changed_pops_path = changed_pops_path,
                     add_legend = add_legend, legend_pos = legend_pos)
  
  return(list(d = d, e = e))
}

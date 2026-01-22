#!/usr/bin/env Rscript
#
# TreeMix Plotting Functions
# Custom implementation of TreeMix plotting functions without bugs
# Based on original plotting_funcs.R but with fixes and improvements
#

library(RColorBrewer)

#' Set Y coordinates for tree vertices
#' @param d Dataframe of vertices
#' @return Dataframe with y coordinates set
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

#' Set Y coordinate for a single vertex
#' @param d Dataframe of vertices
#' @param i Index of vertex to set
#' @return Updated dataframe
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

#' Set X coordinates for tree vertices
#' @param d Dataframe of vertices
#' @param e Dataframe of edges
#' @return Dataframe with x coordinates set
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

#' Set X coordinate for a single vertex
#' @param d Dataframe of vertices
#' @param e Dataframe of edges
#' @param i Index of vertex to set
#' @return Updated dataframe
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

#' Get distance to non-migration node
#' @param d Dataframe of vertices
#' @param e Dataframe of edges
#' @param n1 Node 1
#' @param n2 Node 2
#' @return Distance
get_dist_to_nmig <- function(d, e, n1, n2) {
  toreturn <- e[e[,1] == n1 & e[,2] == n2, 3]
  while (d[d[,1] == n2, 4] == "MIG") {
    tmp <- e[e[,1] == n2 & e[,5] == "NOT_MIG",]
    toreturn <- toreturn + tmp[1,3]
    n2 <- tmp[1,2]
  }
  return(toreturn)
}

#' Set migration coordinates
#' @param d Dataframe of vertices
#' @param e Dataframe of edges
#' @return Updated dataframe
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

#' Flip children of a node
#' @param d Dataframe of vertices
#' @param n Node to flip
#' @return Updated dataframe
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
plot_tree_internal <- function(d, e, o = NA, cex = 1, disp = 0.005, plus = 0.005, 
                                arrow = 0.05, ybar = 0.01, scale = TRUE, mbar = TRUE, 
                                mse = 0.01, plotmig = TRUE, plotnames = TRUE, xmin = 0, 
                                lwd = 1, font = 1) {
  
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
  
  # Fixed color handling - check if o is NA or a dataframe
  if (length(o) == 1 && is.na(o)) {
    # No colors provided
    if (plotnames) {
      text(tmp$x + disp, tmp$y, labels = tmp[,2], adj = 0, cex = cex, font = font)
    }
  } else {
    # Colors provided as dataframe
    if (plotnames) {
      for (i in 1:nrow(tmp)) {
        tcol <- o[o[,1] == tmp[i,2], 2]
        if (length(tcol) == 0) tcol <- "black"
        text(tmp[i,]$x + disp, tmp[i,]$y, labels = tmp[i,2], 
             adj = 0, cex = cex, col = tcol, font = font)
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
}

#' Main function to plot a TreeMix tree
#' @param stem File stem (path without extension)
#' @param o Color file or NA
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
#' @return List with vertices (d) and edges (e) dataframes
plot_tree <- function(stem, o = NA, cex = 1, disp = 0.003, plus = 0.01, flip = vector(), 
                      arrow = 0.05, scale = TRUE, ybar = 0.1, mbar = TRUE, plotmig = TRUE, 
                      plotnames = TRUE, xmin = 0, lwd = 1, font = 1) {
  
  # Read data files
  d <- paste(stem, ".vertices.gz", sep = "")
  e <- paste(stem, ".edges.gz", sep = "")
  se <- paste(stem, ".covse.gz", sep = "")
  
  d <- read.table(gzfile(d), as.is = TRUE, comment.char = "", quote = "")
  e <- read.table(gzfile(e), as.is = TRUE, comment.char = "", quote = "")
  
  # Read color file if provided
  if (!is.na(o) && is.character(o)) {
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
                     plotmig = plotmig, plotnames = plotnames, lwd = lwd, font = font)
  
  return(list(d = d, e = e))
}

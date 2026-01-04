library(data.table)
source("/Users/marleneuni/Projects/arnold-test/treemix-1.13/src/plotting_funcs.R")  # Replace with the correct filename if needed

compute_variance_and_plot <- function(
    stem,                  # TreeMix file prefix (e.g. "baseline_seed_231_m_8")
    poporder_file,         # Path to population order file (txt)
    output_dir = ".",      # Where to save the plots
    plot_format = "pdf",   # "pdf" or "png"
    cex = 0.5              # Text size for population labels
) {
  # --- Load covariance matrices ---
  cov_file <- paste0(stem, ".cov.gz")
  modelcov_file <- paste0(stem, ".modelcov.gz")
  
  obs <- fread(cov_file, data.table = FALSE)
  rownames(obs) <- obs[,1]
  #rownames(obs) <- obs[[1]]
  obs <- obs[,-1]
  obs <- as.matrix(obs)
  
  exp <- fread(modelcov_file, data.table = FALSE)
  rownames(exp) <- exp[,1]
  #rownames(exp) <- exp[[1]]
  exp <- exp[,-1]
  exp <- as.matrix(exp)
  
  # --- Align by common populations ---
  common <- intersect(rownames(obs), rownames(exp))
  print(common)
  obs <- obs[common, common]
  exp <- exp[common, common]
  
  # --- Compute explained variance ---
  # --- as in the paper ----
  # Get upper triangle indices (i < j)
  R <- obs - exp
  triu_idx <- which(upper.tri(obs), arr.ind = TRUE)
  
  # Extract upper triangle values
  R_vals <- R[triu_idx]
  W_vals <- obs[triu_idx]
  
  # Compute means
  R_bar <- mean(R_vals)
  W_bar <- mean(W_vals)
  
  # Equation (30)
  numerator <- sum((R_vals - R_bar)^2)
  denominator <- sum((W_vals - W_bar)^2)
  
  explained_variance <- 1 - (numerator / denominator)
  
  
  # --- simplified -----
  #obs_vec <- as.vector(obs)
  #exp_vec <- as.vector(exp)
  #residual_ss <- sum((obs_vec - exp_vec)^2)
  #total_ss <- sum(obs_vec^2)
  #explained_variance <- 1 - (residual_ss / total_ss)
  
  # --- Save residual plot ---
  plot_file <- file.path(output_dir, paste0(basename(stem), "_residuals.", plot_format))
  
  if (plot_format == "pdf") {
    #pdf(plot_file, width = 6, height = 6)
  } else if (plot_format == "png") {
    #png(plot_file, width = 2000, height = 2000, res = 300)
  } else {
    stop("Unsupported plot format.")
  }
  
  plot_resid(stem, poporder_file, cex = cex)
  
  dev.off()
  
  # --- Return result ---
  cat(sprintf("Saved residual plot to: %s\n", plot_file))
  return(explained_variance)
}


results <- data.frame(m = integer(), explained_variance = numeric())
seedlist <-list(1)
for (m in seedlist) {
  stem <- sprintf("Projects/Treemix-Project/treemix_results/rerun_21_03/migration/baseline_seed_231_m_%d", m)
  ev <- compute_variance_and_plot(
    stem = stem,
    poporder_file = "Projects/Treemix-Project/treemix_results/rerun_21_03/poporder.txt",
    output_dir = "Projects/Treemix-Project/plots/baseline_tests/",
    plot_format = "png",
    cex = 0.4
  )
  results <- rbind(results, data.frame(m = m, explained_variance = ev))
}
results

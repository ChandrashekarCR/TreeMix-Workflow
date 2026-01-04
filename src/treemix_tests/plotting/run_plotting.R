source("/Users/marleneuni/Projects/arnold-test/treemix-1.13/src/plotting_funcs.R")  # Replace with the correct filename if needed
library(jsonlite) 



plot_all_treemix_trees <- function(
    files_path,
    output_plot_path
) {
  # List only files ending with .treeout.gz (i.e., ones we can plot)
  all_files <- list.files(files_path, pattern = "\\.treeout\\.gz$", full.names = FALSE)
  all_files
  # Extract base names by removing the known suffix
  base_names <- gsub("\\.treeout\\.gz$", "", all_files)
  base_names
  print(base_names)
  message("Found ", length(base_names), " valid base names to plot.")
  
  for (base in base_names) {
    message("Processing: ", base)
    
    # Construct file paths
    full_path <- file.path(files_path, base)
    output_file <- file.path(output_plot_path, paste0(base, "_1.png"))
    
    full_path
    # Plot and save
    png(filename = output_file, width = 2500, height = 2100, res = 300)
    plot_tree(
      full_path,
      cex = 0.4,
      arrow = 0.05,
      plotmig = TRUE,
      plotnames = TRUE,
      scale = FALSE,
      base_name = titel
    )
    dev.off()
  }
}

plot_all_treemix_trees_cooler <- function(
    files_path,
    output_plot_path,
    titles = NULL  # optional vector of titles
) {
  # List files ending with .treeout.gz
  all_files <- list.files(files_path, pattern = "\\.treeout\\.gz$", full.names = FALSE)
  base_names <- gsub("\\.treeout\\.gz$", "", all_files)
  
  message("Found ", length(base_names), " valid base names to plot.")
  
  # If no titles provided, use base names as titles
  if (is.null(titles)) {
    titles <- base_names
  }
  
  # Sanity check: length of titles must match base_names
  if (length(titles) != length(base_names)) {
    stop("❌ Length of 'titles' must match number of input files!")
  }
  
  # Loop through and plot each
  for (i in seq_along(base_names)) {
    base <- base_names[i]
    title <- titles[i]
    
    message("Processing: ", base, " with title: ", title)
    
    full_path <- file.path(files_path, base)
    output_file <- file.path(output_plot_path, paste0(base, "_1.png"))
    
    png(filename = output_file, width = 2500, height = 2100, res = 300)
    plot_tree(
      full_path,
      cex = 0.4,
      arrow = 0.05,
      plotmig = TRUE,
      plotnames = TRUE,
      scale = FALSE,
      base_name = title  # now this will be the actual title
    )
    dev.off()
  }
}


files_path <- "Projects/Treemix-Project/results/experiments/experiment_10/treemix_output/"
all_files <- list.files(files_path, pattern = "\\.treeout\\.gz$", full.names = FALSE)
all_files
output_plot_path <- "Projects/Treemix-Project/results/experiments/experiment_10/plots//"
titels<-("Admixed populations removed")
plot_all_treemix_trees_cooler(files_path, output_plot_path, titels)

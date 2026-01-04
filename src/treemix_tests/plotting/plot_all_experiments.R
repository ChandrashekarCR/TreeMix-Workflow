source("/Users/marleneuni/Projects/arnold-test/treemix-1.13/src/plotting_funcs.R")  # Replace with the correct filename if needed

# Get Treemix trees with colored superpopulations and changes
library(jsonlite) 


plot_all_treemix_trees <- function(
    files_path,
    output_plot_path,
    titles = NULL# optional vector of titles

) {
  # List files ending with .treeout.gz
  all_files <- list.files(files_path, pattern = "\\.treeout\\.gz$", full.names = FALSE)
  base_names <- gsub("\\.treeout\\.gz$", "", all_files)
  
  message("Found ", length(base_names), " valid base names to plot.")
  
  # Loop through and plot each
  for (i in seq_along(base_names)) {
    base <- base_names[i]

    message("Processing: ", base, " with title: ", titles)
    
    full_path <- file.path(files_path, base)
    output_file <- file.path(output_plot_path , paste0(base, ".png"))
    print(output_file)

    png(filename = output_file, width = 2500, height = 2100, res = 300)
    plot_tree(
      full_path,
      cex = 0.6,#0.4
      arrow = 0.05,
      plotmig = TRUE,
      plotnames = TRUE,
      scale = FALSE,
      base_name = NULL, #"Baseline", #title,  # now this will be the actual title
      mark_changes_bool= FALSE
    )
    print(output_file)
    dev.off()
  }
}




plot_all_treemix_trees(
  files_path = "Projects/Treemix-Project/23062025_results/experiments/baseline/treemix_output/",
  output_plot_path="Projects/Treemix-Project/23062025_results/experiments/baseline/plots",
  titles="baseline")
   



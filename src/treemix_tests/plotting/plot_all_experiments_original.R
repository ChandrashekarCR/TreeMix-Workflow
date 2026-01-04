source("/Users/marleneuni/Projects/Treemix-Project/bin/treemix/src/plotting_funcs.R")  # Replace with the correct filename if needed
# Get Trees with the orginal code!
library(jsonlite) 


plot_all_treemix_trees <- function(
    files_path,
    output_plot_path

) {
  # List files ending with .treeout.gz
  all_files <- list.files(files_path, pattern = "\\.treeout\\.gz$", full.names = FALSE)
  base_names <- gsub("\\.treeout\\.gz$", "", all_files)
  
  message("Found ", length(base_names), " valid base names to plot.")
  

  # Loop through and plot each
  for (i in seq_along(base_names)) {
    base <- base_names[i]

    message("Processing: ", base)
    
    full_path <- file.path(files_path, base)
    output_file <- file.path(output_plot_path, paste0(base, "_org",".png"))
    print(output_file)

    png(filename = output_file, width = 2500, height = 2100, res = 300)
    plot_tree(
      full_path,
      cex = 0.4,
      arrow = 0.05,
      plotmig = TRUE,
      plotnames = TRUE,
      scale = FALSE,
    )
    print(output_file)
    dev.off()
  }
}




plot_all_treemix_trees(
  files_path="Projects/Treemix-Project/290425_results/experiments/experiment_2/treemix_output/", 
  output_plot_path="/Users/marleneuni/Projects/Treemix-Project/scripts/plotting/paper_plots"
)


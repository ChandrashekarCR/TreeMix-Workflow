source("/Users/marleneuni/Projects/arnold-test/treemix-1.13/src/plotting_funcs.R")  # Replace with the correct filename if needed
library(jsonlite) 

plot_and_save_tree <- function(
    files_path,
    output_plot_path,
    title = NULL,
    mark_changes_bool = FALSE,
    changed_pops_path = NULL,
    width = 2500,
    height = 2100,
    res = 300,
    cex = 0.6,
    arrow = 0.05,
    plotmig = TRUE,
    plotnames = TRUE,
    scale = FALSE
) {
    # Validate input parameters
    if (!file.exists(paste0(files_path, ".treeout.gz"))) {
        stop(sprintf("Input file not found: %s", paste0(files_path, ".treeout.gz")))
    }
    
    if (mark_changes_bool && is.null(changed_pops_path)) {
        stop("changed_pops_path must be provided when mark_changes_bool is TRUE")
    }
    
    if (mark_changes_bool && !file.exists(changed_pops_path)) {
        stop(sprintf("Changed populations file not found: %s", changed_pops_path))
    }
    
    # Create output directory if it doesn't exist
    output_dir <- dirname(output_plot_path)
    if (!dir.exists(output_dir)) {
        dir.create(output_dir, recursive = TRUE)
    }
    
    # Start PNG device with error handling
    tryCatch({
        png(
            filename = output_plot_path,
            width = width,
            height = height,
            res = res
        )
        
        # Plot the tree
        plot_tree(
            files_path,
            cex = cex,
            arrow = arrow,
            plotmig = plotmig,
            plotnames = plotnames,
            scale = scale,
            base_name = title,
            mark_changes_bool = mark_changes_bool,
            changed_pops = changed_pops_path
        )
        
        # Close the device
        dev.off()
        
        # Print success message
        message(sprintf("Plot saved successfully to: %s", output_plot_path))
        
    }, error = function(e) {
        # Ensure device is closed in case of error
        if (dev.cur() > 1) {
            dev.off()
        }
        stop(sprintf("Error creating plot: %s", e$message))
    })
}


generate_all_tree_plots <- function(
    experiment_folder,
    plots_dir = NULL
) {
    # Define subfolders
    treemix_dir <- file.path(experiment_folder, "treemix_output")
    differences_dir <- file.path(experiment_folder, "comparision_results")
    
    if (is.null(plots_dir)) {
      plots_dir <- file.path(experiment_folder, "plots")
    }
    
    # Create plots directory if not exists
    if (!dir.exists(plots_dir)) {
        dir.create(plots_dir, recursive = TRUE)
    }
    
    # List all .treeout.gz files
    tree_files <- list.files(treemix_dir, pattern = "\\.treeout\\.gz$", full.names = TRUE)
    
    if (length(tree_files) == 0) {
        stop(sprintf("No tree files found in %s", treemix_dir))
    }
    
    print(sprintf("Found %d tree files to process", length(tree_files)))
    
    for (file_path in tree_files) {
        # Extract base name (remove directory and file extension)
        base_name <- sub("\\.treeout\\.gz$", "", basename(file_path))
        print(sprintf("Processing %s", base_name))
        
        # Construct corresponding paths
        changed_pops_path <- file.path(differences_dir, paste0(base_name, "_differences.txt"))
        print(changed_pops_path)
        output_plot_path <- file.path(plots_dir, paste0(base_name,"_diff",".png"))
        
        
        
        # Skip if the required differences file doesn't exist
        if (!file.exists(changed_pops_path)) {
            warning(sprintf("Missing changes file for %s, skipping.", base_name))
            next
        }
        print(sprintf("Output %s", output_plot_path))
        print(sprintf("Processing %s", base_name))
        path <- file.path(treemix_dir, base_name)
        print(path)
        # Call the plotting function
        plot_and_save_tree(
            files_path = path,
            output_plot_path = output_plot_path,
            title = NULL,
            mark_changes_bool = TRUE,
            changed_pops_path = changed_pops_path,
        # 
         )
    }
    
    print("All plots generated!")
}

# Example usage with correct path
generate_all_tree_plots("/Users/marleneuni/Projects/Treemix-Project/23062025_results/experiments/experiment_5", "/Users/marleneuni/Projects/Treemix-Project/23062025_results/experiments/experiment_5/plots")
#plot_and_save_tree("/Users/marleneuni/Projects/Treemix-Project/23062025_results/experiments/baseline/treemix_output/baseline_output", "/Users/marleneuni/Projects/Treemix-Project/scripts/plotting/paper_plots/baseline.png", "Baseline")

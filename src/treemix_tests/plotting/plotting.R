source("/Users/marleneuni/Projects/arnold-test/treemix-1.13/src/plotting_funcs.R")  # Replace with the correct filename if needed
library(jsonlite) 
# Get all files in the directory
#all_files <- list.files("/Users/marleneuni/Downloads/treemix_results/", full.names = TRUE)

#all_control_files <- list.files("/Users/marleneuni/Projects/Treemix-Project/control/control_results/", full.names = TRUE)
#all_files <- list.files("/Uswers/mar")
# Extract unique base filenames

files_path = "/Users/marleneuni/Projects/Treemix-Project/plink_results/experiments/artificial_pops2/artificial_pops2/"

all_files <- list.files(files_path)
base_names <- unique(gsub("\\.(llik|cov\\.gz|covse\\.gz|modelcov\\.gz|treeout\\.gz|vertices\\.gz|edges\\.gz)", "", basename(all_files)))
base_names<-"treemix_output"
for (base in base_names) {
  print(base)
  # Define file path for saving the image
  output_path = paste("/Users/marleneuni/Projects/Treemix-Project/plink_results/experiments/artificial_pops2/", base, ".png", sep = "")
  # Save as PNG
  png(filename = output_path, width = 2400, height = 2000, res = 300)  # Adjust size & resolution as needed
  
  path = paste(files_path,base, sep = "")
  print(path)
  plot_tree(path,
            cex = 0.6,         # Text size
            arrow = 0.05,      # Arrow size for migration edges
            plotmig = TRUE,    # Show migration edges
            plotnames = TRUE,  # Show population names
            scale = FALSE,
            base_name=base
            
  )
  dev.off() 
  
}

pop_list <- c(
  "MbutiPygmy", "BiakaPygmy", "Mandenka", "Yoruba",
  "San", "BantuSouthAfrica", "BantuKenya", "Mozabite",
  
  "French", "Sardinian" , "Orcadian" , "Russian" , 
  "Italian" , "Tuscan" , "Basque" , "Adygei" ,
  
  "Japanese" , "Han" , "Han-NChina" , "Yi" ,
  "Miao" , "Tujia" , "Oroqen" , "Daur" ,
  "Mongola" , "Hezhen" , "Xibo" , "She" ,
  "Dai" , "Lahu" , "Tu" , "Naxi" ,
  "Cambodian" , "Yakut" ,
  
  "Brahui" , "Balochi" , "Hazara" , "Makrani" ,
  "Sindhi" , "Pathan" , "Kalash" , "Burusho" ,
  "Uygur" ,
  
  "Druze" , "Bedouin" , "Palestinian" ,
  
  "Colombian", "Surui", "Maya", "Karitiana",
  "Pima",
  
  "Papuan", "Melanesian"
)

# Save to file (one name per line)
writeLines(pop_list, "Projects/Treemix-Project/treemix_results/rerun_21_03/poporder.txt")


plot_resid("Projects/Treemix-Project/treemix_results/rerun_21_03/baseline_tests/baseline_seed_123",
           "Projects/Treemix-Project/treemix_results/rerun_21_03/poporder.txt", cex = 0.6, 
)


# Load required libraries
library(data.table)  # for fast file reading
library(Matrix)

# Load observed covariance matrix
obs <- fread("Projects/Treemix-Project/treemix_results/rerun_21_03/migration/baseline_seed_231_m_8.cov.gz", data.table = FALSE)
rownames(obs) <- obs[,1]
obs <- obs[,-1]
obs <- as.matrix(obs)

# Load expected/model covariance matrix
exp <- fread("Projects/Treemix-Project/treemix_results/rerun_21_03/migration/baseline_seed_231_m_8.modelcov.gz", data.table = FALSE)
rownames(exp) <- exp[,1]
exp <- exp[,-1]
exp <- as.matrix(exp)

# Make sure matrices align (intersection only)
common <- intersect(rownames(obs), rownames(exp))
obs <- obs[common, common]
exp <- exp[common, common]

# Flatten and calculate explained variance
obs_vec <- as.vector(obs)
exp_vec <- as.vector(exp)

residual_ss <- sum((obs_vec - exp_vec)^2)
total_ss <- sum(obs_vec^2)

explained_variance <- 1 - (residual_ss / total_ss)

cat(sprintf("Explained variance: %.4f\n", explained_variance))


#0.9937 #45
# 0.9937#43
# 0.9937 #15
#0.9937 #231
#0.9937 #123



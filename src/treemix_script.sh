#!/bin/bash

# ================
# TREEMIX Batch Processing Scripts
# Author: Chandrashekar CR
# Date: 26/01/2026
# Description: This script runs different treemix parameters on the experimental output from PLINK.
# 
#
#
# ================

# === CONFIGURATION ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # Script Directory
PROJECT_ROOT="$(cd "$SCRIPT_DIR"/.. && pwd)" # Project Root Directory
TREEMIX="$HOME/miniconda3/envs/treemix_env/bin/treemix" # Treemix 
EXPERIMENTS_DIR="$PROJECT_ROOT"/experiments
SEED=1 # Seed
SPLIT=0 # Split only
MIGRATION_ENABLED=10 # Migration Enabled
SNP_SIZE=1000 # SNP Block size
ROOT="San" # Root of the trees

# Check if treemix is installed
if ! command -v "$TREEMIX" &> /dev/null; then
    echo "Error: treemix not fouunf at $TREEMIX"
    echo "Please activte conda environment: conda actiavte treemix_env"
    exit 1
fi

# Baseline split only treemix function
treemix_baseline () {
    local INPUT_FILE=$1
    local OUTPUT_FILE=$2

    if [ ! -d "$OUTPUT_FILE" ]; then 
        echo "Creating output directory."
        mkdir -p "$OUTPUT_FILE"
    else
        echo "Directory already exists."
    fi

    echo "Running treemix.."
    "$TREEMIX"  -i "$INPUT_FILE" -seed "$SEED" -m "$SPLIT" -k "$SNP_SIZE" -o "$OUTPUT_FILE/baseline_split"
    echo "Done."
}

# Baseline migration enabled treemix function
treemix_migration_enabled () {
    local INPUT_FILE=$1
    local OUTPUT_FILE=$2

    if [ ! -d "$OUTPUT_FILE" ]; then 
        echo "Creating output directory."
        mkdir -p $OUTPUT_FILE
    else
        echo "Directory already exists."
    fi
    
    echo "Running treemix.."
    "$TREEMIX" -i "$INPUT_FILE" -seed "$SEED" -m "$MIGRATION_ENABLED" -k "$SNP_SIZE" -o "$OUTPUT_FILE/baseline_migration"
    echo "Done"
}

time_tracker () {

}

START_TIME=$(date +%s)

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo "Elapsed time: ${ELAPSED} seconds."

# Experiment 1 - Baseline Dataset
# ------------------------------------------------------------
# This script gives treemix results for both baseline condition and migration enabled (-m 10).
# 
# Steps:
# 1. In the baseline treemix model there are two sub-experiments
#   a) Split only : -i <input file> -seed 1 -m 0 -k 1000 -root San -o <output stem> 
#   b) Migration enabled: -i <input_file> -seed 1 -m 10 -k 1000 -root San -o <output stem> 
# 2. The input file for each of these cases are the deafult plink parameters to treemix file.

test_1() {
    # Input and output files
    local INPUT_FILE=$1
    local OUTPUT_FILE=$2

    # Baseline - Split
    treemix_baseline "$INPUT_FILE" "$OUTPUT_FILE"
    # Baseline - Migration Enabled
    treemix_migration_enabled "$INPUT_FILE" "$OUTPUT_FILE"
       
}

# Experiment 2 - Treemix Parameters
# -------------------------------------------------------------
# This script is used to check for different treemix parameters like SNP size and migrations numbers
# 
# Steps:
# 1) The 

test_2aa() {
    # Input and output files
    local INPUT_FILE=$1
    local OUTPUT_FILE=$2

    # Define the SNP sizes
    k=("200" "500" "1000" "1500" "2000" "10000")

    for snp in "${k[@]}"; do
        treemix -i "$INPUT_FILE" -seed "$SEED" -m "$SPLIT" -k "$snp" -o "$OUTPUT_FILE" &
    done    

    wait # Wait for all the background jobs to finish
}

test_2ab() {
    # Input and output files
    local INPUT_FILE=$1
    local OUTPUT_FILE=$2

    # Define the SNP sizes
    k=("200" "500" "1000" "1500" "2000" "10000")

    for snp in "${k[@]}"; do
        treemix -i "$INPUT_FILE" -seed "$SEED" -m "$MIGRATION_ENABLED" -k "$snp" -o "${OUTPUT_FILE}_k${snp}" &
    done    
    
    wait # Wait for all the background jobs to finish
}


test_2b() {
    #Input and output files
    local INPUT_FILE=$1
    local OUTPUT_FILE=$2

    # Migration enaled changes
    for m in $(seq 1 15); do
        treemix -i "$INPUT_FILE" -seed "$SEED" -m "$m" -k "$SNP_SIZE" -o "${OUPUT_FILE}_m${m}" &
    done

    wait # Wait for all the background jobs to finish
}

# All other experiments it is the same thing
test_all() {
    local INPUT_FILE=$1
    local OUTPUT_FILE=$2

    # Run treemix on the baseline parameters
    treemix_baseline $INPUT_FILE $OUPUT_FILE &
    # Run treemix on the migration enabled parameters
    treemix_migration_enabled $INPUT_FILE $OUTPUT_FILE

    wait # Wait for the all the jobs to finish
}

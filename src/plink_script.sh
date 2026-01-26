#!/bin/bash

# ==========================
# PLINK Batch Processing Script
# Author: Marlene Ganz & Chandrashekar CR
# Date: 26/01/26
# Description: This script runs different PLINK tests in a modular way.
# Usage: 
# - Run a specific test:   ./plink_tests.sh test_2
# - Run all tests:         ./plink_tests.sh all
# - Interactive mode:      ./plink_tests.sh
# ==========================

# ==== CONFIGURATION ====
# Get the directory of this script and the project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PLINK="$PROJECT_ROOT/bin/plink/plink" # Path to executable
PLINK2TREEMIX="$PROJECT_ROOT/src/treemix_tests/plink2treemix.py" # Convert plink to treemix format
POPMANIPULATION="$PROJECT_ROOT/src/treemix_tests/population_manipulation.py"
POP_MAPPING="$PROJECT_ROOT/raw_data/region_mapping.json" # Map the continents to the population group
RAW_DATA="$PROJECT_ROOT/raw_data/Harvard_HGDP-CEPH/all_snp" # Basis-PLINK-Dataset
RESULTS_DIR="$PROJECT_ROOT/experiments" # Result folder
POP_LIST="$PROJECT_ROOT/raw_data/2306_poplist.tsv" # Population List

# ==== GLOBAL FUNCTIONS ====

convert_plink_to_treemix() {
  # This function processes genetic data from PLINK and converts it into a format compatible with TreeMix.
  # Usage:
  #   convert_plink_to_treemix <PREFIX> <OUT_DIR>
  # Arguments:
  #   PREFIX  - The base name of the input PLINK files (without file extensions).
  #   OUT_DIR - The directory where the final compressed TreeMix file will be stored.

    PREFIX=$1
    OUT_DIR=$2
    CURR_POP_LIST=$3

    echo "Convert PLINK Output to TreeMix Format..."

    # 1. Runs PLINK to calculate allele frequencies and missing data statistics within populations.
    $PLINK --bfile "$PREFIX" --freq --missing --within "$CURR_POP_LIST" --out "$PREFIX"

    # 2. Converts the PLINK output to TreeMix format using a Python script.
    python3 "$PLINK2TREEMIX" "${PREFIX}.frq.strat" "${PREFIX}_treemix"

    # 3. Compresses the resulting TreeMix file.
    gzip "${PREFIX}_treemix"
    # 4. Compresses all the other PLINK output files for saving space
    gzip "${PREFIX}".*

    echo "Process finished and saved in $OUT_DIR"
}

# ==== LOCAL FUNCTIONS ====
# Creates a results directory
mkdir -p "$RESULTS_DIR"

# Experiment 1 - Baseline Dataset
# ---------------------------------------------------
# This script performs standard quality control (QC) on the genetic dataset.
# Only default PLINK filters are applied (--geno 0.1 & --maf 0.01).
#
# Steps:
# 1. Apply default PLINK processing to generate a clean dataset.
# 2. Retain all variants and individuals without additional filtering criteria.
# 3. Convert the processed dataset to TreeMix format.

test_1() {

    echo "===== Running Standard Quality Control ===== "
    # Creates results directory
    OUT_DIR="$RESULTS_DIR/baseline/plink_results"
    mkdir -p "$OUT_DIR"
    PREFIX="$OUT_DIR/baseline"

    $PLINK --bfile "$RAW_DATA" --geno --maf --make-bed --out "$PREFIX"

    convert_plink_to_treemix "$PREFIX" "$OUT_DIR" "$POP_LIST"
}

# Experiment 2 -Treemix Parameters
# The experiment 2 is all about the parameters of treemix and can be found on the treemix_script.sh

# Experiment 3 - PLINK Parameters
# Experiment 3a: Genotype Missingness
# ---------------------------------------------------
# This script generates three datasets with different genotype missingness thresholds.
#
# Steps:
# 1. Loop through three predefined missingness thresholds (--geno values).
# 2. Apply PLINK filtering to exclude SNPs exceeding each missingness threshold.
# 3. Generate a new PLINK dataset for each threshold.
# 4. Convert the filtered datasets to TreeMix format.

test_3a() { 
    # Creates results directory
    echo "===== Running Experiment 3a: Genotype Missingness ===== "

    # Creates results directory
    OUT_DIR="$RESULTS_DIR/experiment_3a/plink_results"
    mkdir -p "$OUT_DIR"

    # Define missingness thresholds to test
    GENO_THRESHOLDS=("0.05" "0.01" "0.00")

    for GENO in "${GENO_THRESHOLDS[@]}"; do
        (
          PREFIX="$OUT_DIR/2_geno_missing_${GENO//./}"  # Removes the dot for cleaner filenames

          echo "Running PLINK filtering with genotype missingness threshold: $GENO"
          "$PLINK" --bfile "$RAW_DATA" --geno "$GENO" --maf --make-bed --out "$PREFIX"

          convert_plink_to_treemix "$PREFIX" "$OUT_DIR" "$POP_LIST"
        ) &
    done

    wait # Wait for all the background processes to finish
    echo "Process finished and saved in $OUT_DIR"
}

# Experiment 3b: Minor Allele Frequency (MAF)
# ---------------------------------------------------
# This script filters the dataset to retain only genetic variants with a minor allele
# frequency (MAF) of at least 0.05.
#
# Steps:
# 1. Apply PLINK filters to exclude variants with a MAF below 0.05 and those with
#    more than 10% missing data (--geno 0.1).
# 2. Generate a new PLINK dataset.
# 3. Convert the filtered dataset to TreeMix format.


test_3b() {
    # Creates results directory
    echo "===== Running Experiment 3b: Minor Allele Frequency ===== "
    OUT_DIR="$RESULTS_DIR/experiment_3b/plink_results"
    mkdir -p "$OUT_DIR"
    PREFIX="$OUT_DIR/3_minor_allele_freq_005"

    $PLINK --bfile "$RAW_DATA" --geno --maf 0.05 --make-bed --out "$PREFIX"

    convert_plink_to_treemix "$PREFIX" "$OUT_DIR" "$POP_LIST"

    echo "Experiment 3b completed. Results in: $OUT_DIR"
}


# Experiment 4: Addition of Archaic Hominin Genomes
# ---------------------------------------------------
# This script integrates two hominin individuals (Denisovan and Vindija Neanderthal)
# from the Affymetrix Human Origins dataset into the original dataset. Each hominin
# individual is added separately and set as the root and outgroup for the phylogenetic tree.
#
# Steps:
# 1. Process Denisovan and Vindija Neanderthal individuals separately.
# 2. Filter the dataset to retain only the selected hominin individuals along with
#    the original populations.
# 3. Apply standard genotype and allele frequency filters.
# 4. Convert the resulting dataset to TreeMix format.

test_4() {

    # Creates results directory
    echo "===== Running Experiment 4: Addition of Archaic Hominin Genomes ===== "
    OUT_DIR="$RESULTS_DIR/experiment_4/plink_results"
    mkdir -p "$OUT_DIR"

    # Function to process a hominin population (Denisovan or Vindija)
    process_hominin() {
        local POP_NAME=$1      # "Deni" or "Vindija"
        local PREFIX="$OUT_DIR/4_added_${POP_NAME}"

        echo "Processing $POP_NAME individuals..."

        python3 "$POPMANIPULATION" new_outgroup "$POP_LIST" "$POP_NAME" "$OUT_DIR"

        local CUR_POP_LIST="${OUT_DIR}/added_${POP_NAME}.tsv"

        echo "Filtering dataset for $POP_NAME individuals..."
        $PLINK --bfile "$RAW_DATA" --keep "$CUR_POP_LIST"  --geno --maf --make-bed --out "$PREFIX"

        convert_plink_to_treemix "$PREFIX" "$OUT_DIR" "$CUR_POP_LIST"

        echo "$POP_NAME processing completed successfully! Results stored in: $OUT_DIR"
    }

    # Run for both Denisovans and Vindija
    process_hominin "Deni" &
    process_hominin "Vindija" &
    process_hominin "Both" &

    wait # Wait for all the processes to finish that are still running
    echo "Experiment 4 completed. Results in: $OUT_DIR"
}


# Experiment 5: Unbalanced or Small Samples
# Experiment 5a: Uneven Sampling
# ---------------------------------------------------
# This script reduces the sample size of a subset of populations, introducing an uneven
# sample distribution in the dataset.
#
# Steps:
# 1. Loop through a set of predefined sample sizes (given in MAX_PER_POP).
# 2. Generate a population list that reduces the number of individuals in the given POPULATIONS
#    using the $POPMANIPULATION Python script.
# 3. Create a filtered PLINK dataset that retains only the selected individuals.
# 4. Convert the new dataset to TreeMix format.
# 5. Repeat the process for each sample size in the list.

test_5a() {
    echo "===== Running Experiment 5a: Uneven Sampling ===== "
    OUT_DIR="$RESULTS_DIR/experiment_5a/plink_results"
    mkdir -p "$OUT_DIR"

    # Define percentages for removal
    MAX_PER_POP=(3 5)

    # Loop through each percentage
    for MAX in "${MAX_PER_POP[@]}"; do
        (
        echo "Dropping $MAX of populations..."
        CUR_POP_LIST="${OUT_DIR}/reduced_${MAX}.tsv"

        # Set population list depending on MAX
        if [[ "$MAX" -eq 3 ]]; then
            POPULATIONS="Maya,Surui,Hazara,Makrani,Hezhen,Tu,Balochi,Kalash,Naxi,Basque,Russian,Bedouin,Mozabite,Papuan,BantuKenya,BantuSouthAfrica"
            #POPULATIONS="Mongola,NorthernHan,Japanese,Mozabite,Russian,BergamoItalian,Tuscan,Pima,Colombian,Mandenka,BantuKenya,BantuSouthAfrica"
        elif [[ "$MAX" -eq 5 ]]; then
            POPULATIONS="Maya,Surui,Hazara,Makrani,Hezhen,Tu,Balochi,Kalash,Naxi,Basque,Russian,Bedouin,Mozabite,Papuan,BantuKenya,BantuSouthAfrica"
            #POPULATIONS="Basque,Biaka,Druze,French,Han,BergamoItalian,Japanese,Mandenka,Maya,Bougainville,Mongola,Mozabite,Palestinian,Pima,Russian,Sardinian,Sindhi,Burusho"
        else
            echo "No population list defined for MAX=$MAX"
            exit 1
        fi

        # Generate the list of populations to remove
        python3 "$POPMANIPULATION" reduce_population_counts "$POP_LIST" "$CUR_POP_LIST" "$POPULATIONS" "$MAX"

        # Define prefix based on percentage
        PREFIX_OUT="${OUT_DIR}/5a_filtered_${MAX}"

        # Remove the selected populations and generate new PLINK files
        $PLINK --bfile "$RAW_DATA" --keep "$CUR_POP_LIST" --maf --geno --make-bed --out "$PREFIX_OUT"

        # Convert to TreeMix format
        convert_plink_to_treemix "$PREFIX_OUT" "$OUT_DIR" "$CUR_POP_LIST"
        ) &
    done

    wait # Wait for all background processes to finish 
    echo "Experiment 5a completed. Results in: $OUT_DIR"
}


# Experiment 5: Unbalanced or Small Samples
# Experiment 5b: Even Sampling
# ---------------------------------------------------
# This script reduces the sample size of all populations to the same predefined number defined in $SAMPLESIZES.
#
# Steps:
# 1. Loop through a set of predefined sample sizes (given in SAMPLESIZES).
# 2. Generate a population list that reduces all populations to the same number of individuals
#    using the $POPMANIPULATION Python script.
# 3. Create a filtered PLINK dataset that retains only the selected individuals.
# 4. Convert the new dataset to TreeMix format.
# 5. Repeat the process for each sample size in the list.
#
test_5b() {
    echo "===== Running Experiment 5b: Even Sampling ===== "
    OUT_DIR="$RESULTS_DIR/experiment_5b/plink_results"
    mkdir -p "$OUT_DIR"

    # Define different sample sizes to test
    SAMPLESIZES=(3 4 5 6)

    for SAMPLESIZE in "${SAMPLESIZES[@]}";do
        (
        # Naming
        CURR_POP_LIST="${OUT_DIR}/even_${SAMPLESIZE}ind.tsv"
        RANDOMSTATE=$((45 + SAMPLESIZE))
        PREFIX="$OUT_DIR/7_${SAMPLESIZE}_individuals_even"

        echo "Processing test case: $SAMPLESIZE individuals"

        # Create new pop_list with reduced sample sizes
        python3 "$POPMANIPULATION" generate_pop_lists "$POP_LIST" "$SAMPLESIZE" "$OUT_DIR" --num-populations all --random-state $RANDOMSTATE

        # Filter dataset for selected individuals
        echo "Filtering dataset: Keeping manipulated populations with $SAMPLESIZE..."
        $PLINK --bfile "$RAW_DATA" --keep "$CURR_POP_LIST" --geno --maf --make-bed --out "$PREFIX"

        convert_plink_to_treemix "$PREFIX" "$OUT_DIR" "$CURR_POP_LIST"
        ) &

    done
    
    wait # Wait for all the processes to finish running in the background
    echo "Experiment 5b completed. Results in: $OUT_DIR"
}

# Experiment 6: Population Removal
# Experiment 6a: Unifrom Population Removal 
# ---------------------------------------------------
# This script loops through a list of predefined percentages and removes that proportion of populations from the dataset.
# The removal is performed relatively evenly to maintain the overall population distribution across continents.
#
# Steps:
# 1. Generate a list of populations to be removed (X% of the total, based on the PERCENTAGE value)
#    using the $POPMANIPULATION Python script.
# 2. Remove the selected populations and generate a new PLINK dataset with the remaining individuals.
# 3. Convert the updated dataset to TreeMix format for further analysis.
# 4. Repeat the process for each percentage in the list.

test_6a() {
    echo "===== Running Experiment 6a: Drop specific populations  ===== "
    OUT_DIR="$RESULTS_DIR/experiment_6a/plink_results"
    mkdir -p "$OUT_DIR"

    # Drop 14 and 20 populations respectively
    NUM_POPS=(14 20)

    # Loop through each percentage
    for NUM in "${NUM_POPS[@]}"; do
        (
        PREFIX="$OUT_DIR/4_drop_pops_${NUM}"
        CUR_POP_LIST="${OUT_DIR}/remove_pops_${NUM}.tsv"

        # Set population list depending on MAX
        if [[ "$NUM" -eq 14 ]]; then
              POPULATIONS=("Biaka" "Mbuti" "Mandenka" "Druze" "Sardinian" "Basque" "Orcadian" "Tuscan" "Makrani" "Balochi" "Burusho" "Karitiana" "Surui" "Pima")
        elif [[ "$NUM" -eq 20 ]]; then
              POPULATIONS=("Biaka" "Mbuti" "Mandenka" "Druze" "Sardinian" "Basque" "Orcadian" "Tuscan" "Makrani" "Balochi" "Burusho" "Karitiana" "Surui" "Pima" "Adygei" "Kalash" "Pathan" "Sindhi" "Maya" "Papuan")
        else
              echo "No population list defined for MAX=$MAX"
              exit 1
        fi

        python3 "$POPMANIPULATION" drop_specific_populations "$POP_LIST" "$CUR_POP_LIST" "${POPULATIONS[@]}"

        $PLINK --bfile "$RAW_DATA" --remove "$CUR_POP_LIST" --geno --maf --make-bed --out "$PREFIX"

        echo "Dataset $PREFIX created."

        convert_plink_to_treemix "$PREFIX" "$OUT_DIR" "$POP_LIST"
        ) &
    done
    wait # Wait for all the process to finish in th background
    echo "Experiment 6a completed. Results in: $OUT_DIR"
}


# Experiment 6: Population removal
# Experiment 6b: Whole Continent Removal
# ---------------------------------------------------
# This script systematically removes populations from specific continents.
#
# Steps:
# 1. Loop through a predefined list of continents.
# 2. For each continent, generate a removal list using the $POPMANIPULATION script.
# 3. Apply PLINK filtering to exclude individuals from the selected continent.
# 4. Convert the modified dataset to TreeMix format.
# 5. Repeat the process for all listed continents.
#
test_6b() {
    echo "===== Running Experiment 6b: Remove continental populations ===== "
    OUT_DIR="$RESULTS_DIR/experiment_6b/plink_results"
    mkdir -p "$OUT_DIR"

    # List of continents to remove
    continents=("Europe" "North Africa" "Middle East" "Asia" "America" "Oceania")
    # Loop through each continent
    for continent in "${continents[@]}"; do
        (
        echo "Processing dataset without $continent..."
        safe_continent=$(echo "$continent" | tr ' ' '_')

        # Define input and output filenames
        remove_file="${OUT_DIR}/remove_${safe_continent}.tsv"
        PREFIX="$OUT_DIR/6b_dataset_no_${safe_continent}"

        python3 "$POPMANIPULATION" drop_continents "$POP_LIST" "$continent" "$POP_MAPPING" "$OUT_DIR"

        # Run PLINK command
        $PLINK --bfile "$RAW_DATA" --remove "$remove_file" --geno --maf --make-bed --out "$PREFIX"

        echo "Dataset $PREFIX created."

        convert_plink_to_treemix "$PREFIX" "$OUT_DIR" "$POP_LIST"
        ) &

    done
    wait # Wait for all background processes to finish
    echo "All datasets processed. Results in: $OUT_DIR"
}

# Experiment 7: Addition and Removal of Admixed Population
# Experiment 7a: Removal of historically admixed population
# ---------------------------------------------------
# This script removes selected historically admixed populations from the dataset.
#
# Steps:
# 1. Define a list of historically admixed populations to remove.
# 2. Use the $POPMANIPULATION script to generate a removal list.
# 3. Apply PLINK filtering to exclude individuals from the specified populations.
# 4. Convert the modified dataset to TreeMix format.
#

test_7a() {
    echo "===== Running Experiment 7a: Drop specific historical admixed populations ===== "
    OUT_DIR="$RESULTS_DIR/experiment_7a/plink_results"
    mkdir -p "$OUT_DIR"
    PREFIX="$OUT_DIR/7a_drop_admixed_pops"
    CURR_POP_LIST="${OUT_DIR}/remove_admixture_pops.tsv"

    admixed_pops=("Colombian" "Druze" "Karitiana" "Surui" "Balochi" "Brahui" "Burusho" "Hazara" "Kalash" "Makrani" "Pathan")

    python3 "$POPMANIPULATION" drop_specific_populations "$POP_LIST" "$CURR_POP_LIST" "${admixed_pops[@]}"

    $PLINK --bfile "$RAW_DATA" --remove "$CURR_POP_LIST" --geno --maf --make-bed --out "$PREFIX"

    echo "Dataset $PREFIX created."

    convert_plink_to_treemix "$PREFIX" "$OUT_DIR" "$POP_LIST"

    echo "Experiment 7a completed. Results in: $OUT_DIR"
}

# Experiment 7: Addition and Removal of Admixed Population
# Experiment 7ba: Addition of Aritifical Individuals with 2 source hybrids
# ---------------------------------------------------
# This script creates artificial hybrid populations by combining two populations.
# The populations that are combined are written in scripts/population_manipulation.py:write_json_structures.
# Steps:
# 1. Prepare population .tsv lists and the .json file
# 2. Create one big PED with all hybrids
# 3. Convert all hybrids to binary
# 4. Merge all hybrids with full dataset
# 5. Run TreeMix input converter
#

test_7ba() {
    echo "===== Running Experiment 7ba: Artificial hybrid populations with two-mixtures ===== "
    OUT_DIR="$RESULTS_DIR/experiment_7ba/plink_results"
    mkdir -p "$OUT_DIR"

    HYBRID_DIR="$OUT_DIR/hybrids"
    LIST_DIR="$OUT_DIR/hybrid_lists"

    FINAL_HYBRID_PED="$HYBRID_DIR/all_hybrids.ped"
    FINAL_HYBRID_MAP="$HYBRID_DIR/all_hybrids.map"
    NUM_HYBRID_POPS=2

    mkdir -p "$HYBRID_DIR" "$LIST_DIR"

    # Step 1: Prepare population .tsv lists and the .json file
    python3 "$POPMANIPULATION" write_json_structures "$OUT_DIR" "$NUM_HYBRID_POPS"
    STRUCTURE_JSON="${OUT_DIR}/${NUM_HYBRID_POPS}_structure.tsv"

    python3 "$POPMANIPULATION" prepare_groupwise_hybrid_lists "$POP_LIST" "$STRUCTURE_JSON" "$LIST_DIR"

    # Step 2: Create one big PED with all hybrids
    true > "$FINAL_HYBRID_PED"  # Empty file

    MAP_COPIED=0
    # Create baseline dataset 
    $PLINK --bfile "$RAW_DATA" --geno --maf --make-bed --out "$OUT_DIR/all"

    for tsv in "$LIST_DIR"/*.tsv; do
        BASENAME=$(basename "$tsv" .tsv)
        # Skip the population list file
        if [[ "$BASENAME" == "population_list_with_hybrids" ]]; then
            continue
        fi
        echo "Processing hybrid group: $BASENAME"

        # Extract relevant individuals and recode 

        $PLINK --bfile "$OUT_DIR/all" --keep "$tsv" --make-bed --out "$HYBRID_DIR/$BASENAME"
        $PLINK --bfile "$HYBRID_DIR/$BASENAME" --recode --out "$HYBRID_DIR/$BASENAME"

        # Run hybrid creation (produces $HYBRID_DIR/$BASENAME.ped)
        python3 "$POPMANIPULATION" create_snpsplit_hybrids \
           "$HYBRID_DIR/$BASENAME.ped" \
           "$BASENAME" \
           "$(echo "$BASENAME" | tr '-' ' ')" \
           "$HYBRID_DIR"

        # Append created hybrid .ped to final hybrid file
        cat "$HYBRID_DIR/$BASENAME.ped" >> "$FINAL_HYBRID_PED"

        # Copy map file once
        if [[ $MAP_COPIED -eq 0 ]]; then
            cp "$HYBRID_DIR/$BASENAME.map" "$FINAL_HYBRID_MAP"
            MAP_COPIED=1
        fi
    done

    ### Step 3: Convert all hybrids to binary
    $PLINK --file "$HYBRID_DIR/all_hybrids" --make-bed --out "$HYBRID_DIR/all_hybrids"
    #
    ## Step 4: Merge all hybrids with full dataset #somethimes --geno --maf
    $PLINK --bfile "$OUT_DIR/all" --bmerge "$HYBRID_DIR/all_hybrids" --make-bed --out "$OUT_DIR/7ba_artificial_2_merged_all"

    ### Step 5: Run TreeMix input converter
    convert_plink_to_treemix "$OUT_DIR/7ba_artificial_2_merged_all" "$OUT_DIR" "$LIST_DIR/population_list_with_hybrids.tsv"


    echo "Experiment 7ba completed. Results in: $OUT_DIR"
}

# Experiment 7: Addition and Removal of Admixed Population
# Experiment 7bb: Addition of Aritifical Individuals with 5 source hybrids
# ---------------------------------------------------
# This script creates artificial hybrid populations by combining five populations.
# The populations that are combined are written in scripts/population_manipulation.py:write_json_structures.
# Steps:
# 1. Prepare population .tsv lists and the .json file
# 2. Create one big PED with all hybrids
# 3. Convert all hybrids to binary
# 4. Merge all hybrids with full dataset
# 5. Run TreeMix input converter


test_7bb() {
    echo "===== Running Experiment 7bb: Artificial hybrid populations with five-mixtures ===== "
    OUT_DIR="$RESULTS_DIR/experiment_7bb/plink_results"
    mkdir -p "$OUT_DIR"

    HYBRID_DIR="$OUT_DIR/hybrids"
    LIST_DIR="$OUT_DIR/hybrid_lists"

    FINAL_HYBRID_PED="$HYBRID_DIR/all_hybrids.ped"
    FINAL_HYBRID_MAP="$HYBRID_DIR/all_hybrids.map"
    NUM_HYBRID_POPS=5

    mkdir -p "$HYBRID_DIR" "$LIST_DIR"

    # Step 1: Prepare population .tsv lists and the .json file
    python3 "$POPMANIPULATION" write_json_structures "$OUT_DIR" "$NUM_HYBRID_POPS"
    STRUCTURE_JSON="${OUT_DIR}/${NUM_HYBRID_POPS}_structure.tsv"

    python3 "$POPMANIPULATION" prepare_groupwise_hybrid_lists "$POP_LIST" "$STRUCTURE_JSON" "$LIST_DIR"

    # Create baseline dataset 
    $PLINK --bfile "$RAW_DATA" --geno --maf --make-bed --out "$OUT_DIR/all"

    # Step 2: Create one big PED with all hybrids
    true > "$FINAL_HYBRID_PED"  # Empty file

    MAP_COPIED=0

    for tsv in "$LIST_DIR"/*.tsv; do
        BASENAME=$(basename "$tsv" .tsv)
        # Skip the population list file
        if [[ "$BASENAME" == "population_list_with_hybrids" ]]; then
            continue
        fi
        echo "Processing hybrid group: $BASENAME"

        # Extract relevant individuals and recode
        $PLINK --bfile "$OUT_DIR/all" --keep "$tsv" --make-bed --out "$HYBRID_DIR/$BASENAME"
        $PLINK --bfile "$HYBRID_DIR/$BASENAME" --recode --out "$HYBRID_DIR/$BASENAME"

        # Run hybrid creation (produces $HYBRID_DIR/$BASENAME.ped)
        python3 "$POPMANIPULATION" create_snpsplit_hybrids \
           "$HYBRID_DIR/$BASENAME.ped" \
           "$BASENAME" \
           "$(echo "$BASENAME" | tr '-' ' ')" \
           "$HYBRID_DIR"

        # Append created hybrid .ped to final hybrid file
        cat "$HYBRID_DIR/$BASENAME.ped" >> "$FINAL_HYBRID_PED"

        # Copy map file once
        if [[ $MAP_COPIED -eq 0 ]]; then
            cp "$HYBRID_DIR/$BASENAME.map" "$FINAL_HYBRID_MAP"
            MAP_COPIED=1
        fi
    done

    ### Step 3: Convert all hybrids to binary
    $PLINK --file "$HYBRID_DIR/all_hybrids" --make-bed --out "$HYBRID_DIR/all_hybrids"
    #
    ## Step 4: Merge all hybrids with full dataset
    $PLINK --bfile "$OUT_DIR/all" --bmerge "$HYBRID_DIR/all_hybrids" --make-bed --out "$OUT_DIR/7bb_artificial_5_merged_all"

    ### Step 5 (optional): Run TreeMix input converter
    convert_plink_to_treemix "$OUT_DIR/7bb_artificial_5_merged_all" "$OUT_DIR" "$LIST_DIR/population_list_with_hybrids.tsv"


    echo "Experiment 7bb completed. Results in: $OUT_DIR"
}

# Experiment 12: Artificial hybrid populations with fifty-mixtures-shuffled:
# ---------------------------------------------------
# This script creates artificial hybrid populations by combining five populations the same population but shuffled.
# Example:
# Pop1, Pop2, Pop3, Pop4, Pop5
# Pop2, Pop1, Pop3, Pop4, Pop5
# Pop1, Pop3, Pop2, Pop4, Pop5
# Pop1, Pop2, Pop4, Pop3, Pop5
# Pop1, Pop2, Pop3, Pop5, Pop4
# Pop1, Pop2, Pop5, Pop3, Pop4
# The populations that are combined are written in scripts/population_manipulation.py:write_json_structures.
# Steps:
# 1. Prepare population .tsv lists and the .json file
# 2. Create one big PED with all hybrids
# 3. Convert all hybrids to binary
# 4. Merge all hybrids with full dataset
# 5. Run TreeMix input converter


test_8() {
    echo "===== Running Experiment 8: Artificial hybrid populations with five-mixtures same shuffled ===== "
    OUT_DIR="$RESULTS_DIR/experiment_8/plink_results"
    mkdir -p "$OUT_DIR"


    PYTHON_SCRIPT="../scripts/artificial.py"
    HYBRID_DIR="$OUT_DIR/hybrids"
    LIST_DIR="$OUT_DIR/hybrid_lists"
    FINAL_HYBRID_PED="$HYBRID_DIR/all_hybrids.ped"
    FINAL_HYBRID_MAP="$HYBRID_DIR/all_hybrids.map"

    NUM_POPS_HYBRID=51

    mkdir -p "$HYBRID_DIR" "$LIST_DIR"

    # Step 1: Prepare population .tsv lists and the .json file
    python3 "$POPMANIPULATION" write_json_structures "$OUT_DIR" "$NUM_POPS_HYBRID"
    STRUCTURE_JSON="${OUT_DIR}/${NUM_POPS_HYBRID}_structure.tsv"
    python3 "$PYTHON_SCRIPT" prepare --poplist "$POP_LIST" --structure "$STRUCTURE_JSON" --outdir "$LIST_DIR"

    # Create baseline dataset 
    $PLINK --bfile "$RAW_DATA" --geno --maf --make-bed --out "$OUT_DIR/all"
    
    # Step 2: Create one big PED with all hybrids
    true > "$FINAL_HYBRID_PED"  # Empty file

    MAP_COPIED=0

    for tsv in "$LIST_DIR"/*.tsv; do
        BASENAME=$(basename "$tsv" .tsv)
        # Skip the population list file
        if [[ "$BASENAME" == "population_list_with_hybrids" ]]; then
            continue
        fi
        echo "Processing hybrid group: $BASENAME"

        # Extract relevant individuals and recode
        $PLINK --bfile "$OUT_DIR/all" --keep "$tsv" --geno --maf --make-bed --out "$HYBRID_DIR/$BASENAME"
        $PLINK --bfile "$HYBRID_DIR/$BASENAME" --recode --out "$HYBRID_DIR/$BASENAME"

        # Run hybrid creation (produces $HYBRID_DIR/$BASENAME.ped)
        python3 "$PYTHON_SCRIPT" create \
          --ped "$HYBRID_DIR/$BASENAME.ped" \
          --hybrid_label "$BASENAME" \
          --pops "$(echo "$BASENAME" | tr '-' ' ')" \
          --outdir "$HYBRID_DIR"

        # Append created hybrid .ped to final hybrid file
        cat "$HYBRID_DIR/$BASENAME.ped" >> "$FINAL_HYBRID_PED"

        # Copy map file once
        if [[ $MAP_COPIED -eq 0 ]]; then
            cp "$HYBRID_DIR/$BASENAME.map" "$FINAL_HYBRID_MAP"
            MAP_COPIED=1
        fi
    done

    ### Step 3: Convert all hybrids to binary
    $PLINK --file "$HYBRID_DIR/all_hybrids" --make-bed --out "$HYBRID_DIR/all_hybrids"
    ##
    ### Step 4: Merge all hybrids with full dataset
    $PLINK --bfile "$OUT_DIR/all" --bmerge "$HYBRID_DIR/all_hybrids" --make-bed --out "$OUT_DIR/8_artificial_5_merged_all"
    ##
    ### Step 5 (optional): Run TreeMix input converter
    convert_plink_to_treemix "$OUT_DIR/8_artificial_5_merged_all" "$OUT_DIR" "$LIST_DIR/population_list_with_hybrids.tsv"


    echo "Experiment 8 completed. Results in: $OUT_DIR"
}


# ==== TEST SELECTION ====

# Run all tests
run_all() {
    test_1
    test_3a
    test_3b
    test_4
    test_5a
    test_5b
    test_6a
    test_6b
    test_7a
    test_7ba
    test_7bb
    test_8
}

# Run interactive mode
interactive_mode() {
    echo "Select a test to run:"
    echo ""
    echo "1)  Baseline"
    echo "3a) Genotype Missingness"
    echo "3b) Minor Allele Frequency"
    echo "4)  Hominins Outgroup"
    echo "5a) Uneven sample number"
    echo "5b) Even sample number"
    echo "6a) Drop specific populations"
    echo "6b) Remove continental populations"
    echo "7a) Drop specific historical admixed populations"
    echo "7ba) Artificial hybrid populations - two"
    echo "7bb) Artificial hybrid populations - five"
    echo "8) Artificial hybrid populations - five shuffled"
    echo "9) Run all tests"
    echo "10) Exit"

    read -r -p "Enter your choice: " choice
    case $choice in
        1) test_1 ;;
        2) test_3a ;;
        3) test_3b ;;
        4) test_4 ;;
        5) test_5a ;;
        6) test_5b ;;
        7) test_6a ;;
        8) test_6b ;;
        9) test_7a ;;
        10) test_7ba ;;
        11) test_7bb ;;
        12) test_8 ;;
        13) run_all ;;
        14) exit 0 ;;
        *) echo "Invalid choice!" ;;
    esac
}

# ==== SCRIPT EXECUTION ====
# If argument falls in the test case name
if [[ "$1" == "all" ]]; then
    run_all
elif [[ "$1" == "test_1" ]]; then
    test_1
elif [[ "$1" == "test_3a" ]]; then
    test_3a
elif [[ "$1" == "test_3b" ]]; then
    test_3b
elif [[ "$1" == "test_4" ]]; then
    test_4
elif [[ "$1" == "test_5a" ]]; then
    test_5a
elif [[ "$1" == "test_5b" ]]; then
    test_5b
elif [[ "$1" == "test_6a" ]]; then
    test_6a
elif [[ "$1" == "test_6b" ]]; then
    test_6b
elif [[ "$1" == "test_7a" ]]; then
    test_7a
elif [[ "$1" == "test_7ba" ]]; then
    test_7ba
elif [[ "$1" == "test_7bb" ]]; then
    test_7bb
elif [[ "$1" == "test_8" ]]; then
    test_8
elif [[ -z "$1" ]]; then
    interactive_mode
else
    echo "Invalid argument. Use 'all', a specific test name (e.g., 'test_1', 'test_3a'), or no argument for interactive mode."
fi

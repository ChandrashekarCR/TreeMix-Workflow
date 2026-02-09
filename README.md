# TreeMix Workflow: Systematic Population Genetics Analysis Pipeline

A reproducible Snakemake workflow for comprehensive population genetics analysis using TreeMix phylogenetic reconstruction. This pipeline automates data preprocessing with PLINK, systematic TreeMix analysis across multiple experimental configurations, quantitative tree comparison, and publication-quality visualization to assess population splits. [Paper reference]

## Abstract

This workflow implements a systematic approach to population phylogenetic analysis using TreeMix, evaluating the phylogenetic reconstructions across different experimental scenarios. The pipeline processes genetic data from the Human Genome Diversity Project (HGDP), applies various filtering strategies, constructs phylogenetic trees under different parameterizations, and quantifies differences in tree topology and branch lengths. Each experiment is designed to assess specific aspects of TreeMix sensitivity: data quality parameters (genotype missingness, minor allele frequency), population sampling strategies (even vs. uneven sampling, population exclusion), inclusion of archaic genomes (Denisovan, Neanderthal), and artificial population creation (2-way and 5-way admixed populations).

## Methodology

### System Requirements

**Hardware Requirements:**
- Minimum: 16 GB RAM, 100 GB free disk space
- Recommended: 64 GB RAM, 500 GB free disk space, 32+ CPU cores
- Operating System: Linux (tested on CentOS 7/8, Ubuntu 18.04+)

**Software Dependencies:**
- Conda/Miniconda (version 4.8+)
- Git (version 2.0+)
- Make (for automated setup)

### 1. Initial Environment Setup

**1.1 Clone the Repository**
```bash
git clone <repository-url>
cd treemix_project
```

**1.2 Create Conda Environment**

The workflow requires a specific computational environment with TreeMix, R packages, and Python dependencies. All requirements are specified in the provided `environment.yml` file.

```bash
# Method 1: Using conda directly
conda env create -f environment.yml
conda activate treemix_env

# Method 2: Using provided Makefile (recommended)
make conda_env
source activate treemix_env
```

**Environment Contents:**
- TreeMix v1.13 (phylogenetic reconstruction)
- Python 3.12 with pandas, numpy, dendropy
- R 4.3+ with jsonlite, RColorBrewer packages
- PLINK (will be downloaded separately)
- Snakemake 7.0+ (workflow management)

**1.3 Verify Environment Installation**
```bash
# Check TreeMix installation
which treemix
treemix --help

# Check Python packages
python -c "import pandas, numpy, dendropy; print('Python packages OK')"

# Check R packages
Rscript -e "library(jsonlite); library(RColorBrewer); cat('R packages OK\\n')"

# Check Snakemake
snakemake --version
```

### 2. Software Installation and Data Preparation

**2.1 PLINK Installation**

PLINK v1.90 is required for genetic data preprocessing. The Makefile automates the download:

```bash
# Download and install PLINK
make plink

# Verify installation
./bin/plink/plink --help
```

This downloads the PLINK binary to `bin/plink/` and includes associated tools (prettify for format conversion).

**2.2 Raw Data Requirements**

The pipeline expects Human Genome Diversity Project (HGDP) genetic data in PLINK binary format:

**Required Files:**
```
raw_data/Harvard_HGDP-CEPH/
├── all_snp.bed        # Binary genotype file
├── all_snp.bim        # Variant information file
├── all_snp.fam        # Sample information file
└── annotation.txt     # Sample metadata
```

**Additional Required Files:**
```
raw_data/
├── 2306_poplist.tsv      # Population assignments (FID, IID, Population)
└── region_mapping.json   # Continental region mapping
```

**2.3 Population List Format**

The population list file (`2306_poplist.tsv`) must follow this format:
```
HGDP00001    HGDP00001    French
HGDP00002    HGDP00002    French
HGDP00003    HGDP00003    Basque
```
- Column 1: Family ID (FID)
- Column 2: Individual ID (IID)  
- Column 3: Population name
- Tab-separated, no header

**2.4 Regional Mapping Configuration**

The `region_mapping.json` file defines continental assignments:
```json
{
    "French": "Europe",
    "Basque": "Europe", 
    "Han": "East Asia",
    "Yoruba": "Sub-Saharan Africa",
    ...
}
```

### 3. Project Directory Structure and Organization

The workflow follows a standardized directory structure optimized for reproducibility. Each directory and file is mentioned in brief as to their functionality:

```
treemix_project/
├── workflow/
│   └── Snakefile              # Main workflow orchestration
├── src/                       # Source code and scripts
│   ├── plink_script.sh        # Modular PLINK preprocessing
│   └── treemix_tests/
│       ├── analysis/
│       │   ├── find_differences.py      # Tree comparison algorithms
│       ├── plot_scripts/
│       │   ├── plot_with_legend.R      # Main plotting interface
│       │   ├── plotting_funcs.R        # Core TreeMix plotting functions
│       ├── plink2treemix.py             # Format conversion utilities
│       ├── population_manipulation.py  # Population filtering tools
|
├── raw_data/                  # Input genetic data (PLINK format)
├── experiments/            # All experimental results (generated after running the pipeline)
├── bin/                      # External binaries (PLINK in instlled in this folder)
├── treemix/                  # TreeMix configuration files (Appendix section)
├── tests/                    # Unit tests for validation
├── environment.yml           # Conda environment specification
├── Makefile                 # Automated setup commands
└── README.md                # Documentation
```

**Important Notes:**
- `experiments/` directory contains all results but is excluded from version control due to large file sizes
- `raw_data` files are not included in the repository and must be obtained separately
- All intermediate and final results will be generated in `experiments/` during pipeline execution

### 4. Pipeline Execution Methods

**4.1 Complete Workflow Execution (Recommended)**

For full reproducible analysis, execute the entire Snakemake workflow:

```bash
# Full pipeline with maximum parallelization
snakemake --snakefile workflows/Snakefile --cores 64

# Medium-scale execution
snakemake --snakefile workflows/Snakefile --cores 16

# Test run (dry run to check workflow)
snakemake --snakefile workflows/Snakefile --cores 8 --dry-run
```

**Execution Monitoring:**
```bash
# Monitor progress
htop

ps aux | grep "treemix"
```

**4.2 Targeted Experiment Execution**

Execute specific experiments or components:

```bash
# Run only baseline analysis
snakemake --snakefile workflows/Snakefile \
    experiments/baseline/plots/ \
    --cores 8

# Run specific experiment (e.g., genotype missingness)
snakemake --snakefile workflows/Snakefile \
    experiments/experiment_3a/ \
    --cores 8

# Run comparison and plotting only (assuming TreeMix completed)
snakemake --snakefile workflows/Snakefile \
    --cores 8 \
    --until plot_tree
```

**4.3 Manual Component Execution**

For debugging or custom analysis, individual components can be executed:

```bash
# PLINK preprocessing only
bash src/plink_script.sh test_1              # Baseline dataset
bash src/plink_script.sh test_3a             # Genotype missingness
bash src/plink_script.sh test_6b             # Continental removal

# TreeMix execution (manual)
treemix -i experiments/baseline/plink_results/baseline_treemix.gz \
    -m 10 -k 1000 -seed 1 -root San \
    -o experiments/baseline/treemix_results/baseline_migration

# Plotting (manual)
Rscript src/treemix_tests/plot_scripts/plot_with_legend.R \
    experiments/baseline/treemix_results/baseline_split \
    --both --dpi 600 --output-dir experiments/baseline/plots/
```

### 5. Detailed Experimental Design and Methodology

#### 5.1 Baseline Analysis (Control Experiment)

**Purpose:** Establish reference phylogenetic trees for all subsequent comparisons.

**Methodology:**
1. **Data Quality Control:** Apply standard PLINK filters
   - Genotype missingness: 10% threshold (`--geno 0.1`)
   - Minor allele frequency: 1% threshold (`--maf 0.01`)
   - No individual-level filtering applied

2. **TreeMix Configuration:**
   - Split-only model: 0 migration edges (`-m 0`)
   - Migration model: 10 migration edges (`-m 10`)
   - SNP block size: 1000 (`-k 1000`)
   - Random seed: 1 for reproducibility (`-seed 1`)
   - Root population: San (African hunter-gatherer outgroup)

3. **Output Files:**
   ```
   experiments/baseline/
   ├── plink_results/baseline_treemix.gz     # Input for TreeMix
   ├── treemix_results/
   │   ├── baseline_split.treeout.gz         # Split-only tree
   │   ├── baseline_migration.treeout.gz     # Migration tree
   │   └── [.vertices.gz, .edges.gz, .log]  # Supporting files
   └── plots/
       ├── baseline_split.pdf/.png           # Visualization files
       └── baseline_migration.pdf/.png
   ```

#### 5.2 PLINK Parameter Sensitivity Analysis

**5.2.1 Experiment 3a: Genotype Missingness Thresholds**

**Hypothesis:** Genotype missingness filtering affects population relationships by reducing available genetic information.

**Methodology:**
- **Missingness Thresholds:** 0%, 1%, 5% (`--geno 0.00, 0.01, 0.05`)
- **Parallel Processing:** Three datasets generated simultaneously
- **Other Parameters:** MAF 1% maintained across all conditions
- **Comparison Metric:** Tree topology changes relative to baseline (10% missingness)


**5.2.2 Experiment 3b: Minor Allele Frequency Filtering**

**Hypothesis:** Increased MAF thresholds eliminate rare variants that may contain population-specific evolutionary signals.

**Methodology:**
- **MAF Threshold:** 5% (`--maf 0.05`) vs baseline 1%
- **Genotype Missingness:** Standard 10% maintained
- **Analysis Focus:** Impact on branch lengths and population divergence estimates

#### 5.3 Archaic Genome Integration (Experiment 4)

**Purpose:** Assess phylogenetic impact of including archaic hominin genomes in modern human population analysis.

**Methodology:**
1. **Archaic Populations:**
   - Denisovan individuals
   - Vindija Neanderthal 
   - Combined (both archaic genomes simultaneously, Denisovan and Vindija)

2. **Integration Protocol:**
   - Archaic individuals treated as separate populations
   - Standard quality filters applied
   - Migration edges capture modern human-archaic gene flow

3. **Analysis Focus:**
   - Changes in modern human population relationships
   - Migration edge patterns between modern and archaic lineages
   - Impact on divergence time estimates

#### 5.4 Population Sampling Strategies (Experiments 5a & 5b)

**5.4.1 Experiment 5a: Uneven Sampling Design**

**Purpose:** Simulate real-world datasets where population sampling is unbalanced.

**Methodology:**
- **Target Populations:** Specific populations reduced to 3 or 5 individuals
- **Selection Criteria:** Focus on historically admixed populations
  - Colombian, Druze, Karitiana, Surui (known admixed groups)
  - Balochi, Brahui, Burusho, Hazara, Kalash (Central/South Asian)
- **Other Populations:** Maintain original sample sizes
- **Analysis:** Impact of sample size imbalance on tree reconstruction

**5.4.2 Experiment 5b: Even Sampling Design**

**Purpose:** Control experiment with uniform sampling across all populations.

**Methodology:**
- **Uniform Sampling:** All populations reduced to 3 or 5 individuals
- **Random Selection:** Individuals randomly selected per population
- **Comparison:** Even vs uneven sampling effects on phylogenetic accuracy

#### 5.5 Population Exclusion Analysis (Experiments 6a & 6b)

**5.5.1 Experiment 6a: Random Population Removal**

**Purpose:** Assess robustness of phylogenetic patterns to missing population data.

**Methodology:**
- **Removal Strategy:** Random selection of 14 and 20 populations
- **Selection Algorithm:** Stratified sampling to maintain continental representation
- **Comparison:** Tree stability with reduced population diversity

**5.5.2 Experiment 6b: Continental Exclusion**

**Purpose:** Examine the effect of systematic continental-level data gaps.

**Methodology:**
- **Excluded Continents:** 
  - Europe (removal of European populations)
  - North Africa (removal of North African populations)
  - Middle East (removal of Middle Eastern populations)
  - East Asia (removal of East Asian populations)
  - Central South Asia (removal of Central/South Asian populations)
  - Native America (removal of Native American populations)
  - Oceania (removal of Oceanian populations)

- **Analysis Focus:** 
  - Remaining population relationships
  - Compensation patterns in phylogenetic reconstruction
  - Migration edge redistribution

#### 5.6 Admixed Population Analysis (Experiment 7a)

**Purpose:** Evaluate phylogenetic patterns when known admixed populations are excluded.

**Methodology:**
- **Removed Populations:** Known historically admixed groups
  - Colombian, Druze, Karitiana, Surui (documented admixture)
  - Balochi, Brahui, Burusho, Hazara, Kalash, Makrani, Pathan (Central/South Asian admixed)
- **Analysis:** Simplified population relationships without admixed intermediates
- **Comparison:** Tree complexity and migration edge requirements

#### 5.7 Artificial Population Experiments (7ba & 7bb)

**5.7.1 Experiment 7ba: Two-Way Artificial Hybrids**

**Purpose:** Create controlled admixed populations to test TreeMix's ability to detect known admixture patterns.

**Methodology:**
- **Hybrid Creation Protocol:**
  1. Select parent populations from different continents
  2. Randomly select individuals from each parent population
  3. Create artificial genomes with 50:50 admixture proportions
  4. Generate hybrid individuals using SNP-level recombination
- **Hybrid Populations Created:** Multiple 2-way combinations
- **Analysis:** TreeMix's accuracy in placing artificial hybrids

**5.7.2 Experiment 7bb: Five-Way Artificial Hybrids**

**Purpose:** Test TreeMix performance with complex, multi-way admixed populations.

**Methodology:**
- **Complex Admixture:** Five-way hybrids with equal contribution (20% each)
- **Parent Selection:** Representatives from different continental groups
- **Computational Challenge:** Higher complexity than natural admixture patterns
- **Validation:** Known admixture proportions vs. TreeMix-inferred patterns

**Expected Results:** TreeMix should detect admixture but may struggle with accurate proportion estimation for complex multi-way hybrids.

### 6. Output Structure and Data Organization

**6.1 Experiment Directory Structure**

Each experiment generates a standardized output structure:

```
experiments/experiment_X/
├── plink_results/              # PLINK preprocessing outputs
│   ├── [exp]_[variant]_treemix.gz     # TreeMix input files
│   ├── [exp]_[variant].bed/.bim/.fam  # Binary PLINK files
│   ├── [exp]_[variant].log            # PLINK processing logs
│   └── [specific filter files]        # Population lists, removal files
├── treemix_results/            # TreeMix analysis outputs
│   ├── [exp]_[variant]_split.treeout.gz    # Split-only tree
│   ├── [exp]_[variant]_migration.treeout.gz # Migration tree
│   ├── [exp]_[variant]_split.vertices.gz   # Tree vertex information
│   ├── [exp]_[variant]_migration.vertices.gz
│   ├── [exp]_[variant]_split.edges.gz      # Tree edge information
│   ├── [exp]_[variant]_migration.edges.gz
│   └── [exp]_[variant]_[mode].log          # TreeMix execution logs
├── comparison_results/         # Tree comparison analysis
│   ├── [exp]_[variant]_[mode]_differences.txt    # Population differences
│   └── [exp]_[variant]_[mode]_tree_comparison_results.json # Metrics
└── plots/                     # Publication-quality visualizations
    ├── [exp]_[variant]_[mode].pdf        # Vector graphics
    └── [exp]_[variant]_[mode].png        # High-resolution rasters
```
For example,
```
experiments/baseline/
├── plink_results/baseline_treemix.gz     # Input for TreeMix
├── treemix_results/
│   ├── baseline_split.treeout.gz         # Split-only tree
│   ├── baseline_migration.treeout.gz     # Migration tree
│   └── [.vertices.gz, .edges.gz, .log]  # Supporting files
└── plots/
    ├── baseline_split.pdf/.png           # Visualization files
    └── baseline_migration.pdf/.png
```

**6.2 Tree Comparison Methodology**

**Comparison Algorithm:**
1. **Tree Parsing:** Load baseline and experimental trees using DendroPy
2. **Topology Comparison:** Robinson-Foulds distance calculation
3. **Population Relationship Analysis:** 
   - Sister group identification changes
   - Branch length comparisons
   - Migration edge pattern differences
4. **Statistical Significance:** Bootstrap support comparison where available

**Output Files:**
- **Text Summary (`.txt`):** Human-readable list of changed population relationships
- **JSON Metrics (`.json`):** Quantitative measures (RF distance, branch length differences, etc.)

**6.3 Visualization and Plotting System**

**Plotting Features:**
- **Continental Color Coding:** Populations colored by regional assignment
- **Change Highlighting:** Red boxes around populations with altered relationships
- **Multiple Output Formats:** PDF (vector) and PNG (600 DPI raster)
- **Publication Ready:** Standardized fonts, legend, and layout

**Plot Generation Command:**
```bash
Rscript src/treemix_tests/plot_scripts/plot_with_legend.R \
    <treemix_output_stem> \
    --both \                    # Generate both PDF and PNG
    --dpi 600 \                 # High-resolution PNG
    --changed-pops <diff_file> \ # Highlight changed populations
    --output-dir <output_path>   # Specify output directory
```

### 7. Reproducibility and Version Control

**7.1 Reproducibility Measures**

- **Fixed Random Seeds:** All analyses use seed=1 for consistency
- **Conda Environment:** Locked software versions in environment.yml
- **Snakemake Workflow:** Ensures consistent execution order
- **Version Control:** All scripts tracked with Git

**7.2 Replication Protocol**

1. **Environment Setup:** Use provided environment.yml exactly
2. **Data Preparation:** Follow data format specifications precisely
3. **Execution Parameters:** Use recommended core counts and memory
4. **Result Comparison:** Compare key metrics against expected ranges

**7.3 Publication and Sharing**

**Required Components for Sharing:**
- Complete source code (this repository)
- Environment specification (environment.yml)
- Sample configuration files
- Detailed methodology (this README)

**Not Shared (Due to Size):**
- Complete raw data files
- All intermediate analysis files
- Full experimental output directories

### 8. Performance Optimization and Scalability

**8.1 Hardware Optimization**

**Recommended Configurations:**
- **Small Scale (testing):** 8 cores, 16 GB RAM, 100 GB storage
- **Medium Scale (full analysis):** 32 cores, 64 GB RAM, 500 GB storage  
- **Large Scale (parallel experiments):** 64+ cores, 128+ GB RAM, 1+ TB storage

**8.2 Execution Time Estimates**

**Per Experiment (32-core system):**
- PLINK preprocessing: 10-30 minutes
- TreeMix analysis: 30-120 minutes
- Comparison and plotting: 5-15 minutes
- **Total per experiment:** 1-3 hours

**Complete Pipeline:** 8-24 hours depending on hardware and parallelization

**8.3 Parallelization Strategy**

**Optimal Core Allocation:**
```bash
# Maximum parallelization
snakemake --cores 64 

# Balanced approach (recommended)
snakemake --cores 32 

# Conservative (limited resources)
snakemake --cores 16 
```
### 9. Contact and Support

Please contact

---
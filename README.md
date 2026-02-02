# TreeMix Workflow

A reproducible Snakemake workflow for population genetics analysis using TreeMix. Automates data preprocessing, TreeMix runs, tree comparison, and high-quality plotting to assess population splits and admixture events across multiple experimental conditions.

## Project Overview

This workflow systematically analyzes genetic data through 11 different experimental configurations to understand the effects of various parameters on TreeMix phylogenetic tree reconstruction. It includes baseline analysis, parameter testing, population sampling variations, and archaic genome additions.

## Project Structure

```
├── workflows/
│   └── Snakefile              # Main Snakemake workflow orchestrating all steps
├── src/
│   ├── plink_script.sh        # Modular PLINK preprocessing script
│   └── treemix_tests/
│       ├── analysis/
│       │   └── find_differences.py    # Tree comparison and difference detection
│       ├── plot_scripts/
│       │   ├── plot_with_legend.R     # Main plotting script with region colors
│       │   ├── plotting_funcs.R       # Core TreeMix plotting functions  
│       │   └── README.md              # Detailed plotting documentation
│       ├── plink2treemix.py           # PLINK to TreeMix format conversion
│       └── population_manipulation.py # Population filtering utilities
├── raw_data/
│   ├── Harvard_HGDP-CEPH/     # Raw genetic data (BED/BIM/FAM files)
│   ├── region_mapping.json    # Continental region assignments
│   └── 2306_poplist.tsv      # Population metadata
├── experiments/               # All experiment results (auto-generated)
│   ├── baseline/             # Reference TreeMix analysis
│   ├── experiment_3a/        # Genotype missingness tests
│   ├── experiment_3b/        # Minor allele frequency tests
│   ├── experiment_4/         # Archaic genome additions
│   ├── experiment_5a/        # Uneven sampling tests
│   ├── experiment_5b/        # Even sampling tests
│   ├── experiment_6a/        # Population dropping tests
│   ├── experiment_6b/        # Continental exclusion tests
│   ├── experiment_7a/        # Admixed population removal
│   ├── experiment_7ba/       # Artificial 2-way hybrids
│   └── experiment_7bb/       # Artificial 5-way hybrids
├── bin/plink/                # PLINK binary and tools
├── treemix/                  # TreeMix configuration files and test scripts
├── environment.yml           # Conda environment specification
├── requirements.txt          # Python dependencies
├── Makefile                 # Setup and utility commands
└── tests/                   # Unit tests
```

## Quick Start

### 1. Environment Setup

```bash
# Create conda environment
conda env create -f environment.yml
conda activate treemix_env

# Or use Make
make conda_env
```

### 2. Download PLINK

```bash
make plink
```

### 3. Run the Complete Workflow

```bash
# Run all experiments (recommended: use many cores)
snakemake --snakefile workflows/Snakefile --cores 64

# Run specific experiment
snakemake --snakefile workflows/Snakefile \
    experiments/experiment_3a/plots/ \
    --cores 8

# Dry run to see planned jobs
snakemake --snakefile workflows/Snakefile --cores 8 -n
```

### 4. Manual Steps

```bash
# Run PLINK preprocessing only
bash src/plink_script.sh test_1        # Baseline
bash src/plink_script.sh test_3a       # Genotype missingness

# Create plots manually
Rscript src/treemix_tests/plot_scripts/plot_with_legend.R \
    experiments/baseline/treemix_results/baseline_split \
    --both --dpi 600 --output-dir plots/
```

## Experiments Overview

### Baseline (test_1)
- **Purpose**: Reference TreeMix analysis
- **Parameters**: Standard PLINK filtering, TreeMix with 0 migrations (split) and 10 migrations
- **Output**: Reference trees for all comparisons

### Parameter Testing
- **Experiment 3a**: Tests genotype missingness thresholds (0.00, 0.01, 0.05)
- **Experiment 3b**: Tests minor allele frequency threshold (0.05)

### Archaic Genomes (test_4)
- **Purpose**: Assess impact of archaic hominin genomes
- **Variants**: Denisovan, Vindija Neanderthal, Both combined

### Sampling Variations
- **Experiment 5a**: Uneven sampling (3 and 5 individuals per population)
- **Experiment 5b**: Even sampling (3 and 5 individuals per population)

### Population Filtering
- **Experiment 6a**: Random population dropping (14 and 20 populations)
- **Experiment 6b**: Continental exclusion (remove Europe, Asia, Africa, etc.)
- **Experiment 7a**: Remove admixed populations

### Artificial Populations
- **Experiment 7ba**: 2-way artificial hybrids
- **Experiment 7bb**: 5-way artificial hybrids

## Key Features

### Automated Pipeline
- **Modular PLINK processing** with parallel execution
- **Systematic TreeMix runs** for split-only and migration models
- **Automated tree comparison** using phylogenetic distance metrics
- **Publication-quality plotting** with continental region colors

### Reproducibility
- **Snakemake workflow** ensures reproducible execution order
- **Conda environment** for dependency management
- **Version control** of all scripts and configurations
- **Comprehensive logging** of all processing steps

### Visualization
- **Region-colored plots** showing populations by continental origin
- **Difference highlighting** with red boxes around changed populations
- **High-resolution output** (600 DPI PNG + PDF)
- **Customizable legends** and plot layouts

## Output Structure

Each experiment produces:
```
experiments/experiment_X/
├── plink_results/           # PLINK-processed data
├── treemix_results/        # TreeMix output files (.treeout.gz, .vertices.gz, .edges.gz)
├── comparison_results/     # Tree differences and metrics (.txt, .json)
└── plots/                 # High-quality publication plots (.pdf, .png)
```

## Plotting Features

The plotting system includes:
- **Continental region colors** based on population assignments
- **Change highlighting** showing populations with different relationships vs baseline
- **Multiple output formats** (PDF and PNG)
- **Customizable parameters** (DPI, size, legend position)

```bash
# Example plotting commands
Rscript plot_with_legend.R <stem> --both --dpi 600
Rscript plot_with_legend.R <stem> --changed-pops differences.txt --output-dir results/
```

See `src/treemix_tests/plot_scripts/README.md` for complete plotting documentation.

## Dependencies

### Core Tools
- **Python 3.12**: Main scripting language
- **R**: Plotting and visualization
- **PLINK**: Genetic data preprocessing
- **TreeMix**: Phylogenetic tree reconstruction
- **Snakemake**: Workflow management

### Python Packages
```
pandas, numpy          # Data manipulation
dendropy              # Phylogenetic analysis
pytest, ruff          # Testing and linting
```

### R Packages
```
jsonlite              # JSON processing
RColorBrewer          # Color schemes
```

## Performance Notes

- **Parallelization**: Use `--cores` parameter to utilize multiple CPUs
- **Memory usage**: TreeMix analysis can be memory-intensive for large datasets
- **Storage**: Plan for ~50-100GB of intermediate and output files
- **Runtime**: Complete workflow takes 2-6 hours depending on available cores

## Troubleshooting

### Common Issues
1. **Missing PLINK binary**: Run `make plink` to download
2. **Environment issues**: Ensure conda environment is activated
3. **File permissions**: Check that raw data files are readable
4. **Memory errors**: Reduce parallel jobs or increase available RAM

### Getting Help
- Check individual script documentation in `src/treemix_tests/`
- Review Snakemake logs in `.snakemake/log/`
- Examine PLINK and TreeMix log files in experiment directories

## Citation

If you use this workflow, please cite the relevant tools:
- **TreeMix**: Pickrell & Pritchard (2012)
- **PLINK**: Purcell et al. (2007)
- **Snakemake**: Köster & Rahmann (2012)

## License

This project is available under the MIT License. See individual tool licenses for dependencies.
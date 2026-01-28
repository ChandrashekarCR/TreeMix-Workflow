import os
import argparse
from pathlib import Path
import pandas as pd

ROOT_DIR = Path.cwd()
EXPERIMENTS_DIR=f"{ROOT_DIR}/experiments"
TREEMIX=f"{os.environ['HOME']}/miniconda3/envs/treemix_env/bin/treemix"
SEED=1
SNP_SIZE=1000
SPLIT_ONLY=1
MIGRATION_ENABLED=10
ROOT="San"


EXPERIMENTS = {
    # Experiment 1: Baseline (Split only and migration enabled)
    "baseline": {
        "plink_test": "test_1",
        "plink_output":"baseline/plink_results/baseline_treemix.gz",
        "variants": []
    },

    # Experiment 2a: Treemix Parameters - SNP Block Size
    "exp_2a": {
        "plink_test":"test_1", # Use the baseline PLINK file
        "prefix":"baseline",
        "plink_output":"baseline/plink_results/baseline_treemix.gz",
        "variants":[
            {"name":"k200","k":200},
            {"name":"k500","k":500},
            {"name":"k1000","k":1000},
            {"name":"k1500","k":1500},
            {"name":"k2000","k":2000},
            {"name":"k10000","k":10000}
        ]
    },

    # Experiment 2b: Treemix Parameters - Migration Edges
    "exp_2b": {
        "plink_test": "test_1", #Use the baseline PLINK file
        "plink_output": "baseline/plink_results/baseline_treemix.gz",
        "variants":[
            {"name":f"m{m}","m":m}
            for m in [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
        ]
    },

    # Experiment 3a: PLINK Parameters - Genotype missigness
    "exp_3a": {
        "plink_test":"test_3a",
        "variants":[
            {"name":"geno_missing_000","geno":"0.00"},
            {"name":"geno_missing_001","geno":"0.01"},
            {"name":"geno_missing_005","geno":"0.05"}
        ]
    },

    # Experiment 3b: PLINK Parameters - Minor Allele Frequency
    "exp_3b": {
        "plink_test":"test_3b",
        "variants": [
            {"name":"minor_allele_freq_005","maf":"0.05"}
        ]
    },

    # Experiment 4: Addtion of Archaic Homonin Genomes
    "exp_4" : {
        "plink_test":"test_4",
        "variants":[
            {"name":"added_Deni"},
            {"name":"added_Vindija"},
            {"name":"added_Both"}
        ]
    },

    # Experiment 5a: Uneven Sampling
    "exp_5a": {
        "plink_test":"test_5a",
        "variants": [ 
            {"name":"filtered_3_uneven_ind","size":3},
            {"name":"filtered_5_uneven_ind","size":5}
        ]
    },

        # Experiment 5b: Even sampling
    "exp_5b": {
        "plink_test": "test_5b",
        "variants": [
            {"name": "filtered_3_even_ind", "size": 3},
            {"name": "filtered_5_even_ind", "size": 5}
        ]
    },
    
    # Experiment 6a: Drop populations
    "exp_6a": {
        "plink_test": "test_6a",
        "variants": [
            {"name": "drop_pops_14", "num": 14},
            {"name": "drop_pops_20", "num": 20}
        ]
    },
    
    # Experiment 6b: Remove continents
    "exp_6b": {
        "plink_test": "test_6b",
        "variants": [
            {"name": f"dataset_no_{continent.replace(' ', '_')}"} 
            for continent in ["Europe", "North_Africa", "Middle_East", "Asia", "America", "Oceania"]
        ]
    },
    
    # Experiment 7a: Remove admixed populations
    "exp_7a": {
        "plink_test": "test_7a",
        "variants": [{"name": "drop_admixed_pops"}]
    },
    
    # Experiment 7ba: Artificial 2-way hybrids
    "exp_7ba": {
        "plink_test": "test_7ba",
        "variants": [{"name": "artificial_2_merged_all"}]
    },
    
    # Experiment 7bb: Artificial 5-way hybrids
    "exp_7bb": {
        "plink_test": "test_7bb",
        "variants": [{"name": "artificial_5_merged_all"}]
    },
    
    # Experiment 8: Artificial shuffled
    "exp_8": {
        "plink_test": "test_8",
        "variants": [{"name": "artificial_5_merged_all_shuffled"}]
    }
}


# ======== Helper Function ========
def get_all_plink_outputs():
    # Get all the plink output file names and store it in a list
    outputs = []
    for exp_name, exp_config in EXPERIMENTS.items():
        if "plink_output" in exp_config.keys():
            write_out = f"{EXPERIMENTS_DIR}/{exp_config['plink_output']}"
            outputs.append(write_out)
        else:
            variant_id = [var_name['name'] for var_name in exp_config['variants']]
            for id in variant_id:
                write_out = f"{EXPERIMENTS_DIR}/experiment_{exp_name.split("_")[-1]}/plink_results/{exp_name.split("_")[-1]}_{id}_treemix.gz"
                outputs.append(write_out)
    return outputs
        
print(get_all_plink_outputs())
def get_treemix_params(exp_name, k=None, mode='split'):
    params = {
        'seed':SEED,
        'k':SNP_SIZE,
        'm': 0 if mode == 'split' else 10,
        'root': ROOT
    }
    
    if k is not None:
        variant = EXPERIMENTS[exp_name]['variants']
        print([var["k"] for var in variant])

        # Override if variant specific parameters
        if k in [var['k'] for var in variant]:
            params["k"] = k

    return params

variant=lambda w: [v["name"] for v in EXPERIMENTS[w.exp]["variants"]]


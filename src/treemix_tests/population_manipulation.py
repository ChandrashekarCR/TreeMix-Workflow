"""
Population manipulation tools for genetic data analysis.

This module provides a collection of tools for manipulating population data in genetic studies.
It includes functions for:
- Removing specific populations or continents
- Adding outgroup populations
- Generating hybrid populations
- Creating SNP-split hybrids
- Managing population lists and structures

The module is designed to work with standard genetic data formats (PLINK .ped files,
population list files) and provides both programmatic and command-line interfaces.
"""

import argparse
import json
import os
import sys
import logging
from typing import Union, List

import random

import numpy as np
import pandas as pd

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S',
    handlers=[
        logging.StreamHandler(),  # Console output
        logging.FileHandler('population_manipulation.log')  # File output
    ]
)

# Constants
VALID_HYBRID_POPULATIONS = [2, 5, 51]
VALID_OUTGROUP_TYPES = ["Deni", "Vindija", "Both"]

__all__ = [
    'drop_continents',
    'drop_random_populations',
    'drop_specific_populations',
    'generate_pop_lists',
    'reduce_population_counts',
    'new_outgroup',
    'write_json_structures',
    'prepare_groupwise_hybrid_lists',
    'create_snpsplit_hybrids_aligned'
]

def drop_continents(
    poplist_file: str,
    continent_to_remove: str,
    population_mapping_file: str,
    output_dir: str
) -> None:
    """
    Filters a population list file by removing all individuals belonging to a specified continent.

    This function processes a population list file, maps populations to their respective
    continents using a provided mapping file, and filters out individuals associated with
    a specified continent. It saves the information about removed individuals to a new file
    named with the format `remove_<continent>.tsv`.

    Args:
        poplist_file: Path to the population list file to be processed, where each row
            contains FID, IID, and Population, separated by tabs.
        continent_to_remove: Name of the continent whose individuals should be removed
            from the population list.
        population_mapping_file: Path to the JSON file containing the mapping between
            populations and continents.
        output_dir: Directory where the output file will be saved.

    Returns:
        None

    Raises:
        FileNotFoundError: If the input file or continent mapping file doesn't exist
        ValueError: If the input file is empty or malformed
        ValueError: If the continent mapping file is invalid
    """
    try:
        # Load continent mapping
        try:
            continent_map = json.load(open(population_mapping_file, "r"))
        except FileNotFoundError:
            raise FileNotFoundError(f"Continent mapping file not found: {population_mapping_file}")
        except json.JSONDecodeError:
            raise ValueError(f"Invalid continent mapping file: {population_mapping_file}")

        # Read population list
        poplist_df = pd.read_csv(poplist_file, sep="\t", names=["FID", "IID", "Population"], header=None)
        
        if poplist_df.empty or poplist_df.isna().all().all():
            raise ValueError("Input file is empty or malformed")

        # Map the populations to continents
        poplist_df["Continent"] = poplist_df["Population"].map(continent_map)

        # Checks
        if poplist_df["Continent"].isnull().any():
            logging.warning("Warning: Some populations are missing a continent mapping!")

        if continent_to_remove not in continent_map.values():
            logging.warning(f"Warning: Continent '{continent_to_remove}' not found in the population list!")

        # Remove all populations from continent_to_remove
        to_remove = poplist_df[poplist_df["Continent"] == continent_to_remove][["FID", "IID", "Population"]]
        
        # Create output directory if it doesn't exist
        os.makedirs(output_dir, exist_ok=True)

        # Save data
        continent_to_remove = '_'.join(continent_to_remove.split())
        remove_file = os.path.join(output_dir, f"remove_{continent_to_remove}.tsv")
        to_remove.to_csv(remove_file, sep="\t", index=False, header=False)

        logging.info(f"Saved {len(to_remove)} individuals to {remove_file} ({continent_to_remove} removed).")

    except FileNotFoundError:
        raise FileNotFoundError(f"Input file not found: {poplist_file}")
    except pd.errors.EmptyDataError:
        raise ValueError(f"Input file is empty: {poplist_file}")
    except ValueError:
        raise
    except Exception as e:
        raise Exception(f"An error occurred while processing the file: {str(e)}")

def drop_random_populations(poplist_file:str, outdir:str, percentage:float=0.50, random_state:int=42):
    """
    Randomly removes a specified percentage of populations from a population list file,
    ensuring that removals are distributed across continents. The function identifies
    populations grouped by continents, computes the number of populations to remove
    proportionately for each continent, and creates a removal list for a specified
    subset of individuals. The generated file can then be used to filter individuals
    using PLINK.

    :param poplist_file: Absolute or relative path to the population list file. The file
        should be in a space-separated format with three columns: Family ID (FID),
        Individual ID (IID), and Population ID (Population).
    :param percentage: Fraction of populations to randomly remove. The default is 0.50
        (50%). The value must lie between 0 and 1.
    :param random_state: Random seed for ensuring reproducibility of selected populations.
        The default value is 42.
    :return: None. Outputs a population removal list to a file named
        'remove_list_<percentage_in_percent>.tsv' in the current working directory. The
        removal list contains Family ID and Individual ID columns.
    """

    logging.info(f"📂 poplist_file: {poplist_file}")
    logging.info(f"📁 outdir: {outdir}")
    logging.info(f"🔢 percentage: {percentage}")
    logging.info(f"🎲 random_state: {random_state}")
    np.random.seed(random_state)

    # Read population list
    poplist_df = pd.read_csv(poplist_file, sep="\t", names=["FID", "IID", "Population"], header=None)

    # Get a list of unique populations
    unique_populations = poplist_df["Population"].dropna().unique()
    # Set the number of populations to remove (Modify as needed)
    num_populations_to_remove = int(len(unique_populations) * percentage)  # Remove 20% of populations

    continent_map =json.load(open("../raw_data/hgdp_popto_simplified.json", "r"))

    # Map population to continents
    poplist_df["Continent"] = poplist_df["Population"].map(continent_map)

    # Check if any populations are missing continent mapping
    missing_continent = poplist_df[poplist_df["Continent"].isnull()]["Population"].unique()
    if len(missing_continent) > 0:
        logging.warning(f"Warning: The following populations are missing a continent mapping: {missing_continent}")


    continent_groups = poplist_df.groupby("Continent")["Population"].unique()
    total_populations = sum(len(pops) for pops in continent_groups)

    # Iterate through the
    populations_to_remove = []
    for continent, populations in continent_groups.items():
        if len(populations) > 1:  # Only if there are more than 1 population per continent
            num_to_remove = max(1, int(len(populations) / total_populations * num_populations_to_remove))
            selected_pops = np.random.choice(populations, size=min(num_to_remove, len(populations, )), replace=False)
            populations_to_remove.extend(selected_pops)

    logging.info(f"Randomly selected {len(populations_to_remove)} populations to remove (evenly distributed across continents): {populations_to_remove}")
    to_remove = poplist_df[poplist_df["Population"].isin(populations_to_remove)][["FID", "IID"]]

    # Save remove list for PLINK
    remove_file = (os.path.join(outdir,f"remove_list_0{int(percentage*100)}.tsv" ))
    to_remove.to_csv(remove_file, sep="\t", index=False, header=False)

    logging.info(f"Saved {len(to_remove)} individuals to {remove_file}. Now run PLINK to filter them.")


def drop_specific_populations( #CHECKED
    poplist_file: str,
    path: str,
    populations_to_remove: list[str] = ["Druze", "Colombian"]
) -> None:
    """
    Removes specific populations from a population list file by filtering out individuals from the
    specified populations. The function generates a file containing individuals to be removed
    based on the provided populations.

    Args:
        poplist_file: Path to the file containing population data. This file should have three
            columns: FID, IID, and Population, separated by tabs.
        path: Output path where the filtered population list will be saved.
        populations_to_remove: A list of populations to be removed from the dataset. If not
            provided, defaults to ["Druze", "Colombian"].

    Returns:
        None

    Raises:
        FileNotFoundError: If the input file doesn't exist
        ValueError: If the input file is empty or malformed
    """
    try:
        # Read population list
        poplist_df = pd.read_csv(poplist_file, sep="\t", names=["FID", "IID", "Population"], header=None)
        if poplist_df.empty or poplist_df.isna().all().all():
            raise ValueError("Input file is empty or malformed")
            
        # Get unique populations in the dataset
        existing_populations = set(poplist_df["Population"].dropna().unique())
        
        logging.info(f"Following populations will be added to the 'to_remove' list: {populations_to_remove}")

        # Check if populations to remove exist
        invalid_populations = [pop for pop in populations_to_remove if pop not in existing_populations]
        if invalid_populations:
            logging.warning(f"Warning: The following populations are NOT in the dataset: {invalid_populations}")
            populations_to_remove = [pop for pop in populations_to_remove if pop in existing_populations]

        if not populations_to_remove:
            logging.warning("Warning: No valid populations to remove after filtering")
            return

        # Make a dataframe with all populations that should be removed
        to_remove = poplist_df[poplist_df["Population"].isin(populations_to_remove)][["FID", "IID", "Population"]]

        # Create output directory if it doesn't exist
        os.makedirs(os.path.dirname(path), exist_ok=True)

        # Save to remove_list.tsv
        to_remove.to_csv(path, sep="\t", index=False, header=False)
        logging.info(f"Saved {len(to_remove)} individuals to {path}")
    
    except FileNotFoundError:
        raise FileNotFoundError(f"Input file not found: {poplist_file}")
    except pd.errors.EmptyDataError:
        raise ValueError(f"Input file is empty: {poplist_file}")
    except ValueError:
        raise
    except Exception as e:
        raise Exception(f"An error occurred while processing the file: {str(e)}")

    
def generate_pop_lists( #CHECKED
    full_list_path: str,
    nr_individuals: int,
    outdir: str,
    num_populations_to_reduce: Union[str, int] = "10",
    random_state: int = 42
) -> None:
    """
    Generates a modified population list with controlled sample sizes for specific populations.

    This function randomly selects a specified number of populations and reduces their
    sample size to a given number of individuals, while keeping all other populations unchanged.
    The modified dataset is then saved as a new TSV file.

    Args:
        full_list_path: Path to the input TSV file containing population data.
            The file should have three columns: Family ID (FID), Individual ID (IID), and Population name.
            The separator should be a tab & no header.
        nr_individuals: The number of individuals to retain for each selected population.
        outdir: Directory where the output file will be saved.
        num_populations_to_reduce: Number of populations to randomly select for sample size reduction.
            If the value is 'all', all populations will be reduced. Defaults to "10".
        random_state: Seed for reproducibility in random selection. Defaults to 42.

    Returns:
        None

    Raises:
        FileNotFoundError: If the input file doesn't exist
        ValueError: If the input file is empty or malformed
        ValueError: If nr_individuals is less than 1
        ValueError: If num_populations_to_reduce is invalid
    """
    # Validate nr_individuals
    if nr_individuals < 1:
        raise ValueError("nr_individuals must be at least 1")

    try:
        # Read full tsv in a DataFrame
        df = pd.read_csv(full_list_path, sep="\t", header=None, names=["FID", "IID", "POPULATION"])
        
        if df.empty or df.isna().all().all():
            raise ValueError("Input file is empty or malformed")

        # List all unique populations
        unique_populations = df["POPULATION"].unique()

        # Check if user wants to apply the even sample test
        if str(num_populations_to_reduce).lower() == "all":
            selected_populations = unique_populations
            logging.info(f"Reducing ALL populations to {nr_individuals} individuals (Even Sample Number Test).")
            file_prefix = "even"
        else:
            try:
                num_populations_to_reduce = int(num_populations_to_reduce)
                if num_populations_to_reduce < 1:
                    raise ValueError("num_populations_to_reduce must be at least 1")
                if num_populations_to_reduce > len(unique_populations):
                    raise ValueError(f"num_populations_to_reduce ({num_populations_to_reduce}) cannot be greater than the number of unique populations ({len(unique_populations)})")
            except ValueError as e:
                raise ValueError(f"Invalid num_populations_to_reduce: {num_populations_to_reduce}. Must be 'all' or a positive integer.")

            # Randomly select populations that will be manipulated
            selected_populations = random.sample(list(unique_populations), num_populations_to_reduce)
            logging.info(
                f"Reducing {num_populations_to_reduce} populations to {nr_individuals} individuals (Uneven Sample Number Test):",
                selected_populations)
            file_prefix = f"uneven_{num_populations_to_reduce}pop"

        modified_data = []

        for pop, group in df.groupby("POPULATION"):
            if pop in selected_populations:
                # Reduces selected population to nr_individuals
                sample = group.sample(n=min(nr_individuals, len(group)), random_state=random_state)
                modified_data.append(sample)
            else:
                # The other populations stay same
                modified_data.append(group)

        # Combine the reduced and other populations
        final_df = pd.concat(modified_data)

        # Create output directory if it doesn't exist
        os.makedirs(outdir, exist_ok=True)

        # Save data
        output_file = os.path.join(outdir, f"{file_prefix}_{nr_individuals}ind.tsv")
        final_df.to_csv(output_file, sep="\t", index=False, header=False)
        logging.info(f"Pop list manipulation is completed: {output_file}")

    except FileNotFoundError:
        raise FileNotFoundError(f"Input file not found: {full_list_path}")
    except pd.errors.EmptyDataError:
        raise ValueError(f"Input file is empty: {full_list_path}")
    except ValueError:
        raise
    except Exception as e:
        raise Exception(f"An error occurred while processing the file: {str(e)}")




def reduce_population_counts( #CHECKED
    poplist_file: str,
    out_path: str,
    populations_to_reduce: Union[List[str], None] = None,
    max_per_population: int = 10
) -> None:
    """
    Reduces the number of individuals from specified populations in a population list file.
    Keeps at most `max_per_population` individuals per target population.

    Args:
        poplist_file: Path to the file containing population data. Should have FID, IID, Population 
            (tab-separated).
        out_path: Output path for the modified population list file.
        populations_to_reduce: List of populations to reduce in size. If None, uses default list of
            historically admixed populations.
        max_per_population: Maximum number of individuals to keep for each listed population.
            Defaults to 10.

    Returns:
        None

    Raises:
        FileNotFoundError: If the input file doesn't exist
        ValueError: If the input file is empty or malformed
        ValueError: If max_per_population is less than 1
    """
    # Validate max_per_population
    if max_per_population < 1:
        raise ValueError("max_per_population must be at least 1")

    # Set default populations if none provided
    if populations_to_reduce is None:
        populations_to_reduce = [
            "Druze", "Colombian", "Karitiana", "Surui", "Balochi", "Brahui",
            "Burusho", "Hazara", "Kalash", "Makrani", "Pathan"
        ]

    try:
        # Read the poplist file
        poplist_df = pd.read_csv(poplist_file, sep="\t", names=["FID", "IID", "Population"], header=None)
        
        if poplist_df.empty or poplist_df.isna().all().all():
            raise ValueError("Input file is empty or malformed")

        # Get unique populations in the dataset
        existing_populations = set(poplist_df["Population"].dropna().unique())
        
        # Check for invalid populations
        invalid_populations = [pop for pop in populations_to_reduce if pop not in existing_populations]
        if invalid_populations:
            logging.warning(f"Warning: The following populations are NOT in the dataset: {invalid_populations}")
            populations_to_reduce = [pop for pop in populations_to_reduce if pop in existing_populations]

        if not populations_to_reduce:
            logging.warning("Warning: No valid populations to reduce after filtering")
            return

        # Split the dataframe: populations to reduce vs others
        to_reduce_df = poplist_df[poplist_df["Population"].isin(populations_to_reduce)]
        keep_as_is_df = poplist_df[~poplist_df["Population"].isin(populations_to_reduce)]

        # Reduce each population
        reduced_list = []
        for pop in populations_to_reduce:
            sub_df = to_reduce_df[to_reduce_df["Population"] == pop]
            if len(sub_df) > max_per_population:
                sub_df = sub_df.sample(n=max_per_population, random_state=42)
            reduced_list.append(sub_df)

        reduced_df = pd.concat(reduced_list, ignore_index=True)
        final_df = pd.concat([keep_as_is_df, reduced_df], ignore_index=True)

        # Create output directory if it doesn't exist
        os.makedirs(os.path.dirname(out_path), exist_ok=True)

        # Save the final list
        final_df.to_csv(out_path, sep="\t", index=False, header=False)
        logging.info(f"Saved reduced population list with {len(final_df)} individuals to {out_path}")

    except FileNotFoundError:
        raise FileNotFoundError(f"Input file not found: {poplist_file}")
    except pd.errors.EmptyDataError:
        raise ValueError(f"Input file is empty: {poplist_file}")
    except ValueError:
        raise
    except Exception as e:
        raise Exception(f"An error occurred while processing the file: {str(e)}")
    


def new_outgroup( #CHECKED
    poplist_file: str,
    outgroup_type: str,
    outdir: str = "."
) -> None:
    """
    Adds outgroup populations to an existing population list file.

    Args:
        poplist_file: Path to the input population list file (tab-separated with FID, IID, Population columns).
        outgroup_type: Type of outgroup to add. Must be one of: "Deni", "Vindija", or "Both".
        outdir: Directory where the output file will be saved. Defaults to current directory.

    Returns:
        None

    Raises:
        FileNotFoundError: If the input file doesn't exist
        ValueError: If outgroup_type is invalid or input file is empty/malformed
    """
    # Validate outgroup type
    valid_types = ["Deni", "Vindija", "Both"]
    if outgroup_type not in valid_types:
        raise ValueError(f"Invalid outgroup_type: {outgroup_type}. Must be one of {valid_types}")

    try:
        # Read population list
        poplist_df = pd.read_csv(poplist_file, sep="\t", names=["FID", "IID", "Population"], header=None)
        
        if poplist_df.empty:
            raise ValueError("Input file is empty")

        # Create outgroup dataframes
        if outgroup_type == "Deni":
            new_pop = pd.DataFrame([["Denisova", "Denisova", "Denisovan"]], 
                                 columns=["FID", "IID", "Population"])
        elif outgroup_type == "Vindija":
            new_pop = pd.DataFrame([["Vindija", "Vindija", "Vindija"]], 
                                 columns=["FID", "IID", "Population"])
        else:  # Both
            deni = pd.DataFrame([["Denisova", "Denisova", "Denisovan"]], 
                              columns=["FID", "IID", "Population"])
            vind = pd.DataFrame([["Vindija", "Vindija", "Vindija"]], 
                              columns=["FID", "IID", "Population"])
            new_pop = pd.concat([deni, vind])

        # Combine with the whole pop_list
        poplist_combined = pd.concat([poplist_df, new_pop])

        # Create output directory if it doesn't exist
        os.makedirs(outdir, exist_ok=True)

        # Prepare output
        outfile = os.path.join(outdir, f"added_{outgroup_type}.tsv")
        poplist_combined.to_csv(outfile, sep="\t", index=False, header=False)

        logging.info(f"Outgroup population lists written to: {outdir}")

    except FileNotFoundError:
        raise FileNotFoundError(f"Input file not found: {poplist_file}")
    except pd.errors.EmptyDataError:
        raise ValueError(f"Input file is empty: {poplist_file}")


def write_json_structures(
    outdir: str,
    number_of_pop_per_hybrid: int
) -> None:
    """
    Generates JSON structures for hybrid populations with a specified number of populations per hybrid.

    This function creates a JSON file containing predefined hybrid structures based on the
    number of populations per hybrid. The structures are used to define how different
    populations should be combined to create hybrid individuals.

    Args:
        outdir: Directory where the output JSON file will be saved.
        number_of_pop_per_hybrid: Number of populations to include in each hybrid.
            Must be one of: 2, 5, or 51.

    Returns:
        None

    Raises:
        ValueError: If number_of_pop_per_hybrid is not one of the supported values (2, 5, or 51)
        FileNotFoundError: If the output directory cannot be created
    """
    try:
        # Validate number_of_pop_per_hybrid
        valid_numbers = [2, 5, 51]
        if number_of_pop_per_hybrid not in valid_numbers:
            raise ValueError(f"number_of_pop_per_hybrid must be one of {valid_numbers}, got {number_of_pop_per_hybrid}")

        # Create output directory if it doesn't exist
        os.makedirs(outdir, exist_ok=True)

        # Define hybrid structures based on number_of_pop_per_hybrid
        if number_of_pop_per_hybrid == 2:
            hybrid_dict = {
                "Tuscan-Yoruba": ["Tuscan", "Yoruba"],
                "French-Japanese": ["French", "Japanese"],
                "BantuSouthAfrica-Bedouin": ["BantuSouthAfrica", "Bedouin"],
                "Maya-BergamoItalian": ["Maya", "BergamoItalian"],
                "Mandenka-Han": ["Mandenka", "Han"],
                "Burusho-Pima": ["Burusho", "Pima"],
                "Basque-Cambodian": ["Basque", "Cambodian"],
                "Adygei-Colombian": ["Adygei", "Colombian"],
                "Mbuti-Bougainville": ["Mbuti", "Bougainville"],
                "Biaka-Palestinian": ["Biaka", "Palestinian"]
            }
        elif number_of_pop_per_hybrid == 5:
            hybrid_dict = {
                "Yoruba-BergamoItalian-Bedouin-Japanese-Maya": ["Yoruba", "BergamoItalian", "Bedouin", "Japanese", "Maya"],
                "Mbuti-French-Burusho-Bougainville-Pima": ["Mbuti", "French", "Burusho", "Bougainville", "Pima"],
                "Mandenka-Adygei-Sindhi-Mongola-Colombian": ["Mandenka", "Adygei", "Sindhi", "Mongola", "Colombian"],
                "BantuSouthAfrica-Kalash-Basque-Han-Surui": ["BantuSouthAfrica", "Kalash", "Basque", "Han", "Surui"]
            }
        elif number_of_pop_per_hybrid == 51:
            hybrid_dict = {
                "French-Mbuti-Burusho-Bougainville-Pima": ["French", "Mbuti", "Burusho", "Bougainville", "Pima"],
                "Mbuti-French-Burusho-Bougainville-Pima": ["Mbuti", "French", "Burusho", "Bougainville", "Pima"],
                "French-Burusho-Mbuti-Bougainville-Pima": ["French", "Burusho", "Mbuti", "Bougainville", "Pima"]
            }

        # Save the hybrid structures to a JSON file
        outfile = os.path.join(outdir, f"{number_of_pop_per_hybrid}_structure.tsv")
        with open(outfile, "w") as f:
            json.dump(hybrid_dict, f, indent=2)

        logging.info(f"Hybrid JSON structures saved in: {outdir}")

    except ValueError:
        raise
    except OSError:
        raise
    except FileNotFoundError:
        raise
    except Exception as e:
        raise Exception(f"An error occurred while writing the JSON structures: {str(e)}")


def prepare_groupwise_hybrid_lists(
    full_pop_list_path: str,
    hybrid_structure: str,
    output_dir: str
) -> None:
    """
    Creates one .tsv per hybrid group for PLINK --keep and an updated population list with hybrid individuals.

    This function processes a population list and a hybrid structure definition to create:
    1. Individual .tsv files for each hybrid group (for PLINK --keep)
    2. An updated population list that includes the hybrid individuals

    Args:
        full_pop_list_path: Path to the population list file (tab-separated with FID, IID, Pop columns).
        hybrid_structure: Path to a JSON file containing the hybrid structure definition.
            The JSON should be a dictionary like {"Pop1-Pop2-Pop3": ["Pop1", "Pop2", "Pop3"]}.
        output_dir: Directory where the output files will be saved.

    Returns:
        None

    Raises:
        FileNotFoundError: If the input files don't exist
        ValueError: If the input files are empty or malformed
        ValueError: If the hybrid structure is invalid
    """
    try:
        # Create output directory if it doesn't exist
        os.makedirs(output_dir, exist_ok=True)

        # Load hybrid structure
        try:
            with open(hybrid_structure) as f:
                hybrid_structure = json.load(f)
        except FileNotFoundError:
            raise FileNotFoundError(f"Hybrid structure file not found: {hybrid_structure}")
        except json.JSONDecodeError:
            raise ValueError(f"Invalid hybrid structure file: {hybrid_structure}")

        # Read population list
        try:
            poplist = pd.read_csv(full_pop_list_path, sep="\t", names=["FID", "IID", "Pop"])
            if poplist.empty or poplist.isna().all().all():
                raise ValueError("Population list file is empty or malformed")
        except FileNotFoundError:
            raise FileNotFoundError(f"Population list file not found: {full_pop_list_path}")
        except pd.errors.EmptyDataError:
            raise ValueError(f"Population list file is empty: {full_pop_list_path}")

        hybrid_entries = []

        logging.info(f"Unique populations available:{poplist['Pop'].unique()}")


        for group_index, (hybrid_label, source_pops) in enumerate(hybrid_structure.items()):
            # Get individuals for each source population
            subpops = [poplist[poplist["Pop"] == pop] for pop in source_pops]
            sizes = [len(df) for df in subpops]

            if min(sizes) == 0:
                logging.warning(f"Skipping {hybrid_label} — one or more source pops are empty.")
                continue

            n_to_use = min(sizes)
            logging.info(f"{hybrid_label}: using {n_to_use} individuals per pop")

            # Sample individuals from each population
            trimmed_dfs = [
                df.sample(n=n_to_use, random_state=group_index)
                for df in subpops
            ]

            # Combine all individuals for PLINK --keep
            combined = pd.concat(trimmed_dfs)
            combined[["FID", "IID"]].to_csv(
                os.path.join(output_dir, f"{hybrid_label}.tsv"),
                sep="\t", index=False, header=False
            )

            # Add hybrid FID/IID entries
            for i in range(n_to_use):
                hybrid_entries.append({
                    "FID": f"{hybrid_label}_{i}",
                    "IID": f"{hybrid_label}_{i}",
                    "Pop": hybrid_label
                })

        # Save updated population list
        hybrid_df = pd.DataFrame(hybrid_entries)
        updated_poplist = pd.concat([poplist, hybrid_df])
        updated_poplist.to_csv(
            os.path.join(output_dir, "population_list_with_hybrids.tsv"),
            sep="\t", index=False, header=False
        )

        logging.info("Done: One .tsv per hybrid group ready for PLINK.")
    except ValueError:
        raise
    except FileNotFoundError:
        raise FileNotFoundError(f"Population list file not found: {full_pop_list_path}")
    except Exception as e:
        raise Exception(f"An error occurred while processing the files: {str(e)}")

def create_snpsplit_hybrids_aligned(
    ped_file: str,
    hybrid_label: str,
    pop_names: List[str],
    output_dir: str
) -> None:
    """
    Creates SNP-split hybrids from a .ped file by aligning individuals across populations.

    This function takes a .ped file containing individuals from multiple populations and creates
    hybrid individuals by combining SNP blocks from different populations. Each hybrid individual
    is created by taking SNP blocks from different source populations in sequence.

    Assumptions:
    - Equal number of individuals per population
    - Individuals ordered by population in the .ped file
    - All individuals have the same number of SNPs

    Args:
        ped_file: Path to the .ped file containing all individuals from the hybrid group.
            The file should be in standard PLINK .ped format with 6 metadata columns
            followed by genotype columns.
        hybrid_label: Label to use for the hybrid individuals (e.g., "Pop1-Pop2-Pop3").
        pop_names: List of population names in SNP block order (e.g., ["Pop1", "Pop2", "Pop3"]).
            The order determines which SNP blocks come from which population.
        output_dir: Directory where the output .ped file will be saved.

    Returns:
        None

    Raises:
        FileNotFoundError: If the input .ped file doesn't exist
        ValueError: If the input file is empty or malformed
        ValueError: If the number of individuals is not divisible by the number of populations
        ValueError: If the number of SNPs is not divisible by the number of populations
    """
    try:
        # Create output directory if it doesn't exist
        os.makedirs(output_dir, exist_ok=True)

        # Read and validate .ped file
        try:
            with open(ped_file, 'r') as f:
                all_lines = [line.strip().split() for line in f]
        except FileNotFoundError:
            raise FileNotFoundError(f"Input .ped file not found: {ped_file}")

        if not all_lines:
            raise ValueError("Input .ped file is empty")

        # Validate number of individuals and populations
        n_pops = len(pop_names)
        total_inds = len(all_lines)
        n_per_pop = total_inds // n_pops

        if total_inds % n_pops != 0:
            raise ValueError(f"Number of individuals ({total_inds}) must be divisible by number of populations ({n_pops})")

        # Validate SNP count and blocks
        snp_count = (len(all_lines[0]) - 6) // 2
        snps_per_block = snp_count // n_pops

        #if snp_count % n_pops != 0:
        #    raise ValueError(f"Number of SNPs ({snp_count}) must be divisible by number of populations ({n_pops})")

        logging.info(f"Processing {n_pops} populations with {n_per_pop} individuals each")
        logging.info(f"Total SNPs: {snp_count}, SNPs per block: {snps_per_block}")

        # Split individuals by population
        pop_to_inds = {
            pop: all_lines[i * n_per_pop:(i + 1) * n_per_pop]
            for i, pop in enumerate(pop_names)
        }

        hybrid_lines = []

        for i in range(n_per_pop):
            hybrid_id = f"{hybrid_label}_{i}"
            meta = [hybrid_id, hybrid_id, "0", "0", "1", "-9"]
            geno = []

            for block_index, pop in enumerate(pop_names):
                selected = pop_to_inds[pop][i]
                start_snp = block_index * snps_per_block
                end_snp = snp_count if block_index == n_pops - 1 else (block_index + 1) * snps_per_block

                for snp_index in range(start_snp, end_snp):
                    j = 6 + snp_index * 2
                    allele1 = selected[j]
                    allele2 = selected[j + 1]
                    geno.extend([allele1, allele2])

            hybrid_lines.append(meta + geno)

        snp_count_new = (len(hybrid_lines[0]) - 6) // 2
        assert snp_count_new == snp_count, f"Expected {snp_count} SNPs, got {snp_count_new}"
        # Save output file
        out_file = os.path.join(output_dir, f"{hybrid_label}.ped")
        with open(out_file, "w") as f:
            for line in hybrid_lines:
                f.write(" ".join(line) + "\n")

        logging.info(f"Created {n_per_pop} hybrids for {hybrid_label} and saved to {out_file}")
    except ValueError:
        raise
    except FileNotFoundError:
        raise
    except Exception as e:
        raise Exception(f"An error occurred while processing the .ped file: {str(e)}")


def main():
    """Main function to handle command line arguments and execute the appropriate function."""
    parser = argparse.ArgumentParser(
        description="Population manipulation tools for genetic data analysis",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Remove specific populations
  python population_manipulation.py drop_specific_populations input.tsv output.tsv Druze Colombian

  # Add outgroup populations
  python population_manipulation.py new_outgroup input.tsv Deni output_dir

  # Generate population lists with reduced sample sizes
  python population_manipulation.py generate_pop_lists input.tsv 10 output_dir 5

  # Prepare hybrid group population lists
  python population_manipulation.py prepare_groupwise_hybrid_lists input.tsv hybrid_structure.json output_dir

  # Create SNP-split hybrids
  python population_manipulation.py create_snpsplit_hybrids input.ped "Pop1-Pop2" Pop1 Pop2 output_dir
        """
    )

    # Create subparsers for each function
    subparsers = parser.add_subparsers(dest="function", help="Function to execute")

    # Drop continents parser
    drop_continents_parser = subparsers.add_parser("drop_continents", help="Remove populations from a specific continent")
    drop_continents_parser.add_argument("input_file", help="Path to the input TSV file")
    drop_continents_parser.add_argument("continent_to_remove", help="Continent to remove")
    drop_continents_parser.add_argument("population_mapping_file", help="Path to the population to continent mapping file")
    drop_continents_parser.add_argument("output_dir", help="Output directory")

    # Drop random populations parser
    drop_random_parser = subparsers.add_parser("drop_random_populations", help="Randomly remove populations")
    drop_random_parser.add_argument("poplist_file", help="Path to the population list file")
    drop_random_parser.add_argument("outdir", help="Output directory")
    drop_random_parser.add_argument("--percentage", type=float, default=0.50, help="Percentage of populations to remove (default: 0.50)")
    drop_random_parser.add_argument("--random-state", type=int, default=42, help="Random seed for reproducibility (default: 42)")

    # Drop specific populations parser
    drop_specific_parser = subparsers.add_parser("drop_specific_populations", help="Remove specific populations")
    drop_specific_parser.add_argument("poplist_file", help="Path to the population list file")
    drop_specific_parser.add_argument("path", help="Output path")
    drop_specific_parser.add_argument("populations", nargs="+", help="Populations to remove")

    # Generate pop lists parser
    generate_parser = subparsers.add_parser("generate_pop_lists", help="Generate population lists with controlled sample sizes")
    generate_parser.add_argument("full_list_path", help="Path to the input population list")
    generate_parser.add_argument("nr_individuals", type=int, help="Number of individuals to retain")
    generate_parser.add_argument("outdir", help="Output directory")
    generate_parser.add_argument("--num-populations", default="10", help="Number of populations to reduce (default: 10)")
    generate_parser.add_argument("--random-state", type=int, default=42, help="Random seed (default: 42)")

    # Reduce population counts parser
    reduce_parser = subparsers.add_parser("reduce_population_counts", help="Reduce sample sizes for specific populations")
    reduce_parser.add_argument("poplist_file", help="Path to the population list file")
    reduce_parser.add_argument("out_path", help="Output path")
    reduce_parser.add_argument("populations", help="Comma-separated list of populations to reduce")
    reduce_parser.add_argument("max_per_population", type=int, help="Maximum number of individuals per population")

    # New outgroup parser
    outgroup_parser = subparsers.add_parser("new_outgroup", help="Add outgroup populations")
    outgroup_parser.add_argument("poplist_file", help="Path to the population list file")
    outgroup_parser.add_argument("outgroup_type", choices=["Deni", "Vindija", "Both"], help="Type of outgroup to add")
    outgroup_parser.add_argument("outdir", help="Output directory")

    # Write JSON structures parser
    json_parser = subparsers.add_parser("write_json_structures", help="Generate JSON structures for hybrid populations")
    json_parser.add_argument("outdir", help="Output directory")
    json_parser.add_argument("number_of_pop_per_hybrid", type=int, help="Number of populations per hybrid")

    # Prepare groupwise hybrid lists parser
    hybrid_parser = subparsers.add_parser("prepare_groupwise_hybrid_lists", help="Prepare hybrid group population lists")
    hybrid_parser.add_argument("full_pop_list_path", help="Path to the full population list file")
    hybrid_parser.add_argument("hybrid_structure", help="Path to the hybrid structure JSON file")
    hybrid_parser.add_argument("output_dir", help="Output directory")

    # Create SNP-split hybrids parser
    snpsplit_parser = subparsers.add_parser("create_snpsplit_hybrids", help="Create SNP-split hybrids from a .ped file")
    snpsplit_parser.add_argument("ped_file", help="Path to the input .ped file")
    snpsplit_parser.add_argument("hybrid_label", help="Label for the hybrid individuals")
    snpsplit_parser.add_argument("pop_names", nargs="+", help="List of population names in SNP block order")
    snpsplit_parser.add_argument("output_dir", help="Output directory")

    args = parser.parse_args()

    try:
        if args.function == "drop_continents":
            drop_continents(args.input_file, args.continent_to_remove, args.population_mapping_file, args.output_dir)
        
        elif args.function == "drop_random_populations":
            drop_random_populations(
                args.poplist_file,
                args.outdir,
                args.percentage,
                args.random_state
            )
        
        elif args.function == "drop_specific_populations":
            drop_specific_populations(
                args.poplist_file,
                args.path,
                populations_to_remove=args.populations
            )
        
        elif args.function == "generate_pop_lists":
            generate_pop_lists(
                args.full_list_path,
                args.nr_individuals,
                args.outdir,
                args.num_populations,
                args.random_state
            )
        
        elif args.function == "reduce_population_counts":
            populations_to_reduce = args.populations.split(",")
            reduce_population_counts(
                args.poplist_file,
                args.out_path,
                populations_to_reduce,
                args.max_per_population
            )
        
        elif args.function == "new_outgroup":
            new_outgroup(args.poplist_file, args.outgroup_type, args.outdir)
        
        elif args.function == "write_json_structures":
            write_json_structures(args.outdir, args.number_of_pop_per_hybrid)
        
        elif args.function == "prepare_groupwise_hybrid_lists":
            prepare_groupwise_hybrid_lists(
                args.full_pop_list_path,
                args.hybrid_structure,
                args.output_dir
            )
        
        elif args.function == "create_snpsplit_hybrids":
            create_snpsplit_hybrids_aligned(
                args.ped_file,
                args.hybrid_label,
                args.pop_names,
                args.output_dir
            )
        
        else:
            parser.print_help()
            sys.exit(1)

    except Exception as e:
        logging.error(f"Error: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()





